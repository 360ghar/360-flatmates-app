import 'package:flutter/material.dart';

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

    // Icon plus type, no pill behind it (DESIGN.md: rank metadata with type,
    // not tinted chips).
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(variant.icon, size: compact ? 14 : 16, color: color),
          SizedBox(width: compact ? AppSpacing.xs : AppSpacing.sm),
          // Flexible + ellipsis so a long label (or a large text scale) shrinks
          // inside the available width instead of overflowing the pill. Loose
          // fit inside a MainAxisSize.min Row is safe under unbounded width —
          // the label simply falls back to its intrinsic size there.
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _resolveColor(ThemeData theme) {
    switch (variant) {
      case FlatmatesTrustBadgeVariant.verified:
      case FlatmatesTrustBadgeVariant.safe:
        return AppSemanticColors.pineFor(theme.brightness);
      case FlatmatesTrustBadgeVariant.reviewed:
        return AppSemanticColors.clayFor(theme.brightness);
      case FlatmatesTrustBadgeVariant.privacy:
        return AppSemanticColors.textSecondaryFor(theme.brightness);
    }
  }
}
