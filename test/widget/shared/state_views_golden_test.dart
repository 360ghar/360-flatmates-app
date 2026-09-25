import 'dart:io';

import 'package:flatmates_app/app/router/not_found_page.dart';
import 'package:flatmates_app/core/theme/app_theme.dart';
import 'package:flatmates_app/features/shared/presentation/flatmates_empty_state.dart';
import 'package:flatmates_app/features/shared/presentation/flatmates_error_state.dart';
import 'package:flatmates_app/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/golden_fonts.dart';

// Goldens render per-OS; they are generated and checked on macOS only.
final _skip = !Platform.isMacOS;

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
}
