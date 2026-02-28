import 'package:cloud_functions/cloud_functions.dart';

/// Service that wraps Firebase Cloud Functions calls to Genkit AI flows.
/// Each method maps to an onCallGenkit export in functions/src/index.ts.
class GenkitService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Chat with the AI travel guide.
  /// Sends user message + conversation history, returns AI response text.
  Future<String> chatWithGuide({
    required String message,
    String? userId,
    List<Map<String, String>>? history,
  }) async {
    // TODO: wire up when frontend chat screen is ready
    final callable = _functions.httpsCallable('chatWithGuide');
    final result = await callable.call({
      'message': message,
      'userId': userId,
      'history': history,
    });
    return result.data['response'] as String;
  }

  /// Verify a challenge photo + GPS position.
  /// Returns verification result including GPS check and AI photo analysis.
  Future<Map<String, dynamic>> verifyPhoto({
    required String challengeId,
    required String imageBase64,
    required double userLatitude,
    required double userLongitude,
    required String userId,
  }) async {
    // TODO: wire up when photo capture flow is ready
    final callable = _functions.httpsCallable('verifyPhoto');
    final result = await callable.call({
      'challengeId': challengeId,
      'imageBase64': imageBase64,
      'userLatitude': userLatitude,
      'userLongitude': userLongitude,
      'userId': userId,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  /// Generate a personalized challenge route.
  /// Returns ordered list of challenges with AI reasoning.
  Future<Map<String, dynamic>> generateRoute({
    required String userId,
    required List<String> interests,
    required double availableHours,
    String? fitnessLevel,
    int? groupSize,
  }) async {
    // TODO: wire up when route planning UI is ready
    final callable = _functions.httpsCallable('generateRoute');
    final result = await callable.call({
      'userId': userId,
      'interests': interests,
      'availableHours': availableHours,
      'fitnessLevel': fitnessLevel ?? 'medium',
      'groupSize': groupSize ?? 1,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  /// Browse/search locations with AI-enriched results.
  Future<Map<String, dynamic>> browseLocations({
    String? query,
    String? category,
    double? userLatitude,
    double? userLongitude,
    double? radiusMeters,
  }) async {
    // TODO: wire up when browse/search UI is ready
    final callable = _functions.httpsCallable('browseLocations');
    final result = await callable.call({
      'query': query,
      'category': category,
      'userLatitude': userLatitude,
      'userLongitude': userLongitude,
      'radiusMeters': radiusMeters,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  /// Discover new challenges from HK Government Tourism Commission & official sites.
  /// Triggers the browser-agent-style flow: fetches tourism.gov.hk and related pages,
  /// extracts attractions via AI, and saves challenges to Firestore.
  /// Returns { success, message, challengeIds, count }.
  Future<Map<String, dynamic>> discoverChallengesFromWeb({String? sourceUrl}) async {
    final callable = _functions.httpsCallable('discoverChallengesFromWeb');
    final result = await callable.call({
      if (sourceUrl != null) 'sourceUrl': sourceUrl,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }
}
