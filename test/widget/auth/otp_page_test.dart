import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';
import 'package:flatmates_app/features/auth/presentation/otp_page.dart';
import 'package:flatmates_app/features/shared/presentation/flatmates_ui.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetTestAppPreferences();
  });

  group('OtpPage', () {
    testWidgets('renders 6 OTP digit fields and submit button', (tester) async {
      final widget = await testableWidgetAsync(
        child: const OtpPage(phone: '+919999999999'),
      );
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // 6 digit fields with keys otp_digit_0 through otp_digit_5.
      for (var i = 0; i < 6; i++) {
        expect(
          find.byKey(Key('otp_digit_$i')),
          findsOneWidget,
          reason: 'Expected to find OTP digit field $i',
        );
      }
      expect(find.byKey(const Key('otp_submit_button')), findsOneWidget);
    });

    testWidgets('submit button is disabled when OTP is incomplete', (
      tester,
    ) async {
      final widget = await testableWidgetAsync(
        child: const OtpPage(phone: '+919999999999'),
      );
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Submit should be disabled when OTP is incomplete.
      final submitButton = tester.widget<FlatmatesButton>(
        find.byKey(const Key('otp_submit_button')),
      );
      expect(submitButton.onPressed, isNull);

      // Enter only 3 digits — button should still be disabled.
      for (var i = 0; i < 3; i++) {
        await tester.enterText(find.byKey(Key('otp_digit_$i')), '$i');
        await tester.pump();
      }
      await tester.pumpAndSettle();

      final stillDisabledButton = tester.widget<FlatmatesButton>(
        find.byKey(const Key('otp_submit_button')),
      );
      expect(stillDisabledButton.onPressed, isNull);
    });

    testWidgets('entering all 6 digits auto-submits and authenticates', (
      tester,
    ) async {
      final widget = await testableWidgetAsync(
        child: const OtpPage(phone: '+919999999999'),
      );
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Enter all 6 digits — onCompleted fires, which calls verifyOtp.
      for (var i = 0; i < 6; i++) {
        await tester.enterText(find.byKey(Key('otp_digit_$i')), '$i');
        await tester.pump();
      }
      await tester.pumpAndSettle();

      // After auto-submit, the FakeAuthController sets authenticated state.
      // The submit button should now be disabled (isSuccess = true).
      final button = tester.widget<FlatmatesButton>(
        find.byKey(const Key('otp_submit_button')),
      );
      expect(button.onPressed, isNull);
    });
  });
}
