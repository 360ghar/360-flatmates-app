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
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final VoidCallback? onRemoved;
  final FlatmatesChipVariant variant;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _resolveColors(theme);
    final borderRadius = AppRadius.pillBorder;

    return AnimatedScale(
      scale: selected ? 1.03 : 1.0,
      duration: AppMotion.chipSelect,
      curve: AppMotion.easeOutBack,
      child: AnimatedContainer(
        duration: AppMotion.chipSelect,
        curve: AppMotion.easeOutCubic,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl - AppSpacing.xs,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: borderRadius,
          border: Border.all(color: colors.border, width: 1),
        ),
        child: InkWell(
          onTap: enabled && onSelected != null
              ? () => onSelected!(!selected)
              : null,
          borderRadius: borderRadius,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: colors.foreground),
                const SizedBox(width: AppSpacing.sm),
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
                const SizedBox(width: AppSpacing.sm),
                GestureDetector(
                  onTap: onRemoved,
                  child: Icon(Icons.close, size: 16, color: colors.foreground),
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
        background: isDark
            ? AppSemanticColors.darkSurfaceElevated
            : AppSemanticColors.paper4,
        foreground: AppSemanticColors.ink3,
        border: AppSemanticColors.line,
      );
    }

    if (selected) {
      return _ChipColors(
        background: isDark
            ? AppSemanticColors.coralSoftDark
            : AppSemanticColors.coralSoft,
        foreground: AppSemanticColors.accent,
        border: AppSemanticColors.accent.withValues(alpha: 0.15),
      );
    }

    switch (variant) {
      case FlatmatesChipVariant.info:
        return _ChipColors(
          background: isDark
              ? AppSemanticColors.darkSurfaceElevated
              : AppSemanticColors.paper2,
          foreground: isDark
              ? AppSemanticColors.paper3
              : AppSemanticColors.ink2,
          border: AppSemanticColors.line,
        );
      case FlatmatesChipVariant.filter:
      case FlatmatesChipVariant.choice:
      case FlatmatesChipVariant.removable:
        return _ChipColors(
          background: isDark
              ? AppSemanticColors.darkSurface
              : AppSemanticColors.paper2,
          foreground: isDark
              ? AppSemanticColors.paper3
              : AppSemanticColors.ink2,
          border: AppSemanticColors.line,
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
