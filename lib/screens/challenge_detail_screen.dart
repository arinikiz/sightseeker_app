import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/challenge.dart';

class ChallengeDetailScreen extends StatelessWidget {
  final Challenge challenge;

  const ChallengeDetailScreen({super.key, required this.challenge});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(challenge.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TODO: Hero image placeholder
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Icon(Icons.image, size: 64, color: AppTheme.secondaryColor),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              challenge.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(challenge.description),
            const SizedBox(height: 16),
            Row(
              children: [
                Chip(label: Text(challenge.difficulty)),
                const SizedBox(width: 8),
                Chip(
                  label: Text('${challenge.points} pts'),
                  backgroundColor: AppTheme.accentColor,
                ),
                const SizedBox(width: 8),
                Chip(label: Text(challenge.type)),
              ],
            ),
            const SizedBox(height: 16),
            // TODO: Participants section
            // TODO: Sponsor banner if sponsored
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Accept/complete challenge logic
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Accept Challenge'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
