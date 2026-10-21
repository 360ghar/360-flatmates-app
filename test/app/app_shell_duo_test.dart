import 'package:flatmates_app/app/app_shell.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/core/theme/app_theme.dart';
import 'package:flatmates_app/features/auth/auth_controller.dart';
import 'package:flatmates_app/features/bootstrap/bootstrap_controller.dart';
import 'package:flatmates_app/features/shared/presentation/paper/paper_icon.dart';
import 'package:flatmates_app/features/shared/presentation/paper/paper_surface.dart';
import 'package:flatmates_app/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_helpers.dart';

/// The five Maestro identifiers the shell must expose in every chrome mode.
/// 82 flows under `.maestro/` tap or assert these.
const _coHunterIds = <String>[
  'nav_home_tab',
  'nav_explore_tab',
  'nav_swipe_tab',
  'nav_inbox_tab',
  'nav_me_tab',
];

const _roomPosterIds = <String>[
  'nav_home_tab',
  'nav_post_tab',
  'nav_swipe_tab',
  'nav_inbox_tab',
  'nav_me_tab',
];

BootstrapData _roomPosterData() {
  final data = fakeBootstrapData();
  return data.copyWith(profile: data.profile.copyWith(mode: 'room_poster'));
}

class _RoomPosterBootstrapController extends FakeBootstrapController {
  @override
  Future<BootstrapData?> build() async {
    final data = _roomPosterData();
    state = AsyncValue.data(data);
    return data;
  }

  @override
  Future<void> refresh() async {
    state = AsyncValue.data(_roomPosterData());
  }
}

/// Pumps [AppShell] at an exact logical viewport size and returns the router,
/// so a test can assert which branch is on screen.
Future<GoRouter> _pumpShell(
  WidgetTester tester, {
  required double width,
  required double height,
  bool roomPoster = false,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final prefs = await testAppPreferences;
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
            StatefulShellBranch(
              routes: [
                GoRoute(path: p, builder: (_, _) => const SizedBox.shrink()),
              ],
            ),
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
          () => roomPoster
              ? _RoomPosterBootstrapController()
              : FakeBootstrapController(),
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
  return router;
}

/// Asserts every id resolves to exactly one semantics node.
///
/// The handle is disposed inside the test body: `flutter_test` verifies that no
/// [SemanticsHandle] is still active before `addTearDown` callbacks run.
void _expectIdentifiers(WidgetTester tester, List<String> ids, String pose) {
  final semantics = tester.ensureSemantics();
  try {
    for (final id in ids) {
      expect(
        find.bySemanticsIdentifier(id),
        findsOneWidget,
        reason: 'missing Maestro id $id in $pose',
      );
    }
  } finally {
    semantics.dispose();
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('phone-width poses keep the bottom bar', () {
    // Folded portrait, folded landscape, open portrait: 466 / 678 / 669 are
    // all below the 900 dp expanded boundary.
    for (final size in [
      const Size(466, 678),
      const Size(678, 466),
      const Size(669, 951),
    ]) {
      testWidgets('${size.width}x${size.height} renders a NavigationBar', (
        tester,
      ) async {
        await _pumpShell(tester, width: size.width, height: size.height);

        expect(find.byType(NavigationBar), findsOneWidget);
        expect(find.byType(NavigationRail), findsNothing);
        _expectIdentifiers(
          tester,
          _coHunterIds,
          '${size.width}x${size.height} bottom bar',
        );
      });
    }
  });

  group('951 dp open landscape renders a rail', () {
    testWidgets('NavigationRail replaces NavigationBar', (tester) async {
      await _pumpShell(tester, width: 951, height: 669);

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      // Same five cut-paper icons as the bottom bar.
      expect(
        find.descendant(
          of: find.byType(NavigationRail),
          matching: find.byType(PaperIcon),
        ),
        findsNWidgets(5),
      );
      // Paper chrome, no frosted glass anywhere in the shell.
      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('all five Maestro identifiers survive in the rail', (
      tester,
    ) async {
      await _pumpShell(tester, width: 951, height: 669);

      _expectIdentifiers(tester, _coHunterIds, '951x669 rail');
    });

    testWidgets('the rail is left-anchored and does not span the viewport', (
      tester,
    ) async {
      await _pumpShell(tester, width: 951, height: 669);

      final rail = tester.getRect(find.byType(NavigationRail));
      expect(rail.left, 0);
      expect(rail.width, lessThan(200));
      expect(rail.height, 669);
      // The rail's paper chrome is the full-height left column of the shell.
      expect(tester.getSize(find.byType(PaperSurface).first).width, rail.width);
    });

    testWidgets('each id node sits inside the rail, not elsewhere', (
      tester,
    ) async {
      await _pumpShell(tester, width: 951, height: 669);

      final rail = tester.getRect(find.byType(NavigationRail));
      final semantics = tester.ensureSemantics();
      try {
        for (final id in _coHunterIds) {
          final node = tester.getSemantics(find.bySemanticsIdentifier(id));
          final rect = node.rect;
          expect(
            rail.contains(rect.topLeft) && rail.contains(rect.bottomRight),
            isTrue,
            reason: '$id at $rect is outside the rail $rail',
          );
        }
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('tapping a rail destination switches shell branch', (
      tester,
    ) async {
      final router = await _pumpShell(tester, width: 951, height: 669);
      expect(router.routerDelegate.currentConfiguration.uri.path, '/discover');

      final semantics = tester.ensureSemantics();
      try {
        await tester.tap(find.bySemanticsIdentifier('nav_swipe_tab'));
        await tester.pumpAndSettle();
      } finally {
        semantics.dispose();
      }

      expect(router.routerDelegate.currentConfiguration.uri.path, '/swipe');
    });

    testWidgets('room_poster mode swaps slot 2 to nav_post_tab in the rail', (
      tester,
    ) async {
      await _pumpShell(tester, width: 951, height: 669, roomPoster: true);

      _expectIdentifiers(tester, _roomPosterIds, '951x669 rail (room_poster)');

      final semantics = tester.ensureSemantics();
      try {
        expect(find.bySemanticsIdentifier('nav_explore_tab'), findsNothing);
      } finally {
        semantics.dispose();
      }
    });
  });
}
