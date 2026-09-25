import 'package:flatmates_app/app/app_shell.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flatmates_app/core/theme/app_theme.dart';
import 'package:flatmates_app/features/auth/auth_controller.dart';
import 'package:flatmates_app/features/bootstrap/bootstrap_controller.dart';
import 'package:flatmates_app/features/shared/presentation/paper/paper_icon.dart';
import 'package:flatmates_app/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_helpers.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'tab strip uses paper icons: clay when selected, ink-3 when not',
    (tester) async {
      final prefs = await testAppPreferences;
      GoRoute branchRoute(String path) =>
          GoRoute(path: path, builder: (_, _) => const SizedBox.shrink());
      final router = GoRouter(
        initialLocation: '/discover',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (_, _, shell) => AppShell(navigationShell: shell),
            branches: [
              for (final p in [
                '/discover',
                '/tab2',
                '/swipe',
                '/chats',
                '/profile',
              ])
                StatefulShellBranch(routes: [branchRoute(p)]),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(fakeAppConfig()),
            appPreferencesProvider.overrideWithValue(prefs),
            authControllerProvider.overrideWith(() => FakeAuthController()),
            bootstrapControllerProvider.overrideWith(
              () => FakeBootstrapController(),
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.build(brightness: Brightness.light),
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final bar = find.byType(NavigationBar);
      expect(
        find.descendant(of: bar, matching: find.byType(Icon)),
        findsNothing,
      );
      final icons = find.descendant(of: bar, matching: find.byType(PaperIcon));
      expect(icons, findsNWidgets(5));

      final colors = [for (final e in icons.evaluate()) IconTheme.of(e).color];
      expect(colors.first, AppSemanticColors.clay);
      expect(colors.skip(1), everyElement(AppSemanticColors.muted));
    },
  );
}
