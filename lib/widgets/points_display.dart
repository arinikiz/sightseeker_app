import 'package:flutter/material.dart';
import '../config/theme.dart';

class PointsDisplay extends StatelessWidget {
  final int points;
  final String level;

  const PointsDisplay({super.key, required this.points, required this.level});

  @override
  Widget build(BuildContext context) {
    // TODO: Animated points counter with level indicator
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.stars, color: AppTheme.accentColor),
        const SizedBox(width: 4),
        Text(
          '$points pts',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(width: 8),
        Chip(label: Text(level)),
      ],
    );
  }
}
