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
