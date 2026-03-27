import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/announcement.dart';

class AnnouncementFirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'Announcements';

  // Create a new announcement
  static Future<String> createAnnouncement({
    required String title,
    required String content,
    bool isActive = true,
    int priority = 0,
  }) async {
    try {
      final announcementData = {
        'title': title,
        'content': content,
        'isActive': isActive,
        'priority': priority,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef =
          await _firestore.collection(_collectionName).add(announcementData);
      print('Announcement created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error creating announcement: $e');
      rethrow;
    }
  }

  // Get all announcements
  static Future<List<Announcement>> getAllAnnouncements() async {
    try {
      // Try the optimized query with index first
      try {
        final querySnapshot = await _firestore
            .collection(_collectionName)
            .orderBy('priority', descending: true)
            .orderBy('createdAt', descending: true)
            .get();

        return querySnapshot.docs.map((doc) {
          final data = doc.data();
          return Announcement.fromJson({
            'id': doc.id,
            ...data,
          });
        }).toList();
      } catch (indexError) {
        // Fallback: fetch all and sort in memory if index is missing
        print('Composite index not available for getAllAnnouncements, falling back to in-memory sorting: $indexError');
        
        final querySnapshot = await _firestore
            .collection(_collectionName)
            .get();

        final allAnnouncements = querySnapshot.docs.map((doc) {
          final data = doc.data();
          return Announcement.fromJson({
            'id': doc.id,
            ...data,
          });
        }).toList();

        // Sort by priority (descending) then by createdAt (descending)
        allAnnouncements.sort((a, b) {
          final priorityCompare = b.priority.compareTo(a.priority);
          if (priorityCompare != 0) return priorityCompare;
          return b.createdAt.compareTo(a.createdAt);
        });

        return allAnnouncements;
      }
    } catch (e) {
      print('Error getting announcements: $e');
      return []; // Return empty list instead of rethrowing
    }
  }

  // Get active announcements (for user display)
  // Note: Firestore compound queries with where + multiple orderBy require composite indexes.
  // To avoid index requirements, we fetch all and filter/sort in memory.
  static Future<List<Announcement>> getActiveAnnouncements() async {
    try {
      // First, try the optimized query with index
      try {
        final querySnapshot = await _firestore
            .collection(_collectionName)
            .where('isActive', isEqualTo: true)
            .orderBy('priority', descending: true)
            .orderBy('createdAt', descending: true)
            .get();

        return querySnapshot.docs.map((doc) {
          final data = doc.data();
          return Announcement.fromJson({
            'id': doc.id,
            ...data,
          });
        }).toList();
      } catch (indexError) {
        // If index is missing, fallback to fetching all and filtering in memory
        print('Composite index not available, falling back to in-memory filtering: $indexError');
        
        final querySnapshot = await _firestore
            .collection(_collectionName)
            .get();

        final allAnnouncements = querySnapshot.docs.map((doc) {
          final data = doc.data();
          return Announcement.fromJson({
            'id': doc.id,
            ...data,
          });
        }).toList();

        // Filter active announcements
        final activeAnnouncements = allAnnouncements
            .where((announcement) => announcement.isActive)
            .toList();

        // Sort by priority (descending) then by createdAt (descending)
        activeAnnouncements.sort((a, b) {
          final priorityCompare = b.priority.compareTo(a.priority);
          if (priorityCompare != 0) return priorityCompare;
          return b.createdAt.compareTo(a.createdAt);
        });

        return activeAnnouncements;
      }
    } catch (e) {
      print('Error getting active announcements: $e');
      return []; // Return empty list instead of rethrowing to prevent UI crashes
    }
  }

  // Get announcement by ID
  static Future<Announcement?> getAnnouncementById(String id) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(id).get();
      if (doc.exists) {
        final data = doc.data()!;
        return Announcement.fromJson({
          'id': doc.id,
          ...data,
        });
      }
      return null;
    } catch (e) {
      print('Error getting announcement by ID: $e');
      return null;
    }
  }

  // Update announcement
  static Future<bool> updateAnnouncement({
    required String id,
    String? title,
    String? content,
    bool? isActive,
    int? priority,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (title != null) updateData['title'] = title;
      if (content != null) updateData['content'] = content;
      if (isActive != null) updateData['isActive'] = isActive;
      if (priority != null) updateData['priority'] = priority;

      await _firestore.collection(_collectionName).doc(id).update(updateData);
      print('Announcement updated: $id');
      return true;
    } catch (e) {
      print('Error updating announcement: $e');
      return false;
    }
  }

  // Delete announcement
  static Future<bool> deleteAnnouncement(String id) async {
    try {
      await _firestore.collection(_collectionName).doc(id).delete();
      print('Announcement deleted: $id');
      return true;
    } catch (e) {
      print('Error deleting announcement: $e');
      return false;
    }
  }

  // Stream of announcements for real-time updates
  // Note: Uses simple query without compound index to avoid index requirements
  static Stream<List<Announcement>> announcementsStream() {
    return _firestore
        .collection(_collectionName)
        .snapshots()
        .map((snapshot) {
      final announcements = snapshot.docs.map((doc) {
        final data = doc.data();
        return Announcement.fromJson({
          'id': doc.id,
          ...data,
        });
      }).toList();
      
      // Sort in memory by priority (descending) then by createdAt (descending)
      announcements.sort((a, b) {
        final priorityCompare = b.priority.compareTo(a.priority);
        if (priorityCompare != 0) return priorityCompare;
        return b.createdAt.compareTo(a.createdAt);
      });
      
      return announcements;
    });
  }

  // Stream of active announcements for real-time updates
  // Note: Uses simple query and filters in memory to avoid compound index requirements
  static Stream<List<Announcement>> activeAnnouncementsStream() {
    return _firestore
        .collection(_collectionName)
        .snapshots()
        .map((snapshot) {
      final allAnnouncements = snapshot.docs.map((doc) {
        final data = doc.data();
        return Announcement.fromJson({
          'id': doc.id,
          ...data,
        });
      }).toList();
      
      // Filter active announcements
      final activeAnnouncements = allAnnouncements
          .where((announcement) => announcement.isActive)
          .toList();
      
      // Sort by priority (descending) then by createdAt (descending)
      activeAnnouncements.sort((a, b) {
        final priorityCompare = b.priority.compareTo(a.priority);
        if (priorityCompare != 0) return priorityCompare;
        return b.createdAt.compareTo(a.createdAt);
      });
      
      return activeAnnouncements;
    });
  }
}
