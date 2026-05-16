import 'dart:math' as math show pi;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../compatibility/compatibility_engine.dart';
import '../theme/app_semantic_colors.dart';

class CompatibilityRing extends ConsumerStatefulWidget {
  const CompatibilityRing({
    required this.percentage,
    this.size = 72,
    this.strokeWidth = 5,
    super.key,
  });

  final double percentage;
  final double size;
  final double strokeWidth;

  @override
  ConsumerState<CompatibilityRing> createState() => _CompatibilityRingState();
}

class _CompatibilityRingState extends ConsumerState<CompatibilityRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant CompatibilityRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.percentage != widget.percentage) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _hasReliableScore => widget.percentage > 0;

  Color _color() {
    if (!_hasReliableScore) return AppSemanticColors.accent;
    return compatibilityScoreColor(widget.percentage);
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    final theme = Theme.of(context);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, _) {
              final animatedValue = _hasReliableScore
                  ? (widget.percentage / 100) * _animation.value
                  : 0.0;
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _ArcPainter(
                  progress: animatedValue.clamp(0.0, 1.0),
                  color: color,
                  strokeWidth: widget.strokeWidth,
                  backgroundColor: color.withValues(alpha: 0.15),
                ),
              );
            },
          ),
          Text(
            _hasReliableScore ? '${widget.percentage.round()}%' : 'New',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
              fontSize: _hasReliableScore
                  ? widget.size * 0.22
                  : widget.size * 0.20,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter that draws an animated arc (circular progress).
class _ArcPainter extends CustomPainter {
  _ArcPainter({
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

    // Background track
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    // Foreground arc
    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2; // 12 o'clock
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
  bool shouldRepaint(covariant _ArcPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class CompatibilityBreakdown extends StatelessWidget {
  const CompatibilityBreakdown({required this.result, super.key});

  final CompatibilityResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: result.dimensions.map((dim) {
        final icon = dim.isMatch
            ? Icons.check_circle_rounded
            : Icons.warning_amber_rounded;
        final color = dim.isMatch
            ? compatibilityScoreColor(100)
            : compatibilityScoreColor(40);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dim.summary,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${dim.score.round()}%',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
