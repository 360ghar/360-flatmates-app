import 'package:flutter/material.dart';

import '../../../../core/theme/app_motion.dart';

/// Staggered card appear animation — fades in + slides up with per-item delay.
///
/// Only the first [maxAnimatedIndex] items animate. Deeper indices render
/// immediately so long feeds do not create N animation controllers with
/// cumulative delays (which janks after ~10–20 cards).
class StaggeredCardAppear extends StatefulWidget {
  const StaggeredCardAppear({
    required this.index,
    required this.child,
    super.key,
    this.maxAnimatedIndex = 6,
  });

  final int index;
  final Widget child;

  /// Items at this index or above skip animation and paint immediately.
  final int maxAnimatedIndex;

  @override
  State<StaggeredCardAppear> createState() => _StaggeredCardAppearState();
}

class _StaggeredCardAppearState extends State<StaggeredCardAppear>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _fadeIn;
  Animation<Offset>? _slideUp;
  var _skipAnimation = false;

  @override
  void initState() {
    super.initState();
    // Decision deferred to first build so we can read MediaQuery.
  }

  void _ensureController(BuildContext context) {
    if (_controller != null || _skipAnimation) return;

    if (widget.index >= widget.maxAnimatedIndex ||
        AppMotion.reduceMotion(context)) {
      _skipAnimation = true;
      return;
    }

    final controller = AnimationController(
      vsync: this,
      duration: AppMotion.cardAppear,
    );
    _controller = controller;
    _fadeIn = CurvedAnimation(
      parent: controller,
      curve: AppMotion.easeOutCubic,
    );
    _slideUp = Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(
      CurvedAnimation(parent: controller, curve: AppMotion.easeOutCubic),
    );
    final delay = Duration(
      milliseconds: widget.index * AppMotion.cardStagger.inMilliseconds,
    );
    Future.delayed(delay, () {
      if (mounted) controller.forward();
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _ensureController(context);

    if (_skipAnimation || _controller == null) {
      return widget.child;
    }

    return FadeTransition(
      opacity: _fadeIn!,
      child: SlideTransition(position: _slideUp!, child: widget.child),
    );
  }
}
