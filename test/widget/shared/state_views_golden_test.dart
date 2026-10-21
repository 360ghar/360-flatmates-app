import 'dart:io';

import 'package:flatmates_app/app/router/not_found_page.dart';
import 'package:flatmates_app/core/theme/app_theme.dart';
import 'package:flatmates_app/features/shared/presentation/flatmates_empty_state.dart';
import 'package:flatmates_app/features/shared/presentation/flatmates_error_state.dart';
import 'package:flatmates_app/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/foldable_surfaces.dart';
import '../../helpers/golden_fonts.dart';

// Goldens render per-OS; they are generated and checked on macOS only.
final _skip = !Platform.isMacOS;

/// The foldable pose this file adds, and the slug that marks its PNGs as the
/// foldable ones.
///
/// One pose, not four, and it is the widest: these views are a centred icon,
/// a title and a CTA, so the only thing a foldable changes for them is whether
/// `FlatmatesScreen` caps and centres the body in a 720 dp reading column.
/// That happens at 951 dp and at no other Duo pose, so 669 / 678 / 466 would
/// each be 12 more PNGs of the layout the 390 x 844 baseline already covers.
///
/// The existing 12 `*_x1.png` / `*_x2.png` goldens at 390 x 844 are the phone
/// baseline and are left exactly as they are: same size, same file names, same
/// bytes.
const _foldablePose = FoldableSurfaces.openLandscape;
const _foldableSlug = 'duo_open_landscape_951x669';

Widget _app(Brightness b, Widget home, {double textScale = 1}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.build(brightness: b),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: (context, child) => MediaQuery(
    // Reduce motion on: the golden is the settled frame, and it proves the
    // content is complete without any animation running.
    data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(textScale),
      disableAnimations: true,
    ),
    child: child!,
  ),
  home: home,
);

final _cases = <String, Widget>{
  'empty_chats': Scaffold(
    body: FlatmatesEmptyState(
      icon: Icons.chat_bubble_outline_rounded,
      title: 'No conversations yet',
      subtitle: 'Like a room or a person to start a chat.',
      ctaLabel: 'Browse rooms',
      onCtaTap: () {},
    ),
  ),
  'error': Scaffold(
    body: FlatmatesErrorState(
      message: 'We could not load this. Check your connection.',
      onRetry: () {},
    ),
  ),
  'not_found': const NotFoundPage(),
};

void main() {
  setUpAll(loadGoldenFonts);

  // The phone baseline. Do not change the size or the file names: these PNGs
  // are committed and must stay byte-identical.
  for (final entry in _cases.entries) {
    for (final b in Brightness.values) {
      for (final scale in [1.0, 2.0]) {
        final name = '${entry.key}_${b.name}_x${scale.toStringAsFixed(0)}';
        testWidgets(name, skip: _skip, (tester) async {
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(_app(b, entry.value, textScale: scale));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile('goldens/$name.png'),
          );
        });
      }
    }
  }

  // The foldable axis, as siblings rather than a replacement. The suffix goes
  // last so the new PNGs sort next to the phone ones they extend.
  for (final entry in _cases.entries) {
    for (final b in Brightness.values) {
      for (final scale in [1.0, 2.0]) {
        final name =
            '${entry.key}_${b.name}_x${scale.toStringAsFixed(0)}'
            '_$_foldableSlug';
        testWidgets(name, skip: _skip, (tester) async {
          FoldableSurfaces.useSurface(tester, _foldablePose);
          await tester.pumpWidget(_app(b, entry.value, textScale: scale));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile('goldens/$name.png'),
          );
        });
      }
    }
  }
}
