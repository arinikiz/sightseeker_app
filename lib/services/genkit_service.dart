import 'package:cloud_functions/cloud_functions.dart';

/// Service that wraps Firebase Cloud Functions calls to Genkit AI flows.
/// Each method maps to an onCallGenkit export in functions/src/index.ts.
class GenkitService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Chat with the AI travel guide.
  /// [mode] can be 'guide' (standard Genkit) or 'bedrock' (multi-agent workflow).
  /// Returns AI response text and optional route recommendations.
  Future<Map<String, dynamic>> chatWithGuide({
    required String message,
    String? userId,
    List<Map<String, String>>? history,
    String mode = 'guide',
  }) async {
    final callable = _functions.httpsCallable('chatWithGuide');
    final result = await callable.call({
      'message': message,
      'userId': userId,
      'history': history,
      'mode': mode,
    });
    return Map<String, dynamic>.from(result.data as Map);
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
  Future<Map<String, dynamic>> generateRoute({
    required String userId,
    required List<String> interests,
    required double availableHours,
    String? fitnessLevel,
    int? groupSize,
  }) async {
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

  /// Import discovered challenges from browser agent into Firestore.
  Future<Map<String, dynamic>> importDiscoveredChallenges({
    required List<Map<String, dynamic>> challenges,
  }) async {
    final callable = _functions.httpsCallable('importDiscoveredChallenges');
    final result = await callable.call({
      'challenges': challenges,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }
}
