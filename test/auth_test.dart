import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flatmates_app/features/auth/presentation/enter_phone_page.dart';
import 'package:flatmates_app/features/auth/presentation/otp_page.dart';
import 'package:flatmates_app/features/shared/presentation/flatmates_ui.dart';

import 'helpers/test_helpers.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('EnterPhonePage', () {
    testWidgets('renders phone input and OTP CTA', (tester) async {
      await tester.pumpWidget(testableWidget(child: const EnterPhonePage()));
      await tester.pump();
      await tester.pump();

      // Should show the phone text field.
      expect(find.byKey(const Key('enter_phone_input')), findsOneWidget);

      // Should show the OTP CTA (always visible).
      expect(find.byKey(const Key('enter_phone_otp_cta')), findsOneWidget);

      // The password CTA and signup CTA are gated behind enableDebugLogs
      // in the production widget, so they won't appear with our test config.
    });

    testWidgets('starts with +91 prefix in phone field', (tester) async {
      await tester.pumpWidget(testableWidget(child: const EnterPhonePage()));
      await tester.pump();
      await tester.pump();

      final textField = tester.widget<TextField>(
        find.byKey(const Key('enter_phone_input')),
      );
      expect(textField.controller?.text, '+91');
    });
  });

  group('OtpPage', () {
    testWidgets('renders 6 OTP digit fields and submit button', (tester) async {
      await tester.pumpWidget(
        testableWidget(child: const OtpPage(phone: '+919876543210')),
      );
      await tester.pump();
      await tester.pump();

      // Should show 6 individual digit text fields.
      for (var i = 0; i < 6; i++) {
        expect(find.byKey(Key('otp_digit_$i')), findsOneWidget);
      }

      // Should show the submit button.
      expect(find.byKey(const Key('otp_submit_button')), findsOneWidget);
    });

    testWidgets('submit button is enabled when not submitting', (tester) async {
      await tester.pumpWidget(
        testableWidget(child: const OtpPage(phone: '+919876543210')),
      );
      await tester.pump();
      await tester.pump();

      final button = tester.widget<FlatmatesButton>(
        find.byKey(const Key('otp_submit_button')),
      );
      expect(button.onPressed, isNotNull);
    });
  });
}
