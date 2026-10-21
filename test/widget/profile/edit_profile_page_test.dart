import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../contract/contract_checks.dart';
import '../../helpers/recording_api.dart';
import '../../helpers/test_helpers.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/features/auth/auth_controller.dart';
import 'package:flatmates_app/features/bootstrap/bootstrap_controller.dart';
import 'package:flatmates_app/features/profile/edit_profile_page.dart';
import 'package:flatmates_app/features/shared/presentation/flatmates_ui.dart';
import 'package:flatmates_app/l10n/gen/app_localizations.dart';

/// A fake bootstrap controller that returns a catalog WITHOUT the legacy
/// `flexible` move-in timeline id, to verify the page opens without error.
class _NoFlexibleBootstrapController extends FakeBootstrapController {
  @override
  Future<BootstrapData?> build() async {
    final data = BootstrapData(
      profile: fakeBootstrapData().profile,
      catalogs: [
        const CatalogEntryModel(
          key: 'flatmates_modes',
          version: 1,
          payload: {
            'items': [
              {'id': 'co_hunter', 'label': 'Find a Flat / Flatmate'},
              {'id': 'room_poster', 'label': 'List My Flat / Find Flatmate'},
              {'id': 'open_to_both', 'label': 'Open to Both'},
            ],
          },
        ),
        const CatalogEntryModel(
          key: 'flatmates_move_in_timelines',
          version: 1,
          payload: {
            'items': [
              {'id': 'immediately', 'label': 'Immediately'},
              {'id': 'within_1_month', 'label': 'Within 1 month'},
              {'id': 'just_exploring', 'label': 'Just exploring'},
            ],
          },
        ),
      ],
    );
    state = AsyncValue.data(data);
    return data;
  }
}

/// A profile with no email and no phone, as a sign-in by Google or Apple gives.
class _NoContactBootstrapController extends FakeBootstrapController {
  @override
  Future<BootstrapData?> build() async {
    final base = fakeBootstrapData();
    final data = base.copyWith(
      profile: base.profile.copyWith(email: null, phone: null),
    );
    state = AsyncValue.data(data);
    return data;
  }
}

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
      bootstrapControllerProvider.overrideWith(
        () => _NoFlexibleBootstrapController(),
      ),
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

  group('EditProfilePage', () {
    testWidgets('opens without throw when catalog omits legacy flexible id', (
      tester,
    ) async {
      final widget = await _routedTestWidget(child: const EditProfilePage());
      await tester.pumpWidget(widget);
      // Pump a few frames to let post-frame callbacks run.
      await tester.pump();
      await tester.pumpAndSettle();

      // The page should render without throwing.
      expect(find.byType(EditProfilePage), findsOneWidget);
    });

    testWidgets('save button is disabled until the form is edited', (
      tester,
    ) async {
      final widget = await _routedTestWidget(child: const EditProfilePage());
      await tester.pumpWidget(widget);
      await tester.pump();
      await tester.pumpAndSettle();

      final saveButton = find.byKey(const Key('profile_save_button'));
      expect(saveButton, findsOneWidget);
      // The save button should be disabled when the form is not dirty.
      final button = tester.widget<FlatmatesButton>(saveButton);
      expect(button.onPressed, isNull);
    });

    testWidgets(
      'the save body has no email or phone: the profile route does not take them',
      (tester) async {
        final recorder = RecordingApi(
          (options) =>
              ok(<String, dynamic>{'id': 1, 'profile_status': 'active'}),
        );
        final widget = await _routedTestWidget(
          child: const EditProfilePage(),
          overrides: [
            apiClientProvider.overrideWithValue(recorder.client),
            bootstrapControllerProvider.overrideWith(
              () => _NoContactBootstrapController(),
            ),
          ],
        );
        await tester.pumpWidget(widget);
        await tester.pump();
        await tester.pumpAndSettle();

        // Both fields are empty and read-only: nothing to type into.
        final fields = tester.widgetList<TextField>(find.byType(TextField));
        final email = fields.firstWhere(
          (f) => f.decoration?.labelText == 'Email',
        );
        final phone = fields.firstWhere(
          (f) => f.decoration?.labelText == 'Phone number',
        );
        expect(email.readOnly, isTrue);
        expect(phone.readOnly, isTrue);

        await tester.tap(find.byKey(const Key('profile_tab_about')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('profile_bio_input')),
          'Early riser, quiet evenings',
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('profile_save_button')));
        await tester.pumpAndSettle();

        final put = recorder.to('PUT', '/flatmates/profile');
        expect(put, hasLength(1));
        final body = Map<String, dynamic>.from(put.single.data as Map);
        expect(body['bio'], 'Early riser, quiet evenings');
        expect(body.containsKey('email'), isFalse);
        expect(body.containsKey('phone'), isFalse);
        expectBodyMatchesContract(body, 'FlatmatesProfileUpdate');
      },
    );

    testWidgets('tapping into a field does not mark the form dirty', (
      tester,
    ) async {
      final widget = await _routedTestWidget(child: const EditProfilePage());
      await tester.pumpWidget(widget);
      await tester.pump();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('profile_tab_about')));
      await tester.pumpAndSettle();
      // Focus moves the cursor, which notifies the controller; it is not an
      // edit, so Back must not ask to discard changes.
      await tester.tap(find.byKey(const Key('profile_bio_input')));
      await tester.pumpAndSettle();

      final button = tester.widget<FlatmatesButton>(
        find.byKey(const Key('profile_save_button')),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('edit state is preserved when switching tabs', (tester) async {
      final widget = await _routedTestWidget(child: const EditProfilePage());
      await tester.pumpWidget(widget);
      await tester.pump();
      await tester.pumpAndSettle();

      // Tap the "About" tab.
      await tester.tap(find.byKey(const Key('profile_tab_about')));
      await tester.pumpAndSettle();

      // Enter text in the bio field on the About tab.
      await tester.enterText(
        find.byKey(const Key('profile_bio_input')),
        'My bio text',
      );
      await tester.pumpAndSettle();

      // Switch to Identity tab.
      await tester.tap(find.byKey(const Key('profile_tab_identity')));
      await tester.pumpAndSettle();

      // Switch back to About tab.
      await tester.tap(find.byKey(const Key('profile_tab_about')));
      await tester.pumpAndSettle();

      // The save button should now be enabled because the form is dirty.
      final saveButton = find.byKey(const Key('profile_save_button'));
      final button = tester.widget<FlatmatesButton>(saveButton);
      expect(button.onPressed, isNotNull);
    });

    testWidgets('back with unsaved changes shows discard confirmation', (
      tester,
    ) async {
      final widget = await _routedTestWidget(child: const EditProfilePage());
      await tester.pumpWidget(widget);
      await tester.pump();
      await tester.pumpAndSettle();

      // Enter text to make the form dirty.
      await tester.tap(find.byKey(const Key('profile_tab_about')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('profile_bio_input')),
        'Unsaved bio',
      );
      await tester.pumpAndSettle();

      // Tap the back button in the header (FlatmatesChromeIconButton with arrow_back_rounded).
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      // A discard confirmation dialog should appear.
      expect(find.byType(Dialog), findsOneWidget);
    });
  });
}
