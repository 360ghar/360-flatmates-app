import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';

/// Standard card — flat by default, 14px radius, hairline border for scannability.
///
/// Airbnb: most surfaces are flat; elevation is reserved for hover/float moments.
/// List rows use a 1px hairline so white cards separate on white canvas.
class FlatmatesCard extends StatefulWidget {
  const FlatmatesCard({
    required this.child,
    super.key,
    this.padding,
    this.onTap,
    this.elevation,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.bordered = true,
    this.margin,
    this.gradient,
  });

  /// Compact card with reduced padding.
  const FlatmatesCard.compact({
    required this.child,
    super.key,
    this.onTap,
    this.elevation,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.bordered = true,
    this.margin,
    this.gradient,
  }) : padding = const EdgeInsets.all(AppSpacing.md);

  /// Elevated card using the single Airbnb shadow tier.
  const FlatmatesCard.elevated({
    required this.child,
    super.key,
    this.padding,
    this.onTap,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.bordered = true,
    this.margin,
    this.gradient,
  }) : elevation = 1;

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double? elevation;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;

  /// When true (default), draws a 1px hairline (or [borderColor] if set).
  /// Set false for photo tiles / transparent chrome that must not stroke.
  final bool bordered;
  final EdgeInsetsGeometry? margin;

  /// Optional gradient background (overrides [backgroundColor]).
  final LinearGradient? gradient;

  @override
  State<FlatmatesCard> createState() => _FlatmatesCardState();
}

class _FlatmatesCardState extends State<FlatmatesCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final resolvedPadding = widget.padding ?? AppSpacing.cardPadding;
    final resolvedRadius = widget.borderRadius ?? AppRadius.cardBorder;
    final resolvedBg =
        widget.backgroundColor ??
        (isDark ? AppSemanticColors.darkSurface : AppSemanticColors.canvas);

    final bool isInteractive = widget.onTap != null;
    final List<BoxShadow> shadows;
    if (widget.elevation != null && widget.elevation! > 0) {
      shadows = AppShadows.elevationFor(theme.brightness);
    } else if (isInteractive && _pressed) {
      shadows = AppShadows.elevationFor(theme.brightness);
    } else {
      shadows = AppShadows.none;
    }

    final Border? border;
    if (!widget.bordered) {
      border = null;
    } else {
      border = Border.all(
        color:
            widget.borderColor ??
            AppSemanticColors.hairlineFor(theme.brightness),
      );
    }

    return Listener(
      onPointerDown: isInteractive
          ? (_) => setState(() => _pressed = true)
          : null,
      onPointerUp: isInteractive
          ? (_) => setState(() => _pressed = false)
          : null,
      onPointerCancel: isInteractive
          ? (_) => setState(() => _pressed = false)
          : null,
      child: AnimatedScale(
        scale: isInteractive && _pressed ? 0.97 : 1.0,
        duration: AppMotion.fast,
        curve: AppMotion.easeOutCubic,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.easeOutCubic,
          margin: widget.margin,
          decoration: BoxDecoration(
            color: widget.gradient != null ? null : resolvedBg,
            gradient: widget.gradient,
            borderRadius: resolvedRadius,
            border: border,
            boxShadow: shadows,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: resolvedRadius,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: resolvedRadius,
              child: Padding(padding: resolvedPadding, child: widget.child),
            ),
          ),
        ),
      ),
    );
  }
}
