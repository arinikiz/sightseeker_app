import 'package:flutter/foundation.dart';
import '../services/genkit_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<Map<String, dynamic>>? routeSuggestions;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.routeSuggestions,
  }) : timestamp = timestamp ?? DateTime.now();
}

enum ChatMode { guide, bedrock }

class ChatProvider extends ChangeNotifier {
  final GenkitService _genkitService = GenkitService();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  ChatMode _mode = ChatMode.guide;
  String? _userId;

  List<ChatMessage> get messages => _messages;
  bool get isTyping => _isTyping;
  ChatMode get mode => _mode;

  void setUserId(String? userId) {
    _userId = userId;
  }

  void toggleMode() {
    _mode = _mode == ChatMode.guide ? ChatMode.bedrock : ChatMode.guide;
    notifyListeners();
  }

  void setMode(ChatMode mode) {
    _mode = mode;
    notifyListeners();
  }

  List<Map<String, String>> _buildHistory() {
    return _messages.map((m) {
      return {
        'role': m.isUser ? 'user' : 'model',
        'content': m.text,
      };
    }).toList();
  }

  Future<void> sendMessage(String text) async {
    _messages.add(ChatMessage(text: text, isUser: true));
    _isTyping = true;
    notifyListeners();

    try {
      final result = await _genkitService.chatWithGuide(
        message: text,
        userId: _userId,
        history: _buildHistory().sublist(0, _messages.length - 1),
        mode: _mode == ChatMode.bedrock ? 'bedrock' : 'guide',
      );

      final response = result['response'] as String? ?? 'No response received.';
      final route = result['route'] as List<dynamic>?;

      _messages.add(ChatMessage(
        text: response,
        isUser: false,
        routeSuggestions: route?.map((r) => Map<String, dynamic>.from(r as Map)).toList(),
      ));
    } catch (e) {
      _messages.add(ChatMessage(
        text: 'Sorry, I encountered an error: ${e.toString().split(':').last.trim()}. Please try again.',
        isUser: false,
      ));
    }

    _isTyping = false;
    notifyListeners();
  }

  void clearChat() {
    _messages.clear();
    notifyListeners();
  }
}
