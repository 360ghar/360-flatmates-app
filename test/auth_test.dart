import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flatmates_app/core/errors/app_failure.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/features/auth/auth_controller.dart';
import 'package:flatmates_app/features/auth/presentation/enter_phone_page.dart';
import 'package:flatmates_app/features/auth/presentation/otp_page.dart';
import 'package:flatmates_app/features/auth/presentation/splash_page.dart';
import 'package:flatmates_app/features/bootstrap/bootstrap_controller.dart';
import 'package:flatmates_app/features/shared/presentation/flatmates_ui.dart';
import 'package:flatmates_app/l10n/gen/app_localizations.dart';

import 'helpers/test_helpers.dart';

class FailingBootstrapController extends BootstrapController {
  @override
  FutureOr<BootstrapData?> build() {
    throw const NetworkFailure();
  }

  @override
  Future<void> load() async {
    state = AsyncError(const NetworkFailure(), StackTrace.current);
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SplashPage', () {
    testWidgets('network error state does not overflow in landscape', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 360);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(fakeAppConfig()),
            authControllerProvider.overrideWith(() => FakeAuthController()),
            bootstrapControllerProvider.overrideWith(
              () => FailingBootstrapController(),
            ),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: SplashPage(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
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
