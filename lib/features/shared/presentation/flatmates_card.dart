import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';

/// Standard card with padding, 16px radius, optional elevation, light/dark aware.
///
/// Replaces raw `Card`, styled `Container`, `Card(elevation: 0)` one-offs.
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
    this.margin,
    this.gradient,
    this.borderGlow = false,
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
    this.margin,
    this.gradient,
    this.borderGlow = false,
  }) : padding = const EdgeInsets.all(AppSpacing.md);

  /// Elevated card with stronger shadow.
  const FlatmatesCard.elevated({
    required this.child,
    super.key,
    this.padding,
    this.onTap,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.margin,
    this.gradient,
    this.borderGlow = false,
  }) : elevation = 4;

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double? elevation;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final EdgeInsetsGeometry? margin;

  /// Optional gradient background (overrides [backgroundColor]).
  final LinearGradient? gradient;

  /// Whether to show a primary-tinted border glow on press.
  final bool borderGlow;

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
        (isDark ? AppSemanticColors.darkSurface : AppSemanticColors.card);

    final bool isInteractive = widget.onTap != null;
    final shadows = <BoxShadow>[];

    if (widget.elevation != null) {
      shadows.add(
        BoxShadow(
          color: AppSemanticColors.ink.withValues(
            alpha: 0.06 * (widget.elevation! / 2),
          ),
          blurRadius: 4 * (widget.elevation! / 2),
          offset: Offset(0, widget.elevation! / 2),
        ),
      );
    } else {
      shadows.add(AppShadows.cardFor(theme.brightness));
    }

    if (isInteractive && _pressed) {
      shadows.add(AppShadows.subtleGlowFor(theme.brightness));
    }

    final border = widget.borderColor != null
        ? Border.all(color: widget.borderColor!)
        : widget.borderGlow && _pressed
        ? Border.all(
            color: AppSemanticColors.accent.withValues(alpha: 0.3),
            width: 1.5,
          )
        : null;

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
    );
  }
}
