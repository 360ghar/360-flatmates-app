import 'package:flatmates_app/app/router/app_router.dart';
import 'package:flatmates_app/app/router/not_found_page.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/core/storage/secure_kv_store.dart';
import 'package:flatmates_app/features/auth/auth_controller.dart';
import 'package:flatmates_app/features/bootstrap/bootstrap_controller.dart';
import 'package:flatmates_app/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_helpers.dart';

class _ActiveUser extends FakeAuthController {
  @override
  AuthState build() => const AuthState(
    status: AuthStatus.authenticated,
    sessionAuthenticated: true,
    authStage: AuthStage.active,
  );

  @override
  Future<void> checkSession() async {}
}

void main() {
  testWidgets('an unknown route shows NotFoundPage with a way home (M10)', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    resetTestAppPreferences();
    final prefs = await testAppPreferences;
    late final ProviderContainer container;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(fakeAppConfig()),
          appPreferencesProvider.overrideWithValue(prefs),
          secureStoreProvider.overrideWithValue(const SecureKvStore()),
          authControllerProvider.overrideWith(_ActiveUser.new),
          bootstrapControllerProvider.overrideWith(
            () => FakeBootstrapController(),
          ),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            return MaterialApp.router(
              routerConfig: ref.watch(appRouterProvider),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            );
          },
        ),
      ),
    );
    await tester.pump();

    container.read(appRouterProvider).go('/this-route-does-not-exist');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(NotFoundPage), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
  });
}
