import 'package:flutter/material.dart';
import '../../../../core/theme/app_motion.dart';

/// Staggered rise for profile menu groups (content is never hidden).
class StaggeredMenuGroup extends StatefulWidget {
  const StaggeredMenuGroup({
    required this.delayIndex,
    required this.child,
    super.key,
  });

  final int delayIndex;
  final Widget child;

  @override
  State<StaggeredMenuGroup> createState() => _StaggeredMenuGroupState();
}

class _StaggeredMenuGroupState extends State<StaggeredMenuGroup>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<Offset>? _slideUp;
  var _skipAnimation = false;

  @override
  void initState() {
    super.initState();
    // Reduce-Motion decision deferred to first build so MediaQuery is
    // readable; content must never be gated behind the stagger.
  }

  void _ensureController(BuildContext context) {
    // Checked before the controller guard: the platform setting can change
    // while this widget is alive, and a rebuild must honour the new
    // preference rather than the one captured on first build.
    if (AppMotion.reduceMotion(context)) {
      _skipAnimation = true;
      final controller = _controller;
      if (controller != null) {
        // Finish a queued or running rise so it stops ticking.
        controller.stop();
        controller.value = 1;
      }
      return;
    }

    if (_controller != null || _skipAnimation) return;

    final controller = AnimationController(
      vsync: this,
      duration: AppMotion.slow,
    );
    _controller = controller;
    _slideUp = Tween(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: controller, curve: AppMotion.paperOut));
    final delay = Duration(
      milliseconds:
          300 + widget.delayIndex * AppMotion.staggerItem.inMilliseconds,
    );
    Future.delayed(delay, () {
      // Reduce motion may have been switched on while this was queued.
      if (!mounted || _skipAnimation) return;
      controller.forward();
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

    // Rise only: opacity stays 1, so the content is visible even if the
    // delayed animation never starts.
    return SlideTransition(position: _slideUp!, child: widget.child);
  }
}
