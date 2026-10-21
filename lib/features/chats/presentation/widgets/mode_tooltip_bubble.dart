import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Floating, speech-bubble tooltip that surfaces the peer's full mode/intent
/// text (e.g. "Looking for room + flatmate") anchored beneath the header
/// avatar. Rendered as an [OverlayEntry] so it never shifts the chat layout.
class ModeTooltipBubble extends StatelessWidget {
  const ModeTooltipBubble({
    required this.label,
    required this.onTapKeepOpen,
    super.key,
  });

  final String label;
  final VoidCallback onTapKeepOpen;

  @override
  Widget build(BuildContext context) {
    const tailHeight = AppSpacing.sm;
    final brightness = Theme.of(context).brightness;

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: onTapKeepOpen,
        child: CustomPaint(
          painter: _BubblePainter(
            color: AppSemanticColors.clayFor(brightness),
            shadows: AppShadows.e2(brightness),
            tailHeight: tailHeight,
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 280),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              tailHeight + AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppSemanticColors.onClayFor(brightness),
                fontSize: AppTypography.captionSmSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints a clay rounded-rectangle bubble with a small upward tail near the
/// left edge. It casts the directional e2 paper shadow (down and right).
class _BubblePainter extends CustomPainter {
  const _BubblePainter({
    required this.color,
    required this.shadows,
    required this.tailHeight,
  });

  final Color color;
  final List<BoxShadow> shadows;
  final double tailHeight;

  @override
  void paint(Canvas canvas, Size size) {
    for (final shadow in shadows) {
      // `BoxShadow.toPaint()` carries only the colour and the blur: the
      // framework applies `offset` and `spreadRadius` to the geometry
      // (`BoxDecoration._paintShadows`). Do the same, or the e2 token's
      // negative spread is dropped and the shadow paints larger than the
      // token geometry.
      canvas.drawPath(
        _outline(size, shadow.spreadRadius).shift(shadow.offset),
        shadow.toPaint(),
      );
    }
    canvas.drawPath(_outline(size, 0), Paint()..color = color);
  }

  /// The bubble outline, grown outward by [spread] the way `BoxDecoration`
  /// inflates a box before painting its shadow (the corner radius is kept,
  /// matching the framework).
  Path _outline(Size size, double spread) {
    const radius = AppRadius.md;
    const tailWidth = 14.0;
    const tailLeft = 22.0;
    final bodyTop = tailHeight - spread;

    final path = Path();
    path.addRRect(
      RRect.fromLTRBAndCorners(
        -spread,
        bodyTop,
        size.width + spread,
        size.height + spread,
        topLeft: const Radius.circular(radius),
        topRight: const Radius.circular(radius),
        bottomLeft: const Radius.circular(radius),
        bottomRight: const Radius.circular(radius),
      ),
    );
    // The tail grows with the body so the two stay joined.
    const tailCenterX = tailLeft + tailWidth / 2;
    path.moveTo(tailCenterX - tailWidth / 2 - spread, bodyTop);
    path.lineTo(tailCenterX + tailWidth / 2 + spread, bodyTop);
    path.lineTo(tailCenterX, -spread);
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _BubblePainter old) =>
      old.color != color ||
      old.tailHeight != tailHeight ||
      !listEquals(old.shadows, shadows);
}
