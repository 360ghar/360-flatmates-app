import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/compatibility/compatibility_engine.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../swipe_repository.dart';
import 'swipe_profile_card.dart';

/// Renders the swipe deck: one interactive card plus up to two preloaded layers.
///
/// **At rest only the foreground card is visible.** Next/third profiles stay
/// mounted (opacity 0) so Flutter can promote them by stable
/// `ValueKey(profile.id)` without remounting — preserving decoded hero images
/// and carousel state for a flicker-free advance.
///
/// During drag / fly-off, the next card fades in under the leaving foreground
/// so the stack never blanks mid-swipe. The third layer stays invisible and is
/// only for preload continuity.
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
    this.actionBar,
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

  /// Skip / Undo / Like controls, shown only on the foreground card as
  /// trailing scroll content (below the fold).
  final Widget? actionBar;

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
          trailing: actionBar,
        ),
      ],
    );
  }
}

/// A single card in the swipe stack. The same widget structure is used for
/// every depth so elements reconcile cleanly across promotions.
///
/// Background cards park at the foreground's resting geometry (full size) with
/// opacity 0 so promotion has zero layout jump. Depth-1 fades in with
/// [progress] under a dragging / flying foreground; depth-2 stays preloaded
/// but invisible.
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
    this.trailing,
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

  /// Foreground-only trailing scroll content (e.g. action bar).
  final Widget? trailing;

  bool get isForeground => depth == 0;

  /// Foreground resting insets — also used for preloaded layers so promotion
  /// does not animate scale/inset jumps.
  static ({double top, double left, double right, double bottom})
  get _foregroundInsets =>
      (top: 0.0, left: 0.0, right: 0.0, bottom: AppSpacing.xs);

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final foreground = isForeground;

    // Single visual card at rest; preloaded layers share full-size geometry.
    const scale = 1.0;
    final opacity = swipeLayerOpacity(depth: depth, progress: progress);
    final insets = _foregroundInsets;
    final top = insets.top;
    final left = insets.left;
    final right = insets.right;
    final bottom = insets.bottom;

    // Foreground-only drag derived values.
    final Offset translate = foreground ? dragOffset : Offset.zero;
    final double angle = foreground ? rotation : 0.0;

    // Shadow: the foreground "lifts" as it is dragged away; preloaded cards
    // keep a light elevation so they look ready when they fade in.
    final double shadowAlpha = foreground ? 0.08 + 0.15 * progress : 0.06;
    final double shadowBlur = foreground ? 12 + 20 * progress : 10;
    final double shadowSpread = foreground ? 2 + 6 * progress : 1;
    final double shadowDy = foreground ? 4 + 8 * progress : 3;

    final card = RepaintBoundary(
      child: SwipeProfileCard(
        item: profile,
        compatibility: compatibility,
        trailing: trailing,
      ),
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

/// Layer visibility for the single-card-at-rest deck.
///
/// - depth 0 (foreground): always fully visible
/// - depth 1 (next): hidden at rest; fades in with [progress] during swipe
/// - depth ≥ 2 (preload only): always hidden
double swipeLayerOpacity({required int depth, required double progress}) {
  if (depth <= 0) return 1.0;
  if (depth == 1) return progress.clamp(0.0, 1.0);
  return 0.0;
}
