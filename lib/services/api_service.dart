import 'package:http/http.dart' as http;
import '../config/constants.dart';

class ApiService {
  final String baseUrl = AppConstants.apiBaseUrl;

  // TODO: Implement API calls to backend

  Future<List<dynamic>> getChallenges() async {
    // TODO: GET /challenges
    throw UnimplementedError();
  }

  Future<void> acceptChallenge(String challengeId, String userId) async {
    // TODO: POST /challenges/{id}/accept
    throw UnimplementedError();
  }

  Future<Map<String, dynamic>> completeChallenge(String challengeId, String imageBase64) async {
    // TODO: POST /challenges/{id}/complete
    throw UnimplementedError();
  }

  Future<List<dynamic>> getParticipants(String challengeId) async {
    // TODO: GET /challenges/{id}/participants
    throw UnimplementedError();
  }

  Future<List<dynamic>> getPredictions() async {
    // TODO: GET /predictions
    throw UnimplementedError();
  }

  Future<void> makePrediction(String challengeId, int prediction) async {
    // TODO: POST /predictions
    throw UnimplementedError();
  }

  Future<List<dynamic>> getLeaderboard({String period = 'weekly'}) async {
    // TODO: GET /leaderboard
    throw UnimplementedError();
  }

  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    // TODO: GET /users/{id}/profile
    throw UnimplementedError();
  }
}
