import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/feedback.dart';

class FeedbackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'feedback';

  // Submit feedback to Firestore
  Future<bool> submitFeedback(
    String message, {
    String? userId,
    String? name,
    String? subject,
    String? category,
    String? email,
    String? idNumber,
    String? profilePicture,
  }) async {
    try {
      final String id = _firestore.collection(_collectionName).doc().id;
      final Feedback feedback = Feedback(
        id: id,
        message: message,
        feedbackTime: DateTime.now(),
        userId: userId,
        name: name,
        subject: subject,
        category: category,
        email: email,
        idNumber: idNumber,
        profilePicture: profilePicture,
      );

      await _firestore.collection(_collectionName).doc(id).set(feedback.toJson());
      return true;
    } catch (e) {
      print('Error submitting feedback: $e');
      return false;
    }
  }

  // Get all feedback (for admin purposes)
  Future<List<Feedback>> getAllFeedback() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collectionName)
          .orderBy('feedbackTime', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Feedback.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting feedback: $e');
      return [];
    }
  }

  // Get feedback by user ID
  Future<List<Feedback>> getFeedbackByUserId(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .orderBy('feedbackTime', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Feedback.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting user feedback: $e');
      return [];
    }
  }

  // Delete feedback (for admin purposes)
  Future<bool> deleteFeedback(String feedbackId) async {
    try {
      await _firestore.collection(_collectionName).doc(feedbackId).delete();
      return true;
    } catch (e) {
      print('Error deleting feedback: $e');
      return false;
    }
  }
}
