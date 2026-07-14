import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Chip variant — determines visual style.
enum FlatmatesChipVariant {
  /// Selectable filter chip (e.g., "Nearby", "1BHK", "Furnished").
  filter,

  /// Single-select choice chip (e.g., "Veg", "Non-Veg").
  choice,

  /// Read-only info chip (e.g., "2 Beds", "WiFi").
  info,

  /// Removable chip with close icon (e.g., selected filters).
  removable,
}

/// Single chip API for filter, choice, info, and removable states.
///
/// Replaces `FilterChip`, `ChoiceChip`, `ActionChip` defaults.
class FlatmatesChip extends StatelessWidget {
  const FlatmatesChip({
    required this.label,
    super.key,
    this.icon,
    this.selected = false,
    this.onSelected,
    this.onRemoved,
    this.variant = FlatmatesChipVariant.filter,
    this.enabled = true,
    this.tint,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final VoidCallback? onRemoved;
  final FlatmatesChipVariant variant;
  final bool enabled;

  /// When non-null, overrides the variant's color logic with a tinted
  /// background, border, and foreground derived from this color. Used
  /// for status badges (e.g. active/expired/paused on a manage-listing
  /// card) where the semantic color drives the chrome.
  final Color? tint;

  /// Leading glyph: optional [icon], or a check when selected for
  /// filter/choice chips (clearer affordance without extra color).
  IconData? get _leadingIcon {
    if (selected &&
        (variant == FlatmatesChipVariant.filter ||
            variant == FlatmatesChipVariant.choice)) {
      return Icons.check;
    }
    return icon;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _resolveColors(theme);
    const borderRadius = AppRadius.pillBorder;

    return AnimatedScale(
      scale: selected ? 1.03 : 1.0,
      duration: AppMotion.chipSelect,
      curve: AppMotion.easeOutBack,
      child: AnimatedContainer(
        duration: AppMotion.chipSelect,
        curve: AppMotion.easeOutCubic,
        // Compact density (12×6) matches icebreaker pills and keeps more
        // filter options on one row in the search sheet.
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs + AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: borderRadius,
          border: Border.all(color: colors.border),
        ),
        child: InkWell(
          onTap: enabled && onSelected != null
              ? () => onSelected!(!selected)
              : null,
          borderRadius: borderRadius,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_leadingIcon != null) ...[
                Icon(_leadingIcon, size: 14, color: colors.foreground),
                const SizedBox(width: AppSpacing.xs),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.foreground,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
              if (variant == FlatmatesChipVariant.removable) ...[
                const SizedBox(width: AppSpacing.xs),
                GestureDetector(
                  onTap: onRemoved,
                  child: Icon(Icons.close, size: 14, color: colors.foreground),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  _ChipColors _resolveColors(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    if (!enabled) {
      return _ChipColors(
        background: AppSemanticColors.disabledSurfaceFor(theme.brightness),
        foreground: AppSemanticColors.textTertiaryFor(theme.brightness),
        border: AppSemanticColors.hairlineFor(theme.brightness),
      );
    }

    final tintColor = tint;
    if (tintColor != null) {
      return _ChipColors(
        background: tintColor.withValues(alpha: 0.15),
        foreground: tintColor,
        border: tintColor.withValues(alpha: 0.25),
      );
    }

    if (selected) {
      // Airbnb-quiet selected: ink fill, white label (not brand-tinted slab).
      return _ChipColors(
        background: isDark ? AppSemanticColors.darkInk : AppSemanticColors.ink,
        foreground: isDark
            ? AppSemanticColors.darkScaffold
            : AppSemanticColors.onPrimary,
        border: isDark ? AppSemanticColors.darkInk : AppSemanticColors.ink,
      );
    }

    switch (variant) {
      case FlatmatesChipVariant.info:
        return _ChipColors(
          background: isDark
              ? AppSemanticColors.darkSurfaceElevated
              : AppSemanticColors.surfaceSoft,
          foreground: isDark
              ? AppSemanticColors.darkBody
              : AppSemanticColors.body,
          border: AppSemanticColors.hairlineFor(theme.brightness),
        );
      case FlatmatesChipVariant.filter:
      case FlatmatesChipVariant.choice:
      case FlatmatesChipVariant.removable:
        return _ChipColors(
          background: isDark
              ? AppSemanticColors.darkSurface
              : AppSemanticColors.canvas,
          foreground: isDark
              ? AppSemanticColors.darkBody
              : AppSemanticColors.body,
          border: AppSemanticColors.hairlineFor(theme.brightness),
        );
    }
  }
}

class _ChipColors {
  const _ChipColors({
    required this.background,
    required this.foreground,
    required this.border,
  });

  final Color background;
  final Color foreground;
  final Color border;
}
