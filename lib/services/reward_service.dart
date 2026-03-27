import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reward.dart';
import '../models/reward_code.dart';
import '../services/auth_service.dart';
import 'reward_firestore_service.dart';
import 'reward_code_firestore_service.dart';

class RewardService {
  static const String _rewardsKey = 'user_rewards';
  static const String _userProgressKey = 'user_reward_progress';

  // Default rewards list
  static List<Reward> getDefaultRewards() {
    return [
      Reward(
        id: 'reward_1',
        name: 'Free Coffee',
        description: 'Get a free coffee at the campus canteen',
        minimumRequirement: 10, // 10 points required
        redeemCode: 'COFFEE2024',
        platform: RewardPlatform.both,
      ),
      Reward(
        id: 'reward_2',
        name: '₱10 Canteen Discount',
        description: 'Enjoy ₱10 off on your next canteen purchase',
        minimumRequirement: 20, // 20 points required
        redeemCode: 'CANTEEN10',
        platform: RewardPlatform.both,
      ),
      Reward(
        id: 'reward_3',
        name: 'Eco Voucher',
        description: 'Redeem this voucher for eco-friendly merchandise',
        minimumRequirement: 50, // 50 points required
        redeemCode: 'ECOVOUCHER50',
        platform: RewardPlatform.both,
      ),
      Reward(
        id: 'reward_4',
        name: 'Premium Eco Badge',
        description: 'Unlock a special eco badge for your profile',
        minimumRequirement: 100, // 100 points required
        redeemCode: 'ECOBADGE100',
        platform: RewardPlatform.both,
      ),
    ];
  }

  // Get all rewards with current user progress
  static Future<List<Reward>> getUserRewards() async {
    try {
      final currentUser = AuthService.currentUser;
      
      // Load rewards from Firestore
      final firestoreRewards = await _loadRewardsFromFirestore();
      
      // If no rewards in Firestore, use defaults
      final rewardsList = firestoreRewards.isEmpty 
          ? getDefaultRewards() 
          : firestoreRewards;

      if (currentUser == null) {
        // Return rewards without user progress if no user logged in
        return rewardsList;
      }

      // Use user's current points directly
      final userPoints = currentUser.points;
      
      // Get user's redeemed rewards
      final redeemedRewards = await _getRedeemedRewards();

      // Filter rewards by platform (mobile app should only show mobile/both rewards)
      final mobileRewards = rewardsList.where((reward) {
        return reward.platform == RewardPlatform.mobile ||
            reward.platform == RewardPlatform.both;
      }).toList();

      // Create rewards with current progress
      final rewards = mobileRewards.map((reward) {
        // Progress is the user's current points
        final progressValue = userPoints;
        final isRedeemed = redeemedRewards.contains(reward.id);
        final isUnlocked = userPoints >= reward.minimumRequirement;

        RewardStatus status;
        if (isRedeemed) {
          status = RewardStatus.redeemed;
        } else if (isUnlocked) {
          status = RewardStatus.available;
        } else {
          status = RewardStatus.locked;
        }

        return reward.copyWith(
          currentProgress: progressValue,
          status: status,
        );
      }).toList();

      return rewards;
    } catch (e) {
      print('Error getting user rewards: $e');
      return getDefaultRewards();
    }
  }

  // Load rewards from Firestore
  static Future<List<Reward>> _loadRewardsFromFirestore() async {
    try {
      return await RewardFirestoreService.getAllRewards();
    } catch (e) {
      print('Error loading rewards from Firestore: $e');
      return [];
    }
  }

  // Update progress when user earns points
  // This method is called automatically when points are added via AuthService.addPoints()
  // No need to track separately since we use user's current points directly
  static Future<void> updateProgress(double pointsEarned) async {
    // Progress is automatically updated since we use AuthService.currentUser.points
    // This method is kept for compatibility but doesn't need to do anything
    // as rewards are calculated based on current user points in getUserRewards()
  }

  // Mark reward as redeemed
  static Future<bool> redeemReward(String rewardId) async {
    try {
      final currentUser = AuthService.currentUser;
      if (currentUser == null) return false;

      final rewards = await getUserRewards();
      final reward = rewards.firstWhere((r) => r.id == rewardId);

      if (reward.status != RewardStatus.available) {
        return false; // Can't redeem if not available
      }

      final redeemedRewards = await _getRedeemedRewards();
      redeemedRewards.add(rewardId);
      await _saveRedeemedRewards(redeemedRewards);

      return true;
    } catch (e) {
      print('Error redeeming reward: $e');
      return false;
    }
  }

