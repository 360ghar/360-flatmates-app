import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../l10n/gen/app_localizations.dart';

/// Heart save toggle on listing photos.
///
/// Default: outline heart on a paper disc. Liked: filled clay heart. The
/// visible disc is [size]; the tap target is at least 48 dp around it.
class FlatmatesLikeButton extends StatefulWidget {
  const FlatmatesLikeButton({
    required this.liked,
    required this.onTap,
    super.key,
    this.size = 32,
    this.iconSize = 18,
    this.backgroundColor,
    this.unlikedColor,
    this.likedColor,
    this.tooltip,
  });

  final bool liked;
  final VoidCallback onTap;

  /// Diameter of the visible disc.
  final double size;
  final double iconSize;

  /// Defaults: paper-3 disc, ink heart, clay when liked (per brightness).
  final Color? backgroundColor;
  final Color? unlikedColor;
  final Color? likedColor;

  /// Defaults to the localized like / unlike label.
  final String? tooltip;

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
        ).chain(CurveTween(curve: AppMotion.paperSettle)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.25,
          end: 1,
        ).chain(CurveTween(curve: AppMotion.paperOut)),
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
    final brightness = Theme.of(context).brightness;
    final locale = AppLocalizations.of(context);
    final tooltip =
        widget.tooltip ??
        (widget.liked
            ? locale.unlikeListingTooltip
            : locale.likeListingTooltip);
    final heartColor = widget.liked
        ? widget.likedColor ?? AppSemanticColors.clayFor(brightness)
        : widget.unlikedColor ?? AppSemanticColors.textPrimaryFor(brightness);
    final disc =
        widget.backgroundColor ??
        AppSemanticColors.paper3For(brightness).withValues(alpha: 0.92);
    final target = widget.size < kMinInteractiveDimension
        ? kMinInteractiveDimension
        : widget.size;

    return Semantics(
      button: true,
      toggled: widget.liked,
      label: tooltip,
      excludeSemantics: true,
      child: Tooltip(
        message: tooltip,
        child: InkResponse(
          onTap: _handleTap,
          radius: target / 2,
          child: SizedBox.square(
            dimension: target,
            child: Center(
              child: ScaleTransition(
                scale: _scale,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: disc,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox.square(
                    dimension: widget.size,
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
      ),
    );
  }
}
