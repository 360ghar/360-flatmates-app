import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_semantic_colors.dart';

/// Circular heart save toggle (Airbnb property-card heart).
///
/// Default: white/outline on photo. Liked: Rausch filled heart.
class FlatmatesLikeButton extends StatefulWidget {
  const FlatmatesLikeButton({
    required this.liked,
    required this.onTap,
    super.key,
    this.size = 32,
    this.iconSize = 18,
    this.backgroundColor = Colors.white,
    this.unlikedColor = AppSemanticColors.ink,
    this.likedColor = AppSemanticColors.primary,
    this.radius = AppRadius.full,
    this.tooltip = 'Like',
  });

  final bool liked;
  final VoidCallback onTap;
  final double size;
  final double iconSize;
  final Color backgroundColor;
  final Color unlikedColor;
  final Color likedColor;
  final double radius;
  final String tooltip;

  @override
  State<FlatmatesLikeButton> createState() => _FlatmatesLikeButtonState();
}

class _FlatmatesLikeButtonState extends State<FlatmatesLikeButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.standard,
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1,
          end: 1.25,
        ).chain(CurveTween(curve: AppMotion.easeOutBack)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.25,
          end: 1,
        ).chain(CurveTween(curve: AppMotion.easeOutCubic)),
        weight: 50,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!AppMotion.reduceMotion(context)) {
      _controller.forward(from: 0);
    }
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final heartColor = widget.liked ? widget.likedColor : widget.unlikedColor;
    final shape = widget.radius >= AppRadius.full / 2
        ? const CircleBorder()
        : RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(widget.radius),
          );

    return Semantics(
      button: true,
      label: widget.tooltip,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: ScaleTransition(
          scale: _scale,
          child: Material(
            color: widget.backgroundColor == Colors.white
                ? Colors.white.withValues(alpha: 0.92)
                : widget.backgroundColor,
            shape: shape,
            child: InkWell(
              customBorder: shape,
              onTap: _handleTap,
              child: Tooltip(
                message: widget.tooltip,
                child: Center(
                  child: Icon(
                    widget.liked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: widget.iconSize,
                    color: heartColor,
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
