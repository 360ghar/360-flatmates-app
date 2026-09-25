import 'package:flutter/material.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_semantic_colors.dart';

/// Section label above a profile menu group.
class MenuGroupLabel extends StatelessWidget {
  const MenuGroupLabel({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      header: true,
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: AppSemanticColors.textSecondaryFor(theme.brightness),
        ),
      ),
    );
  }
}

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
    if (_controller != null || _skipAnimation) return;

    if (AppMotion.reduceMotion(context)) {
      _skipAnimation = true;
      return;
    }

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

    // Rise only: opacity stays 1, so the content is visible even if the
    // delayed animation never starts.
    return SlideTransition(position: _slideUp!, child: widget.child);
  }
}
