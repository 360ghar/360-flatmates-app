import 'package:flutter/material.dart';

import '../../../../core/theme/app_semantic_colors.dart';

/// Row of action buttons (pass, super-like, like) for the swipe deck.
///
/// Displays three circular buttons:
/// - **Pass** (left, red close icon)
/// - **Super-like** (center, amber star icon)
/// - **Like** (right, green heart icon)
///
/// All buttons are disabled when [isAnimating] is true.
class SwipeActionBar extends StatelessWidget {
  const SwipeActionBar({
    required this.onPass,
    required this.onSuperLike,
    required this.onLike,
    required this.isAnimating,
    super.key,
  });

  final VoidCallback onPass;
  final VoidCallback onSuperLike;
  final VoidCallback onLike;
  final bool isAnimating;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _SwipeActionButton(
            key: const Key('swipe_pass'),
            icon: Icons.close_rounded,
            color: AppSemanticColors.compatLow,
            size: 60,
            onPressed: isAnimating ? null : onPass,
          ),
          _SwipeActionButton(
            key: const Key('swipe_super_like'),
            icon: Icons.star_rounded,
            color: AppSemanticColors.yellowMid,
            size: 50,
            onPressed: isAnimating ? null : onSuperLike,
          ),
          _SwipeActionButton(
            key: const Key('swipe_like'),
            icon: Icons.favorite_rounded,
            color: AppSemanticColors.success,
            size: 60,
            onPressed: isAnimating ? null : onLike,
          ),
        ],
      ),
    );
  }
}

/// A single circular action button with a colored icon.
class _SwipeActionButton extends StatelessWidget {
  const _SwipeActionButton({
    required this.icon,
    required this.color,
    required this.size,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
          ),
          child: Icon(icon, color: color, size: size * 0.45),
        ),
      ),
    );
  }
}
