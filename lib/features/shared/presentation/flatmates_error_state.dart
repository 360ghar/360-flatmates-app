import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/gen/app_localizations.dart';

/// Friendly error state with animated entry and retry CTA.
///
/// Replaces `Text(error.toString())` patterns.
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
  Animation<double>? _fadeIn;
  Animation<Offset>? _slideUp;
  bool _reduceMotion = false;
  bool _motionResolved = false;

  void _resolveMotion(BuildContext context) {
    if (_motionResolved) return;
    _motionResolved = true;
    _reduceMotion = AppMotion.reduceMotion(context);
    if (_reduceMotion) return;

    final controller = AnimationController(
      vsync: this,
      duration: AppMotion.fadeInEntry,
    );
    _controller = controller;
    _fadeIn = CurvedAnimation(
      parent: controller,
      curve: AppMotion.easeOutCubic,
    );
    _slideUp = Tween(begin: const Offset(0, 0.05), end: Offset.zero).animate(
      CurvedAnimation(parent: controller, curve: AppMotion.easeOutCubic),
    );
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
          Icon(
            widget.icon ?? Icons.cloud_off_rounded,
            size: 48,
            color: AppSemanticColors.error,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            widget.message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppSemanticColors.textSecondaryFor(theme.brightness),
            ),
            textAlign: TextAlign.center,
          ),
          if (widget.onRetry != null) ...[
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: widget.onRetry,
              child: Text(widget.retryLabel ?? locale.commonRetry),
            ),
          ],
        ],
      ),
    );

    final content = _reduceMotion || _fadeIn == null || _slideUp == null
        ? body
        : FadeTransition(
            opacity: _fadeIn!,
            child: SlideTransition(position: _slideUp!, child: body),
          );

    return Center(child: content);
  }
}
