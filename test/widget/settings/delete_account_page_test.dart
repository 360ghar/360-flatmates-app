import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/features/auth/auth_controller.dart';
import 'package:flatmates_app/features/bootstrap/bootstrap_controller.dart';
import 'package:flatmates_app/features/settings/delete_account_page.dart';
import 'package:flatmates_app/features/shared/presentation/flatmates_ui.dart';
import 'package:flatmates_app/l10n/gen/app_localizations.dart';

Future<Widget> _routedTestWidget({
  required Widget child,
  List<Override> overrides = const [],
}) async {
  final prefs = await testAppPreferences;
  final router = GoRouter(
    initialLocation: '/page',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Text('host')),
        routes: [GoRoute(path: 'page', builder: (_, _) => child)],
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      appConfigProvider.overrideWithValue(fakeAppConfig()),
      appPreferencesProvider.overrideWithValue(prefs),
      authControllerProvider.overrideWith(() => FakeAuthController()),
      bootstrapControllerProvider.overrideWith(() => FakeBootstrapController()),
      ...overrides,
    ],
    child: MaterialApp.router(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: router,
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetTestAppPreferences();
  });

  group('DeleteAccountPage', () {
    testWidgets('confirm button is disabled until DELETE is typed', (
      tester,
    ) async {
      final widget = await _routedTestWidget(child: const DeleteAccountPage());
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      final confirmButton = find.byKey(
        const Key('delete_account_confirm_button'),
      );
      // The button should be disabled initially.
      final button = tester.widget<FlatmatesButton>(confirmButton);
      expect(button.onPressed, isNull);

      // Type DELETE to enable the button.
      await tester.enterText(
        find.byKey(const Key('delete_account_confirm_field')),
        'DELETE',
      );
      await tester.pumpAndSettle();

      final enabledButton = tester.widget<FlatmatesButton>(confirmButton);
      expect(enabledButton.onPressed, isNotNull);
    });

    testWidgets('tapping confirm shows an irreversible-action dialog', (
      tester,
    ) async {
      final widget = await _routedTestWidget(child: const DeleteAccountPage());
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('delete_account_confirm_field')),
        'DELETE',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('delete_account_confirm_button')));
      await tester.pumpAndSettle();

      // The irreversible-action confirmation dialog should appear.
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.byKey(const Key('delete_account_dialog_cancel')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('delete_account_dialog_confirm')),
        findsOneWidget,
      );
    });

    testWidgets('cancel button dismisses the dialog without deleting', (
      tester,
    ) async {
      final widget = await _routedTestWidget(child: const DeleteAccountPage());
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('delete_account_confirm_field')),
        'DELETE',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('delete_account_confirm_button')));
      await tester.pumpAndSettle();

      // Tap cancel in the dialog.
      await tester.tap(find.byKey(const Key('delete_account_dialog_cancel')));
      await tester.pumpAndSettle();

      // The dialog should be dismissed.
      expect(find.byType(AlertDialog), findsNothing);
      // The page should still be present (not deleted).
      expect(find.byType(DeleteAccountPage), findsOneWidget);
    });
  });
}
