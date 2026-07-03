import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/compatibility/compatibility_engine.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../swipe_repository.dart';
import 'swipe_profile_card.dart';

/// Renders up to three stacked profile cards (third / next / current).
///
/// Each visible profile is rendered by a [_SwipeCardLayer] keyed with a stable
/// `ValueKey(profile.id)`. Because every layer shares the *same* widget
/// structure (only parameters differ by depth), when the deck advances Flutter
/// reconciles by key and **preserves the element** of the card that rises from
/// `next` → `current` — including its already-decoded hero image and carousel
/// state. This is what eliminates the stale-image / flicker that occurred when
/// the previous implementation repurposed a single recycled element across
/// different profiles every swipe.
///
/// The Maestro selector `Key('swipe_card')` is owned by this widget (passed in
/// from the page) rather than by the foreground gesture detector, so it never
/// appears/disappears on a promotion (which would force a remount).
class SwipeCardStack extends StatelessWidget {
  const SwipeCardStack({
    required this.item,
    required this.compatibility,
    required this.nextItem,
    required this.nextCompatibility,
    this.thirdItem,
    this.thirdCompatibility,
    required this.dragOffset,
    required this.dragProgress,
    required this.currentRotation,
    required this.isDragging,
    required this.onHorizontalDragStart,
    required this.onHorizontalDragUpdate,
    required this.onHorizontalDragEnd,
    super.key,
  });

  final SwipeProfile item;
  final CompatibilityResult compatibility;
  final SwipeProfile? nextItem;
  final CompatibilityResult? nextCompatibility;
  final SwipeProfile? thirdItem;
  final CompatibilityResult? thirdCompatibility;
  final Offset dragOffset;
  final double dragProgress;
  final double currentRotation;
  final bool isDragging;

  final void Function(DragStartDetails) onHorizontalDragStart;
  final void Function(DragUpdateDetails) onHorizontalDragUpdate;
  final void Function(DragEndDetails) onHorizontalDragEnd;

  @override
  Widget build(BuildContext context) {
    final progress = dragProgress;
    return Stack(
      children: <Widget>[
        if (thirdItem != null && thirdCompatibility != null)
          _SwipeCardLayer(
            key: ValueKey<int>(thirdItem!.id),
            profile: thirdItem!,
            compatibility: thirdCompatibility!,
            depth: 2,
            progress: progress,
          ),
        if (nextItem != null && nextCompatibility != null)
          _SwipeCardLayer(
            key: ValueKey<int>(nextItem!.id),
            profile: nextItem!,
            compatibility: nextCompatibility!,
            depth: 1,
            progress: progress,
          ),
        _SwipeCardLayer(
          key: ValueKey<int>(item.id),
          profile: item,
          compatibility: compatibility,
          depth: 0,
          dragOffset: dragOffset,
          progress: progress,
          rotation: currentRotation,
          isDragging: isDragging,
          onHorizontalDragStart: onHorizontalDragStart,
          onHorizontalDragUpdate: onHorizontalDragUpdate,
          onHorizontalDragEnd: onHorizontalDragEnd,
        ),
      ],
    );
  }
}

/// A single card in the swipe stack. The same widget structure is used for
/// every depth so elements reconcile cleanly across promotions.
///
/// Geometry (scale / opacity / insets) is depth-driven, and background cards
/// (depth >= 1) "rise" one step toward the front as [progress] grows — so by
/// the time the foreground card has flown off, the next card is already at the
/// foreground's resting geometry. The subsequent index advance is therefore
/// visually seamless: the rising card simply becomes interactive and gains the
/// drag transforms, with its element (and decoded image) preserved.
class _SwipeCardLayer extends StatelessWidget {
  const _SwipeCardLayer({
    super.key,
    required this.profile,
    required this.compatibility,
    required this.depth,
    required this.progress,
    this.dragOffset = Offset.zero,
    this.rotation = 0,
    this.isDragging = false,
    this.onHorizontalDragStart,
    this.onHorizontalDragUpdate,
    this.onHorizontalDragEnd,
  });

