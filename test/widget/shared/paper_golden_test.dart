import 'dart:io';

import 'package:flatmates_app/core/theme/app_spacing.dart';
import 'package:flatmates_app/core/theme/app_theme.dart';
import 'package:flatmates_app/features/shared/presentation/paper/paper_edge_border.dart';
import 'package:flatmates_app/features/shared/presentation/paper/paper_scene.dart';
import 'package:flatmates_app/features/shared/presentation/paper/paper_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/golden_fonts.dart';

// Goldens render per-OS; they are generated and checked on macOS only.
final _skip = !Platform.isMacOS;

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
}
