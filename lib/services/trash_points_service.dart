import 'package:cloud_firestore/cloud_firestore.dart';

class TrashPointsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'Trash Points';
  static const String _documentId = 'points_config'; // Single document ID

  /// Default points per trash type
  static const Map<String, double> defaultPoints = {
    'Plastic': 5.0,
    'Paper': 3.0,
    'Single-stream': 4.0,
  };

  /// Get current points configuration from Firestore
  static Future<Map<String, double>> getTrashPoints() async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(_documentId).get();
      
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        return {
          'Plastic': (data['Plastic'] as num?)?.toDouble() ?? defaultPoints['Plastic']!,
          'Paper': (data['Paper'] as num?)?.toDouble() ?? defaultPoints['Paper']!,
          'Single-stream': (data['Single-stream'] as num?)?.toDouble() ?? defaultPoints['Single-stream']!,
        };
      }
      
      // If document doesn't exist, return defaults and create the document
      await setTrashPoints(defaultPoints);
      return defaultPoints;
    } catch (e) {
      print('Error getting trash points from Firestore: $e');
      return defaultPoints;
    }
  }

  /// Set points for a specific trash type
  static Future<void> setPointsForType(String type, double points) async {
    try {
      if (points < 0) {
        throw ArgumentError('Points cannot be negative');
      }
      
      await _firestore.collection(_collectionName).doc(_documentId).set({
        type: points,
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error setting trash points in Firestore: $e');
      rethrow;
    }
  }

  /// Set all trash points at once
  static Future<void> setTrashPoints(Map<String, double> points) async {
    try {
      // Validate all points are non-negative
      for (final entry in points.entries) {
        if (entry.value < 0) {
          throw ArgumentError('Points cannot be negative for ${entry.key}');
        }
      }
      
      await _firestore.collection(_collectionName).doc(_documentId).set({
        'Plastic': points['Plastic'] ?? defaultPoints['Plastic']!,
        'Paper': points['Paper'] ?? defaultPoints['Paper']!,
        'Single-stream': points['Single-stream'] ?? defaultPoints['Single-stream']!,
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error setting trash points in Firestore: $e');
      rethrow;
    }
  }

  /// Reset all trash points to defaults
  static Future<void> resetToDefaults() async {
    try {
      await _firestore.collection(_collectionName).doc(_documentId).set({
        'Plastic': defaultPoints['Plastic']!,
        'Paper': defaultPoints['Paper']!,
        'Single-stream': defaultPoints['Single-stream']!,
      });
    } catch (e) {
      print('Error resetting trash points in Firestore: $e');
      rethrow;
    }
  }

  /// Listen to trash points changes in real-time
  static Stream<Map<String, double>> listenToTrashPoints() {
    return _firestore
        .collection(_collectionName)
        .doc(_documentId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        return {
          'Plastic': (data['Plastic'] as num?)?.toDouble() ?? defaultPoints['Plastic']!,
          'Paper': (data['Paper'] as num?)?.toDouble() ?? defaultPoints['Paper']!,
          'Single-stream': (data['Single-stream'] as num?)?.toDouble() ?? defaultPoints['Single-stream']!,
        };
      }
      return defaultPoints;
    });
  }

  /// Get points for a specific trash type
  static Future<double> getPointsForType(String type) async {
    final points = await getTrashPoints();
    return points[type] ?? defaultPoints[type] ?? 0.0;
  }
}

