import 'dart:math' as math;

import 'package:flatmates_app/core/theme/app_theme.dart';
import 'package:flatmates_app/features/shared/presentation/paper/paper_art.dart';
import 'package:flatmates_app/features/shared/presentation/paper/paper_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/foldable_surfaces.dart';

/// The hero canvas every layer is authored on: 1200 x 360, 3.33:1 — wider than
/// any phone and wider than the open Duo.
const _canvas = Size(1200, 360);

/// The pre-Duo cover fit, kept verbatim here so the phone poses can be asserted
/// against the code that shipped before the top-edge clamp existed.
({double scale, Offset offset}) _coverBeforeTheClamp(Size canvas, Size box) {
  final scale = math.max(box.width / canvas.width, box.height / canvas.height);
  return (
    scale: scale,
    offset: Offset(
      box.width - canvas.width * scale,
      box.height - canvas.height * scale,
    ),
  );
}

/// Where a canvas-space rect lands inside [box], in box coordinates.
Rect _rendered(Rect canvasRect, Size box) {
  final fit = PaperSceneFit.transform(_canvas, box, BoxFit.cover);
  return Rect.fromLTRB(
    canvasRect.left * fit.scale + fit.offset.dx,
    canvasRect.top * fit.scale + fit.offset.dy,
    canvasRect.right * fit.scale + fit.offset.dx,
    canvasRect.bottom * fit.scale + fit.offset.dy,
  );
}

/// Every (viewport width, scene height) pair the app actually renders.
///
/// Widths: the four Duo poses (466 / 669 / 678 / 951) plus 720, the reading
/// column `FlatmatesScreen` caps a page body to, plus 855, the open Duo's page
/// width once the shell's 96 dp rail is subtracted.
///
/// Heights: the `PaperSceneHeader` default (200), the onboarding splash strip
/// (220), the hero default (240), and the splash page's
/// `(height * 0.36).clamp(180, 340)` — 244 on folded portrait, 241 on open
/// landscape, 340 on open portrait, 180 on folded landscape.
const _boxes = <Size>[
  Size(466, 200),
  Size(466, 220),
  Size(466, 240),
  Size(466, 244),
  Size(669, 200),
  Size(669, 220),
  Size(669, 240),
  Size(669, 340),
  Size(678, 180),
  Size(678, 200),
  Size(678, 220),
  Size(678, 240),
  Size(720, 200),
  Size(720, 240),
  Size(855, 200),
  Size(855, 220),
  Size(855, 240),
  Size(951, 200),
  Size(951, 220),
  Size(951, 240),
  Size(951, 241),
];

