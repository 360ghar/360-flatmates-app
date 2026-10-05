import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flatmates_app/app/build_error_view.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';

Color _panelColor(WidgetTester tester) => tester
    .widget<ColoredBox>(
      find.descendant(
        of: find.byType(BuildErrorView),
        matching: find.byType(ColoredBox),
      ),
    )
    .color;

Color _messageColor(WidgetTester tester) => tester
    .widget<Text>(
      find.descendant(
        of: find.byType(BuildErrorView),
        matching: find.byType(Text),
      ),
    )
    .style!
    .color!;

void main() {
  group('BuildErrorView brightness', () {
    testWidgets('follows the app theme when one is above it', (tester) async {
      // OS says light; the app runs an explicit dark theme.
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      await tester.pumpWidget(
        Theme(
          data: ThemeData(brightness: Brightness.dark),
          child: const BuildErrorView(),
        ),
      );

      expect(_panelColor(tester), AppSemanticColors.darkPaper1);
      expect(_messageColor(tester), AppSemanticColors.darkMuted);
    });

    testWidgets('a light theme wins over a dark OS setting', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      await tester.pumpWidget(
        Theme(
          data: ThemeData(brightness: Brightness.light),
          child: const BuildErrorView(),
        ),
      );

      expect(_panelColor(tester), AppSemanticColors.paper1);
      expect(_messageColor(tester), AppSemanticColors.muted);
    });

    testWidgets('uses the platform brightness when there is no Theme', (
      tester,
    ) async {
      // ErrorWidget renders wherever the failure happened: there may be no
      // Theme ancestor at all, so the panel must still follow the OS.
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(platformBrightness: Brightness.dark),
          child: BuildErrorView(),
        ),
      );

      expect(_panelColor(tester), AppSemanticColors.darkPaper1);
      expect(_messageColor(tester), AppSemanticColors.darkMuted);
    });

    testWidgets('with no Theme at all it still follows the OS setting', (
      tester,
    ) async {
      // `pumpWidget` always roots the tree in a `View`, which installs a
      // MediaQuery from the view (platform brightness) — so the
      // `?? Brightness.light` tail is not reachable from a widget test. What
      // is reachable: no Theme ancestor, OS dark -> dark panel.
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      await tester.pumpWidget(const BuildErrorView());

      expect(_panelColor(tester), AppSemanticColors.darkPaper1);
      expect(_messageColor(tester), AppSemanticColors.darkMuted);
      // No localizations either: the human fallback string is used.
      expect(find.text('Something went wrong.'), findsOneWidget);
    });

    testWidgets('with no Theme and a light OS it renders the light panel', (
      tester,
    ) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      await tester.pumpWidget(const BuildErrorView());

      expect(_panelColor(tester), AppSemanticColors.paper1);
      expect(_messageColor(tester), AppSemanticColors.muted);
    });
  });
}
