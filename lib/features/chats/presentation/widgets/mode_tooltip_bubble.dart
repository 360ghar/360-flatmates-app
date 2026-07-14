import 'package:flutter/material.dart';

import '../../../../core/theme/app_semantic_colors.dart';
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
    const tailHeight = 8.0;

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: onTapKeepOpen,
        child: CustomPaint(
          painter: const _BubblePainter(
            color: AppSemanticColors.accent,
            tailHeight: tailHeight,
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 280),
            padding: const EdgeInsets.fromLTRB(14, tailHeight + 10, 14, 10),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppSemanticColors.onPrimary,
                fontSize: AppTypography.captionSmSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints a pink rounded-rectangle bubble with a small upward tail near the
/// left edge, plus a soft drop shadow for elevation above the chat content.
class _BubblePainter extends CustomPainter {
  const _BubblePainter({required this.color, required this.tailHeight});

  final Color color;
  final double tailHeight;

  @override
  void paint(Canvas canvas, Size size) {
    const radius = 12.0;
    const tailWidth = 14.0;
    const tailLeft = 22.0;
    final bodyTop = tailHeight;

    final path = Path();
    path.addRRect(
      RRect.fromLTRBAndCorners(
        0,
        bodyTop,
        size.width,
        size.height,
        topLeft: const Radius.circular(radius),
        topRight: const Radius.circular(radius),
        bottomLeft: const Radius.circular(radius),
        bottomRight: const Radius.circular(radius),
      ),
    );
    const tailCenterX = tailLeft + tailWidth / 2;
    path.moveTo(tailCenterX - tailWidth / 2, bodyTop);
    path.lineTo(tailCenterX + tailWidth / 2, bodyTop);
    path.lineTo(tailCenterX, 0);
    path.close();

    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.25), 6, false);
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _BubblePainter old) =>
      old.color != color || old.tailHeight != tailHeight;
}