void main() {
  final sun = PaperArt.sun.path().getBounds();
  final cloudB = PaperArt.cloudB.path().getBounds();

  group('hero cover fit', () {
    // scale / dx / dy computed by hand from `max(w/W, h/H)` with a bottom-right
    // anchor, for the boxes where the top-edge clamp does not bite. These are
    // the numbers the scene actually paints with.
    const cases = <(Size, double, double, double)>[
      (Size(466, 200), 0.5555555555555556, -200.66666666666669, 0),
      (Size(466, 220), 0.6111111111111112, -267.3333333333335, 0),
      (Size(466, 240), 0.6666666666666666, -334, 0),
      (Size(669, 200), 0.5575, 0, -0.7000000000000171),
      (Size(669, 220), 0.6111111111111112, -64.33333333333348, 0),
      (Size(669, 240), 0.6666666666666666, -131, 0),
      (Size(678, 200), 0.565, 0, -3.400000000000034),
      (Size(678, 220), 0.6111111111111112, -55.333333333333485, 0),
      (Size(678, 240), 0.6666666666666666, -122, 0),
      (Size(855, 240), 0.7125, 0, -16.5),
      (Size(951, 200), 0.7925, 0, -31.2245),
    ];

    for (final (box, scale, dx, dy) in cases) {
      test('${box.width.toInt()} x ${box.height.toInt()} fits $scale', () {
        final fit = PaperSceneFit.transform(_canvas, box, BoxFit.cover);
        // 1e-4 dp: the clamp bound comes from `Path.getBounds()`, which is
        // exact to float32 (~1e-6 dp here).
        expect(fit.scale, closeTo(scale, 1e-9));
        expect(fit.offset.dx, closeTo(dx, 1e-4));
        expect(fit.offset.dy, closeTo(dy, 1e-4));
      });
    }

    test('a wide box shows the full canvas width', () {
      for (final width in [720.0, 855.0, 951.0]) {
        final fit = PaperSceneFit.transform(
          _canvas,
          Size(width, 200),
          BoxFit.cover,
        );
        // Width-driven scale: nothing is cropped horizontally.
        expect(fit.scale, closeTo(width / 1200, 1e-9), reason: '$width');
        expect(fit.offset.dx, closeTo(0, 1e-9), reason: '$width');
      }
    });
  });

  group('the top-edge clamp is a no-op on a phone', () {
    // The clamp may only raise `dy` when the width drives the scale and the box
    // is short (h < 0.2672 * w). No phone pose or in-use hero height reaches
    // that, so 466 dp and below must be bit-identical to the pre-fix fit.
    for (final width in [320.0, 390.0, 466.0]) {
      for (final height in [
        140.0,
        168.0,
        180.0,
        200.0,
        220.0,
        240.0,
        300.0,
        340.0,
      ]) {
        test('${width.toInt()} x ${height.toInt()} is unchanged', () {
          final box = Size(width, height);
          final fit = PaperSceneFit.transform(_canvas, box, BoxFit.cover);
          final before = _coverBeforeTheClamp(_canvas, box);
          expect(fit.scale, before.scale);
          expect(fit.offset, before.offset);
        });
      }
    }

    test('669 x 200 — the open Duo portrait header — is also unchanged', () {
      const box = Size(669, 200);
      final fit = PaperSceneFit.transform(_canvas, box, BoxFit.cover);
      expect(fit.offset, _coverBeforeTheClamp(_canvas, box).offset);
    });
  });

  group('the art survives every hero box', () {
    test('the clamp bound sits at or above the sun', () {
      // `heroArtTop` is the topmost point any hero layer paints. It has to be
      // above the sun's crown (43), or the clamp would let the sun be cut.
      expect(PaperSceneFit.heroArtTop, lessThanOrEqualTo(sun.top));
      expect(PaperSceneFit.heroArtTop, greaterThanOrEqualTo(0));
      // cloudB is the topmost layer of the hero canvas.
      expect(PaperSceneFit.heroArtTop, closeTo(cloudB.top, 0.01));
    });

    for (final box in _boxes) {
      test(
        '${box.width.toInt()} x ${box.height.toInt()} keeps the sun whole',
        () {
          final rendered = _rendered(sun, box);
          expect(rendered.top, greaterThanOrEqualTo(-0.01), reason: '$box');
          expect(rendered.bottom, lessThanOrEqualTo(box.height + 0.01));
          expect(rendered.left, greaterThanOrEqualTo(-0.01));
          expect(rendered.right, lessThanOrEqualTo(box.width + 0.01));
        },
      );

      test(
        '${box.width.toInt()} x ${box.height.toInt()} keeps cloudB whole',
        () {
          // cloudB is the topmost art on the canvas, so the clamp pins its crown
          // to the top edge instead of slicing it.
          final rendered = _rendered(cloudB, box);
          expect(rendered.top, greaterThanOrEqualTo(-0.01), reason: '$box');
          expect(rendered.bottom, lessThanOrEqualTo(box.height + 0.01));
        },
      );

      test(
        '${box.width.toInt()} x ${box.height.toInt()} still fills the frame',
        () {
          // Cover has to keep covering: no letterbox may appear at the bottom.
          final fit = PaperSceneFit.transform(_canvas, box, BoxFit.cover);
          final canvasBottom = _canvas.height * fit.scale + fit.offset.dy;
          expect(canvasBottom, greaterThanOrEqualTo(box.height - 0.01));
          final canvasRight = _canvas.width * fit.scale + fit.offset.dx;
          expect(canvasRight, greaterThanOrEqualTo(box.width - 0.01));
        },
      );
    }
  });

  group('PaperSceneHeader', () {
    testWidgets('lays out at every Duo pose without overflow', (tester) async {
      for (final size in FoldableSurfaces.all) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.build(brightness: Brightness.light),
            home: MediaQuery(
              data: FoldableSurfaces.mediaQueryFor(
                size,
                disableAnimations: true,
              ),
              child: const Scaffold(body: PaperSceneHeader()),
            ),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull, reason: '$size');
        expect(tester.getSize(find.byType(PaperScene)).height, 200);
        expect(
          tester.getSize(find.byType(PaperScene)).width,
          size.width,
          reason: 'the hero spans the page width at $size',
        );
      }
      tester.view.reset();
    });
  });
}
