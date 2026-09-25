import 'package:flutter/material.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Button variant — determines visual style.
enum FlatmatesButtonVariant {
  /// Solid primary fill.
  primary,

  /// Outline with primary border.
  secondary,

  /// Text only, primary color.
  tertiary,

  /// Circular icon-only.
  iconOnly,

  /// Google theme button.
  google,
}

/// Primary CTA button — solid fill with premium press feedback.
///
/// Use named constructors for variants:
/// - [FlatmatesButton] (default) — solid primary
/// - [FlatmatesButton.secondary] — outline
/// - [FlatmatesButton.tertiary] — text only
/// - [FlatmatesButton.icon] — circular icon-only
class FlatmatesButton extends StatefulWidget {
  const FlatmatesButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.height = 48,
    this.fullWidth = false,
  }) : variant = FlatmatesButtonVariant.primary,
       iconOnly = false,
       tooltip = null,
       destructive = false;

  const FlatmatesButton.secondary({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.height = 48,
    this.fullWidth = false,
    this.destructive = false,
  }) : variant = FlatmatesButtonVariant.secondary,
       tooltip = null,
       iconOnly = false;

  const FlatmatesButton.tertiary({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.destructive = false,
  }) : variant = FlatmatesButtonVariant.tertiary,
       height = 44,
       fullWidth = false,
       tooltip = null,
       iconOnly = false;

  /// Circular icon-only button.
  ///
  /// [tooltip] is required: the icon carries no label, so it is the only
  /// accessible name a screen reader can announce.
  const FlatmatesButton.icon({
    required this.onPressed,
    required this.icon,
    required this.tooltip,
    super.key,
    this.destructive = false,
  }) : variant = FlatmatesButtonVariant.iconOnly,
       label = '',
       height = 44,
       fullWidth = false,
       iconOnly = true;

  const FlatmatesButton.google({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.height = 48,
    this.fullWidth = false,
  }) : variant = FlatmatesButtonVariant.google,
       destructive = false,
       tooltip = null,
       iconOnly = false;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// Accessible name for the icon-only variant. Null for labelled variants.
  final String? tooltip;
  final double height;
  final bool fullWidth;
  final FlatmatesButtonVariant variant;
  final bool iconOnly;
  final bool destructive;

  @override
  State<FlatmatesButton> createState() => _FlatmatesButtonState();
}

