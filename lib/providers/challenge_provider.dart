import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/challenge.dart';
import '../models/participant.dart';
import '../services/dataBaseInteractions.dart';

class ChallengeProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<Challenge> _challenges = [];
  List<String> _acceptedChallengeIds = [];
  List<String> _completedChallengeIds = [];
  bool _isLoading = false;

  // Participants for a specific challenge
  List<Participant> _participants = [];
  int _participantCount = 0;
  bool _loadingParticipants = false;

  // Forum messages for a specific challenge
  List<Map<String, dynamic>> _forumMessages = [];
  bool _loadingForum = false;

  List<Challenge> get challenges => _challenges;
  List<String> get acceptedChallengeIds => _acceptedChallengeIds;
  List<String> get completedChallengeIds => _completedChallengeIds;
  bool get isLoading => _isLoading;
  List<Participant> get participants => _participants;
  int get participantCount => _participantCount;
  bool get loadingParticipants => _loadingParticipants;
  List<Map<String, dynamic>> get forumMessages => _forumMessages;
  bool get loadingForum => _loadingForum;

  /// Load all challenges from Firestore
  Future<void> loadChallenges() async {
    _isLoading = true;
    notifyListeners();

    try {
      final service = ChallengeService();
      final docs = await service.fetchAllChallenges();
      _challenges = docs.map((d) {
        double lat = 0, lng = 0;
        if (d['location'] is List) {
          final loc = d['location'] as List;
          if (loc.length >= 2) {
            lat = (loc[0] as num).toDouble();
            lng = (loc[1] as num).toDouble();
          }
        }
        return Challenge(
          id: d['chlgID'] ?? '',
          title: d['title'] ?? '',
          description: d['description'] ?? '',
          type: d['type'] ?? '',
          latitude: lat,
          longitude: lng,
          points: (d['score'] is num ? (d['score'] as num).toInt() : 0),
          difficulty: d['difficulty'] ?? 'medium',
          badge: d['type'] ?? 'photo',
          sponsor: null,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error loading challenges: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load user-specific joined/completed lists from Firestore
  Future<void> loadUserChallengeState(String userId) async {
    try {
      final profile = await fetchUserProfile(userId);
      if (profile != null) {
        _acceptedChallengeIds = List<String>.from(profile.joinedChlgs);
        _completedChallengeIds = List<String>.from(profile.completedChlgs);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading user challenge state: $e');
    }
  }

  /// Join a challenge
  Future<void> acceptChallenge(String challengeId, String userId) async {
    if (_acceptedChallengeIds.contains(challengeId)) return;

    try {
      await joinChallenge(userId, challengeId);
      _acceptedChallengeIds.add(challengeId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error joining challenge: $e');
    }
  }

  void completeChallenge(String challengeId) {
    if (!_completedChallengeIds.contains(challengeId)) {
      _completedChallengeIds.add(challengeId);
      _acceptedChallengeIds.remove(challengeId);
      notifyListeners();
    }
  }

  bool hasJoined(String challengeId) => _acceptedChallengeIds.contains(challengeId);
  bool hasCompleted(String challengeId) => _completedChallengeIds.contains(challengeId);

  /// Load participants for a specific challenge
  Future<void> loadParticipants(String challengeId) async {
    _loadingParticipants = true;
    _participants = [];
    notifyListeners();

    try {
      final doc = await _db.collection('challenges').doc(challengeId).get();
      final joinedPeople = List<String>.from(doc.data()?['joined_people'] ?? []);
      _participantCount = joinedPeople.length;

      final List<Participant> loaded = [];
      for (final uid in joinedPeople) {
        final userDoc = await _db.collection('users').doc(uid).get();
        if (userDoc.exists) {
          final data = userDoc.data()!;
          loaded.add(Participant(
            userId: uid,
            name: data['name_surname'] ?? 'Explorer',
            avatarUrl: data['user_pic_url'] as String?,
            status: 'going',
          ));
        }
      }
      _participants = loaded;
    } catch (e) {
      debugPrint('Error loading participants: $e');
    }

    _loadingParticipants = false;
    notifyListeners();
  }

  /// Load forum messages for a challenge
  Future<void> loadForumMessages(String challengeId) async {
    _loadingForum = true;
    notifyListeners();

    try {
      final snap = await _db
          .collection('challenges')
          .doc(challengeId)
          .collection('forum')
          .orderBy('created_at', descending: true)
          .limit(50)
          .get();

      _forumMessages = snap.docs.map((doc) {
        final d = doc.data();
        return {
          'id': doc.id,
          'userId': d['user_id'] ?? '',
          'userName': d['user_name'] ?? 'Anonymous',
          'message': d['message'] ?? '',
          'createdAt': d['created_at']?.toDate()?.toString() ?? '',
        };
      }).toList();
    } catch (e) {
      debugPrint('Error loading forum messages: $e');
    }

    _loadingForum = false;
    notifyListeners();
  }

  /// Post a forum message
  Future<void> postForumMessage(String challengeId, String userId, String userName, String message) async {
    try {
      await _db
          .collection('challenges')
          .doc(challengeId)
          .collection('forum')
          .add({
        'user_id': userId,
        'user_name': userName,
        'message': message,
        'created_at': FieldValue.serverTimestamp(),
      });
      await loadForumMessages(challengeId);
    } catch (e) {
      debugPrint('Error posting forum message: $e');
    }
  }
}
