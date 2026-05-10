import 'package:flutter/material.dart';

/// Dashed border container for premium "add photo" tile.
class DashedBorderContainer extends StatelessWidget {
  const DashedBorderContainer({
    required this.child,
    super.key,
    this.color = Colors.grey,
    this.borderRadius = 16,
    this.dashLength = 6,
    this.gapLength = 4,
    this.strokeWidth = 1.5,
  });

  final Widget child;
  final Color color;
  final double borderRadius;
  final double dashLength;
  final double gapLength;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: color,
        borderRadius: borderRadius,
        dashLength: dashLength,
        gapLength: gapLength,
        strokeWidth: strokeWidth,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: child,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({
    required this.color,
    required this.borderRadius,
    required this.dashLength,
    required this.gapLength,
    required this.strokeWidth,
  });

  final Color color;
  final double borderRadius;
  final double dashLength;
  final double gapLength;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + dashLength).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = distance + dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      color != oldDelegate.color ||
      borderRadius != oldDelegate.borderRadius ||
      dashLength != oldDelegate.dashLength ||
      gapLength != oldDelegate.gapLength ||
      strokeWidth != oldDelegate.strokeWidth;
}
