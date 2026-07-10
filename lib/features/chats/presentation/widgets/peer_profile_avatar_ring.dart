import 'dart:math' as math show pi;

import 'package:flutter/material.dart';

import '../../../shared/presentation/components.dart';

/// Avatar with an animated progress ring showing match percentage.
class PeerProfileAvatarRing extends StatelessWidget {
  const PeerProfileAvatarRing({
    required this.name,
    required this.imageUrl,
    this.matchPercentage,
    required this.matchColor,
    super.key,
  });

  static const double _avatarSize = 128;
  static const double _ringSize = _avatarSize + 8;

  final String name;
  final String? imageUrl;
  final double? matchPercentage;
  final Color matchColor;

  @override
  Widget build(BuildContext context) {
    if (matchPercentage == null) {
      return FlatmatesAvatar(name: name, imageUrl: imageUrl, size: _avatarSize);
    }

    final progress = (matchPercentage! / 100).clamp(0.0, 1.0);

    return SizedBox(
      width: _ringSize,
      height: _ringSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(_ringSize, _ringSize),
            painter: _AvatarRingPainter(
              progress: progress,
              color: matchColor,
              strokeWidth: 4,
              backgroundColor: matchColor.withValues(alpha: 0.15),
            ),
          ),
          FlatmatesAvatar(name: name, imageUrl: imageUrl, size: _avatarSize),
        ],
      ),
    );
  }
}

class _AvatarRingPainter extends CustomPainter {
  const _AvatarRingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    required this.backgroundColor,
  });

  final double progress;
  final Color color;
  final double strokeWidth;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _AvatarRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
