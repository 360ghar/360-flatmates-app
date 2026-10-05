import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/paper_theme.dart';
import 'test_id.dart';

/// Paper card: a layer-two sheet with a hand-cut radius, fine grain and a
/// tight down-right shadow (DESIGN.md §4, §8). Interactive cards press flat:
/// scale 0.98 and the shadow drops from e2 to e1.
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

  /// Raised card (e3), for content that floats above its neighbours.
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

  /// When true (default) the card casts its paper shadow. Set false for
  /// transparent chrome that must stay flat. [borderColor] adds a 1.5 px
  /// stroke, for selected states.
  final bool bordered;
  final EdgeInsetsGeometry? margin;

  /// Optional gradient background (overrides [backgroundColor]).
  final LinearGradient? gradient;

  @override
  State<FlatmatesCard> createState() => _FlatmatesCardState();
}

class _FlatmatesCardState extends State<FlatmatesCard> {
  static const _grain = AssetImage('assets/paper/grain.png');
  bool _pressed = false;

  @override
  Widget build(BuildContext context) =>
      withTestId(widget.key, _buildContent(context));

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedPadding = widget.padding ?? AppSpacing.cardPadding;
    final resolvedRadius = widget.borderRadius ?? AppRadius.cardBorder;
    final resolvedBg =
        widget.backgroundColor ??
        AppSemanticColors.surfaceFor(theme.brightness);

    final bool isInteractive = widget.onTap != null;
    final raised = widget.elevation != null && widget.elevation! > 0;
    final List<BoxShadow> shadows;
    if (!widget.bordered) {
      shadows = AppShadows.none;
    } else if (isInteractive && _pressed) {
      shadows = AppShadows.e1(theme.brightness);
    } else {
      shadows = raised
          ? AppShadows.e3(theme.brightness)
          : AppShadows.e2(theme.brightness);
    }
    final borderColor = widget.borderColor;
    final border = borderColor == null
        ? null
        : Border.all(color: borderColor, width: 1.5);
    final reduce = AppMotion.reduceMotion(context);

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
        scale: isInteractive && _pressed && !reduce
            ? AppMotion.pressScale
            : 1.0,
        duration: AppMotion.durationOrZero(context, AppMotion.fast),
        curve: AppMotion.paperOut,
        child: AnimatedContainer(
          duration: AppMotion.durationOrZero(context, AppMotion.fast),
          curve: AppMotion.paperOut,
          margin: widget.margin,
          decoration: BoxDecoration(
            color: widget.gradient != null ? null : resolvedBg,
            gradient: widget.gradient,
            borderRadius: resolvedRadius,
            border: border,
            boxShadow: shadows,
            image: widget.bordered && widget.gradient == null
                ? DecorationImage(
                    image: _grain,
                    repeat: ImageRepeat.repeat,
                    opacity: PaperTheme.of(context).grainOpacity,
                    scale: 2,
                  )
                : null,
          ),
          // Clip so edge-to-edge images follow the hand-cut corners.
          child: Material(
            color: Colors.transparent,
            borderRadius: resolvedRadius,
            clipBehavior: Clip.antiAlias,
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
