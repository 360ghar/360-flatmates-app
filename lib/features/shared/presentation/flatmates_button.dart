import 'package:flutter/material.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';

/// Button variant — determines visual style.
enum FlatmatesButtonVariant {
  /// Solid primary fill.
  primary,

  /// Soft pine fill. Never an outline next to a filled button.
  secondary,

  /// Text only, clay colour.
  tertiary,

  /// Bare icon with a 48 dp tap target and no tile behind it.
  iconOnly,

  /// Google theme button.
  google,
}

/// Paper button: a raised sheet that presses down onto the layer below.
///
/// Use named constructors for variants:
/// - [FlatmatesButton] (default) — clay fill
/// - [FlatmatesButton.secondary] — soft pine fill
/// - [FlatmatesButton.tertiary] — text only
/// - [FlatmatesButton.icon] — bare icon
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
       height = 48,
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
       height = 48,
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

  /// Press feedback shared by the filled variants: scale 0.98 and the
  /// shadow drops from e2 to e1, as if the sheet is pressed flat.
  Widget _paperPress({
    required ThemeData theme,
    required bool enabled,
    required Widget child,
  }) {
    final reduce = AppMotion.reduceMotion(context);
    final brightness = theme.brightness;
    final shadows = !enabled
        ? AppShadows.none
        : _pressed
        ? AppShadows.e1(brightness)
        : AppShadows.e2(brightness);
    return Listener(
      onPointerDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onPointerUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onPointerCancel: enabled ? (_) => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: _pressed && !reduce ? AppMotion.pressScale : 1.0,
        duration: AppMotion.durationOrZero(context, AppMotion.fast),
        curve: AppMotion.paperOut,
        child: AnimatedContainer(
          duration: AppMotion.durationOrZero(context, AppMotion.fast),
          curve: AppMotion.paperOut,
          height: widget.height,
          width: widget.fullWidth ? double.infinity : null,
          decoration: BoxDecoration(
            borderRadius: AppRadius.mdBorder,
            boxShadow: shadows,
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildPrimary(ThemeData theme, bool enabled) {
    final b = theme.brightness;
    final fill = widget.destructive
        ? AppSemanticColors.dangerFor(b)
        : AppSemanticColors.clayFor(b);
    final pressedFill = widget.destructive
        ? AppSemanticColors.errorHover
        : AppSemanticColors.clayPressFor(b);
    final onFill = AppSemanticColors.onClayFor(b);
    return _paperPress(
      theme: theme,
      enabled: enabled,
      child: FilledButton(
        onPressed: widget.onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: _pressed ? pressedFill : fill,
          foregroundColor: onFill,
          disabledBackgroundColor: AppSemanticColors.paperDeepFor(b),
          disabledForegroundColor: AppSemanticColors.textTertiaryFor(b),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: _buildChild(theme, enabled ? onFill : null),
      ),
    );
  }

  Widget _buildSecondary(ThemeData theme, bool enabled) {
    final b = theme.brightness;
    final fill = widget.destructive
        ? AppSemanticColors.errorSoftFor(b)
        : AppSemanticColors.pineSoftFor(b);
    final textColor = widget.destructive
        ? AppSemanticColors.dangerFor(b)
        : AppSemanticColors.textPrimaryFor(b);
    return _paperPress(
      theme: theme,
      enabled: enabled,
      child: FilledButton(
        onPressed: widget.onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: fill,
          foregroundColor: textColor,
          disabledBackgroundColor: AppSemanticColors.paperDeepFor(b),
          disabledForegroundColor: AppSemanticColors.textTertiaryFor(b),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: _buildChild(theme, enabled ? textColor : null),
      ),
    );
  }

  Widget _buildTertiary(ThemeData theme, bool enabled) {
    final textColor = widget.destructive
        ? AppSemanticColors.dangerFor(theme.brightness)
        : AppSemanticColors.clayFor(theme.brightness);

    return TextButton(
      onPressed: widget.onPressed,
      style: TextButton.styleFrom(
        foregroundColor: textColor,
        minimumSize: Size(48, widget.height),
      ),
      child: _buildChild(theme, enabled ? textColor : null),
    );
  }

  Widget _buildIconButton(ThemeData theme, bool enabled) {
    final color = widget.destructive
        ? AppSemanticColors.dangerFor(theme.brightness)
        : AppSemanticColors.textPrimaryFor(theme.brightness);

    return SizedBox(
      width: widget.height,
      height: widget.height,
      child: IconButton(
        onPressed: widget.onPressed,
        tooltip: widget.tooltip,
        icon: Icon(widget.icon, size: 24),
        style: IconButton.styleFrom(
          foregroundColor: color,
          minimumSize: const Size(48, 48),
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

  Widget _buildChild(ThemeData theme, Color? textColor) {
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
            style: theme.textTheme.labelLarge?.copyWith(color: textColor),
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
