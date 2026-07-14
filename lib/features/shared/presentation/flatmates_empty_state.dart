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

    final column = Padding(
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
              reduceMotion: _reduceMotion,
            ),
            SizedBox(height: widget.compact ? AppSpacing.md : AppSpacing.xl),
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
            SizedBox(height: widget.compact ? AppSpacing.xs : AppSpacing.sm),
            Text(
              widget.subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppSemanticColors.textSecondaryFor(theme.brightness),
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (widget.ctaLabel != null && widget.onCtaTap != null) ...[
            SizedBox(height: widget.compact ? AppSpacing.base : AppSpacing.xl),
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
    );

    final content = _reduceMotion || _fadeIn == null || _slideUp == null
        ? column
        : FadeTransition(
            opacity: _fadeIn!,
            child: SlideTransition(position: _slideUp!, child: column),
          );

    if (widget.expand) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final effectiveMinHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : null;
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: effectiveMinHeight != null
                  ? BoxConstraints(minHeight: effectiveMinHeight)
                  : const BoxConstraints(),
              child: Center(child: content),
            ),
          );
        },
      );
    }
    if (widget.minHeight != null) {
      return SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: widget.minHeight!),
          child: Center(child: content),
        ),
      );
    }
    // When the parent has bounded height, center content and scroll if the
    // available height is reduced (keyboard open, emoji picker). When the
    // parent is unbounded (SliverList, etc.) just size to content so we
    // never impose an infinite minHeight constraint.
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.maxHeight.isFinite) {
          return Center(child: content);
        }
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: content),
          ),
        );
      },
    );
  }
}

/// Subtle breathing (pulse) animation for empty-state icons.
class _BreathingIcon extends StatefulWidget {
  const _BreathingIcon({
    required this.icon,
    required this.iconColor,
    required this.reduceMotion,
    this.size = 64,
    this.iconSize = 32,
  });

  final IconData icon;
  final Color iconColor;
  final double size;
  final double iconSize;
  final bool reduceMotion;

  @override
  State<_BreathingIcon> createState() => _BreathingIconState();
}

class _BreathingIconState extends State<_BreathingIcon>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    if (!widget.reduceMotion) {
      _controller = AnimationController(
        vsync: this,
        duration: AppMotion.breathing,
      )..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icon = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: widget.iconColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(widget.icon, size: widget.iconSize, color: widget.iconColor),
    );

    final controller = _controller;
    if (widget.reduceMotion || controller == null) return icon;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + 0.05 * controller.value,
          child: child,
        );
      },
      child: icon,
    );
  }
}
