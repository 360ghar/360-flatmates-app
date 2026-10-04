import 'package:flutter/material.dart';

import '../../../../core/theme/app_motion.dart';
import '../../../../l10n/gen/app_localizations.dart';

/// Slow tone pulse over [child] skeleton bones (DESIGN.md §8): no sweeping
/// highlight. Bones are placeholders, not content, so fading them is safe.
///
/// Respects reduced motion: when animations are disabled, renders a static
/// tree with no [AnimationController].
class FlatmatesSkeletonShimmer extends StatefulWidget {
  const FlatmatesSkeletonShimmer({required this.child, super.key});

  final Widget child;

  @override
  State<FlatmatesSkeletonShimmer> createState() =>
      _FlatmatesSkeletonShimmerState();
}

class _FlatmatesSkeletonShimmerState extends State<FlatmatesSkeletonShimmer>
    with SingleTickerProviderStateMixin {
  /// Built only when motion is enabled, so a reduced-motion skeleton stays a
  /// static tree with no ticker and no allocation at all.
  AnimationController? _controller;
  CurvedAnimation? _curve;

  /// The pulse runs 1.0 -> 0.55 -> 1.0. Null while reduced motion is on.
  Animation<double>? _opacity;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduceMotion(context)) {
      _controller?.stop();
      return;
    }
    var controller = _controller;
    if (controller == null) {
      controller = AnimationController(
        vsync: this,
        duration: AppMotion.skeletonShimmer,
      );
      final curve = CurvedAnimation(
        parent: controller,
        curve: AppMotion.tonePulse,
      );
      _controller = controller;
      _curve = curve;
      _opacity = Tween<double>(begin: 1, end: 0.55).animate(curve);
    }
    if (!controller.isAnimating) {
      controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _curve?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labeled = Semantics(
      label: AppLocalizations.of(context).loadingLabel,
      container: true,
      child: widget.child,
    );

    final opacity = _opacity;
    if (opacity == null) return labeled;
    return FadeTransition(opacity: opacity, child: labeled);
  }
}
