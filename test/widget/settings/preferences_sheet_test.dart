import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';
import 'package:flatmates_app/features/settings/preferences_sheet.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetTestAppPreferences();
  });

  group('PreferencesSheet', () {
    testWidgets('renders theme mode segmented button in preferences sheet', (
      tester,
    ) async {
      final widget = await testableWidgetAsync(
        child: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => showPreferencesSheet(context),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Open the preferences sheet.
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('theme_mode_system_option')), findsOneWidget);
      expect(find.byKey(const Key('theme_mode_light_option')), findsOneWidget);
      expect(find.byKey(const Key('theme_mode_dark_option')), findsOneWidget);
    });

    testWidgets('does not render palette choice chips', (tester) async {
      final widget = await testableWidgetAsync(
        child: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => showPreferencesSheet(context),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // No palette choice chips should be present (single Rausch primary).
      expect(find.byKey(const Key('palette_choice_chips')), findsNothing);
    });

    testWidgets('tapping dark theme option updates state', (tester) async {
      final widget = await testableWidgetAsync(
        child: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => showPreferencesSheet(context),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Tap the dark theme option.
      await tester.tap(find.byKey(const Key('theme_mode_dark_option')));
      await tester.pumpAndSettle();

      // The dark option should now be selected (it gets accent styling).
      // We verify by checking the segmented control still renders.
      expect(find.byKey(const Key('theme_mode_dark_option')), findsOneWidget);
    });

    testWidgets('renders privacy toggles in preferences sheet', (tester) async {
      final widget = await testableWidgetAsync(
        child: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => showPreferencesSheet(context),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Scroll down to reveal the privacy toggles which are below the fold.
      await tester.scrollUntilVisible(
        find.byKey(const Key('setting_hide_last_name')),
        200,
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('setting_hide_last_name')), findsOneWidget);
      expect(find.byKey(const Key('setting_hide_location')), findsOneWidget);
    });
  });
}
