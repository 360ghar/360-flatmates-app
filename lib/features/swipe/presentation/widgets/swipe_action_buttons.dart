import 'package:flutter/material.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';

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
    final locale = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Row(
        children: [
          Expanded(
            child: _SwipeActionButton(
              key: const Key('swipe_pass'),
              icon: Icons.close_rounded,
              label: locale.passActionLabel,
              color: AppSemanticColors.compatLow,
              onPressed: isAnimating ? null : onPass,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _SwipeActionButton(
              key: const Key('swipe_super_like'),
              icon: Icons.star_rounded,
              label: locale.superLikeActionLabel,
              color: AppSemanticColors.yellowMid,
              onPressed: isAnimating ? null : onSuperLike,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _SwipeActionButton(
              key: const Key('swipe_like'),
              icon: Icons.favorite_rounded,
              label: locale.likeActionLabel,
              color: AppSemanticColors.success,
              onPressed: isAnimating ? null : onLike,
            ),
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
    required this.label,
    required this.color,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 52, minWidth: 44),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
