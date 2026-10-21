import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';
import 'package:flatmates_app/features/auth/auth_controller.dart';
import 'package:flatmates_app/features/auth/data/auth_repository.dart';
import 'package:flatmates_app/features/auth/presentation/enter_phone_page.dart';
import 'package:flatmates_app/features/shared/presentation/components.dart';
import 'package:flatmates_app/l10n/gen/app_localizations.dart';

/// Fails the identifier lookup the way the real controller does when the
/// status request throws: the error lands on the auth state and the flow
/// returns no route.
class _FailingIdentifierController extends FakeAuthController {
  @override
  Future<IdentifierStatus?> checkIdentifierStatus(String identifier) async {
    state = const AuthState(
      status: AuthStatus.error,
      errorMessage: 'failure:invalid_credentials',
    );
    return null;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetTestAppPreferences();
  });

  group('EnterPhonePage', () {
    testWidgets('renders identifier input, Google button and continue CTA', (
      tester,
    ) async {
      final widget = await testableWidgetAsync(child: const EnterPhonePage());
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('enter_phone_input')), findsOneWidget);
      expect(find.byKey(const Key('auth_google_button')), findsOneWidget);
      expect(find.byKey(const Key('enter_phone_continue_cta')), findsOneWidget);
    });

    testWidgets(
      'terms checkbox is accepted by default and gates continue CTA',
      (tester) async {
        final widget = await testableWidgetAsync(child: const EnterPhonePage());
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        final checkbox = tester.widget<Checkbox>(
          find.byKey(const Key('terms_checkbox')),
        );
        expect(checkbox.value, isTrue);

        // FlatmatesButton wraps a FilledButton; terms accepted → CTA enabled.
        final filledButton = find.descendant(
          of: find.byKey(const Key('enter_phone_continue_cta')),
          matching: find.byType(FilledButton),
        );
        final button = tester.widget<FilledButton>(filledButton);
        expect(button.onPressed, isNotNull);

        // Uncheck → CTA disabled.
        await tester.tap(find.byKey(const Key('terms_checkbox')));
        await tester.pumpAndSettle();
        final disabledButton = tester.widget<FilledButton>(filledButton);
        expect(disabledButton.onPressed, isNull);

        // Recheck → CTA enabled again.
        await tester.tap(find.byKey(const Key('terms_checkbox')));
        await tester.pumpAndSettle();
        final enabledButton = tester.widget<FilledButton>(filledButton);
        expect(enabledButton.onPressed, isNotNull);
      },
    );

    testWidgets(
      'a failed identifier flow shows one inline error and no toast',
      (tester) async {
        final widget = await testableWidgetAsync(
          overrides: [
            authControllerProvider.overrideWith(
              _FailingIdentifierController.new,
            ),
          ],
          child: const EnterPhonePage(),
        );
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('enter_phone_input')),
          '9876543210',
        );
        // The CTA sits below the fold on the test surface.
        final cta = find.byKey(const Key('enter_phone_continue_cta'));
        await tester.ensureVisible(cta);
        await tester.pumpAndSettle();
        await tester.tap(cta);
        await tester.pumpAndSettle();

        final l10n = await AppLocalizations.delegate.load(const Locale('en'));

        // The failure is presented once, inline, from the auth state.
        expect(find.byType(FlatmatesInlineError), findsOneWidget);
        expect(find.text(l10n.errorInvalidCredentials), findsOneWidget);

        // …and not a second time as a toast. Before the fix, the `route ==
        // null` branch read the error back off the auth state and showed
        // `FlatmatesToast.error` alongside the inline error.
        expect(find.byType(SnackBar), findsNothing);
        expect(find.text(l10n.unverifiedAccountHint), findsNothing);
      },
    );

    testWidgets('the toast assertion is not vacuous', (tester) async {
      // Guards the `findsNothing` above: the same finder must see a real
      // FlatmatesToast when one is shown in this host.
      final widget = await testableWidgetAsync(child: const EnterPhonePage());
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      FlatmatesToast.info(
        tester.element(find.byType(EnterPhonePage)),
        l10n.unverifiedAccountHint,
      );
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text(l10n.unverifiedAccountHint), findsOneWidget);
    });
  });
}
