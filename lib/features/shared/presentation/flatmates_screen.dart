import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';

/// Unified page scaffold with safe area, background, optional bottom bar.
/// On mount the page rises into place; it is fully visible from the first
/// frame (no fade from transparent).
///
/// Replaces the repeated `Scaffold > SafeArea > ListView/Column` pattern.
class FlatmatesScreen extends StatefulWidget {
  const FlatmatesScreen({
    required this.body,
    super.key,
    this.appBar,
    this.bottomNavigationBar,
    this.bottomSheet,
    this.floatingActionButton,
    this.backgroundColor,
    this.useSafeArea = true,
    this.scrollable = false,
    this.padding,
    this.scrollController,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? bottomSheet;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final bool useSafeArea;
  final bool scrollable;
  final EdgeInsetsGeometry? padding;

  /// Controller for the [scrollable] body, for example to drive scene
  /// parallax.
  final ScrollController? scrollController;

  @override
  State<FlatmatesScreen> createState() => _FlatmatesScreenState();
}

class _FlatmatesScreenState extends State<FlatmatesScreen>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _rise;
  bool _reduceMotion = false;
  bool _motionResolved = false;

  void _resolveMotion(BuildContext context) {
    if (_motionResolved) return;
    _motionResolved = true;
    _reduceMotion = AppMotion.reduceMotion(context);
    if (_reduceMotion) return;

    final controller = AnimationController(
      vsync: this,
      duration: AppMotion.slow,
    );
    _controller = controller;
    _rise = CurvedAnimation(parent: controller, curve: AppMotion.paperOut);
    controller.forward();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _resolveMotion(context);
    final effectivePadding = widget.padding ?? AppSpacing.horizontalScreen;
    final content = widget.scrollable
        ? LayoutBuilder(
            builder: (context, constraints) {
              final verticalPadding = effectivePadding.vertical;
              return SingleChildScrollView(
                controller: widget.scrollController,
                padding: effectivePadding,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: (constraints.maxHeight - verticalPadding) > 0
                        ? (constraints.maxHeight - verticalPadding)
                        : 0.0,
                  ),
                  child: widget.body,
                ),
              );
            },
          )
        : Padding(
            padding: widget.padding ?? EdgeInsets.zero,
            child: widget.body,
          );

    final body = widget.useSafeArea ? SafeArea(child: content) : content;
    final rise = _rise;

    return Scaffold(
      appBar: widget.appBar,
      backgroundColor: widget.backgroundColor,
      bottomNavigationBar: widget.bottomNavigationBar,
      bottomSheet: widget.bottomSheet,
      floatingActionButton: widget.floatingActionButton,
      body: _reduceMotion || rise == null
          ? body
          : AnimatedBuilder(
              animation: rise,
              child: body,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, AppMotion.layerRise * (1 - rise.value)),
                child: child,
              ),
            ),
    );
  }
}
