import 'package:flutter/material.dart';

import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// A single compact "icon + label" fact used by [FlatmatesListingMetaChips].
class ListingMetaItem {
  const ListingMetaItem({
    required this.icon,
    required this.label,
    this.emphasis = false,
  });

  final IconData icon;
  final String label;

  /// When true the label uses the accent colour (e.g. "Furnished" highlight).
  final bool emphasis;
}

/// A scannable, a11y-safe row of small icon+label facts for property cards.
///
/// Replaces the tiny 9–10sp text blobs that violated the DESIGN.md 11sp
/// minimum. Each item renders an icon (13px) + label at a guaranteed 11sp,
/// so bedrooms / baths / area / furnishing are readable at a glance.
///
/// Items are laid out with a [Wrap] so localized label expansion (Hindi,
/// German, etc.) line-breaks to a second row on narrow screens instead
/// of clipping past the card edge.
class FlatmatesListingMetaChips extends StatelessWidget {
  const FlatmatesListingMetaChips({required this.items, super.key});

  final List<ListingMetaItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final secondary = AppSemanticColors.textSecondaryFor(theme.brightness);

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final item in items)
          _MetaFact(item: item, secondary: secondary, theme: theme),
      ],
    );
  }
}

class _MetaFact extends StatelessWidget {
  const _MetaFact({
    required this.item,
    required this.secondary,
    required this.theme,
  });

  final ListingMetaItem item;
  final Color secondary;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final color = item.emphasis ? AppSemanticColors.accent : secondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(item.icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          item.label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 11,
            fontWeight: item.emphasis ? FontWeight.w700 : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}
