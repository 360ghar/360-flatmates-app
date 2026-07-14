import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';
import 'package:flatmates_app/features/auth/presentation/reset_password_page.dart';
import 'package:flatmates_app/features/shared/presentation/flatmates_ui.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetTestAppPreferences();
  });

  group('ResetPasswordPage', () {
    testWidgets('renders OTP fields, password inputs and submit button', (
      tester,
    ) async {
      final widget = await testableWidgetAsync(
        child: const ResetPasswordPage(phone: '+919999999999'),
      );
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // 6 OTP digit fields.
      for (var i = 0; i < 6; i++) {
        expect(
          find.byKey(Key('reset_otp_digit_$i')),
          findsOneWidget,
          reason: 'Expected to find reset OTP digit field $i',
        );
      }
      expect(find.byKey(const Key('reset_new_password_input')), findsOneWidget);
      expect(
        find.byKey(const Key('reset_confirm_password_input')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('reset_password_submit')), findsOneWidget);
    });

    testWidgets('submit stays disabled until OTP + valid matching password', (
      tester,
    ) async {
      final widget = await testableWidgetAsync(
        child: const ResetPasswordPage(phone: '+919999999999'),
      );
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Initially disabled.
      final initialButton = tester.widget<FlatmatesButton>(
        find.byKey(const Key('reset_password_submit')),
      );
      expect(initialButton.onPressed, isNull);

      // Enter OTP only — still disabled (no password).
      for (var i = 0; i < 6; i++) {
        await tester.enterText(find.byKey(Key('reset_otp_digit_$i')), '$i');
        await tester.pump();
      }
      await tester.pumpAndSettle();

      final otpOnlyButton = tester.widget<FlatmatesButton>(
        find.byKey(const Key('reset_password_submit')),
      );
      expect(otpOnlyButton.onPressed, isNull);

      // Enter a valid matching password.
      await tester.enterText(
        find.byKey(const Key('reset_new_password_input')),
        'ValidPass1',
      );
      await tester.enterText(
        find.byKey(const Key('reset_confirm_password_input')),
        'ValidPass1',
      );
      await tester.pumpAndSettle();

      final enabledButton = tester.widget<FlatmatesButton>(
        find.byKey(const Key('reset_password_submit')),
      );
      expect(enabledButton.onPressed, isNotNull);
    });

    testWidgets('mismatched confirm password disables submit', (tester) async {
      final widget = await testableWidgetAsync(
        child: const ResetPasswordPage(phone: '+919999999999'),
      );
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Enter complete OTP.
      for (var i = 0; i < 6; i++) {
        await tester.enterText(find.byKey(Key('reset_otp_digit_$i')), '$i');
        await tester.pump();
      }

      // Enter mismatched passwords.
      await tester.enterText(
        find.byKey(const Key('reset_new_password_input')),
        'ValidPass1',
      );
      await tester.enterText(
        find.byKey(const Key('reset_confirm_password_input')),
        'DifferentPass1',
      );
      await tester.pumpAndSettle();

      final disabledButton = tester.widget<FlatmatesButton>(
        find.byKey(const Key('reset_password_submit')),
      );
      expect(disabledButton.onPressed, isNull);
    });
  });
}
