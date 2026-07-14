import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/features/auth/auth_controller.dart';
import 'package:flatmates_app/features/bootstrap/bootstrap_controller.dart';
import 'package:flatmates_app/features/listings/create_listing_page.dart';
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

  group('CreateListingPage', () {
    testWidgets('renders society, city, locality inputs on step 0', (
      tester,
    ) async {
      final widget = await _routedTestWidget(child: const CreateListingPage());
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('listing_society_input')), findsOneWidget);
      expect(find.byKey(const Key('listing_city_input')), findsOneWidget);
      expect(find.byKey(const Key('listing_locality_input')), findsOneWidget);
    });

    testWidgets('next button is present', (tester) async {
      final widget = await _routedTestWidget(child: const CreateListingPage());
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('listing_next_button')), findsOneWidget);
    });

    testWidgets('back button is not present on step 0', (tester) async {
      final widget = await _routedTestWidget(child: const CreateListingPage());
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // On step 0, the back button should not be present.
      expect(find.byKey(const Key('listing_back_button')), findsNothing);
    });
  });
}
