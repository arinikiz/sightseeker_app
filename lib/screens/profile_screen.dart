import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../config/routes.dart';
import '../services/dataBaseInteractions.dart';
import '../widgets/profile/profile_header.dart';
import '../widgets/profile/profile_challenge_tile.dart';

// Mock data for profile display when not signed in or DB returns empty. IDs match stub places so detail screen works.
const _mockDisplayName = 'Jane Doe';
const _mockEmail = 'janedoe@example.com';
const _mockJoined = [
  ('big_buddha', 'Big Buddha'),
  ('kowloon_challenge', 'Kowloon Night Lights'),
  ('victoria_peak', 'Victoria Peak Trail'),
];
const _mockCompleted = [
  ('big_buddha', 'Big Buddha'),
  ('kowloon_challenge', 'Kowloon Night Lights'),
];

/// Profile screen: header, tabs (Badges / Joined / Completed), and challenge lists from Firestore.
/// Joined: tap opens challenge detail. Completed: tap opens detail, pen opens review screen.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedTabIndex = 0;
  UserProfile? _profile;
  List<String> _joinedIds = [];
  List<String> _completedIds = [];
  Map<String, String> _joinedTitles = {};
  Map<String, String> _completedTitles = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _loading = false;
        _profile = null;
        _joinedIds = _mockJoined.map((e) => e.$1).toList();
        _completedIds = _mockCompleted.map((e) => e.$1).toList();
        _joinedTitles = _mockJoined.asMap().map((_, e) => MapEntry(e.$1, e.$2));
        _completedTitles = _mockCompleted.asMap().map((_, e) => MapEntry(e.$1, e.$2));
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await fetchUserProfile(user.uid);
      if (!mounted) return;
      if (profile == null) {
        setState(() {
          _profile = null;
          _joinedIds = _mockJoined.map((e) => e.$1).toList();
          _completedIds = _mockCompleted.map((e) => e.$1).toList();
          _joinedTitles = _mockJoined.asMap().map((_, e) => MapEntry(e.$1, e.$2));
          _completedTitles = _mockCompleted.asMap().map((_, e) => MapEntry(e.$1, e.$2));
          _loading = false;
        });
        return;
      }
      final joinedTitles = await fetchChallengeTitles(profile.joinedChlgs);
      final completedTitles = await fetchChallengeTitles(profile.completedChlgs);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _joinedIds = profile.joinedChlgs.isNotEmpty ? profile.joinedChlgs : _mockJoined.map((e) => e.$1).toList();
        _completedIds = profile.completedChlgs.isNotEmpty ? profile.completedChlgs : _mockCompleted.map((e) => e.$1).toList();
        _joinedTitles = joinedTitles.isNotEmpty ? joinedTitles : _mockJoined.asMap().map((_, e) => MapEntry(e.$1, e.$2));
        _completedTitles = completedTitles.isNotEmpty ? completedTitles : _mockCompleted.asMap().map((_, e) => MapEntry(e.$1, e.$2));
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _joinedIds = _mockJoined.map((e) => e.$1).toList();
          _completedIds = _mockCompleted.map((e) => e.$1).toList();
          _joinedTitles = _mockJoined.asMap().map((_, e) => MapEntry(e.$1, e.$2));
          _completedTitles = _mockCompleted.asMap().map((_, e) => MapEntry(e.$1, e.$2));
          _loading = false;
        });
      }
    }
  }

  void _openReview(String challengeId, String challengeTitle) {
    Navigator.of(context).pushNamed(
      AppRoutes.challengeReview,
      arguments: <String, dynamic>{
        'challengeId': challengeId,
        'challengeTitle': challengeTitle,
      },
    ).then((_) {
      // Optionally refresh so a new review is reflected
      _loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = _profile?.nameSurname ?? user?.displayName ?? user?.email?.split('@').first ?? _mockDisplayName;
    final email = (_profile?.email.isNotEmpty == true ? _profile!.email : user?.email) ?? _mockEmail;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
        title: const SizedBox.shrink(),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Material(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Coming soon')),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Icon(Icons.menu, color: Colors.white, size: 24),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ProfileHeader(
                    displayName: displayName,
                    email: email,
                  ),
                  const SizedBox(height: 24),
                  _buildTabBar(),
                  const SizedBox(height: 20),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                      ),
                    ),
                  _buildContent(),
                ],
              ),
            ),
    );
  }

  Widget _buildTabBar() {
    const labels = ['Badges', 'Joined Challenges', 'Completed Challenges'];
    return Row(
      children: List.generate(labels.length, (i) {
        final isSelected = _selectedTabIndex == i;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < labels.length - 1 ? 8 : 0),
            child: Material(
              color: isSelected
                  ? Colors.grey.shade200
                  : AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: () => setState(() => _selectedTabIndex = i),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildBadgesPlaceholder();
      case 1:
        return _buildChallengeList(
          _joinedIds,
          _joinedTitles,
          showEditButton: false,
        );
      case 2:
        return _buildChallengeList(
          _completedIds,
          _completedTitles,
          showEditButton: true,
          onEditTap: _openReview,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBadgesPlaceholder() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          'Badges coming soon',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildChallengeList(
    List<String> challengeIds,
    Map<String, String> titles, {
    required bool showEditButton,
    void Function(String challengeId, String challengeTitle)? onEditTap,
  }) {
    if (challengeIds.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            showEditButton ? 'No completed challenges yet' : 'No joined challenges yet',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: challengeIds.asMap().entries.map((entry) {
        final index = entry.key;
        final id = entry.value;
        final title = titles[id] ?? id;
        return ProfileChallengeTile(
          challengeId: id,
          title: title,
          isHighlighted: index == 0,
          showEditButton: showEditButton,
          onEditTap: showEditButton && onEditTap != null
              ? () => onEditTap(id, title)
              : null,
        );
      }).toList(),
    );
  }
}
