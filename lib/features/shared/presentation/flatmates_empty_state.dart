import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'flatmates_button.dart';
import 'paper/paper_scene.dart';

/// Illustrated empty state: a compact paper scene with a prop, a title, one
/// line of help and one action (DESIGN.md §8).
///
/// [prop] picks the scene prop; when null it is derived from [icon]. The
/// [compact] variant (inline sections) shows the bare icon instead of a
/// scene.
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
    this.prop,
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

  /// Scene prop. Null derives it from [icon].
  final PaperProp? prop;

  /// Maps the icons screens already pass to the matching scene prop.
  static PaperProp propForIcon(IconData? icon) {
    const chats = [
      Icons.chat_bubble_outline_rounded,
      Icons.chat_bubble_rounded,
      Icons.forum_outlined,
      Icons.forum_rounded,
    ];
    const hearts = [
      Icons.favorite_rounded,
      Icons.favorite_border_rounded,
      Icons.group_add_rounded,
      Icons.person_off_rounded,
    ];
    const searches = [Icons.search_off_rounded, Icons.search_rounded];
    const bells = [
      Icons.notifications_none_rounded,
      Icons.notifications_rounded,
    ];
    if (chats.contains(icon)) return PaperProp.chat;
    if (hearts.contains(icon)) return PaperProp.heart;
    if (searches.contains(icon)) return PaperProp.magnifier;
    if (bells.contains(icon)) return PaperProp.bell;
    return PaperProp.house;
  }

  @override
  State<FlatmatesEmptyState> createState() => _FlatmatesEmptyStateState();
}

class _FlatmatesEmptyStateState extends State<FlatmatesEmptyState>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<Offset>? _rise;
  bool _motionResolved = false;

  void _resolveMotion(BuildContext context) {
    if (_motionResolved) return;
    _motionResolved = true;
    if (AppMotion.reduceMotion(context)) return;

    // Rise only: the content is fully visible from the first frame.
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
    final icon = widget.icon;

    final column = Padding(
      padding: widget.padHorizontally
          ? AppSpacing.horizontalScreen
          : EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.compact) ...[
            if (icon != null) ...[
              Icon(
                icon,
                size: 32,
                color:
                    widget.iconColor ??
                    AppSemanticColors.clayFor(theme.brightness),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ] else ...[
            PaperScene.compact(
              prop: widget.prop ?? FlatmatesEmptyState.propForIcon(icon),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          Text(
            widget.title,
            style: widget.compact
                ? theme.textTheme.titleMedium
                : theme.textTheme.headlineSmall,
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
            FlatmatesButton(
              label: widget.ctaLabel!,
              onPressed: widget.onCtaTap,
              fullWidth: true,
            ),
          ],
        ],
      ),
    );

    final rise = _rise;
    final content = rise == null
        ? column
        : SlideTransition(position: rise, child: column);

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
