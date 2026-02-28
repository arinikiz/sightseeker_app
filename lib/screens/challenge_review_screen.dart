import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/dataBaseInteractions.dart';

/// Screen to write and submit a review for a completed challenge.
/// [challengeId] and [challengeTitle] identify the challenge.
class ChallengeReviewScreen extends StatefulWidget {
  final String challengeId;
  final String challengeTitle;

  const ChallengeReviewScreen({
    super.key,
    required this.challengeId,
    required this.challengeTitle,
  });

  @override
  State<ChallengeReviewScreen> createState() => _ChallengeReviewScreenState();
}

class _ChallengeReviewScreenState extends State<ChallengeReviewScreen> {
  final TextEditingController _commentController = TextEditingController();
  int _rating = 0;
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be signed in to submit a review')),
        );
      }
      return;
    }
    final comment = _commentController.text.trim();
    if (comment.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please write a review')),
        );
      }
      return;
    }
    if (_rating < 1 || _rating > 5) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a rating (1–5 stars)')),
        );
      }
      return;
    }

    setState(() => _submitting = true);
    try {
      await submitReview(
        userId: userId,
        challengeId: widget.challengeId,
        comment: comment,
        rating: _rating,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted!')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        title: const Text('Write a review'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.challengeTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Rating',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final star = i + 1;
                return IconButton(
                  onPressed: () => setState(() => _rating = star),
                  icon: Icon(
                    _rating >= star ? Icons.star : Icons.star_border,
                    color: AppTheme.accentColor,
                    size: 40,
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            Text(
              'Your review',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _commentController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Write your review...',
                  hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Submit Review'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
