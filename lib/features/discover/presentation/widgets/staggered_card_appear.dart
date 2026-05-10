import 'package:flutter/material.dart';

import '../../../../core/theme/app_motion.dart';

/// Staggered card appear animation — fades in + slides up with per-item delay.
class StaggeredCardAppear extends StatefulWidget {
  const StaggeredCardAppear({
    required this.index,
    required this.child,
    super.key,
  });

  final int index;
  final Widget child;

  @override
  State<StaggeredCardAppear> createState() => _StaggeredCardAppearState();
}

class _StaggeredCardAppearState extends State<StaggeredCardAppear>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.cardAppear,
    );
    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.easeOutCubic,
    );
    _slideUp = Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: AppMotion.easeOutCubic),
    );
    final delay = Duration(
      milliseconds: widget.index * AppMotion.cardStagger.inMilliseconds,
    );
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeIn,
      child: SlideTransition(position: _slideUp, child: widget.child),
    );
  }
}
