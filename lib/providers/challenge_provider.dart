import 'package:flutter/foundation.dart';
import '../models/challenge.dart';

class ChallengeProvider extends ChangeNotifier {
  List<Challenge> _challenges = [];
  List<String> _acceptedChallengeIds = [];
  List<String> _completedChallengeIds = [];
  bool _isLoading = false;

  List<Challenge> get challenges => _challenges;
  List<String> get acceptedChallengeIds => _acceptedChallengeIds;
  List<String> get completedChallengeIds => _completedChallengeIds;
  bool get isLoading => _isLoading;

  // TODO: Load challenges from API or local seed data
  Future<void> loadChallenges() async {
    _isLoading = true;
    notifyListeners();

    // TODO: Fetch from API service
    _isLoading = false;
    notifyListeners();
  }

  void acceptChallenge(String challengeId) {
    if (!_acceptedChallengeIds.contains(challengeId)) {
      _acceptedChallengeIds.add(challengeId);
      notifyListeners();
    }
  }

  void completeChallenge(String challengeId) {
    if (!_completedChallengeIds.contains(challengeId)) {
      _completedChallengeIds.add(challengeId);
      notifyListeners();
    }
  }
}
