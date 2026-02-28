import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';


// generate normal ID
String genID(String prefix) {
  var uuid = Uuid();
  return "${prefix}_${uuid.v4()}";
}
// Prefix rule to follow
/*
- For challenges: chlg
- For reviews: rev
 */


class UserProfile {
  final String uid;
  final String nameSurname;
  final String email;
  final int cumPoints;
  final String userPicUrl;
  final List<String> joinedChlgs;
  final List<String> completedChlgs;

  UserProfile({
    required this.uid,
    required this.nameSurname,
    this.email = '',
    required this.cumPoints,
    required this.userPicUrl,
    required this.joinedChlgs,
    List<String>? completedChlgs,
  }) : completedChlgs = completedChlgs ?? [];

  // Convert Firestore Document to Dart Object
  factory UserProfile.fromFirestore(Map<String, dynamic> data, String id) {
    return UserProfile(
      uid: id,
      nameSurname: data['name_surname'] ?? '',
      email: data['email']?.toString() ?? '',
      cumPoints: data['cum_points'] is int ? data['cum_points'] : 0,
      userPicUrl: data['user_pic_url'] ?? '',
      joinedChlgs: List<String>.from(data['joined_chlgs'] ?? []),
      completedChlgs: List<String>.from(data['completed_chlg'] ?? []),
    );
  }
}

/// Fetches the current user's profile from Firestore (joined + completed challenge IDs).
Future<UserProfile?> fetchUserProfile(String userId) async {
  try {
    final doc = await _db.collection('users').doc(userId).get();
    if (doc.exists && doc.data() != null) {
      return UserProfile.fromFirestore(doc.data()!, doc.id);
    }
  } catch (e) {
    debugPrint('Error fetching user profile: $e');
  }
  return null;
}

/// Fetches challenge title (and optional minimal fields) by challenge ID.
Future<String> fetchChallengeTitle(String challengeId) async {
  try {
    final doc = await _db.collection('challenges').doc(challengeId).get();
    if (doc.exists && doc.data() != null) {
      return doc.data()!['title']?.toString() ?? challengeId;
    }
  } catch (e) {
    debugPrint('Error fetching challenge title: $e');
  }
  return challengeId;
}

/// Fetches titles for multiple challenge IDs (for profile lists).
Future<Map<String, String>> fetchChallengeTitles(List<String> challengeIds) async {
  final Map<String, String> result = {};
  for (final id in challengeIds) {
    result[id] = await fetchChallengeTitle(id);
  }
  return result;
}

/// Fetches full challenge doc by ID for the detail screen. Returns a map with keys
/// compatible with building [MapPlaceDetail] (id, title, description, location, latitude, longitude, etc.)
/// or null if not found.
Future<Map<String, dynamic>?> fetchChallengeDetailById(String challengeId) async {
  try {
    final doc = await _db.collection('challenges').doc(challengeId).get();
    if (!doc.exists || doc.data() == null) return null;
    final d = doc.data()!;
    double lat = 0, lng = 0;
    if (d['location'] is GeoPoint) {
      final g = d['location'] as GeoPoint;
      lat = g.latitude;
      lng = g.longitude;
    }
    return {
      'id': doc.id,
      'title': d['title']?.toString() ?? doc.id,
      'description': d['description']?.toString() ?? '',
      'location': d['location'] != null ? '${lat}, $lng' : '',
      'priceLabel': '',
      'latitude': lat,
      'longitude': lng,
      'colorHex': '#43A047',
      'imageUrl': d['chlg_pic_url']?.toString(),
      'category': d['type']?.toString(),
      'hours': null,
      'tags': <String>[],
      'distanceKm': null,
      'estimatedDuration': d['expected_duration']?.toString(),
      'difficulty': d['difficulty']?.toString(),
      'rewardPoints': null,
      'reviews': <Map<String, dynamic>>[],
    };
  } catch (e) {
    debugPrint('Error fetching challenge detail: $e');
    return null;
  }
}


///////////////// Adding a User /////////////////

final FirebaseFirestore _db = FirebaseFirestore.instance;

Future<void> createUser(String uid, String name, String email) async {
  await _db.collection('users').doc(uid).set({
    'uid': uid,
    'name_surname': name,
    'email': email,
    'cum_points': 0, // Initialized as integer
    'joined_chlgs': [],
    'completed_chlg': [],
  });
}


///////////////// joining a challenge /////////////////

Future<void> joinChallenge(String userId, String challengeId) async {
  WriteBatch batch = _db.batch();

  // 1. Add user to the challenge's list
  DocumentReference chlgRef = _db.collection('challenges').doc(challengeId);
  batch.update(chlgRef, {
    'joined_people': FieldValue.arrayUnion([userId])
  });

  // 2. Add challenge ID to the user's list
  DocumentReference userRef = _db.collection('users').doc(userId);
  batch.update(userRef, {
    'joined_chlgs': FieldValue.arrayUnion([challengeId])
  });

  await batch.commit();
}

