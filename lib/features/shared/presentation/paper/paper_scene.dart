import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/paper_theme.dart';
import 'paper_art.dart';

/// Foreground props for the compact scene. See DESIGN.md §6.
enum PaperProp { house, chat, heart, magnifier, bell, rainCloud }

/// The cut-paper neighbourhood: the signature artifact (DESIGN.md §6).
///
/// Each layer paints once into its own [RepaintBoundary]; parallax and the
/// entrance only translate layers, so scrolling costs no repaint. Layers
/// start fully visible and only rise into place.
class PaperScene extends StatelessWidget {
  /// Full scene: sun, clouds, hills, two towns, lit windows and the tree.
  const PaperScene.hero({super.key, this.parallax, this.height = 240})
    : prop = null,
      _compact = false;

  /// 320 x 200 scene with one prop, for empty, error and offline states.
  const PaperScene.compact({
    required PaperProp this.prop,
    super.key,
    this.height = 168,
  }) : parallax = null,
       _compact = true;

  /// Scroll position that drives parallax. Far layers move least.
  final ScrollController? parallax;
  final double height;
  final PaperProp? prop;
  final bool _compact;

  static Color propColor(PaperProp prop, Brightness b) => switch (prop) {
    PaperProp.house || PaperProp.heart => AppSemanticColors.clayFor(b),
    PaperProp.chat || PaperProp.magnifier => AppSemanticColors.pineFor(b),
    PaperProp.bell => AppSemanticColors.marigoldFor(b),
    PaperProp.rainCloud => AppSemanticColors.textTertiaryFor(b),
  };

  static PaperShape propShape(PaperProp prop) => switch (prop) {
    PaperProp.house => PaperArt.house,
    PaperProp.chat => PaperArt.chat,
    PaperProp.heart => PaperArt.heart,
    PaperProp.magnifier => PaperArt.magnifier,
    PaperProp.bell => PaperArt.bell,
    PaperProp.rainCloud => PaperArt.rainCloud,
  };

  @override
  Widget build(BuildContext context) {
    final t = PaperTheme.of(context);
    final brightness = Theme.of(context).brightness;
    final reduce = AppMotion.reduceMotion(context);

    // (shape, colour, parallax factor), back to front.
    final layers = _compact
        ? [
            (PaperArt.miniSun, t.sun, 0.0),
            (PaperArt.miniHillsFar, t.hillFar, 0.0),
            (PaperArt.miniHillsNear, t.hillNear, 0.0),
          ]
        : [
            (PaperArt.sun, t.sun, 0.5),
            (PaperArt.cloudA, t.cloud, 0.45),
            (PaperArt.cloudB, t.cloud, 0.4),
            (PaperArt.hillsFar, t.hillFar, 0.35),
            (PaperArt.townFar, t.townFar, 0.28),
            (PaperArt.hillsNear, t.hillNear, 0.2),
            (PaperArt.townWindows, t.window, 0.12),
            (PaperArt.townNear, t.town, 0.12),
            (PaperArt.tree, t.tree, 0.08),
          ];

    Widget landscape = Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < layers.length; i++)
          _Layer(
            index: i,
            reduceMotion: reduce,
            parallax: parallax,
            factor: layers[i].$3,
            child: CustomPaint(
              painter: _ShapePainter(
                shape: layers[i].$1,
                color: layers[i].$2,
                shadow: t.layerShadow,
              ),
            ),
          ),
      ],
    );
    if (_compact) {
      // Feather the sides and the bottom so the hills dissolve into the page
      // (no hard seam against whatever surface holds the scene).
      landscape = ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (rect) => const LinearGradient(
          colors: [
            Color(0x00000000),
            Color(0xFF000000),
            Color(0xFF000000),
            Color(0x00000000),
          ],
          stops: [0, 0.14, 0.86, 1],
        ).createShader(rect),
        child: ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (rect) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF000000), Color(0xFF000000), Color(0x00000000)],
            stops: [0, 0.72, 1],
          ).createShader(rect),
          child: landscape,
        ),
      );
    }

    final scene = ClipRect(
      child: SizedBox(
        height: height,
        width: _compact ? height * 1.6 : double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            landscape,
            // The prop sits above the feathered landscape, unfaded.
            if (prop case final prop?)
              _Layer(
                index: layers.length,
                reduceMotion: reduce,
                child: Align(
                  // Seated on the near hills, not floating in the sky.
                  alignment: const Alignment(0, 0.8),
                  child: FractionallySizedBox(
                    heightFactor: 0.6,
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: CustomPaint(
                        painter: _ShapePainter(
                          shape: propShape(prop),
                          color: propColor(prop, brightness),
                          shadow: t.layerShadow,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    return ExcludeSemantics(child: scene);
  }
}

class _Layer extends StatelessWidget {
  const _Layer({
    required this.index,
    required this.reduceMotion,
    required this.child,
    this.parallax,
    this.factor = 0,
  });

  final int index;
  final bool reduceMotion;
  final ScrollController? parallax;
  final double factor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    Widget layer = RepaintBoundary(child: child);

    final controller = parallax;
    if (controller != null && factor > 0 && !reduceMotion) {
      layer = AnimatedBuilder(
        animation: controller,
        child: layer,
        builder: (context, child) {
          final offset = controller.hasClients ? controller.offset : 0.0;
          // Content scrolls up; far layers drift down a little, so they
          // appear to move slower. Clamped so overscroll never tears a gap.
          final dy = math.max(0.0, offset) * factor;
          return Transform.translate(offset: Offset(0, dy), child: child);
        },
      );
    }

    if (reduceMotion) return layer;

    // Entrance: the layer starts visible, 12 px low, and rises into place.
    // Back layers settle first.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1, end: 0),
      duration: AppMotion.slow + AppMotion.layerStagger * index,
      curve: AppMotion.paperOut,
      child: layer,
      builder: (context, t, child) => Transform.translate(
        offset: Offset(0, AppMotion.layerRise * t),
        child: child,
      ),
    );
  }
}

class _ShapePainter extends CustomPainter {
  _ShapePainter({
    required this.shape,
    required this.color,
    required this.shadow,
    this.fit = BoxFit.cover,
  });

  final PaperShape shape;
  final Color color;
  final Color shadow;
  final BoxFit fit;

  static final Map<PaperShape, Path> _paths = {};

  @override
  void paint(Canvas canvas, Size size) {
    final src = shape.size;
    final scale = fit == BoxFit.cover
        ? math.max(size.width / src.width, size.height / src.height)
        : math.min(size.width / src.width, size.height / src.height);
    // Cover: bottom-right, so the ground meets the bottom edge and a narrow
    // phone still shows the sun and the tree (both sit on the right).
    final dx = fit == BoxFit.cover
        ? size.width - src.width * scale
        : (size.width - src.width * scale) / 2;
    final dy = fit == BoxFit.cover
        ? size.height - src.height * scale
        : (size.height - src.height * scale) / 2;
    final matrix = Matrix4.identity()
      ..translateByDouble(dx, dy, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);
    final path = (_paths[shape] ??= shape.path()).transform(matrix.storage);

    // One light source, top-left: a tight shadow down and to the right.
    canvas.drawPath(
      path.shift(const Offset(1, 2)),
      Paint()
        ..color = shadow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_ShapePainter old) =>
      old.shape != shape ||
      old.color != color ||
      old.shadow != shadow ||
      old.fit != fit;
}
