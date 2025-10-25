import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';

final firestoreServiceProvider = Provider((ref) => FirestoreService());

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get User Profile
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserProfile.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw 'Error fetching profile: $e';
    }
  }

  // Create User Profile
  Future<void> createUserProfile(String userId, UserProfile profile) async {
    try {
      await _firestore.collection('users').doc(userId).set(
        UserProfile.toFirestore(profile),
      );
    } catch (e) {
      throw 'Error creating profile: $e';
    }
  }

  // Update User Profile
  Future<void> updateUserProfile(String userId, UserProfile profile) async {
    try {
      await _firestore.collection('users').doc(userId).update(
        UserProfile.toFirestore(profile),
      );
    } catch (e) {
      throw 'Error updating profile: $e';
    }
  }

  // Stream User Profile
  Stream<UserProfile?> streamUserProfile(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return UserProfile.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    });
  }
}