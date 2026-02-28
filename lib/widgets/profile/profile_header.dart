import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// Profile header: avatar with accent border, display name, and email/status.
/// Uses [displayName] and [email] for easy swap with real user data later.
class ProfileHeader extends StatelessWidget {
  final String displayName;
  final String email;
  final String? avatarInitials;

  const ProfileHeader({
    super.key,
    required this.displayName,
    required this.email,
    this.avatarInitials,
  });

  /// Derives initials from [displayName] (e.g. "Jane Doe" -> "JD").
  String get _initials {
    if (avatarInitials != null && avatarInitials!.isNotEmpty) {
      return avatarInitials!.toUpperCase();
    }
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].length >= 2
          ? parts[0].substring(0, 2).toUpperCase()
          : parts[0].toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        // Avatar with thick primary border and thin inner ring
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryColor,
            ),
            child: CircleAvatar(
              radius: 44,
              backgroundColor: AppTheme.backgroundColor,
              child: Text(
                _initials,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondaryColor,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          displayName,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          email,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
