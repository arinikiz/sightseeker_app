import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/map_place_detail.dart';

/// Sticky header area: hero image (or placeholder) and title.
/// Used at the top of the challenge detail sliver layout.
class ChallengeHeader extends StatelessWidget {
  final MapPlaceDetail detail;

  const ChallengeHeader({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeroImage(imageUrl: detail.imageUrl),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Text(
              detail.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.secondaryColor,
              ) ??
                  const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondaryColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  final String? imageUrl;

  const _HeroImage({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _Placeholder(),
            )
          : const _Placeholder(),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4A90E2),
            Color(0xFF003366),
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.landscape_rounded,
          color: Colors.white70,
          size: 72,
        ),
      ),
    );
  }
}
