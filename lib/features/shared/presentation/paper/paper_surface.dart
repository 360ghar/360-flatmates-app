import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/paper_theme.dart';
import 'paper_edge_border.dart';

/// Paper layers from DESIGN.md §1: 1 = sections, 2 = cards, 3 = popovers.
enum PaperLayer { one, two, three }

/// Elevation levels from DESIGN.md §4.
enum PaperElevation { e0, e1, e2, e3 }

/// A sheet of paper: layer colour, directional shadow, fine grain behind the
/// content, and an optional torn or scalloped edge.
class PaperSurface extends StatelessWidget {
  const PaperSurface({
    required this.child,
    super.key,
    this.layer = PaperLayer.two,
    this.elevation = PaperElevation.e2,
    this.borderRadius = AppRadius.cardBorder,
    this.edge,
    this.edgeSide = PaperEdgeSide.top,
    this.edgeDepth = 10,
    this.padding,
    this.color,
    this.grain = true,
  });

  final Widget child;
  final PaperLayer layer;
  final PaperElevation elevation;

  /// Corner shape when [edge] is null.
  final BorderRadius borderRadius;

  /// Optional cut along [edgeSide]. Padding on that side is increased by
  /// [edgeDepth] automatically so content clears the cut.
  final PaperEdge? edge;
  final PaperEdgeSide edgeSide;
  final double edgeDepth;
  final EdgeInsetsGeometry? padding;

  /// Overrides the layer colour (for example a soft status fill).
  final Color? color;
  final bool grain;

  static const _grain = AssetImage('assets/paper/grain.png');

  static Color layerColor(PaperLayer layer, Brightness b) => switch (layer) {
    PaperLayer.one => AppSemanticColors.paper1For(b),
    PaperLayer.two => AppSemanticColors.paper2For(b),
    PaperLayer.three => AppSemanticColors.paper3For(b),
  };

  static List<BoxShadow> shadowsFor(PaperElevation e, Brightness b) =>
      switch (e) {
        PaperElevation.e0 => AppShadows.none,
        PaperElevation.e1 => AppShadows.e1(b),
        PaperElevation.e2 => AppShadows.e2(b),
        PaperElevation.e3 => AppShadows.e3(b),
      };

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final paper = PaperTheme.of(context);
    final cut = edge;
    final ShapeBorder shape = cut == null
        ? RoundedRectangleBorder(borderRadius: borderRadius)
        : PaperEdgeBorder(
            edge: cut,
            side: edgeSide,
            depth: edgeDepth,
            radius: borderRadius.topLeft.x,
          );

    var inner = padding ?? EdgeInsets.zero;
    if (cut != null) {
      inner = inner.add(switch (edgeSide) {
        PaperEdgeSide.top => EdgeInsets.only(top: edgeDepth),
        PaperEdgeSide.bottom => EdgeInsets.only(bottom: edgeDepth),
        PaperEdgeSide.left => EdgeInsets.only(left: edgeDepth),
      });
    }

    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: shape,
        color: color ?? layerColor(layer, brightness),
        shadows: shadowsFor(elevation, brightness),
        image: grain
            ? DecorationImage(
                image: _grain,
                repeat: ImageRepeat.repeat,
                opacity: paper.grainOpacity,
                scale: 2,
              )
            : null,
      ),
      child: Padding(padding: inner, child: child),
    );
  }
}
