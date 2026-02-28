import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/map_place_detail.dart';

/// A single review row: username, date, rating, comment.
class ReviewTile extends StatelessWidget {
  final Review review;

  const ReviewTile({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.secondaryColor.withOpacity(0.2),
                child: Text(
                  review.username.isNotEmpty
                      ? review.username.substring(0, 1).toUpperCase()
                      : '?',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppTheme.secondaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.username,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _formatDate(review.date),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              _RatingStars(rating: review.rating),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review.comment,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.4,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${d.day}/${d.month}/${d.year}';
  }
}

class _RatingStars extends StatelessWidget {
  final double rating;

  const _RatingStars({required this.rating});

  @override
  Widget build(BuildContext context) {
    const full = Icons.star_rounded;
    const half = Icons.star_half_rounded;
    const empty = Icons.star_outline_rounded;
    const color = AppTheme.accentColor;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final value = i + 1.0;
        IconData icon;
        if (rating >= value) {
          icon = full;
        } else if (rating >= value - 0.5) {
          icon = half;
        } else {
          icon = empty;
        }
        return Icon(icon, size: 18, color: color);
      }),
    );
  }
}
