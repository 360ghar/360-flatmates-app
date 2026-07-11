import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Semantic colour categories for [ListingMetaItem] pills.
///
/// Each maps to a soft-background + coloured-icon pair from the categorical
/// pastel tokens in [AppSemanticColors]. These are product-only tokens (not
/// Airbnb mainline) used to differentiate property facts at a glance.
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
    // Colour-coded pill style when a chipColor is specified.
    if (item.chipColor != null) {
      final palette = _ChipPalette.forColor(
        item.chipColor!,
        theme.brightness == Brightness.dark,
      );
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm - AppSpacing.xxs,
          vertical: AppSpacing.xxs + 1,
        ),
        decoration: BoxDecoration(
          color: palette.background,
          borderRadius: AppRadius.xsBorder,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, size: 13, color: palette.foreground),
            const SizedBox(width: 3),
            Text(
              item.label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: palette.foreground,
              ),
            ),
          ],
        ),
      );
    }

    // Legacy plain style (no chipColor).
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

/// Resolves a [MetaChipColor] to its soft-background + foreground colour pair,
/// with dark-mode variants.
class _ChipPalette {
  const _ChipPalette({required this.background, required this.foreground});

  final Color background;
  final Color foreground;

  static _ChipPalette forColor(MetaChipColor color, bool isDark) {
    final brightness = isDark ? Brightness.dark : Brightness.light;
    return switch (color) {
      MetaChipColor.blue => _ChipPalette(
        background: AppSemanticColors.blueSoftFor(brightness),
        foreground: isDark
            ? AppSemanticColors.blueMid
            : AppSemanticColors.blueInk,
      ),
      MetaChipColor.teal => _ChipPalette(
        background: AppSemanticColors.tealSoftFor(brightness),
        foreground: isDark
            ? AppSemanticColors.tealMid
            : AppSemanticColors.tealInk,
      ),
      MetaChipColor.purple => _ChipPalette(
        background: AppSemanticColors.purpleSoftFor(brightness),
        foreground: isDark
            ? AppSemanticColors.purpleMid
            : AppSemanticColors.purpleInk,
      ),
      MetaChipColor.orange => _ChipPalette(
        background: AppSemanticColors.orangeSoftFor(brightness),
        foreground: isDark
            ? AppSemanticColors.orangeMid
            : AppSemanticColors.orangeInk,
      ),
      MetaChipColor.green => _ChipPalette(
        background: AppSemanticColors.greenSoftFor(brightness),
        foreground: AppSemanticColors.greenInkFor(brightness),
      ),
    };
  }
}
