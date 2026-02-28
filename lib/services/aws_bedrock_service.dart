import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';

class AwsBedrockService {
  final String baseUrl = AppConstants.apiBaseUrl;

  // TODO: Implement Bedrock AgentCore chat via API Gateway

  Future<String> sendMessage({
    required String sessionId,
    required String message,
  }) async {
    // TODO: POST /agent/chat
    // Returns AI agent response text
    throw UnimplementedError();
  }

  Future<Map<String, dynamic>> verifyPhoto({
    required String challengeId,
    required String imageBase64,
    required String challengeType,
    required String challengeLocation,
  }) async {
    // TODO: POST /challenges/{id}/complete with photo for AI verification
    throw UnimplementedError();
  }
}
