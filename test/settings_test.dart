import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flatmates_app/core/theme/app_palette.dart';
import 'package:flatmates_app/features/settings/settings_page.dart';

import 'helpers/test_helpers.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SettingsPage', () {
    testWidgets('renders theme mode segmented button', (tester) async {
      await tester.pumpWidget(
        await testableWidgetAsync(child: const SettingsPage()),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(SegmentedButton<ThemeMode>), findsOneWidget);
      expect(
        find.byKey(const Key('theme_mode_system_option')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('theme_mode_light_option')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('theme_mode_dark_option')),
        findsOneWidget,
      );
    });

    testWidgets('renders palette choice chips for all palettes', (tester) async {
      await tester.pumpWidget(
        await testableWidgetAsync(child: const SettingsPage()),
      );
      await tester.pump();
      await tester.pump();

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
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byKey(const Key('theme_mode_dark_option')));
      await tester.pump();
      await tester.pump();

      final segmentedButton = tester.widget<SegmentedButton<ThemeMode>>(
        find.byType(SegmentedButton<ThemeMode>),
      );
      expect(segmentedButton.selected, contains(ThemeMode.dark));
    });

    testWidgets('tapping a palette chip updates state', (tester) async {
      await tester.pumpWidget(
        await testableWidgetAsync(child: const SettingsPage()),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byKey(const Key('palette_ember_coral')));
      await tester.pump();
      await tester.pump();

      final chip = tester.widget<ChoiceChip>(
        find.byKey(const Key('palette_ember_coral')),
      );
      expect(chip.selected, isTrue);
    });

    testWidgets('renders privacy toggles', (tester) async {
      await tester.pumpWidget(
        await testableWidgetAsync(child: const SettingsPage()),
      );
      await tester.pump();
      await tester.pump();

      // Scroll down to reveal privacy section.
      await tester.scrollUntilVisible(
        find.byKey(const Key('setting_hide_last_name')),
        200,
        scrollable: find.byType(Scrollable),
      );

      expect(find.byKey(const Key('setting_hide_last_name')), findsOneWidget);
      expect(find.byKey(const Key('setting_hide_location')), findsOneWidget);
    });

    testWidgets('renders logout button', (tester) async {
      await tester.pumpWidget(
        await testableWidgetAsync(child: const SettingsPage()),
      );
      await tester.pump();
      await tester.pump();

      // Scroll down to reveal session section.
      await tester.scrollUntilVisible(
        find.byKey(const Key('logout_button')),
        400,
        scrollable: find.byType(Scrollable),
      );

      expect(find.byKey(const Key('logout_button')), findsOneWidget);
    });
  });
}
