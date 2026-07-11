import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flatmates_app/features/settings/preferences_sheet.dart';
import 'package:flatmates_app/features/settings/settings_page.dart';
import 'package:flatmates_app/features/shared/presentation/flatmates_segmented_control.dart';

import 'helpers/test_helpers.dart';

/// Opens the Preferences bottom sheet from a minimal harness.
Future<void> openPreferencesSheet(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('open_preferences_test_button')));
  await tester.pumpAndSettle();
}

Future<void> pumpPreferencesHost(WidgetTester tester) async {
  await tester.pumpWidget(
    await testableWidgetAsync(
      child: Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: TextButton(
                key: const Key('open_preferences_test_button'),
                onPressed: () => showPreferencesSheet(context),
                child: const Text('Open Preferences'),
              ),
            ),
          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PreferencesSheet', () {
    testWidgets('renders theme mode segmented button in preferences sheet', (
      tester,
    ) async {
      await pumpPreferencesHost(tester);
      await openPreferencesSheet(tester);

      expect(find.byType(FlatmatesSegmentedControl<ThemeMode>), findsOneWidget);
      expect(find.byKey(const Key('theme_mode_system_option')), findsOneWidget);
      expect(find.byKey(const Key('theme_mode_light_option')), findsOneWidget);
      expect(find.byKey(const Key('theme_mode_dark_option')), findsOneWidget);
    });

    testWidgets('does not render palette choice chips', (tester) async {
      await pumpPreferencesHost(tester);
      await openPreferencesSheet(tester);

      expect(find.byKey(const Key('palette_rausch')), findsNothing);
      expect(find.byKey(const Key('palette_ember_coral')), findsNothing);
    });

    testWidgets('tapping dark theme option updates state', (tester) async {
      await pumpPreferencesHost(tester);
      await openPreferencesSheet(tester);

      await tester.tap(find.byKey(const Key('theme_mode_dark_option')));
      await tester.pumpAndSettle();

      final segmentedControl = tester
          .widget<FlatmatesSegmentedControl<ThemeMode>>(
            find.byType(FlatmatesSegmentedControl<ThemeMode>),
          );
      expect(segmentedControl.selected, equals(ThemeMode.dark));
    });

    testWidgets('renders privacy toggles in preferences sheet', (tester) async {
      await pumpPreferencesHost(tester);
      await openPreferencesSheet(tester);

      // Scroll the bottom sheet's scrollable to reveal privacy toggles.
      final sheetScrollable = find.descendant(
        of: find.byType(DraggableScrollableSheet),
        matching: find.byType(Scrollable),
      );

      await tester.scrollUntilVisible(
        find.byKey(const Key('setting_hide_last_name')),
        200,
        scrollable: sheetScrollable,
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('setting_hide_location')),
        200,
        scrollable: sheetScrollable,
      );

      expect(find.byKey(const Key('setting_hide_last_name')), findsOneWidget);
      expect(find.byKey(const Key('setting_hide_location')), findsOneWidget);
    });
  });

  group('SettingsPage', () {
    testWidgets('renders logout button on main page', (tester) async {
      await tester.pumpWidget(
        await testableWidgetAsync(child: const SettingsPage()),
      );
      await tester.pumpAndSettle();

      // Scroll down to reveal the logout button.
      await tester.scrollUntilVisible(
        find.byKey(const Key('logout_button')),
        400,
        scrollable: find.byType(Scrollable),
      );

      expect(find.byKey(const Key('logout_button')), findsOneWidget);
    });
  });
}
