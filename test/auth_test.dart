import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flatmates_app/core/errors/app_failure.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/features/auth/auth_controller.dart';
import 'package:flatmates_app/features/auth/presentation/enter_phone_page.dart';
import 'package:flatmates_app/features/auth/presentation/login_page.dart';
import 'package:flatmates_app/features/auth/presentation/otp_page.dart';
import 'package:flatmates_app/features/auth/presentation/reset_password_page.dart';
import 'package:flatmates_app/features/auth/presentation/splash_page.dart';
import 'package:flatmates_app/features/bootstrap/bootstrap_controller.dart';
import 'package:flatmates_app/features/shared/presentation/flatmates_ui.dart';
import 'package:flatmates_app/l10n/gen/app_localizations.dart';

import 'helpers/test_helpers.dart';

class FailingBootstrapController extends BootstrapController {
  @override
  Future<BootstrapData?> build() async {
    throw const NetworkFailure();
  }

  @override
  Future<void> refresh() async {
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
    testWidgets('renders identifier input, Google button and continue CTA', (
      tester,
    ) async {
      await tester.pumpWidget(
        await testableWidgetAsync(child: const EnterPhonePage()),
      );
      await tester.pump();
      await tester.pump();

      // Single identifier text field (phone or email).
      expect(find.byKey(const Key('enter_phone_input')), findsOneWidget);

      // Google sign-in button.
      expect(find.byKey(const Key('auth_google_button')), findsOneWidget);

      // Unified continue CTA (replaces the separate login/signup buttons).
      expect(find.byKey(const Key('enter_phone_continue_cta')), findsOneWidget);
    });
  });

  group('EnterPhonePage terms gate', () {
    testWidgets('continue CTA is disabled until terms accepted, then enabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        await testableWidgetAsync(child: const EnterPhonePage()),
      );
      await tester.pump();
      await tester.pump();

      FlatmatesButton cta() => tester.widget<FlatmatesButton>(
        find.byKey(const Key('enter_phone_continue_cta')),
      );

      // Terms unchecked by default → CTA disabled.
      expect(cta().onPressed, isNull);

      // Accepting the terms enables the CTA (StateProvider rebuild, no
      // setState in the ConsumerStatefulWidget).
      await tester.tap(find.byKey(const Key('terms_checkbox')));
      await tester.pump();
      expect(cta().onPressed, isNotNull);
    });
  });

  group('LoginPage', () {
    testWidgets('password visibility toggle flips obscureText', (tester) async {
      await tester.pumpWidget(
        await testableWidgetAsync(child: const LoginPage(phone: '+91999')),
      );
      await tester.pump();
      await tester.pump();

      TextField passwordField() => tester.widget<TextField>(
        find.byKey(const Key('login_password_input')),
      );

      // Obscured by default.
      expect(passwordField().obscureText, isTrue);

      // Tap the visibility toggle inside the password field's suffix.
      await tester.tap(find.byTooltip('Toggle password visibility'));
      await tester.pump();
      expect(passwordField().obscureText, isFalse);
    });
  });

  group('ResetPasswordPage', () {
    testWidgets('submit stays disabled until OTP + valid matching password', (
      tester,
    ) async {
      await tester.pumpWidget(
        await testableWidgetAsync(child: const ResetPasswordPage()),
      );
      await tester.pump();
      await tester.pump();

      FlatmatesButton submit() => tester.widget<FlatmatesButton>(
        find.byKey(const Key('reset_password_submit')),
      );

      // Nothing entered → disabled (previously the button was always enabled
      // and a tap silently no-opped, a dead-end).
      expect(submit().onPressed, isNull);

      // Fill the 6 OTP digits.
      for (var i = 0; i < 6; i++) {
        await tester.enterText(find.byKey(Key('reset_otp_digit_$i')), '1');
      }
      await tester.pump();

      // Valid, matching password → enabled.
      await tester.enterText(
        find.byKey(const Key('reset_new_password_input')),
        'Password1',
      );
      await tester.enterText(
        find.byKey(const Key('reset_confirm_password_input')),
        'Password1',
      );
      await tester.pump();
      expect(submit().onPressed, isNotNull);

      // Mismatched confirm → disabled again and a warning is shown.
      await tester.enterText(
        find.byKey(const Key('reset_confirm_password_input')),
        'Password2',
      );
      await tester.pump();
      expect(submit().onPressed, isNull);
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