  final SwipeProfile profile;
  final CompatibilityResult compatibility;
  final int depth; // 0 = foreground, 1 = next, 2 = third
  final double progress;
  final Offset dragOffset;
  final double rotation;
  final bool isDragging;
  final void Function(DragStartDetails)? onHorizontalDragStart;
  final void Function(DragUpdateDetails)? onHorizontalDragUpdate;
  final void Function(DragEndDetails)? onHorizontalDragEnd;

  bool get isForeground => depth == 0;

  static double _scaleForDepth(int d) {
    switch (d) {
      case 0:
        return 1.0;
      case 1:
        return 0.94;
      default:
        return 0.88;
    }
  }

  static double _opacityForDepth(int d) {
    switch (d) {
      case 0:
        return 1.0;
      case 1:
        return 0.6;
      default:
        return 0.3;
    }
  }

  /// Resting insets for a card at [d]. The foreground sits flush; background
  /// cards are inset to suggest a stacked deck.
  static ({double top, double left, double right, double bottom})
  _insetsForDepth(int d) {
    switch (d) {
      case 0:
        return (top: 0.0, left: 0.0, right: 0.0, bottom: AppSpacing.xs);
      case 1:
        return (
          top: AppSpacing.xs + AppSpacing.xs / 2,
          left: AppSpacing.md,
          right: AppSpacing.md,
          bottom: 0.0,
        );
      default:
        return (
          top: AppSpacing.md,
          left: AppSpacing.screen,
          right: AppSpacing.screen,
          bottom: 0.0,
        );
    }
  }

  double _lerp(double a, double b) => a + (b - a) * progress;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final foreground = isForeground;

    // Depth-driven geometry. Background cards interpolate toward the next-step
    // geometry by `progress` so they arrive at the foreground's resting state
    // exactly as the foreground flies off.
    final double scale;
    final double opacity;
    final double top;
    final double left;
    final double right;
    final double bottom;
    if (foreground) {
      scale = _scaleForDepth(0);
      opacity = _opacityForDepth(0);
      final i = _insetsForDepth(0);
      top = i.top;
      left = i.left;
      right = i.right;
      bottom = i.bottom;
    } else {
      scale = _lerp(_scaleForDepth(depth), _scaleForDepth(depth - 1));
      opacity = _lerp(_opacityForDepth(depth), _opacityForDepth(depth - 1));
      final cur = _insetsForDepth(depth);
      final nxt = _insetsForDepth(depth - 1);
      top = _lerp(cur.top, nxt.top);
      left = _lerp(cur.left, nxt.left);
      right = _lerp(cur.right, nxt.right);
      bottom = _lerp(cur.bottom, nxt.bottom);
    }

    // Foreground-only drag derived values.
    final Offset translate = foreground ? dragOffset : Offset.zero;
    final double angle = foreground ? rotation : 0.0;

    // Shadow: the foreground "lifts" as it is dragged away; background cards
    // keep a subtle resting elevation.
    final double shadowAlpha = foreground ? 0.08 + 0.15 * progress : 0.06;
    final double shadowBlur = foreground ? 12 + 20 * progress : 10;
    final double shadowSpread = foreground ? 2 + 6 * progress : 1;
    final double shadowDy = foreground ? 4 + 8 * progress : 3;

