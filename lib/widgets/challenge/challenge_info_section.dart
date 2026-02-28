import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/map_place_detail.dart';

/// Listing details as key-value rows with icons (address, category, hours, etc.).
class ChallengeInfoSection extends StatelessWidget {
  final MapPlaceDetail detail;

  const ChallengeInfoSection({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = <_InfoRow>[];

    rows.add(_InfoRow(
      icon: Icons.location_on_outlined,
      label: 'Address / Area',
      value: detail.location,
    ));
    if (detail.category != null && detail.category!.isNotEmpty) {
      rows.add(_InfoRow(
        icon: Icons.category_outlined,
        label: 'Category',
        value: detail.category!,
      ));
    }
    if (detail.hours != null && detail.hours!.isNotEmpty) {
      rows.add(_InfoRow(
        icon: Icons.schedule_outlined,
        label: 'Hours',
        value: detail.hours!,
      ));
    }
    if (detail.estimatedDuration != null && detail.estimatedDuration!.isNotEmpty) {
      rows.add(_InfoRow(
        icon: Icons.timer_outlined,
        label: 'Estimated time',
        value: detail.estimatedDuration!,
      ));
    }
    if (detail.difficulty != null && detail.difficulty!.isNotEmpty) {
      rows.add(_InfoRow(
        icon: Icons.trending_up_outlined,
        label: 'Difficulty',
        value: detail.difficulty!,
      ));
    }
    if (detail.rewardPoints != null) {
      rows.add(_InfoRow(
        icon: Icons.stars_outlined,
        label: 'Reward points',
        value: '${detail.rewardPoints} pts',
      ));
    }
    if (detail.distanceKm != null) {
      rows.add(_InfoRow(
        icon: Icons.straighten_outlined,
        label: 'Distance',
        value: '${detail.distanceKm!.toStringAsFixed(1)} km',
      ));
    }
    rows.add(_InfoRow(
      icon: Icons.sell_outlined,
      label: 'Price',
      value: detail.priceLabel,
    ));
    if (detail.tags.isNotEmpty) {
      rows.add(_InfoRow(
        icon: Icons.label_outlined,
        label: 'Tags',
        value: detail.tags.join(', '),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.info_outline_rounded, color: AppTheme.secondaryColor, size: 22),
            const SizedBox(width: 8),
            Text(
              'Details',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...rows.map(
          (r) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(r.icon, size: 20, color: Colors.black54),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        r.value,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow {
  final IconData icon;
  final String label;
  final String value;

  _InfoRow({required this.icon, required this.label, required this.value});
}
