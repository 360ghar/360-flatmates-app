import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/gen/app_localizations.dart';
import 'flatmates_button.dart';
import 'paper/paper_scene.dart';

/// Error state: the rain-cloud paper scene, a human message (never raw error
/// text) and a Retry button (DESIGN.md §8).
///
/// Replaces `Text(error.toString())` patterns. [icon] is kept for API
/// compatibility; the scene replaces it.
class FlatmatesErrorState extends StatefulWidget {
  const FlatmatesErrorState({
    required this.message,
    super.key,
    this.onRetry,
    this.retryLabel,
    this.icon,
  });

  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;
  final IconData? icon;

  @override
  State<FlatmatesErrorState> createState() => _FlatmatesErrorStateState();
}

class _FlatmatesErrorStateState extends State<FlatmatesErrorState>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<Offset>? _rise;
  bool _motionResolved = false;

  void _resolveMotion(BuildContext context) {
    if (_motionResolved) return;
    _motionResolved = true;
    if (AppMotion.reduceMotion(context)) return;

    // Rise only: the message is fully visible from the first frame.
    final controller = AnimationController(
      vsync: this,
      duration: AppMotion.slow,
    );
    _controller = controller;
    _rise = Tween(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: controller, curve: AppMotion.paperOut));
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
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);

    final body = Padding(
      padding: AppSpacing.horizontalScreen,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PaperScene.compact(prop: PaperProp.rainCloud),
          const SizedBox(height: AppSpacing.lg),
          Text(
            widget.message,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppSemanticColors.textSecondaryFor(theme.brightness),
            ),
            textAlign: TextAlign.center,
          ),
          if (widget.onRetry != null) ...[
            const SizedBox(height: AppSpacing.xl),
            FlatmatesButton(
              label: widget.retryLabel ?? locale.commonRetry,
              onPressed: widget.onRetry,
              icon: Icons.refresh_rounded,
            ),
          ],
        ],
      ),
    );

    final rise = _rise;
    final content = rise == null
        ? body
        : SlideTransition(position: rise, child: body);

    // Scrolls when height is short (keyboard, small phone, large text).
    return Center(child: SingleChildScrollView(child: content));
  }
}
