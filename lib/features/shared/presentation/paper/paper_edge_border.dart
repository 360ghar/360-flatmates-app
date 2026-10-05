import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'paper_art.dart';

/// Which kind of cut runs along the edge. See DESIGN.md §5.
enum PaperEdge { torn, scallop }

/// Which side of the shape carries the cut.
enum PaperEdgeSide { top, bottom, left }

/// A rectangle with one torn or scalloped edge; the other corners use
/// [radius].
///
/// The cut is drawn inside the rect, so content needs padding larger than
/// [depth] on the cut side ("clear the cut", DESIGN.md §5).
class PaperEdgeBorder extends ShapeBorder {
  const PaperEdgeBorder({
    this.edge = PaperEdge.torn,
    this.side = PaperEdgeSide.top,
    this.depth = 10,
    this.radius = 0,
  });

  final PaperEdge edge;
  final PaperEdgeSide side;

  /// How far the cut reaches into the shape, in logical pixels.
  final double depth;

  /// Radius of the corners away from the cut edge.
  final double radius;

  /// Width of one torn tile before it repeats.
  static const double tornTileWidth = 120;

  @override
  EdgeInsetsGeometry get dimensions => switch (side) {
    PaperEdgeSide.top => EdgeInsets.only(top: depth),
    PaperEdgeSide.bottom => EdgeInsets.only(bottom: depth),
    PaperEdgeSide.left => EdgeInsets.only(left: depth),
  };

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    // Build the shape as if the cut were on top, in a frame where "along"
    // runs the length of the cut edge, then rotate into place.
    final along = side == PaperEdgeSide.left ? rect.height : rect.width;
    final across = side == PaperEdgeSide.left ? rect.width : rect.height;
    final r = math.min(radius, math.min(along, across) / 2);

    final p = Path()..moveTo(0, across - r);
    _cutProfile(p, along);
    p
      ..lineTo(along, across - r)
      ..arcToPoint(Offset(along - r, across), radius: Radius.circular(r))
      ..lineTo(r, across)
      ..arcToPoint(Offset(0, across - r), radius: Radius.circular(r))
      ..close();

    final m = Matrix4.identity();
    switch (side) {
      case PaperEdgeSide.top:
        m.translateByDouble(rect.left, rect.top, 0, 1);
      case PaperEdgeSide.bottom:
        // Flip vertically: the cut ends up on the bottom edge.
        m
          ..translateByDouble(rect.left, rect.bottom, 0, 1)
          ..scaleByDouble(1, -1, 1, 1);
      case PaperEdgeSide.left:
        // Along = y, across = x; cut on the left edge.
        m
          ..translateByDouble(rect.left, rect.top, 0, 1)
          ..setEntry(0, 0, 0)
          ..setEntry(0, 1, 1)
          ..setEntry(1, 0, 1)
          ..setEntry(1, 1, 0);
    }
    return p.transform(m.storage);
  }

  /// Draws the cut from (0, y0) to (along, y1), with the cut reaching down
  /// to at most [depth] from the top.
  void _cutProfile(Path p, double along) {
    switch (edge) {
      case PaperEdge.torn:
        const tile = PaperArt.tornEdgeTile;
        final pointsPerTile = tile.length ~/ 2;
        var x0 = 0.0;
        var first = true;
        while (x0 < along) {
          for (var i = 0; i < pointsPerTile; i++) {
            final x = x0 + tile[i * 2] * tornTileWidth;
            final y = depth * (1 - tile[i * 2 + 1]);
            final clampedX = math.min(x, along);
            if (first) {
              p.lineTo(0, y);
              first = false;
            } else {
              p.lineTo(clampedX, y);
            }
            if (x >= along) return;
          }
          x0 += tornTileWidth;
        }
      case PaperEdge.scallop:
        // Semicircles bulging outward (towards y = 0), sitting on y = depth.
        final count = math.max(1, (along / (depth * 2)).round());
        final w = along / count;
        p.lineTo(0, depth);
        for (var i = 0; i < count; i++) {
          p.arcToPoint(
            Offset((i + 1) * w, depth),
            radius: Radius.elliptical(w / 2, depth),
          );
        }
    }
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => PaperEdgeBorder(
    edge: edge,
    side: side,
    depth: depth * t,
    radius: radius * t,
  );

  @override
  bool operator ==(Object other) =>
      other is PaperEdgeBorder &&
      other.edge == edge &&
      other.side == side &&
      other.depth == depth &&
      other.radius == radius;

  @override
  int get hashCode => Object.hash(edge, side, depth, radius);
}
