import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/features/auth/auth_controller.dart';
import 'package:flatmates_app/features/bootstrap/bootstrap_controller.dart';
import 'package:flatmates_app/features/profile/edit_profile_page.dart';
import 'package:flatmates_app/features/shared/presentation/components.dart';
import 'package:flatmates_app/l10n/gen/app_localizations.dart';

import '../helpers/test_helpers.dart';

/// Bootstrap with production-like move-in catalog (no legacy `flexible` id).
class _CatalogBootstrapController extends FakeBootstrapController {
  @override
  Future<BootstrapData?> build() async {
    final base = fakeBootstrapData();
    final data = BootstrapData(
      profile: base.profile.copyWith(moveInTimeline: 'flexible'),
      catalogs: [
        ...base.catalogs,
        const CatalogEntryModel(
          key: 'flatmates_move_in_timelines',
          version: 1,
          payload: {
            'items': [
              {'id': 'immediately', 'label': 'Immediately'},
              {'id': 'within_2_weeks', 'label': 'Within 2 Weeks'},
              {'id': 'within_1_month', 'label': 'Within 1 Month'},
              {'id': 'just_exploring', 'label': 'Just Exploring'},
            ],
          },
        ),
      ],
      activeListingCount: base.activeListingCount,
      conversationCount: base.conversationCount,
      unreadMessageCount: base.unreadMessageCount,
    );
    state = AsyncValue.data(data);
    return data;
  }
}

Widget _editProfileHarness({BootstrapController Function()? bootstrap}) {
  // Router so the page's go_router extensions (canPop/pop/go) resolve.
  // Start on /profile then push /profile/edit so the edit page sits on top of a
  // poppable route (mirrors production, where it is pushed from the profile
  // page or the help/account actions).
  final router = GoRouter(
    initialLocation: '/profile',
    routes: [
      GoRoute(
        path: '/profile',
        builder: (context, state) => Scaffold(
          body: Center(
            child: TextButton(
              key: const Key('open_edit'),
              onPressed: () => context.push('/profile/edit'),
              child: const Text('Profile Home'),
            ),
          ),
        ),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (context, state) => const EditProfilePage(),
          ),
        ],
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      appConfigProvider.overrideWithValue(fakeAppConfig()),
      authControllerProvider.overrideWith(FakeAuthController.new),
      bootstrapControllerProvider.overrideWith(
        bootstrap ?? FakeBootstrapController.new,
      ),
    ],
    child: MaterialApp.router(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: router,
    ),
  );
}

Future<void> _openEditPage(
  WidgetTester tester, {
  BootstrapController Function()? bootstrap,
}) async {
  await tester.pumpWidget(_editProfileHarness(bootstrap: bootstrap));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('open_edit')));
  await tester.pumpAndSettle();
}

void main() {
  group('EditProfilePage', () {
    testWidgets('opens without throw when catalog omits legacy flexible id', (
      tester,
    ) async {
      // Profile move_in_timeline is legacy `flexible` while catalog only has
      // just_exploring — page must map the alias and not assert.
      await _openEditPage(tester, bootstrap: _CatalogBootstrapController.new);

      final saveFinder = find.byKey(const Key('profile_save_button'));
      await tester.scrollUntilVisible(
        saveFinder,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(saveFinder, findsOneWidget);
      // Seed alone must not mark the form dirty.
      final button = tester.widget<FlatmatesButton>(saveFinder);
      expect(button.onPressed, isNull);
    });

    testWidgets('save button is disabled until the form is edited', (
      tester,
    ) async {
      await _openEditPage(tester);

      final saveFinder = find.byKey(const Key('profile_save_button'));
      await tester.scrollUntilVisible(
        saveFinder,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(saveFinder, findsOneWidget);

      // Not dirty yet -> disabled.
      FlatmatesButton button = tester.widget(saveFinder);
      expect(button.onPressed, isNull);

      // Edit a field -> becomes enabled.
      await tester.enterText(
        find.byKey(const Key('profile_bio_input')),
        'New bio content',
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        saveFinder,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      button = tester.widget(saveFinder);
      expect(button.onPressed, isNotNull);
    });

    testWidgets('back with unsaved changes shows discard confirmation', (
      tester,
    ) async {
      await _openEditPage(tester);

      // Make the form dirty.
      await tester.enterText(
        find.byKey(const Key('profile_city_input')),
        'Mumbai',
      );
      await tester.pumpAndSettle();

      // Attempt to leave via the back button in the header.
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.text('Discard changes?'), findsOneWidget);
      expect(find.text('Keep editing'), findsOneWidget);
      expect(find.text('Discard'), findsOneWidget);

      // Keep editing -> dialog dismisses, still on edit page.
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();

      expect(find.text('Discard changes?'), findsNothing);
      // Still on the edit page (a visible field remains).
      expect(find.byKey(const Key('profile_city_input')), findsOneWidget);
      expect(find.text('Profile Home'), findsNothing);
    });

    testWidgets('discarding unsaved changes leaves the edit page', (
      tester,
    ) async {
      await _openEditPage(tester);

      await tester.enterText(
        find.byKey(const Key('profile_locality_input')),
        'Andheri',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      // Routed back to the /profile fallback.
      expect(find.text('Profile Home'), findsOneWidget);
    });
  });
}
