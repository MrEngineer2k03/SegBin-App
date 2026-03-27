import 'package:cloud_firestore/cloud_firestore.dart';

class AppSettingsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'App Settings';
  static const String _documentId = 'global_config';
  static const String pointingSystemEnabledKey = 'pointingSystemEnabled';

  static const bool defaultPointingSystemEnabled = true;

  static Future<bool> isPointingSystemEnabled() async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(_documentId).get();

      if (doc.exists && doc.data() != null) {
        return doc.data()![pointingSystemEnabledKey] as bool? ??
            defaultPointingSystemEnabled;
      }

      await setPointingSystemEnabled(defaultPointingSystemEnabled);
      return defaultPointingSystemEnabled;
    } catch (e) {
      print('Error getting app settings from Firestore: $e');
      return defaultPointingSystemEnabled;
    }
  }

  static Future<void> setPointingSystemEnabled(bool enabled) async {
    try {
      await _firestore.collection(_collectionName).doc(_documentId).set({
        pointingSystemEnabledKey: enabled,
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error saving app settings to Firestore: $e');
      rethrow;
    }
  }

  static Stream<bool> listenToPointingSystemEnabled() {
    return _firestore
        .collection(_collectionName)
        .doc(_documentId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return doc.data()![pointingSystemEnabledKey] as bool? ??
            defaultPointingSystemEnabled;
      }

      return defaultPointingSystemEnabled;
    });
  }
}