  // Redeem reward code (4-digit code that gives points)
  static Future<Map<String, dynamic>> redeemRewardCode(String code) async {
    try {
      final currentUser = AuthService.currentUser;
      if (currentUser == null) {
        return {'success': false, 'message': 'User not logged in'};
      }

      // Normalize the code (trim, ensure 4 digits)
      final normalizedCode = code.trim();
      
      if (normalizedCode.length != 4 || !RegExp(r'^\d{4}$').hasMatch(normalizedCode)) {
        return {'success': false, 'message': 'Invalid code format. Please enter a 4-digit code.'};
      }

      // Check if code exists and is available
      final rewardCode = await RewardCodeFirestoreService.getRewardCodeByCode(normalizedCode);
      
      if (rewardCode == null) {
        return {'success': false, 'message': 'Invalid or already redeemed code'};
      }

      // Redeem the code
      final success = await RewardCodeFirestoreService.redeemCode(
        code: normalizedCode,
        userId: currentUser.username,
      );

      if (success) {
        // Add points to user
        await AuthService.addPoints(rewardCode.points);
        
        return {
          'success': true,
          'message': 'Code redeemed successfully! You received ${rewardCode.points} points.',
          'points': rewardCode.points,
        };
      } else {
        return {'success': false, 'message': 'Failed to redeem code. Please try again.'};
      }
    } catch (e) {
      print('Error redeeming reward code: $e');
      return {'success': false, 'message': 'An error occurred. Please try again.'};
    }
  }

  // Redeem reward by code
  static Future<Map<String, dynamic>> redeemByCode(String code) async {
    try {
      final currentUser = AuthService.currentUser;
      if (currentUser == null) {
        return {'success': false, 'message': 'User not logged in'};
      }

      // Normalize the code (uppercase, trim)
      final normalizedCode = code.trim().toUpperCase();

      // Find reward by code - load from Firestore first
      final firestoreRewards = await _loadRewardsFromFirestore();
      final rewardsList = firestoreRewards.isEmpty 
          ? getDefaultRewards() 
          : firestoreRewards;
      
      final reward = rewardsList.firstWhere(
        (r) => r.redeemCode != null && r.redeemCode!.toUpperCase() == normalizedCode,
        orElse: () => Reward(
          id: '',
          name: '',
          description: '',
          minimumRequirement: 0,
        ),
      );

      if (reward.id.isEmpty) {
        return {'success': false, 'message': 'Invalid redeem code'};
      }

      // Check if reward is unlocked
      final userRewards = await getUserRewards();
      final userReward = userRewards.firstWhere(
        (r) => r.id == reward.id,
        orElse: () => Reward(
          id: '',
          name: '',
          description: '',
          minimumRequirement: 0,
        ),
      );

      if (userReward.id.isEmpty) {
        return {'success': false, 'message': 'Reward not found'};
      }

      if (userReward.status == RewardStatus.locked) {
        return {
          'success': false,
          'message':
              'Reward not unlocked yet. Earn ${reward.minimumRequirement} points to unlock.'
        };
      }

      if (userReward.status == RewardStatus.redeemed) {
        return {'success': false, 'message': 'This reward has already been redeemed'};
      }

      // Redeem the reward
      final success = await redeemReward(reward.id);
      if (success) {
        return {
          'success': true,
          'message': '${reward.name} redeemed successfully!',
          'reward': reward
        };
      } else {
        return {'success': false, 'message': 'Failed to redeem reward'};
      }
    } catch (e) {
      print('Error redeeming by code: $e');
      return {'success': false, 'message': 'An error occurred. Please try again.'};
    }
  }

  // Get user's progress map
  static Future<Map<String, int>> _getUserProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = AuthService.currentUser?.username;
      if (username == null) return {};

      final progressKey = '${_userProgressKey}_$username';
      final progressString = prefs.getString(progressKey);
      if (progressString == null) return {};

      final Map<String, dynamic> decoded = jsonDecode(progressString);
      return decoded.map((key, value) => MapEntry(key, value as int));
    } catch (e) {
      print('Error getting user progress: $e');
      return {};
    }
  }

  // Save user's progress map
  static Future<void> _saveUserProgress(Map<String, int> progress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = AuthService.currentUser?.username;
      if (username == null) return;

      final progressKey = '${_userProgressKey}_$username';
      await prefs.setString(progressKey, jsonEncode(progress));
    } catch (e) {
      print('Error saving user progress: $e');
    }
  }

  // Get redeemed rewards list
  static Future<Set<String>> _getRedeemedRewards() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = AuthService.currentUser?.username;
      if (username == null) return {};

      final redeemedKey = '${_rewardsKey}_$username';
      final redeemedString = prefs.getString(redeemedKey);
      if (redeemedString == null) return {};

      final List<dynamic> decoded = jsonDecode(redeemedString);
      return decoded.map((e) => e as String).toSet();
    } catch (e) {
      print('Error getting redeemed rewards: $e');
      return {};
    }
  }

  // Save redeemed rewards list
  static Future<void> _saveRedeemedRewards(Set<String> redeemedRewards) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = AuthService.currentUser?.username;
      if (username == null) return;

      final redeemedKey = '${_rewardsKey}_$username';
      await prefs.setString(redeemedKey, jsonEncode(redeemedRewards.toList()));
    } catch (e) {
      print('Error saving redeemed rewards: $e');
    }
  }

  // Initialize progress based on user's current points
  // No initialization needed since we use user's current points directly
  static Future<void> initializeProgress() async {
    // This method is kept for compatibility but doesn't need to do anything
    // as rewards are calculated based on current user points in getUserRewards()
  }
}