class _FlatmatesButtonState extends State<FlatmatesButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = widget.onPressed != null;

    if (widget.iconOnly) {
      return _buildIconButton(theme, enabled);
    }

    switch (widget.variant) {
      case FlatmatesButtonVariant.primary:
        return _buildPrimary(theme, enabled);
      case FlatmatesButtonVariant.secondary:
        return _buildSecondary(theme, enabled);
      case FlatmatesButtonVariant.tertiary:
        return _buildTertiary(theme, enabled);
      case FlatmatesButtonVariant.iconOnly:
        return _buildIconButton(theme, enabled);
      case FlatmatesButtonVariant.google:
        return _buildGoogle(theme, enabled);
    }
  }

  Widget _buildPrimary(ThemeData theme, bool enabled) {
    return Listener(
      onPointerDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onPointerUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onPointerCancel: enabled ? (_) => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: AppMotion.buttonPress,
        curve: AppMotion.easeOutCubic,
        child: SizedBox(
          height: widget.height,
          width: widget.fullWidth ? double.infinity : null,
          child: FilledButton(
            onPressed: widget.onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: widget.destructive
                  ? AppSemanticColors.error
                  : enabled
                  ? AppSemanticColors.primary
                  : AppSemanticColors.primaryDisabled,
              foregroundColor: AppSemanticColors.onPrimary,
              disabledBackgroundColor: AppSemanticColors.primaryDisabled,
              disabledForegroundColor: AppSemanticColors.onPrimary,
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.smBorder,
              ),
              elevation: 0,
              shadowColor: Colors.transparent,
            ),
            child: _buildChild(theme, AppSemanticColors.onPrimary),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondary(ThemeData theme, bool enabled) {
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = widget.destructive
        ? AppSemanticColors.error
        : (isDark ? AppSemanticColors.darkInk : AppSemanticColors.ink);
    final textColor = widget.destructive
        ? AppSemanticColors.error
        : (isDark ? AppSemanticColors.darkInk : AppSemanticColors.ink);

    return Listener(
      onPointerDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onPointerUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onPointerCancel: enabled ? (_) => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: AppMotion.buttonPress,
        curve: AppMotion.easeOutCubic,
        child: SizedBox(
          height: widget.height,
          width: widget.fullWidth ? double.infinity : null,
          child: OutlinedButton(
            onPressed: widget.onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: textColor,
              backgroundColor: isDark
                  ? AppSemanticColors.darkSurface
                  : AppSemanticColors.canvas,
              side: BorderSide(color: borderColor),
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.smBorder,
              ),
            ),
            child: _buildChild(theme, textColor),
          ),
        ),
      ),
    );
  }

  Widget _buildTertiary(ThemeData theme, bool enabled) {
    final textColor = widget.destructive
        ? AppSemanticColors.error
        : AppSemanticColors.textPrimaryFor(theme.brightness);

    return TextButton(
      onPressed: widget.onPressed,
      style: TextButton.styleFrom(foregroundColor: textColor),
      child: _buildChild(theme, textColor),
    );
  }

  Widget _buildIconButton(ThemeData theme, bool enabled) {
    final color = widget.destructive
        ? AppSemanticColors.error
        : AppSemanticColors.textPrimaryFor(theme.brightness);

    return SizedBox(
      width: widget.height,
      height: widget.height,
      child: IconButton(
        onPressed: widget.onPressed,
        tooltip: widget.tooltip,
        icon: Icon(widget.icon, size: 22),
        style: IconButton.styleFrom(
          foregroundColor: color,
          backgroundColor: color.withValues(alpha: 0.1),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
        ),
      ),
    );
  }

  Widget _buildGoogle(ThemeData theme, bool enabled) {
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark
        ? const Color(0xFF131314)
        : const Color(0xFFFFFFFF);
    final foregroundColor = isDark
        ? const Color(0xFFE3E3E3)
        : const Color(0xFF3C4043);
    final borderColor = isDark
        ? const Color(0xFF8E918F)
        : const Color(0xFFDADCE0);
    final hoverColor = isDark
        ? const Color(0xFF1E1F20)
        : const Color(0xFFF8F9FA);

    return Listener(
      onPointerDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onPointerUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onPointerCancel: enabled ? (_) => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: AppMotion.buttonPress,
        curve: AppMotion.easeOutCubic,
        child: SizedBox(
          height: widget.height,
          width: widget.fullWidth ? double.infinity : null,
          child: ElevatedButton(
            onPressed: widget.onPressed,
            style:
                ElevatedButton.styleFrom(
                  backgroundColor: backgroundColor,
                  foregroundColor: foregroundColor,
                  surfaceTintColor: Colors.transparent,
                  elevation: enabled ? 1 : 0,
                  shadowColor: Colors.black.withValues(alpha: 0.15),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.mdBorder,
                    side: BorderSide(
                      color: enabled
                          ? borderColor
                          : theme.disabledColor.withValues(alpha: 0.2),
                    ),
                  ),
                ).copyWith(
                  overlayColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.pressed) ||
                        states.contains(WidgetState.hovered)) {
                      return hoverColor;
                    }
                    return null;
                  }),
                ),
            child: Row(
              mainAxisSize: widget.fullWidth
                  ? MainAxisSize.max
                  : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/icons/google_logo.png',
                  width: 20,
                  height: 20,
                  filterQuality: FilterQuality.high,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    widget.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: foregroundColor,
                      letterSpacing: 0.2,
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

  Widget _buildChild(ThemeData theme, Color textColor) {
    return Row(
      mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: 20),
          const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
        ],
        Flexible(
          child: Text(
            widget.label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: widget.variant == FlatmatesButtonVariant.primary
                  ? null
                  : textColor,
            ),
          ),
        ),
      ],
    );
  }
}

/// Legacy alias — now delegates to solid FlatmatesButton.
/// Prefer using FlatmatesButton directly in new code.
class GradientActionButton extends StatelessWidget {
  const GradientActionButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.height = 56,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    return FlatmatesButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      height: height,
    );
  }
}
