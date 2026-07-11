import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';
import 'package:flatmates_app/features/settings/settings_page.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetTestAppPreferences();
  });

  group('SettingsPage', () {
    testWidgets('renders logout button on main page', (tester) async {
      final widget = await testableWidgetAsync(child: const SettingsPage());
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      final logoutFinder = find.byKey(const Key('logout_button'));
      await tester.scrollUntilVisible(
        logoutFinder,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(logoutFinder, findsOneWidget);
    });

    testWidgets('renders privacy & security menu item', (tester) async {
      final widget = await testableWidgetAsync(child: const SettingsPage());
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('settings_privacy_security_item')),
        findsOneWidget,
      );
    });

    testWidgets('renders delete account menu item', (tester) async {
      final widget = await testableWidgetAsync(child: const SettingsPage());
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('delete_account_menu_item')), findsOneWidget);
    });
  });
}
