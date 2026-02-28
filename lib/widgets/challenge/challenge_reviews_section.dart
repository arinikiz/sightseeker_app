import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/map_place_detail.dart';
import 'review_tile.dart';

/// Reviews block: average rating, count, and list of [ReviewTile]s.
/// Shows an empty state when there are no reviews.
class ChallengeReviewsSection extends StatelessWidget {
  final MapPlaceDetail detail;

  const ChallengeReviewsSection({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reviews = detail.reviews;
    final avg = detail.averageRating;
    final count = reviews.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.rate_review_outlined, color: AppTheme.secondaryColor, size: 22),
            const SizedBox(width: 8),
            Text(
              'Reviews',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (reviews.isEmpty)
          _EmptyReviews()
        else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                avg.toStringAsFixed(1),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                count == 1 ? '1 review' : '$count reviews',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...reviews.map((r) => ReviewTile(review: r)),
        ],
      ],
    );
  }
}

class _EmptyReviews extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.rate_review_outlined, size: 40, color: Colors.black26),
            const SizedBox(height: 8),
            Text(
              'No reviews yet',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Be the first to complete this challenge and leave a review.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
