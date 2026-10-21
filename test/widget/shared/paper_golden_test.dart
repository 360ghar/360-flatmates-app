import 'dart:io';

import 'package:flatmates_app/core/theme/app_spacing.dart';
import 'package:flatmates_app/core/theme/app_theme.dart';
import 'package:flatmates_app/features/shared/presentation/paper/paper_edge_border.dart';
import 'package:flatmates_app/features/shared/presentation/paper/paper_scene.dart';
import 'package:flatmates_app/features/shared/presentation/paper/paper_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/foldable_surfaces.dart';
import '../../helpers/golden_fonts.dart';

// Goldens render per-OS; they are generated and checked on macOS only.
final _skip = !Platform.isMacOS;

/// The foldable poses this file adds, and the slug that marks their PNGs as
/// the foldable ones.
///
/// Deliberately the two *extreme* Duo poses
/// ([FoldableSurfaces.extremes]) rather than all four. A golden is a byte
/// comparison, so every variant is a permanent maintenance cost, and the two
/// middle poses add no new layout: the paper primitives are a vertical
/// `ListView`, so width is the only axis that changes anything, and 669 dp
/// sits inside the same `AppBreakpoints` branch as the 390 dp phone baseline
/// (below `medium`, no reading column) while 678 dp sits inside the same one
/// as 466 dp. 466 and 951 are the narrowest and widest the app can ever be.
///
/// The existing `paper_primitives_<brightness>.png` at 390 x 900 is the phone
/// baseline and is left exactly as it is: same size, same file name, same
/// bytes.
const _foldablePoses = <(Size, String)>[
  (FoldableSurfaces.foldedPortrait, 'duo_folded_466x678'),
  (FoldableSurfaces.openLandscape, 'duo_open_landscape_951x669'),
];

Widget _frame(Brightness b, Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.build(brightness: b),
  home: Scaffold(body: child),
);

Widget _primitives() => ListView(
  padding: const EdgeInsets.only(bottom: AppSpacing.xl),
  children: [
    const PaperScene.hero(),
    Transform.translate(
      offset: const Offset(0, -12),
      child: PaperSurface(
        layer: PaperLayer.one,
        elevation: PaperElevation.e0,
        edge: PaperEdge.torn,
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Builder(
          builder: (context) {
            final text = Theme.of(context).textTheme;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Find your flatmate', style: text.headlineLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Rooms and people near Koramangala',
                  style: text.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.base),
                PaperSurface(
                  padding: const EdgeInsets.all(AppSpacing.base),
                  child: Text('A card on layer two', style: text.titleMedium),
                ),
                const SizedBox(height: AppSpacing.base),
                PaperSurface(
                  layer: PaperLayer.three,
                  elevation: PaperElevation.e3,
                  edge: PaperEdge.scallop,
                  edgeSide: PaperEdgeSide.left,
                  edgeDepth: 6,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    'Toast with a scallop edge',
                    style: text.bodyMedium,
                  ),
                ),
                const SizedBox(height: AppSpacing.base),
                FilledButton(onPressed: () {}, child: const Text('Message')),
              ],
            );
          },
        ),
      ),
    ),
    const Center(child: PaperScene.compact(prop: PaperProp.chat)),
  ],
);

void main() {
  setUpAll(loadGoldenFonts);

  // The phone baseline. Do not change the size or the file names: these PNGs
  // are committed and must stay byte-identical.
  for (final b in Brightness.values) {
    testWidgets('paper primitives (${b.name})', skip: _skip, (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_frame(b, _primitives()));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/paper_primitives_${b.name}.png'),
      );
    });
  }

  // The foldable axis, as siblings rather than a replacement.
  for (final (size, slug) in _foldablePoses) {
    for (final b in Brightness.values) {
      testWidgets('paper primitives $slug (${b.name})', skip: _skip, (
        tester,
      ) async {
        FoldableSurfaces.useSurface(tester, size);
        await tester.pumpWidget(_frame(b, _primitives()));
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/paper_primitives_${slug}_${b.name}.png'),
        );
      });
    }
  }
}
