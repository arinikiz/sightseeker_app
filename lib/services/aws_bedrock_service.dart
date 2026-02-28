import '../services/genkit_service.dart';

/// AWS Bedrock service that delegates to Genkit Cloud Functions.
/// The Bedrock multi-agent workflow (Planner -> Research -> Guide) is
/// now implemented as a Genkit flow with mode='bedrock', which mirrors
/// the Python Bedrock AgentCore pipeline via Firebase Cloud Functions.
class AwsBedrockService {
  final GenkitService _genkitService = GenkitService();

  /// Send a message using the Bedrock multi-agent workflow via Genkit.
  Future<Map<String, dynamic>> sendMessage({
    required String message,
    String? userId,
    List<Map<String, String>>? history,
  }) async {
    return await _genkitService.chatWithGuide(
      message: message,
      userId: userId,
      history: history,
      mode: 'bedrock',
    );
  }

  /// Verify a photo using the Genkit photo verification flow.
  Future<Map<String, dynamic>> verifyPhoto({
    required String challengeId,
    required String imageBase64,
    required double userLatitude,
    required double userLongitude,
    required String userId,
  }) async {
    return await _genkitService.verifyPhoto(
      challengeId: challengeId,
      imageBase64: imageBase64,
      userLatitude: userLatitude,
      userLongitude: userLongitude,
      userId: userId,
    );
  }
}
