import 'package:flutter/material.dart';
import '../config/theme.dart';

class BusinessBanner extends StatelessWidget {
  final String businessName;
  final String businessType;

  const BusinessBanner({
    super.key,
    required this.businessName,
    required this.businessType,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: Styled sponsor banner for challenge detail screen
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified, size: 16, color: AppTheme.secondaryColor),
          const SizedBox(width: 8),
          Text('Sponsored by $businessName'),
        ],
      ),
    );
  }
}
