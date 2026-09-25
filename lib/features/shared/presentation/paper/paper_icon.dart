import 'package:flutter/widgets.dart';

import 'paper_art.dart';

/// A cut-paper icon: one [PaperShape] (24 x 24 art) filled with a single
/// colour. Size and colour come from the ambient [IconTheme] unless given,
/// so it drops into a `NavigationBar` or next to text like an [Icon].
class PaperIcon extends StatelessWidget {
  const PaperIcon(this.shape, {super.key, this.size, this.color});

  final PaperShape shape;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final side = size ?? theme.size ?? 24;
    return SizedBox.square(
      dimension: side,
      child: CustomPaint(
        painter: _PaperIconPainter(
          shape,
          color ?? theme.color ?? const Color.fromARGB(255, 0, 0, 0),
        ),
      ),
    );
  }
}

class _PaperIconPainter extends CustomPainter {
  _PaperIconPainter(this.shape, this.color);

  final PaperShape shape;
  final Color color;

  static final Map<PaperShape, Path> _paths = {};

  @override
  void paint(Canvas canvas, Size size) {
    final path = _paths[shape] ??= shape.path();
    canvas
      ..save()
      ..scale(size.width / shape.size.width, size.height / shape.size.height)
      ..drawPath(path, Paint()..color = color)
      ..restore();
  }

  @override
  bool shouldRepaint(_PaperIconPainter old) =>
      old.shape != shape || old.color != color;
}
