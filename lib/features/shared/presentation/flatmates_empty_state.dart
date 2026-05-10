import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Premium empty state: animated icon + title + subtitle + optional CTA.
///
/// Replaces `Center(Text(...))` empty patterns.
class FlatmatesEmptyState extends StatefulWidget {
  const FlatmatesEmptyState({
    required this.title,
    super.key,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.ctaLabel,
    this.onCtaTap,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final String? ctaLabel;
  final VoidCallback? onCtaTap;

  @override
  State<FlatmatesEmptyState> createState() => _FlatmatesEmptyStateState();
}

class _FlatmatesEmptyStateState extends State<FlatmatesEmptyState>
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
                if (widget.icon != null) ...[
                  _BreathingIcon(
                    icon: widget.icon!,
                    iconColor: widget.iconColor ?? AppSemanticColors.accent,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
                Text(
                  widget.title,
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    widget.subtitle!,
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
                if (widget.ctaLabel != null && widget.onCtaTap != null) ...[
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: widget.onCtaTap,
                      child: Text(widget.ctaLabel!),
                    ),
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

/// Subtle breathing (pulse) animation for empty-state icons.
class _BreathingIcon extends StatefulWidget {
  const _BreathingIcon({required this.icon, required this.iconColor});

  final IconData icon;
  final Color iconColor;

  @override
  State<_BreathingIcon> createState() => _BreathingIconState();
}

class _BreathingIconState extends State<_BreathingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.breathing,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + 0.05 * _controller.value,
          child: child,
        );
      },
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: widget.iconColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(widget.icon, size: 32, color: widget.iconColor),
      ),
    );
  }
}
