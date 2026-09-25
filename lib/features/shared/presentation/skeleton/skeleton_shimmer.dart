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
  AnimationController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = AppMotion.reduceMotion(context);
    if (reduce) {
      if (_controller != null) {
        _controller!.dispose();
        _controller = null;
      }
      return;
    }
    _controller ??= AnimationController(
      vsync: this,
      duration: AppMotion.skeletonShimmer,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
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

    final controller = _controller;
    if (controller == null) {
      return labeled;
    }

    return FadeTransition(
      opacity: Tween<double>(
        begin: 1,
        end: 0.55,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut)),
      child: labeled,
    );
  }
}
