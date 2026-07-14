import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';
import 'package:flatmates_app/features/profile/profile_page.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetTestAppPreferences();
  });

  group('ProfilePage', () {
    testWidgets('renders edit button and name text', (tester) async {
      final widget = await testableWidgetAsync(child: const ProfilePage());
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('profile_edit_button')), findsOneWidget);
      expect(find.byKey(const Key('profile_name_text')), findsOneWidget);
    });

    testWidgets('renders logout button', (tester) async {
      final widget = await testableWidgetAsync(child: const ProfilePage());
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Scroll to find the logout button which may be off-screen.
      final logoutFinder = find.byKey(const Key('logout_button'));
      await tester.scrollUntilVisible(
        logoutFinder,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(logoutFinder, findsOneWidget);
    });

    testWidgets('renders menu items (preferences, settings, help & safety)', (
      tester,
    ) async {
      final widget = await testableWidgetAsync(child: const ProfilePage());
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('preferences_menu_item')), findsOneWidget);
      expect(
        find.byKey(const Key('profile_settings_menu_item')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('profile_help_safety_menu_item')),
        findsOneWidget,
      );
    });
  });
}
