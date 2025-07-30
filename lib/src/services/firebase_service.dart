import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:stima_sense/src/services/ml/ml_service.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  static String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  // Get current user
  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Create user profile
  static Future<void> createUserProfile(Map<String, dynamic> userData) async {
    try {
      final userId = getCurrentUserId();
      if (userId != null) {
        userData['createdAt'] = FieldValue.serverTimestamp();
        userData['lastUpdated'] = FieldValue.serverTimestamp();
        await _firestore
            .collection('users')
            .doc(userId)
            .set(userData, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error creating user profile: $e');
      rethrow;
    }
  }

  // Get user profile
  static Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      final userId = getCurrentUserId();
      if (userId != null) {
        final doc = await _firestore.collection('users').doc(userId).get();
        return doc.data();
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }

  // Update user profile
  static Future<void> updateCurrentUserProfile(
      Map<String, dynamic> userData) async {
    try {
      final userId = getCurrentUserId();
      if (userId != null) {
        userData['lastUpdated'] = FieldValue.serverTimestamp();
        // Use set with merge instead of update to handle new documents
        await _firestore.collection('users').doc(userId).set(userData, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      rethrow;
    }
  }

  // Submit report
  static Future<void> submitReport(Map<String, dynamic> reportData) async {
    try {
      final userId = getCurrentUserId();
      if (userId != null) {
        reportData['userId'] = userId;
        reportData['timestamp'] = FieldValue.serverTimestamp();
        await _firestore.collection('reports').add(reportData);
      }
    } catch (e) {
      debugPrint('Error submitting report: $e');
      rethrow;
    }
  }

  // Get reports stream
  static Stream<QuerySnapshot> getReportsStream() {
    return _firestore
        .collection('reports')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Like a report
  static Future<void> likeReport(String reportId) async {
    try {
      final userId = getCurrentUserId();
      if (userId != null) {
        final likeRef = _firestore
            .collection('reports')
            .doc(reportId)
            .collection('likes')
            .doc(userId);
        final likeDoc = await likeRef.get();

        if (likeDoc.exists) {
          await likeRef.delete();
        } else {
          await likeRef.set({
            'userId': userId,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      debugPrint('Error liking report: $e');
      rethrow;
    }
  }

  // Add comment to report
  static Future<void> addComment(
      String reportId, Map<String, dynamic> commentData) async {
    try {
      final userId = getCurrentUserId();
      if (userId != null) {
        commentData['userId'] = userId;
        commentData['timestamp'] = FieldValue.serverTimestamp();
        await _firestore
            .collection('reports')
            .doc(reportId)
            .collection('comments')
            .add(commentData);
      }
    } catch (e) {
      debugPrint('Error adding comment: $e');
      rethrow;
    }
  }

  // Get outages stream
  static Stream<QuerySnapshot> getOutagesStream() {
    return _firestore
        .collection('outages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Update outage status
  static Future<void> updateOutageStatus(String outageId, String status) async {
    try {
      await _firestore.collection('outages').doc(outageId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating outage status: $e');
      rethrow;
    }
  }

  // Load ML model (delegates to MLService)
  static Future<bool> loadMLModel() async {
    return await MLService.loadFirebaseModel();
  }

  // Predict outage (delegates to MLService)
  static Future<Map<String, dynamic>> predictOutage(
      Map<String, dynamic> inputData) async {
    return await MLService.predictOutage(inputData);
  }

  // Sign out user
  static Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }

  // Dispose ML models (delegates to MLService)
  static void disposeModel() {
    MLService.dispose();
  }

  // Get ML model status
  static Map<String, dynamic> getMLModelStatus() {
    return MLService.getModelStatus();
  }
}
