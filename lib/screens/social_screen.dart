import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/theme.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _challenges = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchChallengesWithParticipants();
  }

  Future<void> _fetchChallengesWithParticipants() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final snapshot = await _db.collection('challenges').get();

      final challenges = await Future.wait(snapshot.docs.map((doc) async {
        final data = doc.data();
        final List<String> joinedUids =
        List<String>.from(data['joined_people'] ?? []);

        // Fetch minimal user info for each participant
        final participants = await Future.wait(joinedUids.map((uid) async {
          try {
            final userDoc = await _db.collection('users').doc(uid).get();
            if (userDoc.exists && userDoc.data() != null) {
              final ud = userDoc.data()!;
              return {
                'uid': uid,
                'name': ud['name_surname'] ?? 'Unknown',
                'user_pic_url': ud['user_pic_url'] ?? '',
              };
            }
          } catch (_) {}
          return {'uid': uid, 'name': 'Unknown', 'user_pic_url': ''};
        }));

        double lat = 0, lng = 0;
        if (data['location'] is GeoPoint) {
          final g = data['location'] as GeoPoint;
          lat = g.latitude;
          lng = g.longitude;
        }

        return {
          'id': doc.id,
          'title': data['title'] ?? doc.id,
          'type': data['type'] ?? '',
          'difficulty': data['difficulty'] ?? '',
          'chlg_pic_url': data['chlg_pic_url'] ?? '',
          'participants': participants,
          'lat': lat,
          'lng': lng,
        };
      }));

      // Sort: challenges with more participants first
      challenges.sort((a, b) =>
          (b['participants'] as List).length
              .compareTo((a['participants'] as List).length));

      setState(() {
        _challenges = challenges;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load social data. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Social'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _fetchChallengesWithParticipants,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
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
              onPressed: _fetchChallengesWithParticipants,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_challenges.isEmpty) {
      return const Center(child: Text('No challenges found.'));
    }

    return RefreshIndicator(
      onRefresh: _fetchChallengesWithParticipants,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _challenges.length,
        itemBuilder: (context, index) =>
            _buildChallengeCard(_challenges[index]),
      ),
    );
  }

  Widget _buildChallengeCard(Map<String, dynamic> challenge) {
    final participants = challenge['participants'] as List<Map<String, dynamic>>;
    final hasParticipants = participants.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: hasParticipants
            ? () => _showParticipantsSheet(challenge)
            : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      challenge['title'],
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  _buildBadge(challenge['difficulty']),
                ],
              ),
              const SizedBox(height: 4),
              // Type chip
              if ((challenge['type'] as String).isNotEmpty)
                Text(
                  challenge['type'].toString().toUpperCase(),
                  style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.secondaryColor,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1),
                ),
              const SizedBox(height: 12),
              // Participants row
              Row(
                children: [
                  const Icon(Icons.people, size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    hasParticipants
                        ? '${participants.length} participant${participants.length > 1 ? 's' : ''}'
                        : 'No participants yet',
                    style: TextStyle(
                        color: hasParticipants ? Colors.black87 : Colors.grey,
                        fontSize: 13),
                  ),
                  const Spacer(),
                  if (hasParticipants)
                    _buildAvatarStack(participants),
                ],
              ),
              if (hasParticipants) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Tap to see participants →',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.secondaryColor,
                        fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String difficulty) {
    final colors = {
      'easy': Colors.green,
      'medium': Colors.orange,
      'hard': Colors.red,
    };
    final color = colors[difficulty.toLowerCase()] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        difficulty.toUpperCase(),
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildAvatarStack(List<Map<String, dynamic>> participants) {
    final display = participants.take(4).toList();
    return SizedBox(
      width: display.length * 22.0 + 12,
      height: 32,
      child: Stack(
        children: List.generate(display.length, (i) {
          final p = display[i];
          return Positioned(
            left: i * 22.0,
            child: CircleAvatar(
              radius: 14,
              backgroundColor: AppTheme.secondaryColor.withOpacity(0.2),
              backgroundImage: (p['user_pic_url'] as String).isNotEmpty
                  ? NetworkImage(p['user_pic_url'])
                  : null,
              child: (p['user_pic_url'] as String).isEmpty
                  ? Text(
                (p['name'] as String).isNotEmpty
                    ? (p['name'] as String)[0].toUpperCase()
                    : '?',
                style: const TextStyle(fontSize: 11),
              )
                  : null,
            ),
          );
        }),
      ),
    );
  }

  void _showParticipantsSheet(Map<String, dynamic> challenge) {
    final participants = challenge['participants'] as List<Map<String, dynamic>>;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                challenge['title'],
                style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '${participants.length} participant${participants.length > 1 ? 's' : ''} joined',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const Divider(height: 24),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: participants.length,
                  itemBuilder: (context, index) {
                    final p = participants[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor:
                        AppTheme.secondaryColor.withOpacity(0.2),
                        backgroundImage: (p['user_pic_url'] as String).isNotEmpty
                            ? NetworkImage(p['user_pic_url'])
                            : null,
                        child: (p['user_pic_url'] as String).isEmpty
                            ? Text(
                          (p['name'] as String).isNotEmpty
                              ? (p['name'] as String)[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold),
                        )
                            : null,
                      ),
                      title: Text(p['name'],
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}