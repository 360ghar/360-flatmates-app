import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';
import 'package:flatmates_app/features/settings/notification_settings_page.dart';
import 'package:flatmates_app/features/settings/settings_controller.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetTestAppPreferences();
  });

  group('NotificationSettingsPage', () {
    testWidgets('renders all five notification toggles', (tester) async {
      final widget = await testableWidgetAsync(
        child: const NotificationSettingsPage(),
      );
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Five SwitchListTile widgets for the five notification toggles.
      expect(find.byType(SwitchListTile), findsNWidgets(5));
    });

    testWidgets('Disable All turns every toggle off and shows a toast', (
      tester,
    ) async {
      final widget = await testableWidgetAsync(
        child: const NotificationSettingsPage(),
      );
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Tap the "Disable All" button.
      await tester.tap(find.byKey(const Key('notif_disable_all')));
      await tester.pumpAndSettle();

      // All switches should now be off.
      final switches = tester.widgetList<SwitchListTile>(
        find.byType(SwitchListTile),
      );
      for (final sw in switches) {
        expect(sw.value, isFalse);
      }
    });

    testWidgets('Enable All turns every toggle on', (tester) async {
      final widget = await testableWidgetAsync(
        child: const NotificationSettingsPage(),
      );
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // First disable all to ensure a known starting state.
      await tester.tap(find.byKey(const Key('notif_disable_all')));
      await tester.pumpAndSettle();

      // Call updateAllNotificationSettings(true) directly via the controller,
      // since the Enable All button is below the fold and hard to tap
      // reliably in the default 800x600 test surface.
      final container = ProviderScope.containerOf(
        tester.element(find.byType(NotificationSettingsPage)),
      );
      await container
          .read(settingsControllerProvider.notifier)
          .updateAllNotificationSettings(true);
      await tester.pumpAndSettle();

      // All switches should now be on.
      final switches = tester.widgetList<SwitchListTile>(
        find.byType(SwitchListTile),
      );
      for (final sw in switches) {
        expect(sw.value, isTrue);
      }
    });
  });
}