///////////////// Complete Challenge and Increment Point /////////////////

Future<void> completeChallenge(String userId, String challengeId, int pointsEarned) async {
  DocumentReference userRef = _db.collection('users').doc(userId);

  await userRef.update({
    'cum_points': FieldValue.increment(pointsEarned), // Atomic increment
    'joined_chlgs': FieldValue.arrayRemove([challengeId]),
    'completed_chlg': FieldValue.arrayUnion([challengeId]),
  });
}


///////////////// Handling Images /////////////////


Future<void> uploadUserProfilePic(String userId, File imageFile) async {
  // 1. Upload to Storage
  Reference ref = FirebaseStorage.instance.ref().child('user_profiles/$userId.jpg');
  UploadTask uploadTask = ref.putFile(imageFile);

  TaskSnapshot snapshot = await uploadTask;
  String downloadUrl = await snapshot.ref.getDownloadURL();

  // 2. Update Firestore with the new URL
  await _db.collection('users').doc(userId).update({
    'user_pic_url': downloadUrl,
  });
}


///////////////// Reviews /////////////////

/// Submits a review for a challenge. Uses [userId], [challengeId], [comment], and [rating].
Future<void> submitReview({
  required String userId,
  required String challengeId,
  required String comment,
  required int rating,
}) async {
  await _db.collection('reviews').doc(genID('rev')).set({
    'user_id': userId,
    'challenge_id': challengeId,
    'comment': comment,
    'rating': rating.clamp(1, 5),
    'created_at': FieldValue.serverTimestamp(),
  });
}

///////////////// Weekly Event /////////////////

Stream<QuerySnapshot> getActiveEvents() {
  return _db.collection('weekly_events')
      .where('end_date', isGreaterThan: DateTime.now())
      .snapshots();
}

///////////////// On-demand Leaderboard /////////////////



class DatabaseSeeder {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> seedDatabase() async {
    try {
      // 1. Create a Sample Challenge (The Ultimate Hiker)
      await _db.collection('challenges').doc('chlg_f47ac10b').set({
        'title': "The Ultimate Hiker",
        'description': "Conquer the mountains of Hong Kong!",
        'difficulty': "medium",
        'type': "hiking",
        'score': 9.5,
        'expected_duration': "01:00:00",
        'location': const GeoPoint(22.254, 113.905),
        'created_at': FieldValue.serverTimestamp(),
        'joined_people': [],
        'chlg_pic_url': "https://firebasestorage.../challenge_photos/chlg_f47.jpg",
      });

      // 2. Create a Weekly Event
      await _db.collection('weekly_events').doc('week_2026_9_1').set({
        'description': "The Great Outdoors Week! Earn double points for every hike",
        'multiplier': 2,
        'target_category': "hiking",
        'start_date': Timestamp.fromDate(DateTime(2026, 2, 21)),
        'end_date': Timestamp.fromDate(DateTime(2026, 2, 28)),
      });

      // 3. Create Initial User
      await _db.collection('users').doc('d7NZMXbNcntWotOR011k').set({
        'name_surname': "John Doe",
        'email': "johndoe@gmail.com",
        'age': 23,
        'cum_points': 154,
        'cur_location': const GeoPoint(35.6197, 139.7282),
        'joined_chlgs': ['chlg_f47ac10b'],
        'completed_chlg': [],
        'user_pic_url': "https://firebasestorage.../user_profiles/d7NZM.jpg",
      });

      debugPrint("Database seeded successfully!");
    } catch (e, stackTrace) {
      // Log the error and the stack trace for better debugging
      debugPrint("Error seeding database: $e");
      debugPrint("Stack trace: $stackTrace");
    }
  }
}


///////////////// Fetching challenge Details for Google Api /////////////////

class ChallengeService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> fetchAllChallenges() async {
    try {
      // Fetch the collection from Firestore
      QuerySnapshot snapshot = await _db.collection('challenges').get();

      // Map the documents into a structured List
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        // Convert Firestore GeoPoint to a List [latitude, longitude]
        List<double> formattedLocation = [];
        if (data['location'] is GeoPoint) {
          GeoPoint geo = data['location'];
          formattedLocation = [geo.latitude, geo.longitude];
        }

        return {
          'chlgID': doc.id,
          'chlg_pic_url': data['chlg_pic_url'] ?? '',
          'description': data['description'] ?? '',
          'difficulty': data['difficulty'] ?? '',
          'expected_duration': data['expected_duration'] ?? '',
          'location': formattedLocation,
          'title': data['title'] ?? '',
          'type': data['type'] ?? '',
        };
      }).toList();

    } catch (e, stackTrace) {
      debugPrint("Error fetching challenges: $e");
      debugPrint("Stack trace: $stackTrace");
      return []; // Return an empty list on failure
    }
  }
}