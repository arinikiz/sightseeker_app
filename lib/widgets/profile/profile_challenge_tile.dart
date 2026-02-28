import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';

/// A single row in the profile challenge list: icon, title, and optional edit (pen) action.
/// [challengeId] is used for navigation to detail and review.
/// [showEditButton] and [onEditTap]: when true, the pen icon is shown and opens the review flow (e.g. for completed challenges).
/// The pen icon background is only colorful (primary) while pressing or hovering; otherwise it stays transparent.
class ProfileChallengeTile extends StatefulWidget {
  final String challengeId;
  final String title;
  final bool isHighlighted;
  final bool showEditButton;
  final VoidCallback? onEditTap;

  const ProfileChallengeTile({
    super.key,
    required this.challengeId,
    required this.title,
    this.isHighlighted = false,
    this.showEditButton = false,
    this.onEditTap,
  });

  @override
  State<ProfileChallengeTile> createState() => _ProfileChallengeTileState();
}

class _ProfileChallengeTileState extends State<ProfileChallengeTile> {
  bool _penPressedOrHovered = false;

  void _openDetail(BuildContext context) {
    Navigator.of(context).pushNamed(
      AppRoutes.challengeDetail,
      arguments: widget.challengeId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openDetail(context),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.blue.shade300,
                        Colors.blue.shade700,
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.terrain_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                  ),
                ),
                if (widget.showEditButton)
                  MouseRegion(
                    onEnter: (_) => setState(() => _penPressedOrHovered = true),
                    onExit: (_) => setState(() => _penPressedOrHovered = false),
                    child: GestureDetector(
                      onTapDown: (_) => setState(() => _penPressedOrHovered = true),
                      onTapUp: (_) => setState(() => _penPressedOrHovered = false),
                      onTapCancel: () => setState(() => _penPressedOrHovered = false),
                      onTap: () {
                        if (widget.onEditTap != null) {
                          widget.onEditTap!();
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _penPressedOrHovered
                              ? AppTheme.primaryColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.edit_outlined,
                          size: 22,
                          color: _penPressedOrHovered
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
