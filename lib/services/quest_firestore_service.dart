import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/quest.dart';

class QuestFirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'Quests Data';

  // Create a new quest
  static Future<String> createQuest({
    required String name,
    required String type, // 'plastic', 'paper', 'single-stream', 'mixed'
    required String description,
    required String reward,
    int target = 1,
    String platform = 'kiosk', // 'mobile', 'kiosk', or 'both'
  }) async {
    try {
      final questData = {
        'name': name,
        'title': name, // Also include as 'title' for compatibility
        'type': type,
        'description': description,
        'reward': reward,
        'target': target,
        'platform': platform,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection(_collectionName).add(questData);
      print('Quest created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error creating quest: $e');
      rethrow;
    }
  }

  // Get all quests
  static Future<List<Quest>> getAllQuests() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .orderBy('createdAt', descending: false)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Quest.fromJson({
          'id': doc.id,
          ...data,
        });
      }).toList();
    } catch (e) {
      print('Error getting quests: $e');
      rethrow;
    }
  }

  // Get quest by ID
  static Future<Quest?> getQuestById(String id) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(id).get();
      if (!doc.exists) {
        return null;
      }
      final data = doc.data()!;
      return Quest.fromJson({
        'id': doc.id,
        ...data,
      });
    } catch (e) {
      print('Error getting quest: $e');
      rethrow;
    }
  }

  // Update quest
  static Future<bool> updateQuest({
    required String id,
    required String name,
    required String type,
    required String description,
    required String reward,
    int? target,
    String? platform,
  }) async {
    try {
      final questData = <String, dynamic>{
        'name': name,
        'title': name, // Also include as 'title' for compatibility
        'type': type,
        'description': description,
        'reward': reward,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (target != null) {
        questData['target'] = target;
      }
      if (platform != null) {
        questData['platform'] = platform;
      }

      await _firestore.collection(_collectionName).doc(id).update(questData);
      print('Quest updated: $id');
      return true;
    } catch (e) {
      print('Error updating quest: $e');
      return false;
    }
  }

  // Delete quest
  static Future<bool> deleteQuest(String id) async {
    try {
      await _firestore.collection(_collectionName).doc(id).delete();
      print('Quest deleted: $id');
      return true;
    } catch (e) {
      print('Error deleting quest: $e');
      return false;
    }
  }

  // Stream of quests for real-time updates
  static Stream<List<Quest>> questsStream() {
    return _firestore
        .collection(_collectionName)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Quest.fromJson({
          'id': doc.id,
          ...data,
        });
      }).toList();
    });
  }
}

