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
    this.expand = false,
    this.minHeight,
    this.padHorizontally = true,
    this.compact = false,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final String? ctaLabel;
  final VoidCallback? onCtaTap;

  /// When true, expands to fill parent and centers content (list hubs).
  final bool expand;

  /// Minimum height when nested inside a scroll view (e.g. empty inbox tabs).
  final double? minHeight;

  /// Set false when the parent already applies horizontal screen padding.
  final bool padHorizontally;

  /// Smaller icon + tighter vertical rhythm for inline section empties (Home).
  final bool compact;

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

    final content = FadeTransition(
      opacity: _fadeIn,
      child: SlideTransition(
        position: _slideUp,
        child: Padding(
          padding: widget.padHorizontally
              ? AppSpacing.horizontalScreen
              : EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                _BreathingIcon(
                  icon: widget.icon!,
                  iconColor: widget.iconColor ?? AppSemanticColors.primary,
                  size: widget.compact ? 48 : 64,
                  iconSize: widget.compact ? 24 : 32,
                ),
                SizedBox(
                  height: widget.compact ? AppSpacing.md : AppSpacing.xl,
                ),
              ],
              Text(
                widget.title,
                style: widget.compact
                    ? theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      )
                    : theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              if (widget.subtitle != null) ...[
                SizedBox(
                  height: widget.compact ? AppSpacing.xs : AppSpacing.sm,
                ),
                Text(
                  widget.subtitle!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppSemanticColors.textSecondaryFor(theme.brightness),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (widget.ctaLabel != null && widget.onCtaTap != null) ...[
                SizedBox(
                  height: widget.compact ? AppSpacing.base : AppSpacing.xl,
                ),
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
    );

    if (widget.expand) {
      return SizedBox.expand(child: Center(child: content));
    }
    if (widget.minHeight != null) {
      return ConstrainedBox(
        constraints: BoxConstraints(minHeight: widget.minHeight!),
        child: Center(child: content),
      );
    }
    return Center(child: content);
  }
}

/// Subtle breathing (pulse) animation for empty-state icons.
class _BreathingIcon extends StatefulWidget {
  const _BreathingIcon({
    required this.icon,
    required this.iconColor,
    this.size = 64,
    this.iconSize = 32,
  });

  final IconData icon;
  final Color iconColor;
  final double size;
  final double iconSize;

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
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.iconColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          widget.icon,
          size: widget.iconSize,
          color: widget.iconColor,
        ),
      ),
    );
  }
}
