import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';

/// Unified page scaffold with safe area, background, optional bottom bar.
/// Includes a subtle fade-in animation on mount for silky page entry.
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

  @override
  State<FlatmatesScreen> createState() => _FlatmatesScreenState();
}

class _FlatmatesScreenState extends State<FlatmatesScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.fadeInEntry,
    );
    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectivePadding = widget.padding ?? AppSpacing.horizontalScreen;
    final content = widget.scrollable
        ? LayoutBuilder(
            builder: (context, constraints) {
              final verticalPadding = effectivePadding.vertical;
              return SingleChildScrollView(
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

    return Scaffold(
      appBar: widget.appBar,
      backgroundColor: widget.backgroundColor,
      bottomNavigationBar: widget.bottomNavigationBar,
      bottomSheet: widget.bottomSheet,
      floatingActionButton: widget.floatingActionButton,
      body: FadeTransition(
        opacity: _fadeIn,
        child: widget.useSafeArea ? SafeArea(child: content) : content,
      ),
    );
  }
}
