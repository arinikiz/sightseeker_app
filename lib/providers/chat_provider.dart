import 'package:flutter/foundation.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class ChatProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  String _sessionId = '';

  List<ChatMessage> get messages => _messages;
  bool get isTyping => _isTyping;

  // TODO: Integrate with AwsBedrockService for AI agent chat

  Future<void> sendMessage(String text) async {
    _messages.add(ChatMessage(text: text, isUser: true));
    _isTyping = true;
    notifyListeners();

    // TODO: Call Bedrock agent and get response
    // For now, add a placeholder response
    await Future.delayed(const Duration(seconds: 1));

    _messages.add(ChatMessage(
      text: 'AI response placeholder — integrate Bedrock AgentCore here.',
      isUser: false,
    ));
    _isTyping = false;
    notifyListeners();
  }

  void clearChat() {
    _messages.clear();
    _sessionId = '';
    notifyListeners();
  }
}
