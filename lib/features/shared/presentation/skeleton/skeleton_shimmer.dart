import 'package:flutter/material.dart';

import '../../../../core/theme/app_motion.dart';
import 'skeleton_tokens.dart';

/// Sweeps a highlight gradient over [child] skeleton bones.
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
    )..repeat();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final base = SkeletonTokens.shimmerBase(brightness);
    final highlight = SkeletonTokens.shimmerHighlight(brightness);

    final labeled = Semantics(
      label: 'Loading',
      container: true,
      child: widget.child,
    );

    final controller = _controller;
    if (controller == null) {
      return labeled;
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.2 + 2.4 * controller.value, 0),
              end: Alignment(0.2 + 2.4 * controller.value, 0),
              colors: [base, highlight, base],
              stops: const [0.25, 0.5, 0.75],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: labeled,
    );
  }
}
