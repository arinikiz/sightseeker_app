import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/theme.dart';
import '../providers/challenge_provider.dart';
import '../widgets/participant_tile.dart';

/// Challenge Hub screen shown when a user joins a challenge.
/// Shows: participant count, participant list/forum, and a photo verification button.
class ChallengeHubScreen extends StatefulWidget {
  final String challengeId;
  final String challengeTitle;

  const ChallengeHubScreen({
    super.key,
    required this.challengeId,
    required this.challengeTitle,
  });

  @override
  State<ChallengeHubScreen> createState() => _ChallengeHubScreenState();
}

class _ChallengeHubScreenState extends State<ChallengeHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _forumController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    final provider = context.read<ChallengeProvider>();
    provider.loadParticipants(widget.challengeId);
    provider.loadForumMessages(widget.challengeId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _forumController.dispose();
    super.dispose();
  }

  void _openCamera() {
    Navigator.of(context).pushNamed(
      '/photo-verify',
      arguments: {
        'challengeId': widget.challengeId,
        'challengeTitle': widget.challengeTitle,
      },
    );
  }

  void _postMessage(ChallengeProvider provider) {
    final text = _forumController.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? 'anonymous';
    final userName = user?.displayName ?? 'Explorer';

    provider.postForumMessage(widget.challengeId, userId, userName, text);
    _forumController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChallengeProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.challengeTitle),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.primaryColor,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: Colors.grey,
              tabs: [
                Tab(
                  icon: const Icon(Icons.people),
                  text: 'Participants (${provider.participantCount})',
                ),
                const Tab(
                  icon: Icon(Icons.forum),
                  text: 'Forum',
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              // Participant count banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withAlpha(25),
                      AppTheme.secondaryColor.withAlpha(15),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.group, color: AppTheme.primaryColor, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${provider.participantCount} Explorer${provider.participantCount != 1 ? 's' : ''} Joined',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.secondaryColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Take a photo to prove you visited!',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildParticipantsTab(provider),
                    _buildForumTab(provider),
                  ],
                ),
              ),
            ],
          ),
          // Floating photo verification button
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openCamera,
            backgroundColor: AppTheme.primaryColor,
            icon: const Icon(Icons.camera_alt, color: Colors.white),
            label: const Text(
              'Take Photo',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        );
      },
    );
  }

  Widget _buildParticipantsTab(ChallengeProvider provider) {
    if (provider.loadingParticipants) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    if (provider.participants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No explorers yet',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to join this challenge!',
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 80), // Space for FAB
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80), // Space for FAB
      itemCount: provider.participants.length,
      itemBuilder: (context, index) {
        return ParticipantTile(participant: provider.participants[index]);
      },
    );
  }

  Widget _buildForumTab(ChallengeProvider provider) {
    return Column(
      children: [
        // Forum messages list
        Expanded(
          child: provider.loadingForum
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryColor),
                )
              : provider.forumMessages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No messages yet',
                            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start the conversation!',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 80),
                      itemCount: provider.forumMessages.length,
                      itemBuilder: (context, index) {
                        final msg = provider.forumMessages[index];
                        return _buildForumMessageTile(msg);
                      },
                    ),
        ),
        // Forum input
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
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
                    controller: _forumController,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _postMessage(provider),
                    decoration: InputDecoration(
                      hintText: 'Share tips, plan meetups...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppTheme.secondaryColor,
                  radius: 20,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
                    onPressed: () => _postMessage(provider),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForumMessageTile(Map<String, dynamic> msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Card(
        elevation: 0.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.secondaryColor.withAlpha(30),
                radius: 18,
                child: Text(
                  (msg['userName'] as String? ?? 'A').substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.secondaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          msg['userName'] ?? 'Anonymous',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        if (msg['createdAt'] != null && (msg['createdAt'] as String).isNotEmpty)
                          Text(
                            _formatTime(msg['createdAt']),
                            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      msg['message'] ?? '',
                      style: const TextStyle(fontSize: 14, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }
}
