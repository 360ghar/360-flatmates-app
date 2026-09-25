import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/compatibility/compatibility_engine.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/gen/app_localizations.dart';
import 'flatmates_network_image.dart';
import 'flatmates_avatar.dart';

/// Profile grid card for Likes tab — matches screenshot #9 2-column grid pattern.
/// Includes animated compatibility ring on mount.
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
    _ringController.forward();
  }

  @override
  void dispose() {
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasReliableMatch =
        widget.matchPercentage != null && widget.matchPercentage! > 0;
    final matchColor = hasReliableMatch
        ? compatibilityScoreColor(widget.matchPercentage!)
        : AppSemanticColors.accent;

    final title = widget.age == null
        ? widget.name
        : '${widget.name}, ${widget.age}';
    final location = widget.location.trim();
    final profession = widget.profession.trim();

    // Photo-first card: meta sits on a bottom scrim like the match badge.
    final body = ClipRRect(
      borderRadius: BorderRadius.circular(16),
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
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppSemanticColors.accent.withValues(alpha: 0.18),
                    AppSemanticColors.secondarySurfaceFor(theme.brightness),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      initialsFromName(widget.name),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: AppSemanticColors.accent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      AppLocalizations.of(context).photoPendingLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppSemanticColors.textSecondaryFor(
                          theme.brightness,
                        ),
                        fontWeight: FontWeight.w700,
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
                        color: AppSemanticColors.onPrimary,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (location.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        location,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppSemanticColors.onPrimary.withValues(
                            alpha: 0.88,
                          ),
                          fontSize: 12,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (profession.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        profession,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppSemanticColors.onPrimary.withValues(
                            alpha: 0.78,
                          ),
                          fontSize: 12,
                          height: 1.2,
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
              top: 8,
              right: 8,
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
                  child: Text(
                    hasReliableMatch
                        ? '${widget.matchPercentage!.toInt()}%'
                        : 'New',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: matchColor,
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
            onPointerDown: (_) => setState(() => _scale = 0.97),
            onPointerUp: (_) => setState(() => _scale = 1.0),
            onPointerCancel: (_) => setState(() => _scale = 1.0),
            child: AnimatedScale(
              scale: _scale,
              duration: AppMotion.buttonPress,
              curve: Curves.easeOutCubic,
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  key: const Key('flatmate_card_tap'),
                  borderRadius: BorderRadius.circular(16),
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
          SizedBox(
            width: double.infinity,
            // No fixed height: the label's line box grows with the text scale
            // so Devanagari matras are never clipped. 34 stays the *minimum*
            // so the card keeps its proportions at 1.0x.
            child: FilledButton(
              onPressed: widget.onMatchTap,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
                minimumSize: const Size(0, 34),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                widget.matchButtonLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                // Size from the canonical button-sm token behind
                // textTheme.labelMedium; colour still inherits onPrimary from
                // the button's DefaultTextStyle.
                style: const TextStyle(
                  fontSize: AppTypography.buttonSmSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
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
