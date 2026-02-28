import 'package:flutter/foundation.dart';
import '../models/user.dart';

class UserProvider extends ChangeNotifier {
  AppUser? _user;
  bool _isLoading = false;

  AppUser? get user => _user;
  bool get isLoading => _isLoading;

  // TODO: Load user profile from API or auth service
  Future<void> loadUser() async {
    _isLoading = true;
    notifyListeners();

    // TODO: Fetch user profile
    _isLoading = false;
    notifyListeners();
  }

  void addPoints(int points) {
    if (_user != null) {
      _user!.points += points;
      notifyListeners();
    }
  }

  void addBadge(String badge) {
    if (_user != null && !_user!.badges.contains(badge)) {
      _user!.badges.add(badge);
      notifyListeners();
    }
  }

  String get userLevel {
    final points = _user?.points ?? 0;
    if (points >= 1500) return 'Local Legend';
    if (points >= 500) return 'Adventurer';
    return 'Explorer';
  }
}
