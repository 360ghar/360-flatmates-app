import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/compatibility/compatibility_engine.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../swipe_repository.dart';
import 'swipe_profile_card.dart';

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
    required this.cardScaleAnimation,
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
  final Animation<double> cardScaleAnimation;
  final bool isDragging;

  final void Function(DragStartDetails) onHorizontalDragStart;
  final void Function(DragUpdateDetails) onHorizontalDragUpdate;
  final void Function(DragEndDetails) onHorizontalDragEnd;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final progress = dragProgress;

    // Card 3: deepest background card (only if a third profile exists)
    final Widget thirdCard =
        thirdItem != null && thirdCompatibility != null
            ? Positioned(
                top: AppSpacing.md,
                left: AppSpacing.screen,
                right: AppSpacing.screen,
                bottom: 0,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.3 + 0.2 * progress,
                    child: Transform.scale(
                      scale: 0.88 + 0.06 * progress,
                      child: SwipeProfileCard(
                        item: thirdItem!,
                        compatibility: thirdCompatibility!,
                      ),
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink();

    // Card 2: middle background card (next card)
    final Widget nextCard =
        nextItem != null && nextCompatibility != null
            ? Positioned(
                top: AppSpacing.xs + AppSpacing.xs / 2,
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: 0,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.6 + 0.4 * progress,
                    child: Transform.scale(
                      scale: 0.94 + 0.06 * progress,
                      child: SwipeProfileCard(
                        item: nextItem!,
                        compatibility: nextCompatibility!,
                      ),
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink();

    // Card 1: foreground card (active, draggable)
    final Widget currentCard = Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: AppSpacing.xs,
      child: GestureDetector(
        key: const Key('swipe_card'),
        onHorizontalDragStart: onHorizontalDragStart,
        onHorizontalDragUpdate: onHorizontalDragUpdate,
        onHorizontalDragEnd: onHorizontalDragEnd,
        child: AnimatedBuilder(
          animation: cardScaleAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: dragOffset,
              child: Transform.rotate(
                angle: currentRotation,
                child: Transform.scale(
                  scale: cardScaleAnimation.value,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: AppRadius.cardBorder,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: 0.08 + 0.15 * progress,
                              ),
                              blurRadius: 12 + 20 * progress,
                              spreadRadius: 2 + 6 * progress,
                              offset: Offset(0, 4 + 8 * progress),
                            ),
                          ],
                        ),
                        child: child,
                      ),
                      if (isDragging && dragOffset.dx != 0)
                        _DirectionalTint(
                          dragOffset: dragOffset,
                          dragProgress: dragProgress,
                        ),
                      if (dragOffset.dx > 0)
                        _SwipeOverlay(
                          label: locale.swipeLikeLabel,
                          alignment: SwipeOverlayAlignment.like,
                          opacity: dragProgress,
                        ),
                      if (dragOffset.dx < 0)
                        _SwipeOverlay(
                          label: locale.swipeNopeLabel,
                          alignment: SwipeOverlayAlignment.nope,
                          opacity: dragProgress,
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
          child: SwipeProfileCard(item: item, compatibility: compatibility),
        ),
      ),
    );

    return Stack(
      children: [thirdCard, nextCard, currentCard],
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
              children: [
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
              colors: [
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
