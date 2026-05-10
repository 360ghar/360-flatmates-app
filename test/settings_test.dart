import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flatmates_app/core/theme/app_palette.dart';
import 'package:flatmates_app/features/settings/settings_page.dart';
import 'package:flatmates_app/features/shared/presentation/flatmates_chip.dart';

import 'helpers/test_helpers.dart';

/// Opens the Preferences bottom sheet by tapping the menu item.
Future<void> openPreferencesSheet(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('preferences_menu_item')));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SettingsPage', () {
    testWidgets('renders theme mode segmented button in preferences sheet', (
      tester,
    ) async {
      await tester.pumpWidget(
        await testableWidgetAsync(child: const SettingsPage()),
      );
      await tester.pumpAndSettle();

      await openPreferencesSheet(tester);

      expect(find.byType(SegmentedButton<ThemeMode>), findsOneWidget);
      expect(find.byKey(const Key('theme_mode_system_option')), findsOneWidget);
      expect(find.byKey(const Key('theme_mode_light_option')), findsOneWidget);
      expect(find.byKey(const Key('theme_mode_dark_option')), findsOneWidget);
    });

    testWidgets('renders palette choice chips for all palettes', (
      tester,
    ) async {
      await tester.pumpWidget(
        await testableWidgetAsync(child: const SettingsPage()),
      );
      await tester.pumpAndSettle();

      await openPreferencesSheet(tester);

      for (final palette in AppPalette.values) {
        expect(
          find.byKey(Key('palette_${palette.storageValue}')),
          findsOneWidget,
        );
      }
    });

    testWidgets('tapping dark theme option updates state', (tester) async {
      await tester.pumpWidget(
        await testableWidgetAsync(child: const SettingsPage()),
      );
      await tester.pumpAndSettle();

      await openPreferencesSheet(tester);

      await tester.tap(find.byKey(const Key('theme_mode_dark_option')));
      await tester.pumpAndSettle();

      final segmentedButton = tester.widget<SegmentedButton<ThemeMode>>(
        find.byType(SegmentedButton<ThemeMode>),
      );
      expect(segmentedButton.selected, contains(ThemeMode.dark));
    });

    testWidgets('tapping a palette chip updates state', (tester) async {
      await tester.pumpWidget(
        await testableWidgetAsync(child: const SettingsPage()),
      );
      await tester.pumpAndSettle();

      await openPreferencesSheet(tester);

      final emberChip = find.byKey(const Key('palette_ember_coral'));
      await tester.ensureVisible(emberChip);
      await tester.tap(emberChip, warnIfMissed: false);
      await tester.pumpAndSettle();

      final chip = tester.widget<FlatmatesChip>(
        find.byKey(const Key('palette_ember_coral')),
      );
      expect(chip.selected, isTrue);
    });

    testWidgets('renders privacy toggles in preferences sheet', (tester) async {
      await tester.pumpWidget(
        await testableWidgetAsync(child: const SettingsPage()),
      );
      await tester.pumpAndSettle();

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
