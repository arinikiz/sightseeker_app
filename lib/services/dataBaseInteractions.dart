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
      // ─── 1. Challenges (Hong Kong themed) ────────────────────────────────────

      // Hiking
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

      await _db.collection('challenges').doc('chlg_dragons_back').set({
        'title': "Dragon's Back Trail",
        'description': "Complete the 8.5km Dragon's Back hiking trail with panoramic ocean views.",
        'difficulty': "hard",
        'type': "hiking",
        'score': 9.0,
        'expected_duration': "03:00:00",
        'location': const GeoPoint(22.245, 114.232),
        'created_at': FieldValue.serverTimestamp(),
        'joined_people': [],
        'chlg_pic_url': "https://firebasestorage.../challenge_photos/chlg_dragons.jpg",
      });

      await _db.collection('challenges').doc('chlg_big_buddha').set({
        'title': "Big Buddha Ascent",
        'description': "Take the Ngong Ping 360 cable car and climb the 268 steps to the Tian Tan Buddha.",
        'difficulty': "hard",
        'type': "hiking",
        'score': 9.3,
        'expected_duration': "03:30:00",
        'location': const GeoPoint(22.254, 113.905),
        'created_at': FieldValue.serverTimestamp(),
        'joined_people': [],
        'chlg_pic_url': "https://firebasestorage.../challenge_photos/chlg_buddha.jpg",
      });

      // Dining / Food
      await _db.collection('challenges').doc('chlg_hunger_rush').set({
        'title': "The Hunger Rush",
        'description': "Eat everything around Hong Kong! Sample street food, dim sum, and local delicacies across the city.",
        'difficulty': "medium",
        'type': "dining",
        'score': 10.0,
        'expected_duration': "02:00:00",
        'location': const GeoPoint(22.278, 114.182), // Causeway Bay
        'created_at': FieldValue.serverTimestamp(),
        'joined_people': [],
        'chlg_pic_url': "https://firebasestorage.../challenge_photos/chlg_hunger.jpg",
      });

      await _db.collection('challenges').doc('chlg_dim_sum').set({
        'title': "Dim Sum Master",
        'description': "Order and finish 3 different dim sum dishes at Tim Ho Wan, the cheapest Michelin star restaurant.",
        'difficulty': "medium",
        'type': "dining",
        'score': 9.5,
        'expected_duration': "01:00:00",
        'location': const GeoPoint(22.330, 114.162), // Sham Shui Po
        'created_at': FieldValue.serverTimestamp(),
        'joined_people': [],
        'chlg_pic_url': "https://firebasestorage.../challenge_photos/chlg_dimsum.jpg",
      });

      await _db.collection('challenges').doc('chlg_temple_street').set({
        'title': "Temple Street Night Market",
        'description': "Explore the bustling night market and try at least 3 different street food stalls.",
        'difficulty': "easy",
        'type': "dining",
        'score': 8.8,
        'expected_duration': "01:30:00",
        'location': const GeoPoint(22.307, 114.170), // Yau Ma Tei
        'created_at': FieldValue.serverTimestamp(),
        'joined_people': [],
        'chlg_pic_url': "https://firebasestorage.../challenge_photos/chlg_temple.jpg",
      });

      await _db.collection('challenges').doc('chlg_egg_tart').set({
        'title': "Egg Tart Quest at Tai Cheong",
        'description': "Find the legendary Tai Cheong Bakery on Lyndhurst Terrace and taste their famous egg tarts.",
        'difficulty': "easy",
        'type': "dining",
        'score': 9.1,
        'expected_duration': "00:30:00",
        'location': const GeoPoint(22.282, 114.154), // Central
        'created_at': FieldValue.serverTimestamp(),
        'joined_people': [],
        'chlg_pic_url': "https://firebasestorage.../challenge_photos/chlg_eggtart.jpg",
      });

      // Culture & Photo
      await _db.collection('challenges').doc('chlg_star_ferry').set({
        'title': "Star Ferry Sunset",
        'description': "Take the Star Ferry across Victoria Harbour and capture the iconic skyline at golden hour.",
        'difficulty': "easy",
        'type': "photo",
        'score': 9.2,
        'expected_duration': "01:00:00",
        'location': const GeoPoint(22.293, 114.168), // TST
        'created_at': FieldValue.serverTimestamp(),
        'joined_people': [],
        'chlg_pic_url': "https://firebasestorage.../challenge_photos/chlg_starferry.jpg",
      });

      await _db.collection('challenges').doc('chlg_man_mo').set({
        'title': "Man Mo Temple Seeker",
        'description': "Visit the historic Man Mo Temple on Hollywood Road and photograph the giant incense coils.",
        'difficulty': "easy",
        'type': "culture",
        'score': 8.7,
        'expected_duration': "00:45:00",
        'location': const GeoPoint(22.284, 114.150), // Sheung Wan
        'created_at': FieldValue.serverTimestamp(),
        'joined_people': [],
        'chlg_pic_url': "https://firebasestorage.../challenge_photos/chlg_manmo.jpg",
      });

      await _db.collection('challenges').doc('chlg_tai_o').set({
        'title': "Tai O Fishing Village",
        'description': "Explore the stilt houses of Tai O, sample salted egg yolk fish skin, and spot pink dolphins from the pier.",
        'difficulty': "medium",
        'type': "culture",
        'score': 9.0,
        'expected_duration': "02:00:00",
        'location': const GeoPoint(22.252, 113.897), // Lantau
        'created_at': FieldValue.serverTimestamp(),
        'joined_people': [],
        'chlg_pic_url': "https://firebasestorage.../challenge_photos/chlg_tai_o.jpg",
      });

      // ─── 2. Weekly Events ────────────────────────────────────────────────────

      await _db.collection('weekly_events').doc('week_2026_9_1').set({
        'description': "The Great Outdoors Week! Earn double points for every hike",
        'multiplier': 2,
        'target_category': "hiking",
        'start_date': Timestamp.fromDate(DateTime(2026, 2, 21)),
        'end_date': Timestamp.fromDate(DateTime(2026, 2, 28)),
      });

      await _db.collection('weekly_events').doc('week_2026_hungry').set({
        'description': "The Hungry Week! Eat as you can — double points for dining challenges",
        'multiplier': 2,
        'target_category': "dining",
        'start_date': Timestamp.fromDate(DateTime(2026, 2, 21)),
        'end_date': Timestamp.fromDate(DateTime(2026, 2, 28)),
      });

      // ─── 3. Initial Users ────────────────────────────────────────────────────

      await _db.collection('users').doc('d7NZMXbNcntWotOR011k').set({
        'name_surname': "John Doe",
        'email': "johndoe@gmail.com",
        'age': 23,
        'cum_points': 154,
        'cur_location': const GeoPoint(22.278, 114.182), // Causeway Bay, HK
        'joined_chlgs': ['chlg_f47ac10b'],
        'completed_chlg': [],
        'user_pic_url': "https://firebasestorage.../user_profiles/d7NZM.jpg",
      });

      await _db.collection('users').doc('alex_hunter_001').set({
        'name_surname': "Alex Hunter",
        'email': "alexhunter@gmail.com",
        'age': 19,
        'cum_points': 155,
        'cur_location': const GeoPoint(22.293, 114.172), // TST, Hong Kong
        'joined_chlgs': ['chlg_hunger_rush'],
        'completed_chlg': [],
        'user_pic_url': "https://firebasestorage.../user_profiles/alexHunter.jpg",
      });

      await _db.collection('users').doc('user_sarah_002').set({
        'name_surname': "Sarah Chen",
        'email': "sarahchen@gmail.com",
        'age': 28,
        'cum_points': 320,
        'cur_location': const GeoPoint(22.284, 114.150), // Sheung Wan
        'joined_chlgs': ['chlg_dragons_back', 'chlg_egg_tart'],
        'completed_chlg': ['chlg_star_ferry', 'chlg_man_mo', 'chlg_temple_street'],
        'user_pic_url': "https://firebasestorage.../user_profiles/sarahChen.jpg",
      });

      await _db.collection('users').doc('user_mike_003').set({
        'name_surname': "Mike Wong",
        'email': "mikewong@gmail.com",
        'age': 24,
        'cum_points': 89,
        'cur_location': const GeoPoint(22.318, 114.170), // Mongkok
        'joined_chlgs': ['chlg_dim_sum'],
        'completed_chlg': ['chlg_egg_tart'],
        'user_pic_url': "https://firebasestorage.../user_profiles/mikeWong.jpg",
      });

      await _db.collection('users').doc('user_emma_004').set({
        'name_surname': "Emma Liu",
        'email': "emmaliu@gmail.com",
        'age': 31,
        'cum_points': 445,
        'cur_location': const GeoPoint(22.254, 113.905), // Lantau
        'joined_chlgs': [],
        'completed_chlg': ['chlg_big_buddha', 'chlg_tai_o', 'chlg_dragons_back', 'chlg_hunger_rush'],
        'user_pic_url': "https://firebasestorage.../user_profiles/emmaLiu.jpg",
      });

      await _db.collection('users').doc('user_james_005').set({
        'name_surname': "James Park",
        'email': "jamespark@gmail.com",
        'age': 22,
        'cum_points': 12,
        'cur_location': const GeoPoint(22.278, 114.182), // Causeway Bay
        'joined_chlgs': ['chlg_star_ferry', 'chlg_man_mo'],
        'completed_chlg': [],
        'user_pic_url': "https://firebasestorage.../user_profiles/jamesPark.jpg",
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