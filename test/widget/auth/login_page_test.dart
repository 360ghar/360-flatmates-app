import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';
import 'package:flatmates_app/features/auth/presentation/login_page.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetTestAppPreferences();
  });

  group('LoginPage', () {
    testWidgets('renders password input and submit button', (tester) async {
      final widget = await testableWidgetAsync(
        child: const LoginPage(phone: '+919999999999'),
      );
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('login_phone_input')), findsOneWidget);
      expect(find.byKey(const Key('login_password_input')), findsOneWidget);
      expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
    });

    testWidgets('password visibility toggle flips obscureText', (tester) async {
      final widget = await testableWidgetAsync(
        child: const LoginPage(phone: '+919999999999'),
      );
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Initially the password field is obscured.
      final passwordField = tester.widget<TextField>(
        find.byKey(const Key('login_password_input')),
      );
      expect(passwordField.obscureText, isTrue);

      // Tap the visibility toggle.
      await tester.tap(
        find.byKey(const Key('login_password_visibility_toggle')),
      );
      await tester.pumpAndSettle();

      // Now the password field should not be obscured.
      final toggledField = tester.widget<TextField>(
        find.byKey(const Key('login_password_input')),
      );
      expect(toggledField.obscureText, isFalse);

      // Tap again to re-obscure.
      await tester.tap(
        find.byKey(const Key('login_password_visibility_toggle')),
      );
      await tester.pumpAndSettle();

      final reobscuredField = tester.widget<TextField>(
        find.byKey(const Key('login_password_input')),
      );
      expect(reobscuredField.obscureText, isTrue);
    });
  });
}
