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
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.skeletonShimmer,
  );

  /// Built once; the pulse runs 1.0 -> 0.55 -> 1.0.
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.tonePulse,
  );
  late final Animation<double> _opacity = Tween<double>(
    begin: 1,
    end: 0.55,
  ).animate(_curve);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduceMotion(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labeled = Semantics(
      label: AppLocalizations.of(context).loadingLabel,
      container: true,
      child: widget.child,
    );

    if (AppMotion.reduceMotion(context)) return labeled;
    return FadeTransition(opacity: _opacity, child: labeled);
  }
}
