import 'package:flutter/material.dart';
import '../config/theme.dart';

class BadgeWidget extends StatelessWidget {
  final String name;
  final bool earned;

  const BadgeWidget({super.key, required this.name, this.earned = false});

  @override
  Widget build(BuildContext context) {
    // TODO: Design badge visuals with earned/unearned states
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: earned ? AppTheme.accentColor : Colors.grey[300],
          child: Icon(
            Icons.star,
            color: earned ? AppTheme.primaryColor : Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: TextStyle(
            fontSize: 12,
            color: earned ? Colors.black87 : Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
