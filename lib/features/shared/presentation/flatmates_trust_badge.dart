import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Trust badge variant — determines icon and color tint.
enum FlatmatesTrustBadgeVariant {
  verified(Icons.verified_rounded),
  reviewed(Icons.rate_review_rounded),
  safe(Icons.shield_rounded),
  privacy(Icons.lock_outline_rounded);

  const FlatmatesTrustBadgeVariant(this.icon);
  final IconData icon;
}

/// Trust badge: verified, reviewed, safe, privacy states.
///
/// Used for listing trust indicators, safety banners, privacy notes.
class FlatmatesTrustBadge extends StatelessWidget {
  const FlatmatesTrustBadge({
    required this.label,
    super.key,
    this.variant = FlatmatesTrustBadgeVariant.verified,
    this.compact = false,
  });

  final String label;
  final FlatmatesTrustBadgeVariant variant;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _resolveColor(theme);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : AppSpacing.md,
        vertical: compact ? AppSpacing.xs : AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadius.pillBorder,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(variant.icon, size: compact ? 14 : 16, color: color),
          SizedBox(width: compact ? AppSpacing.xs : AppSpacing.sm),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: compact ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }

  Color _resolveColor(ThemeData theme) {
    switch (variant) {
      case FlatmatesTrustBadgeVariant.verified:
        return AppSemanticColors.accent;
      case FlatmatesTrustBadgeVariant.reviewed:
        return AppSemanticColors.accent;
      case FlatmatesTrustBadgeVariant.safe:
        return AppSemanticColors.success;
      case FlatmatesTrustBadgeVariant.privacy:
        return AppSemanticColors.textSecondaryFor(theme.brightness);
    }
  }
}
