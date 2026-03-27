import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reward_code.dart';

class RewardCodeFirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'Reward Codes';

  // Create a new reward code
  static Future<String> createRewardCode({
    required String code,
    required double points,
  }) async {
    try {
      // Check if code already exists (not redeemed and not assigned)
      final existingCode = await _firestore
          .collection(_collectionName)
          .where('code', isEqualTo: code)
          .where('isRedeemed', isEqualTo: false)
          .where('isAssigned', isEqualTo: false)
          .get();

      if (existingCode.docs.isNotEmpty) {
        throw Exception('Code already exists');
      }

      final rewardCodeData = {
        'code': code,
        'points': points,
        'isRedeemed': false,
        'isAssigned': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef =
          await _firestore.collection(_collectionName).add(rewardCodeData);
      print('Reward code created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error creating reward code: $e');
      rethrow;
    }
  }

  // Get all reward codes
  static Future<List<RewardCode>> getAllRewardCodes() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return RewardCode.fromJson({
          'id': doc.id,
          ...data,
        });
      }).toList();
    } catch (e) {
      print('Error getting reward codes: $e');
      rethrow;
    }
  }

  // Get available (unredeemed and unassigned) reward codes
  static Future<List<RewardCode>> getAvailableRewardCodes() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('isRedeemed', isEqualTo: false)
          .where('isAssigned', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return RewardCode.fromJson({
          'id': doc.id,
          ...data,
        });
      }).toList();
    } catch (e) {
      print('Error getting available reward codes: $e');
      rethrow;
    }
  }

  // Check if code exists and is available for redemption
  // Allows codes that are assigned (displayed in kiosk) but not yet redeemed
  static Future<RewardCode?> getRewardCodeByCode(String code) async {
    try {
      // First check "Reward Codes" collection
      // Allow codes that are assigned but not redeemed (they can still be redeemed)
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('code', isEqualTo: code)
          .where('isRedeemed', isEqualTo: false)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();
        // Convert Firestore Timestamp to DateTime if needed
        final redeemedAt = data['redeemedAt'];
        final convertedData = Map<String, dynamic>.from(data);
        if (redeemedAt != null && redeemedAt is Timestamp) {
          convertedData['redeemedAt'] = redeemedAt.toDate().toIso8601String();
        }
        return RewardCode.fromJson({
          'id': doc.id,
          ...convertedData,
        });
      }

      // If not found in "Reward Codes", check "Codes from Regular Trash" collection
      final regularTrashSnapshot = await _firestore
          .collection('Codes from Regular Trash')
          .where('code', isEqualTo: code)
          .where('isRedeemed', isEqualTo: false)
          .limit(1)
          .get();

      if (regularTrashSnapshot.docs.isNotEmpty) {
        final doc = regularTrashSnapshot.docs.first;
        final data = doc.data();
        // Convert "Codes from Regular Trash" format to RewardCode format
        // The "Codes from Regular Trash" has: code, totalPoints, trashItems, typeCounts, timestamp, createdAt, isRedeemed
        final convertedData = Map<String, dynamic>.from(data);
        final redeemedAt = data['redeemedAt'];
        if (redeemedAt != null && redeemedAt is Timestamp) {
          convertedData['redeemedAt'] = redeemedAt.toDate().toIso8601String();
        }
        // Map totalPoints to points for RewardCode model
        // Preserve decimal values (don't round)
        final totalPoints = data['totalPoints'] ?? 0;
        convertedData['points'] = totalPoints is double 
            ? totalPoints 
            : (totalPoints is int ? totalPoints.toDouble() : 0.0);
        return RewardCode.fromJson({
          'id': doc.id,
          ...convertedData,
        });
      }

      return null;
    } catch (e) {
      print('Error getting reward code by code: $e');
      return null;
    }
  }

  // Redeem a code
  // Allows redemption of codes that are assigned (displayed in kiosk) but not yet redeemed
  static Future<bool> redeemCode({
    required String code,
    required String userId,
  }) async {
    try {
      // First check "Reward Codes" collection
      // Allow codes that are assigned but not redeemed (they can still be redeemed)
      final rewardCodesSnapshot = await _firestore
          .collection(_collectionName)
          .where('code', isEqualTo: code)
          .where('isRedeemed', isEqualTo: false)
          .limit(1)
          .get();

      if (rewardCodesSnapshot.docs.isNotEmpty) {
        // Code is in "Reward Codes" collection
        final doc = rewardCodesSnapshot.docs.first;
        await _firestore.collection(_collectionName).doc(doc.id).update({
          'isRedeemed': true,
          'redeemedBy': userId,
          'redeemedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('Reward code redeemed: $code by user: $userId (from Reward Codes)');
        return true;
      }

      // If not in "Reward Codes", check "Codes from Regular Trash" collection
      final regularTrashSnapshot = await _firestore
          .collection('Codes from Regular Trash')
          .where('code', isEqualTo: code)
          .where('isRedeemed', isEqualTo: false)
          .limit(1)
          .get();

      if (regularTrashSnapshot.docs.isNotEmpty) {
        // Code is in "Codes from Regular Trash" collection
        final doc = regularTrashSnapshot.docs.first;
        await _firestore.collection('Codes from Regular Trash').doc(doc.id).update({
          'isRedeemed': true,
          'redeemedBy': userId,
          'redeemedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('Reward code redeemed: $code by user: $userId (from Codes from Regular Trash)');
        return true;
      }

      return false; // Code not found or already redeemed
    } catch (e) {
      print('Error redeeming reward code: $e');
      return false;
    }
  }

  // Delete reward code
  static Future<bool> deleteRewardCode(String id) async {
    try {
      await _firestore.collection(_collectionName).doc(id).delete();
      print('Reward code deleted: $id');
      return true;
    } catch (e) {
      print('Error deleting reward code: $e');
      return false;
    }
  }

  // Stream of reward codes for real-time updates
  static Stream<List<RewardCode>> rewardCodesStream() {
    return _firestore
        .collection(_collectionName)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        // Convert Firestore Timestamp to DateTime if needed
        final redeemedAt = data['redeemedAt'];
        final convertedData = Map<String, dynamic>.from(data);
        if (redeemedAt != null && redeemedAt is Timestamp) {
          convertedData['redeemedAt'] = redeemedAt.toDate().toIso8601String();
        }
        return RewardCode.fromJson({
          'id': doc.id,
          ...convertedData,
        });
      }).toList();
    });
  }
}

