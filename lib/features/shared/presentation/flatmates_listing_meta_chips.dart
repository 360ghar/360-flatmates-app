import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Colour categories for [ListingMetaItem] pills. Blue, teal and green use
/// the pine family; purple and orange use the clay family (one palette).
enum MetaChipColor { blue, teal, purple, orange, green }

/// A single compact "icon + label" fact used by [FlatmatesListingMetaChips].
class ListingMetaItem {
  const ListingMetaItem({
    required this.icon,
    required this.label,
    this.emphasis = false,
    this.chipColor,
  });

  final IconData icon;
  final String label;

  /// When true the label uses the accent colour (e.g. "Furnished" highlight).
  final bool emphasis;

  /// When set, the chip renders as a soft-background pill with a matching
  /// coloured icon + label. When null, the chip renders as a plain icon+label
  /// in the secondary text colour (legacy style).
  final MetaChipColor? chipColor;
}

/// A scannable, a11y-safe row of small icon+label facts for property cards.
///
/// Each item renders an icon (14 px) and a label in the caption role
/// (13 sp, the DESIGN.md minimum).
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
    final brightness = theme.brightness;
    final style = theme.textTheme.bodySmall;

    // Tinted pill when a chipColor is set: the clay or pine family, with the
    // AA-tested ink for that fill (contrast_test.dart).
    final chipColor = item.chipColor;
    if (chipColor != null) {
      final clay =
          chipColor == MetaChipColor.purple ||
          chipColor == MetaChipColor.orange;
      final background = clay
          ? AppSemanticColors.coralSoftFor(brightness)
          : AppSemanticColors.pineSoftFor(brightness);
      final foreground = clay
          ? AppSemanticColors.clayInkFor(brightness)
          : AppSemanticColors.greenInkFor(brightness);
      return DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: AppRadius.smBorder,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xxs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: 14, color: foreground),
              const SizedBox(width: AppSpacing.xs),
              Text(
                item.label,
                style: style?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Plain icon + label.
    final color = item.emphasis
        ? AppSemanticColors.clayFor(brightness)
        : secondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(item.icon, size: 14, color: color),
        const SizedBox(width: AppSpacing.xs),
        Text(
          item.label,
          style: style?.copyWith(
            fontWeight: item.emphasis ? FontWeight.w600 : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}
