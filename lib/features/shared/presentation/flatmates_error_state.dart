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
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

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
    _slideUp = Tween(begin: const Offset(0, 0.05), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: AppMotion.easeOutCubic),
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
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);

    return Center(
      child: FadeTransition(
        opacity: _fadeIn,
        child: SlideTransition(
          position: _slideUp,
          child: Padding(
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
                    color: theme.brightness == Brightness.dark
                        ? AppSemanticColors.paper3
                        : AppSemanticColors.ink2,
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
          ),
        ),
      ),
    );
  }
}
