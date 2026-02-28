import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signIn(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      debugPrint("Login Error: ${e.message}");
      rethrow;
    }
  }

  Future<User?> signUp(
    String email,
    String password,
    String name,
    int age,
  ) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = result.user;

      if (user != null) {
        await _db.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name_surname': name,
          'email': email,
          'age': age,
          'cum_points': 0,
          'cur_location': const GeoPoint(0, 0),
          'joined_chlgs': [],
          'completed_chlg': [],
          'user_pic_url': '',
        });
      }
      return user;
    } on FirebaseAuthException catch (e) {
      debugPrint("Auth Error: ${e.message}");
      rethrow;
    } catch (e) {
      debugPrint("General Error: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  Future<void> deleteUserAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final uid = user.uid;

      final joinedChallenges = await _db
          .collection('challenges')
          .where('joined_people', arrayContains: uid)
          .get();

      for (final doc in joinedChallenges.docs) {
        await doc.reference.update({
          'joined_people': FieldValue.arrayRemove([uid]),
        });
      }

      await _db.collection('users').doc(uid).delete();

      final userReviews = await _db
          .collection('reviews')
          .where('user_id', isEqualTo: uid)
          .get();

      for (final doc in userReviews.docs) {
        await doc.reference.delete();
      }

      await user.delete();
      debugPrint("User account and data deleted successfully.");
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        debugPrint("Error: Re-authentication required.");
      }
      rethrow;
    } catch (e) {
      debugPrint("General Error during deletion: $e");
      rethrow;
    }
  }

  String getReadableAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        return e.message ?? 'An unexpected error occurred.';
    }
  }
}
