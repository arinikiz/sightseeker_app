import 'package:flutter/material.dart';
import '../config/theme.dart';

class ChallengeMapMarker extends StatelessWidget {
  final String type;
  final String title;

  const ChallengeMapMarker({super.key, required this.type, required this.title});

  @override
  Widget build(BuildContext context) {
    // TODO: Custom marker widget for Google Maps overlay
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _typeColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  Color get _typeColor {
    switch (type) {
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
