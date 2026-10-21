import 'package:flutter/material.dart';

import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';

/// Unified page scaffold with safe area, background, optional bottom bar.
/// On mount the page rises into place; it is fully visible from the first
/// frame (no fade from transparent).
///
/// The body is capped at [AppBreakpoints.contentMaxWidth] and centred, so a
/// wide viewport (the open iPhone Duo is 951 dp) gets a reading column instead
/// of 951 dp lines of text. On a phone the cap is never reached and the layout
/// is unchanged.
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
    this.fullBleed = false,
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

  /// Skips the reading-column cap, for a surface that is not text, such as the
  /// map. Fixed per page: toggling it at runtime would rebuild the body.
  final bool fullBleed;
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

  /// Caps the body at [AppBreakpoints.contentMaxWidth] and centres it.
  ///
  /// When the available width already fits inside the cap the [content] is
  /// returned untouched: on a phone (466 / 669 dp) the layout is byte-for-byte
  /// what it was before this cap existed.
  ///
  /// The wide branch sets only a *width*, never a height: the height
  /// constraints the body receives are the ones the enclosing `Align` loosens
  /// from the page rect, which is exactly what `Scaffold` handed the body
  /// before. That is what keeps the scrollable branch's `minHeight`
  /// (`constraints.maxHeight - verticalPadding`) correct — it still sees the
  /// full page height, only a narrower width.
  Widget _capped(BuildContext context, Widget content) {
    final cap = AppBreakpoints.contentMaxWidth(
      MediaQuery.sizeOf(context).width,
    );
    return LayoutBuilder(
      builder: (context, constraints) => Align(
        alignment: Alignment.topCenter,
        // One widget type in both branches, deliberately. Returning [content]
        // bare while the cap does not bind and an [Align] when it does would
        // swap the element at this slot on every fold/unfold, tearing down the
        // scroll view with it — the reader loses their place in the feed. The
        // cap is therefore always applied as a `maxWidth` constraint, which is
        // a no-op while it is not binding.
        //
        // Only a width is ever set. `BoxConstraints(maxWidth:)` leaves the
        // height constraints alone, so the scrollable branch's `minHeight`
        // still sees the full page height.
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: cap),
          child: content,
        ),
      ),
    );
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

    final capped = widget.fullBleed ? content : _capped(context, content);
    final body = widget.useSafeArea ? SafeArea(child: capped) : capped;
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
