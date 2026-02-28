import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  ///////////////// Sign Up /////////////////
  Future<User?> signUp(String email, String password, String name, int age) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        // Initializes Firestore document based on structure
        await _db.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name_surname': name,
          'email': email,
          'age': age,
          'cum_points': 0, // Initialized as integer
          'cur_location': const GeoPoint(0, 0),
          'joined_chlgs': [],
          'completed_chlg': [],
          'user_pic_url': "",
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

  ///////////////// Login /////////////////
  Future<User?> logIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      debugPrint("Login Error: ${e.message}");
      rethrow;
    }
  }

  ///////////////// Signout /////////////////
  Future<void> signOut() async {
    await _auth.signOut();
  }

  ///////////////// Delete Account /////////////////
  Future<void> deleteUserAccount() async {
    try {
      User? user = _auth.currentUser;

      if (user != null) {
        String uid = user.uid;

        // 1. Remove user from 'joined_people' arrays in challenges
        // This prevents "ghost" users in your challenge lists
        var joinedChallenges = await _db.collection('challenges')
            .where('joined_people', arrayContains: uid)
            .get();

        for (var doc in joinedChallenges.docs) {
          await doc.reference.update({
            'joined_people': FieldValue.arrayRemove([uid])
          });
        }

        // 2. Delete the user's Firestore document
        await _db.collection('users').doc(uid).delete();

        // 3. Delete user reviews
        var userReviews = await _db.collection('reviews')
            .where('user_id', isEqualTo: uid)
            .get();

        for (var doc in userReviews.docs) {
          await doc.reference.delete();
        }

        // 4. Finally, delete the Authentication record
        await user.delete();

        debugPrint("User account and data deleted successfully.");
      }
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
}