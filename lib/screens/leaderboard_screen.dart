import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/theme.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _allTimeUsers = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchLeaderboard();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchLeaderboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final snapshot = await _db
          .collection('users')
          .orderBy('cum_points', descending: true)
          .limit(50)
          .get();

      final users = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'uid': doc.id,
          'name': data['name_surname'] ?? 'Unknown',
          'cum_points': data['cum_points'] is int ? data['cum_points'] : 0,
          'user_pic_url': data['user_pic_url'] ?? '',
          'completed_count':
          (data['completed_chlg'] as List?)?.length ?? 0,
        };
      }).toList();

      setState(() {
        _allTimeUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load leaderboard. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _fetchLeaderboard,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Time'),
            Tab(text: 'This Week'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLeaderboardList(_allTimeUsers),
          // This Week: filter to users who completed challenges this week
          // For now shares the same fetch; extend with a date filter when weekly
          // challenge completion timestamps are available in Firestore.
          _buildLeaderboardList(_allTimeUsers),
        ],
      ),
    );
  }

  Widget _buildLeaderboardList(List<Map<String, dynamic>> users) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchLeaderboard,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (users.isEmpty) {
      return const Center(child: Text('No users found.'));
    }

    return RefreshIndicator(
      onRefresh: _fetchLeaderboard,
      child: Column(
        children: [
          // Top 3 podium
          if (users.length >= 3) _buildPodium(users),
          const Divider(height: 1),
          // Full rankings below top 3
          Expanded(
            child: ListView.builder(
              itemCount: users.length > 3 ? users.length - 3 : 0,
              itemBuilder: (context, index) {
                final user = users[index + 3];
                final rank = index + 4;
                return _buildRankTile(user, rank);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodium(List<Map<String, dynamic>> users) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 2nd place
          _buildPodiumItem(users[1], rank: 2, height: 80),
          const SizedBox(width: 12),
          // 1st place
          _buildPodiumItem(users[0], rank: 1, height: 110),
          const SizedBox(width: 12),
          // 3rd place
          _buildPodiumItem(users[2], rank: 3, height: 60),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(Map<String, dynamic> user, {required int rank, required double height}) {
    final medals = {1: '🥇', 2: '🥈', 3: '🥉'};
    final colors = {
      1: const Color(0xFFFFD700),
      2: const Color(0xFFC0C0C0),
      3: const Color(0xFFCD7F32),
    };

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(medals[rank]!, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          CircleAvatar(
            radius: rank == 1 ? 28 : 22,
            backgroundColor: colors[rank],
            backgroundImage: user['user_pic_url'].isNotEmpty
                ? NetworkImage(user['user_pic_url'])
                : null,
            child: user['user_pic_url'].isEmpty
                ? Text(
              (user['name'] as String).isNotEmpty
                  ? (user['name'] as String)[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            )
                : null,
          ),
          const SizedBox(height: 6),
          Text(
            user['name'],
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          Text(
            '${user['cum_points']} pts',
            style: TextStyle(
              fontSize: 11,
              color: colors[rank],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: height,
            decoration: BoxDecoration(
              color: colors[rank]!.withOpacity(0.3),
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankTile(Map<String, dynamic> user, int rank) {
    return ListTile(
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '#$rank',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.accentColor.withOpacity(0.2),
            backgroundImage: user['user_pic_url'].isNotEmpty
                ? NetworkImage(user['user_pic_url'])
                : null,
            child: user['user_pic_url'].isEmpty
                ? Text(
              (user['name'] as String).isNotEmpty
                  ? (user['name'] as String)[0].toUpperCase()
                  : '?',
              style: const TextStyle(fontWeight: FontWeight.bold),
            )
                : null,
          ),
        ],
      ),
      title: Text(user['name'],
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('${user['completed_count']} challenges completed'),
      trailing: Text(
        '${user['cum_points']} pts',
        style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: AppTheme.accentColor),
      ),
    );
  }
}