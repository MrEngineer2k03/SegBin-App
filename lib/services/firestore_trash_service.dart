import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreTrashService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'Trashbin Data';
  static const String _documentId = 'trash_data'; // Single document ID

  /// Get current trash counts from Firestore
  static Future<Map<String, int>> getTrashData() async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(_documentId).get();
      
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        return {
          'Plastic': (data['Plastic'] as num?)?.toInt() ?? 0,
          'Paper': (data['Paper'] as num?)?.toInt() ?? 0,
          'Single-stream': (data['Single-stream'] as num?)?.toInt() ?? 0,
          'Mixed': (data['Mixed'] as num?)?.toInt() ?? 0,
        };
      }
      
      // If document doesn't exist, return zeros
      return {
        'Plastic': 0,
        'Paper': 0,
        'Single-stream': 0,
        'Mixed': 0,
      };
    } catch (e) {
      print('Error getting trash data from Firestore: $e');
      return {
        'Plastic': 0,
        'Paper': 0,
        'Single-stream': 0,
        'Mixed': 0,
      };
    }
  }

  /// Increment trash count for a specific type
  static Future<void> incrementTrashCount(String type, int amount) async {
    try {
      final fieldName = _getFieldName(type);
      final docRef = _firestore.collection(_collectionName).doc(_documentId);
      
      // Use FieldValue.increment to atomically increment the value
      await docRef.set({
        fieldName: FieldValue.increment(amount),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error incrementing trash count in Firestore: $e');
      rethrow;
    }
  }

  /// Set trash count for a specific type
  static Future<void> setTrashCount(String type, int count) async {
    try {
      final fieldName = _getFieldName(type);
      await _firestore.collection(_collectionName).doc(_documentId).set({
        fieldName: count,
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error setting trash count in Firestore: $e');
      rethrow;
    }
  }

  /// Set all trash counts at once
  static Future<void> setAllTrashCounts({
    required int plastic,
    required int paper,
    required int singleStream,
    required int mixed,
  }) async {
    try {
      await _firestore.collection(_collectionName).doc(_documentId).set({
        'Plastic': plastic,
        'Paper': paper,
        'Single-stream': singleStream,
        'Mixed': mixed,
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error setting all trash counts in Firestore: $e');
      rethrow;
    }
  }

  /// Reset all trash counts to zero
  static Future<void> resetAllTrashCounts() async {
    try {
      await _firestore.collection(_collectionName).doc(_documentId).set({
        'Plastic': 0,
        'Paper': 0,
        'Single-stream': 0,
        'Mixed': 0,
      });
    } catch (e) {
      print('Error resetting trash counts in Firestore: $e');
      rethrow;
    }
  }

  /// Listen to trash data changes in real-time
  static Stream<Map<String, int>> listenToTrashData() {
    return _firestore
        .collection(_collectionName)
        .doc(_documentId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        return {
          'Plastic': (data['Plastic'] as num?)?.toInt() ?? 0,
          'Paper': (data['Paper'] as num?)?.toInt() ?? 0,
          'Single-stream': (data['Single-stream'] as num?)?.toInt() ?? 0,
          'Mixed': (data['Mixed'] as num?)?.toInt() ?? 0,
        };
      }
      return {
        'Plastic': 0,
        'Paper': 0,
        'Single-stream': 0,
        'Mixed': 0,
      };
    });
  }

  /// Convert kiosk type to Firestore field name
  static String _getFieldName(String kioskType) {
    switch (kioskType) {
      case 'plastic':
        return 'Plastic';
      case 'paper':
        return 'Paper';
      case 'single-stream':
        return 'Single-stream';
      case 'mixed':
        return 'Mixed';
      default:
        return 'Mixed';
    }
  }
}

