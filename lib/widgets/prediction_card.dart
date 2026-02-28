import 'package:flutter/material.dart';
import '../models/prediction.dart';

class PredictionCard extends StatelessWidget {
  final Prediction prediction;

  const PredictionCard({super.key, required this.prediction});

  @override
  Widget build(BuildContext context) {
    // TODO: Implement prediction card with slider, community average, counts
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              prediction.challengeTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Community prediction: ${prediction.totalPredicted}'),
            Text('Current completions: ${prediction.currentCount}'),
            Text('Predictors: ${prediction.predictorCount}'),
          ],
        ),
      ),
    );
  }
}
