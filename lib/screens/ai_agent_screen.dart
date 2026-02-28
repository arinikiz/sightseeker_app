import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_bubble.dart';

class AiAgentScreen extends StatefulWidget {
  const AiAgentScreen({super.key});

  @override
  State<AiAgentScreen> createState() => _AiAgentScreenState();
}

class _AiAgentScreenState extends State<AiAgentScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _sendMessage(ChatProvider chatProvider) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    chatProvider.sendMessage(text);
    _scrollToBottom();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

        return Scaffold(
          appBar: AppBar(
            title: const Text('AI Guide'),
            actions: [
              // Mode toggle chip
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: ActionChip(
                  avatar: Icon(
                    chatProvider.mode == ChatMode.bedrock
                        ? Icons.psychology
                        : Icons.chat_bubble,
                    size: 18,
                    color: chatProvider.mode == ChatMode.bedrock
                        ? Colors.deepPurple
                        : AppTheme.primaryColor,
                  ),
                  label: Text(
                    chatProvider.mode == ChatMode.bedrock ? 'Bedrock' : 'Guide',
                    style: TextStyle(
                      fontSize: 12,
                      color: chatProvider.mode == ChatMode.bedrock
                          ? Colors.deepPurple
                          : AppTheme.primaryColor,
                    ),
                  ),
                  onPressed: chatProvider.toggleMode,
                  backgroundColor: chatProvider.mode == ChatMode.bedrock
                      ? Colors.deepPurple.withAlpha(25)
                      : AppTheme.primaryColor.withAlpha(25),
                  side: BorderSide.none,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: chatProvider.clearChat,
                tooltip: 'Clear chat',
              ),
            ],
          ),
          body: Column(
            children: [
              // Mode indicator banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                color: chatProvider.mode == ChatMode.bedrock
                    ? Colors.deepPurple.withAlpha(20)
                    : AppTheme.primaryColor.withAlpha(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      chatProvider.mode == ChatMode.bedrock
                          ? Icons.psychology
                          : Icons.explore,
                      size: 14,
                      color: chatProvider.mode == ChatMode.bedrock
                          ? Colors.deepPurple
                          : AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      chatProvider.mode == ChatMode.bedrock
                          ? 'Bedrock Multi-Agent (Planner \u2192 Research \u2192 Guide)'
                          : 'Genkit AI Guide \u2014 Connected to Firebase',
                      style: TextStyle(
                        fontSize: 11,
                        color: chatProvider.mode == ChatMode.bedrock
                            ? Colors.deepPurple
                            : AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Chat messages
              Expanded(
                child: chatProvider.messages.isEmpty
                    ? _buildEmptyState(chatProvider)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: chatProvider.messages.length,
                        itemBuilder: (context, index) {
                          final msg = chatProvider.messages[index];
                          return Column(
                            children: [
                              ChatBubble(
                                message: msg.text,
                                isUser: msg.isUser,
                              ),
                              if (msg.routeSuggestions != null &&
                                  msg.routeSuggestions!.isNotEmpty)
                                _buildRouteCard(msg.routeSuggestions!),
                            ],
                          );
                        },
                      ),
              ),
              // Typing indicator
              if (chatProvider.isTyping)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: chatProvider.mode == ChatMode.bedrock
                              ? Colors.deepPurple
                              : AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        chatProvider.mode == ChatMode.bedrock
                            ? 'Bedrock agents thinking...'
                            : 'AI Guide typing...',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              // Chat input
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(13),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(chatProvider),
                          decoration: InputDecoration(
                            hintText: chatProvider.mode == ChatMode.bedrock
                                ? 'Ask Bedrock agent...'
                                : 'Ask your AI guide...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: chatProvider.mode == ChatMode.bedrock
                            ? Colors.deepPurple
                            : AppTheme.primaryColor,
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: chatProvider.isTyping
                              ? null
                              : () => _sendMessage(chatProvider),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(ChatProvider chatProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              chatProvider.mode == ChatMode.bedrock
                  ? Icons.psychology
                  : Icons.chat_bubble_outline,
              size: 64,
              color: chatProvider.mode == ChatMode.bedrock
                  ? Colors.deepPurple
                  : AppTheme.secondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              chatProvider.mode == ChatMode.bedrock
                  ? 'Bedrock Multi-Agent'
                  : 'HK Explorer AI Guide',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              chatProvider.mode == ChatMode.bedrock
                  ? 'Powered by Planner \u2192 Research \u2192 Guide pipeline.\nTry: "I have 3 hours and love food!"'
                  : 'Ask me about Hong Kong challenges!\nTry: "What are some easy photo challenges?"',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], height: 1.4),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _buildSuggestionChips(chatProvider),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSuggestionChips(ChatProvider chatProvider) {
    final suggestions = chatProvider.mode == ChatMode.bedrock
        ? [
            'I have 3 hours and love food',
            'Solo hiker, full day, hardcore',
            'Family trip with kids',
            'Quick easy photo spots',
          ]
        : [
            'Show me nearby challenges',
            'Best hiking trails?',
            'What food challenges are popular?',
            "What's happening this week?",
          ];

    return suggestions.map((s) {
      return ActionChip(
        label: Text(s, style: const TextStyle(fontSize: 12)),
        onPressed: () {
          _controller.text = s;
          _sendMessage(chatProvider);
        },
        backgroundColor: Colors.grey[100],
      );
    }).toList();
  }

  Widget _buildRouteCard(List<Map<String, dynamic>> route) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withAlpha(13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.route, size: 16, color: AppTheme.primaryColor),
              SizedBox(width: 4),
              Text(
                'Recommended Route',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...route.asMap().entries.map((entry) {
            final i = entry.key;
            final stop = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: AppTheme.primaryColor,
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stop['title'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        if (stop['reason'] != null)
                          Text(
                            stop['reason'],
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
