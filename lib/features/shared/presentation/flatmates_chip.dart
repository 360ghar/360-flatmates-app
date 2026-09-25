import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_shadows.dart';
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
    const borderRadius = AppRadius.mdBorder;
    final removable = variant == FlatmatesChipVariant.removable;

    return AnimatedContainer(
      duration: AppMotion.durationOrZero(context, AppMotion.chipSelect),
      curve: AppMotion.paperOut,
      constraints: const BoxConstraints(minHeight: 48),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: borderRadius,
        border: colors.border == null
            ? null
            : Border.all(color: colors.border!, width: 1.5),
        boxShadow: selected || !enabled
            ? AppShadows.none
            : AppShadows.e1(theme.brightness),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: enabled && onSelected != null
              ? () => onSelected!(!selected)
              : null,
          borderRadius: borderRadius,
          child: Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.md,
              right: removable ? AppSpacing.xxs : AppSpacing.md,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_leadingIcon != null) ...[
                  Icon(_leadingIcon, size: 16, color: colors.foreground),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.foreground,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                if (removable)
                  // 48 x 48 hit area around a 16 px glyph.
                  Semantics(
                    button: true,
                    label: MaterialLocalizations.of(
                      context,
                    ).deleteButtonTooltip,
                    child: InkResponse(
                      onTap: onRemoved,
                      radius: 24,
                      child: SizedBox.square(
                        dimension: 48,
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: colors.foreground,
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

  _ChipColors _resolveColors(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    if (!enabled) {
      return _ChipColors(
        background: AppSemanticColors.disabledSurfaceFor(theme.brightness),
        foreground: AppSemanticColors.textTertiaryFor(theme.brightness),
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
      // Selected: clay-soft fill pressed flat, ink label, clay lip.
      return _ChipColors(
        background: AppSemanticColors.coralSoftFor(theme.brightness),
        foreground: AppSemanticColors.textPrimaryFor(theme.brightness),
        border: AppSemanticColors.clayFor(theme.brightness),
      );
    }

    switch (variant) {
      case FlatmatesChipVariant.info:
        return _ChipColors(
          background: AppSemanticColors.paper1For(theme.brightness),
          foreground: isDark
              ? AppSemanticColors.darkBody
              : AppSemanticColors.body,
        );
      case FlatmatesChipVariant.filter:
      case FlatmatesChipVariant.choice:
      case FlatmatesChipVariant.removable:
        return _ChipColors(
          background: AppSemanticColors.paper2For(theme.brightness),
          foreground: isDark
              ? AppSemanticColors.darkBody
              : AppSemanticColors.body,
        );
    }
  }
}

class _ChipColors {
  const _ChipColors({
    required this.background,
    required this.foreground,
    this.border,
  });

  final Color background;
  final Color foreground;
  final Color? border;
}
