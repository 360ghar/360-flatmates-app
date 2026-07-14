import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';

/// Visual style for app-bar / overlay chrome icon buttons (DESIGN.md).
enum FlatmatesChromeIconStyle {
  /// 40px canvas + hairline border — default toolbar back/actions.
  outline,

  /// 32–40px surface-strong fill — compact chrome.
  filled,

  /// White circle + elevation shadow — photo/media overlays.
  overlay,
}

/// Circular icon button used in top chrome (app bars, listing overlays).
///
/// Matches Airbnb `icon-button-outline` / `icon-button-circle` tokens.
/// Touch target is at least 40×40 even when the visual diameter is smaller.
class FlatmatesChromeIconButton extends StatefulWidget {
  const FlatmatesChromeIconButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    super.key,
    this.style = FlatmatesChromeIconStyle.outline,
    this.iconColor,
    this.iconSize = 18,
    this.size,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final FlatmatesChromeIconStyle style;
  final Color? iconColor;
  final double iconSize;

  /// Visual diameter. Defaults: outline/overlay 40, filled 32.
  final double? size;

  static const double _minTouch = 40;

  @override
  State<FlatmatesChromeIconButton> createState() =>
      _FlatmatesChromeIconButtonState();
}

class _FlatmatesChromeIconButtonState extends State<FlatmatesChromeIconButton> {
  bool _pressed = false;

  double get _visualSize {
    if (widget.size != null) return widget.size!;
    return switch (widget.style) {
      FlatmatesChromeIconStyle.filled => 32,
      FlatmatesChromeIconStyle.outline ||
      FlatmatesChromeIconStyle.overlay => 40,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final enabled = widget.onPressed != null;
    final visual = _visualSize;
    final touch = visual < FlatmatesChromeIconButton._minTouch
        ? FlatmatesChromeIconButton._minTouch
        : visual;

    final Color bg;
    final Color borderColor;
    final List<BoxShadow> shadows;
    final Color iconColor;

    switch (widget.style) {
      case FlatmatesChromeIconStyle.outline:
        bg = brightness == Brightness.dark
            ? AppSemanticColors.darkSurface
            : AppSemanticColors.canvas;
        borderColor = AppSemanticColors.hairlineFor(brightness);
        shadows = AppShadows.none;
        iconColor =
            widget.iconColor ?? AppSemanticColors.textPrimaryFor(brightness);
      case FlatmatesChromeIconStyle.filled:
        bg = brightness == Brightness.dark
            ? AppSemanticColors.darkSurfaceElevated
            : AppSemanticColors.surfaceStrong;
        borderColor = Colors.transparent;
        shadows = AppShadows.none;
        iconColor =
            widget.iconColor ?? AppSemanticColors.textPrimaryFor(brightness);
      case FlatmatesChromeIconStyle.overlay:
        bg = AppSemanticColors.canvas;
        borderColor = Colors.transparent;
        shadows = AppShadows.elevation;
        iconColor = widget.iconColor ?? AppSemanticColors.ink;
    }

    final button = Listener(
      onPointerDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onPointerUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onPointerCancel: enabled ? (_) => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: AppMotion.buttonPress,
        curve: AppMotion.easeOutCubic,
        child: Tooltip(
          message: widget.tooltip,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPressed,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: touch,
                height: touch,
                child: Center(
                  child: AnimatedOpacity(
                    opacity: enabled ? 1 : 0.4,
                    duration: AppMotion.fast,
                    child: Container(
                      width: visual,
                      height: visual,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: bg,
                        shape: BoxShape.circle,
                        border: borderColor == Colors.transparent
                            ? null
                            : Border.all(color: borderColor),
                        boxShadow: shadows,
                      ),
                      child: Icon(
                        widget.icon,
                        size: widget.iconSize,
                        color: iconColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // Keep actions row alignment tight; outer padding lives in the header.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
      child: button,
    );
  }
}