    final card = RepaintBoundary(
      child: SwipeProfileCard(item: profile, compatibility: compatibility),
    );

    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: IgnorePointer(
        // Only the foreground card is interactive; background cards never
        // claim gestures.
        ignoring: !foreground,
        child: GestureDetector(
          // NOTE: no key here. Keying this gesture detector (per the old code)
          // would make it appear only on the foreground card, forcing a
          // remount of the whole subtree (and the decoded image) on every
          // promotion. The Maestro `swipe_card` selector lives on the
          // SwipeCardStack ancestor instead.
          onHorizontalDragStart: foreground ? onHorizontalDragStart : null,
          onHorizontalDragUpdate: foreground ? onHorizontalDragUpdate : null,
          onHorizontalDragEnd: foreground ? onHorizontalDragEnd : null,
          child: Transform.translate(
            offset: translate,
            child: Transform.rotate(
              angle: angle,
              child: Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Stack(
                    children: <Widget>[
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: AppRadius.cardBorder,
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: shadowAlpha,
                              ),
                              blurRadius: shadowBlur,
                              spreadRadius: shadowSpread,
                              offset: Offset(0, shadowDy),
                            ),
                          ],
                        ),
                        child: card,
                      ),
                      if (foreground && isDragging && dragOffset.dx != 0)
                        _DirectionalTint(
                          dragOffset: dragOffset,
                          dragProgress: progress,
                        ),
                      if (foreground && dragOffset.dx > 0)
                        _SwipeOverlay(
                          label: locale.swipeLikeLabel,
                          alignment: SwipeOverlayAlignment.like,
                          opacity: progress,
                        ),
                      if (foreground && dragOffset.dx < 0)
                        _SwipeOverlay(
                          label: locale.swipeNopeLabel,
                          alignment: SwipeOverlayAlignment.nope,
                          opacity: progress,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum SwipeOverlayAlignment { like, nope }

class _SwipeOverlay extends StatelessWidget {
  const _SwipeOverlay({
    required this.label,
    required this.alignment,
    required this.opacity,
  });

  final String label;
  final SwipeOverlayAlignment alignment;
  final double opacity;

  Color get _color {
    return alignment == SwipeOverlayAlignment.like
        ? AppSemanticColors.success
        : AppSemanticColors.compatLow;
  }

  IconData get _icon {
    return alignment == SwipeOverlayAlignment.like
        ? Icons.favorite_rounded
        : Icons.close_rounded;
  }

  double get _angle {
    return alignment == SwipeOverlayAlignment.like ? 0.15 : -0.15;
  }

  @override
  Widget build(BuildContext context) {
    final isLike = alignment == SwipeOverlayAlignment.like;
    return Positioned(
      top: 40,
      right: isLike ? 24 : null,
      left: isLike ? null : 24,
      child: Opacity(
        opacity: opacity,
        child: Transform.rotate(
          angle: _angle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.2),
              borderRadius: AppRadius.pillBorder,
              border: Border.all(
                color: _color.withValues(alpha: 0.6),
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(_icon, color: Colors.white, size: 20),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DirectionalTint extends StatelessWidget {
  const _DirectionalTint({
    required this.dragOffset,
    required this.dragProgress,
  });

  final Offset dragOffset;
  final double dragProgress;

  @override
  Widget build(BuildContext context) {
    final isLike = dragOffset.dx > 0;
    final color = isLike
        ? AppSemanticColors.success
        : AppSemanticColors.compatLow;
    final alpha = dragProgress * 0.15;
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.cardBorder,
            gradient: LinearGradient(
              begin: isLike ? Alignment.centerRight : Alignment.centerLeft,
              end: isLike ? Alignment.centerLeft : Alignment.centerRight,
              colors: <Color>[
                color.withValues(alpha: alpha),
                color.withValues(alpha: alpha * 0.2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

double calculateRotation(Offset dragOffset, double screenWidth) {
  if (dragOffset.dx == 0) return 0;
  final rotationFactor = (dragOffset.dx / screenWidth).clamp(-1.0, 1.0);
  const maxDegrees = 15.0;
  return rotationFactor * maxDegrees * math.pi / 180;
}

double calculateDragProgress(Offset dragOffset, double screenWidth) {
  return (dragOffset.dx.abs() / (screenWidth * 0.20)).clamp(0.0, 1.0);
}
