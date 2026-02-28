import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/challenge.dart';

class ChallengeCompleteScreen extends StatelessWidget {
  final Challenge challenge;

  const ChallengeCompleteScreen({super.key, required this.challenge});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Challenge')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt, size: 64, color: AppTheme.primaryColor),
              const SizedBox(height: 16),
              Text(
                challenge.title,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Take a photo to verify your challenge completion',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              // TODO: Photo capture & upload flow
              // TODO: AI verification loading state
              // TODO: Confetti celebration on success
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Open camera, upload photo, verify with AI
                },
                icon: const Icon(Icons.camera),
                label: const Text('Take Photo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
