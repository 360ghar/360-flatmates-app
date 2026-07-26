import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/features/auth/auth_controller.dart';
import 'package:flatmates_app/features/bootstrap/bootstrap_controller.dart';
import 'package:flatmates_app/features/onboarding/profile_completion_page.dart';
import 'package:flatmates_app/l10n/gen/app_localizations.dart';

/// A logged-in auth controller stuck on the `profile_completion` gate with a
/// scripted `missing_fields` list.
class _GatedAuthController extends FakeAuthController {
  _GatedAuthController(this.missingFields);

  final List<String> missingFields;

  @override
  AuthState build() => AuthState(
    status: AuthStatus.authenticated,
    sessionAuthenticated: true,
    authStage: AuthStage.profileCompletion,
    missingProfileFields: missingFields,
  );
}

Future<Widget> _routedPage({required List<String> missingFields}) async {
  final prefs = await testAppPreferences;
  final router = GoRouter(
    initialLocation: '/complete-profile',
    routes: [
      GoRoute(
        path: '/complete-profile',
        builder: (_, _) => const ProfileCompletionPage(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (_, _) =>
            const Scaffold(body: Text('full editor', key: Key('editor_stub'))),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      appConfigProvider.overrideWithValue(fakeAppConfig()),
      appPreferencesProvider.overrideWithValue(prefs),
      authControllerProvider.overrideWith(
        () => _GatedAuthController(missingFields),
      ),
      bootstrapControllerProvider.overrideWith(() => FakeBootstrapController()),
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

  group('ProfileCompletionPage', () {
    testWidgets('renders the form for fields it can collect', (tester) async {
      final widget = await _routedPage(missingFields: ['date_of_birth']);
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('profile_completion_submit')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('editor_stub')), findsNothing);
    });

    testWidgets('hands off to the full editor for uncollectable fields', (
      tester,
    ) async {
      // Regression: any missing field other than full_name / date_of_birth
      // rendered zero inputs with an enabled Continue that no-oped, and
      // PopScope(canPop: false) plus the router gate left no escape.
      final widget = await _routedPage(missingFields: ['gender']);
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('editor_stub')), findsOneWidget);
      expect(find.byKey(const Key('profile_completion_submit')), findsNothing);
    });
  });
}
