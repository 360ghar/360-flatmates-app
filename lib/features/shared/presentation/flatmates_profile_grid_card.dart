import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/compatibility/compatibility_engine.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../l10n/gen/app_localizations.dart';
import 'flatmates_network_image.dart';
import 'flatmates_avatar.dart';
import 'flatmates_button.dart';

/// Profile card for the Likes grid: photo with a bottom scrim, a match ring
/// that draws on mount (complete at once under reduce motion) and a 48 dp
/// match button.
class FlatmatesProfileGridCard extends StatefulWidget {
  const FlatmatesProfileGridCard({
    required this.name,
    required this.location,
    required this.profession,
    required this.matchPercentage,
    required this.imageUrl,
    required this.onMatchTap,
    required this.matchButtonLabel,
    super.key,
    this.age,
    this.blurImage = false,
    this.onTap,
  });

  final String name;
  final int? age;
  final String location;
  final String profession;
  final double? matchPercentage;
  final String? imageUrl;
  final VoidCallback? onMatchTap;
  final String matchButtonLabel;
  final bool blurImage;

  /// Optional whole-card tap. When non-null the card body (everything except
  /// the match button) responds to taps with press-scale feedback. The match
  /// button manages its own [onMatchTap] independently.
  final VoidCallback? onTap;

  @override
  State<FlatmatesProfileGridCard> createState() =>
      _FlatmatesProfileGridCardState();
}

class _FlatmatesProfileGridCardState extends State<FlatmatesProfileGridCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ringController;
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: AppMotion.compatibilityRing,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Under reduce motion the ring is drawn complete at once.
    if (AppMotion.reduceMotion(context)) {
      _ringController.value = 1;
    } else if (_ringController.isDismissed) {
      _ringController.forward();
    }
  }

  void _press(bool down) {
    if (AppMotion.reduceMotion(context)) return;
    setState(() => _scale = down ? AppMotion.pressScale : 1.0);
  }

  @override
  void dispose() {
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final locale = AppLocalizations.of(context);
    final hasReliableMatch =
        widget.matchPercentage != null && widget.matchPercentage! > 0;
    final matchColor = hasReliableMatch
        ? compatibilityScoreColor(
            widget.matchPercentage!,
            brightness: Theme.of(context).brightness,
          )
        : AppSemanticColors.clayFor(brightness);

    final title = widget.age == null
        ? widget.name
        : '${widget.name}, ${widget.age}';
    final location = widget.location.trim();
    final profession = widget.profession.trim();

    // Photo-first card: meta sits on a bottom scrim like the match badge.
    final body = ClipRRect(
      borderRadius: AppRadius.cardBorder,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
            ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: widget.blurImage ? 7 : 0,
                sigmaY: widget.blurImage ? 7 : 0,
              ),
              // LayoutBuilder inside FlatmatesNetworkImage sizes the
              // Cloudinary delivery + mem cache to this expanded slot.
              child: FlatmatesNetworkImage(
                imageUrl: widget.imageUrl!,
                fit: BoxFit.cover,
              ),
            )
          else
            // No photo: a solid clay-soft sheet with the initials.
            ColoredBox(
              color: AppSemanticColors.coralSoftFor(brightness),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      initialsFromName(widget.name),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: AppSemanticColors.clayInkFor(brightness),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      locale.photoPendingLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppSemanticColors.clayInkFor(brightness),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Bottom scrim for legible name / location / profession.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppSemanticColors.scrim.withValues(alpha: 0),
                    AppSemanticColors.scrim.withValues(alpha: 0.55),
                    AppSemanticColors.scrim.withValues(alpha: 0.78),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.xl,
                  AppSpacing.sm,
                  AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppSemanticColors.onScrim,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (location.isNotEmpty) ...[
                      Text(
                        location,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppSemanticColors.onScrim.withValues(
                            alpha: 0.9,
                          ),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (profession.isNotEmpty) ...[
                      Text(
                        profession,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppSemanticColors.onScrim.withValues(
                            alpha: 0.9,
                          ),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (widget.matchPercentage != null)
            Positioned(
              top: AppSpacing.sm,
              right: AppSpacing.sm,
              child: AnimatedBuilder(
                animation: _ringController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _MatchRingPainter(
                      progress: _ringController.value,
                      color: matchColor,
                      strokeWidth: 3,
                    ),
                    child: child,
                  );
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppSemanticColors.surfaceFor(theme.brightness),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  padding: AppSpacing.edgeXs,
                  // Scales down at large text sizes instead of overflowing
                  // the fixed ring.
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      hasReliableMatch
                          ? '${widget.matchPercentage!.toInt()}%'
                          : locale.badgeNew,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: matchColor,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    // Make the body (image + name/location/profession) tappable when an
    // onTap is provided. The match button below is a separate hit target and
    // manages its own callback independently, so this never swallows it.
    final tappableBody = widget.onTap == null
        ? body
        : Listener(
            onPointerDown: (_) => _press(true),
            onPointerUp: (_) => _press(false),
            onPointerCancel: (_) => _press(false),
            child: AnimatedScale(
              scale: _scale,
              duration: AppMotion.fast,
              curve: AppMotion.paperOut,
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  key: const Key('flatmate_card_tap'),
                  borderRadius: AppRadius.cardBorder,
                  onTap: widget.onTap,
                  child: body,
                ),
              ),
            ),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: tappableBody),
        if (widget.matchButtonLabel.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          FlatmatesButton(
            label: widget.matchButtonLabel,
            onPressed: widget.onMatchTap,
            fullWidth: true,
          ),
        ],
      ],
    );
  }
}

/// Animated ring painter for the match percentage circle.
class _MatchRingPainter extends CustomPainter {
  _MatchRingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - (strokeWidth / 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_MatchRingPainter oldDelegate) =>
      progress != oldDelegate.progress;
}
