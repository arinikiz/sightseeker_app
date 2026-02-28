import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/challenge.dart';

class ChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final VoidCallback? onTap;

  const ChallengeCard({super.key, required this.challenge, this.onTap});

  @override
  Widget build(BuildContext context) {
    // TODO: Implement styled challenge card with type color, points, difficulty
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(Icons.flag, color: _typeColor),
        title: Text(challenge.title),
        subtitle: Text('${challenge.points} pts  |  ${challenge.difficulty}'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Color get _typeColor {
    switch (challenge.type) {
      case 'photo':
        return AppTheme.photoColor;
      case 'food':
        return AppTheme.foodColor;
      case 'activity':
        return AppTheme.activityColor;
      default:
        return Colors.grey;
    }
  }
}
