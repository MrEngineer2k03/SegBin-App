import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reward.dart';

class RewardFirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'Mobile App Rewards Data';

  // Create a new reward
  static Future<String> createReward({
    required String name,
    required String description,
    required int pointsNeeded,
    String? redeemCode,
    String platform = 'both', // 'mobile', 'kiosk', or 'both'
  }) async {
    try {
      // Ensure platform is explicitly set
      final platformValue = platform.isNotEmpty ? platform : 'both';
      
      final rewardData = {
        'name': name,
        'description': description,
        'minimumRequirement': pointsNeeded,
        'redeemCode': redeemCode,
        'platform': platformValue,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection(_collectionName).add(rewardData);
      print('Reward created with ID: ${docRef.id}, platform: $platformValue');
      return docRef.id;
    } catch (e) {
      print('Error creating reward: $e');
      rethrow;
    }
  }

  // Get all rewards
  static Future<List<Reward>> getAllRewards() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .orderBy('createdAt', descending: false)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        final platformStr = data['platform'] ?? 'both';
        return Reward(
          id: doc.id,
          name: data['name'] ?? '',
          description: data['description'] ?? '',
          minimumRequirement: data['minimumRequirement'] ?? 0,
          redeemCode: data['redeemCode'],
          platform: RewardPlatform.values.firstWhere(
            (e) => e.toString().split('.').last == platformStr,
            orElse: () => RewardPlatform.both,
          ),
        );
      }).toList();
    } catch (e) {
      print('Error getting rewards: $e');
      return [];
    }
  }

  // Get a single reward by ID
  static Future<Reward?> getRewardById(String id) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(id).get();
      if (doc.exists) {
        final data = doc.data()!;
        final platformStr = data['platform'] ?? 'both';
        return Reward(
          id: doc.id,
          name: data['name'] ?? '',
          description: data['description'] ?? '',
          minimumRequirement: data['minimumRequirement'] ?? 0,
          redeemCode: data['redeemCode'],
          platform: RewardPlatform.values.firstWhere(
            (e) => e.toString().split('.').last == platformStr,
            orElse: () => RewardPlatform.both,
          ),
        );
      }
      return null;
    } catch (e) {
      print('Error getting reward: $e');
      return null;
    }
  }

  // Update a reward
  static Future<bool> updateReward({
    required String id,
    required String name,
    required String description,
    required int pointsNeeded,
    String? redeemCode,
    String platform = 'both',
  }) async {
    try {
      await _firestore.collection(_collectionName).doc(id).update({
        'name': name,
        'description': description,
        'minimumRequirement': pointsNeeded,
        'redeemCode': redeemCode,
        'platform': platform,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('Reward updated: $id');
      return true;
    } catch (e) {
      print('Error updating reward: $e');
      return false;
    }
  }

  // Delete a reward
  static Future<bool> deleteReward(String id) async {
    try {
      await _firestore.collection(_collectionName).doc(id).delete();
      print('Reward deleted: $id');
      return true;
    } catch (e) {
      print('Error deleting reward: $e');
      return false;
    }
  }

  // Stream of rewards for real-time updates
  static Stream<List<Reward>> rewardsStream() {
    return _firestore
        .collection(_collectionName)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final platformStr = data['platform'] ?? 'both';
        return Reward(
          id: doc.id,
          name: data['name'] ?? '',
          description: data['description'] ?? '',
          minimumRequirement: data['minimumRequirement'] ?? 0,
          redeemCode: data['redeemCode'],
          platform: RewardPlatform.values.firstWhere(
            (e) => e.toString().split('.').last == platformStr,
            orElse: () => RewardPlatform.both,
          ),
        );
      }).toList();
    });
  }
}

