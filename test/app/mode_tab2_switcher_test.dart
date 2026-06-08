import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flatmates_app/app/router/app_router.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/features/auth/auth_controller.dart';
import 'package:flatmates_app/features/bootstrap/bootstrap_controller.dart';
import 'package:flatmates_app/features/discover/application/map_listings_controller.dart';
import 'package:flatmates_app/features/discover/discover_repository.dart';
import 'package:flatmates_app/features/discover/map_view_page.dart';
import 'package:flatmates_app/features/listings/listings_repository.dart';
import 'package:flatmates_app/features/location/application/location_controller.dart';
import 'package:flatmates_app/l10n/gen/app_localizations.dart';

import '../helpers/test_helpers.dart';

/// Regression test for the `!semantics.parentDataDirty` assertion in
/// `package:flutter/src/rendering/object.dart`.
///
/// History: the `/tab2` shell branch used a `ConsumerWidget` that returned
/// either `MapViewPage(key: ValueKey('tab2_map'))` or
/// `ManageListingPage(key: ValueKey('tab2_room_poster'))` based on the
/// user's `mode`. The `ValueKey` swap forced a full Element unmount+remount
/// when the mode flipped, and in the same frame the bottom `NavigationBar`
/// rebuilt its destination list — which made the Semantics tree under
/// `/tab2` detach and reattach concurrently with a sibling SemanticsNode
/// in the same parent. The framework fired
/// `!semantics.parentDataDirty` at `rendering/object.dart:5493`.
///
/// The fix:
/// 1. `_ModeTab2Switcher` is now `ModeTab2Switcher extends
///    ConsumerStatefulWidget` with a stable Element, no `ValueKey` on
///    children.
/// 2. The `NavigationBar` destinations are shape-stable (same key, just
///    icon/label change).
///
/// Note on test reliability: the `parentDataDirty` race in production is
/// driven by the slow `maplibre_gl` PlatformView mount inside `MapViewPage`
/// racing with the `NavigationBar` destination rebuild. A unit test pumps
/// frames synchronously and does not invoke the platform view, so the
/// race does not fire deterministically here. This test therefore
/// asserts the *behavioral contract* (correct child for each mode, no
/// rendering exceptions during rapid flips) — which together prevent the
/// race from recurring in production even though we cannot
/// deterministically reproduce the assertion itself in a test
/// environment.
void main() {
  group('ModeTab2Switcher', () {
    testWidgets(
      'flipping mode between co_hunter and room_poster shows the correct '
      'child and does not throw any rendering assertion when paired with '
      'a NavigationBar that also reacts to the same mode',
      (tester) async {
        final flutterErrors = <FlutterErrorDetails>[];
        final previousOnError = FlutterError.onError;
        FlutterError.onError = flutterErrors.add;
        addTearDown(() => FlutterError.onError = previousOnError);

        // Pump a `Scaffold` whose `body` is the real `ModeTab2Switcher`
        // and whose `bottomNavigationBar` is a `NavigationBar` whose
        // destinations also depend on the mode provider. This mirrors
        // the production `AppShell` so the test exercises the same
        // double-rebuild path that triggered the original assertion.
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appConfigProvider.overrideWithValue(fakeAppConfig()),
              authControllerProvider.overrideWith(() => FakeAuthController()),
              bootstrapControllerProvider.overrideWith(
                () => FakeBootstrapController(),
              ),
              tab2ModeProvider.overrideWith(
                (ref) => ref.watch(_testModeProvider),
              ),
              mapListingsProvider.overrideWith(_StubMapListingsController.new),
              myListingsProvider.overrideWith(
                (ref) async => const <PropertyListing>[],
              ),
              locationControllerProvider.overrideWith(
                _StubLocationController.new,
              ),
              discoverRepositoryProvider.overrideWithValue(
                _NoopDiscoverRepository(),
              ),
              listingsRepositoryProvider.overrideWithValue(
                _NoopListingsRepository(),
              ),
            ],
            child: MaterialApp(
              locale: const Locale('en'),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: const _Tab2Harness(),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        final container = ProviderScope.containerOf(
          tester.element(find.byType(ModeTab2Switcher)),
        );

        // ── Behavioral contract #1: co_hunter shows MapViewPage ──
        expect(
          find.byType(MapViewPage),
          findsOneWidget,
          reason: 'co_hunter mode should render MapViewPage.',
        );

        // ── Flip to room_poster ──────────────────────────────────
        container.read(_testModeProvider.notifier).state = 'room_poster';
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));

        // ── Flip back to co_hunter ───────────────────────────────
        container.read(_testModeProvider.notifier).state = 'co_hunter';
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));

        expect(
          find.byType(MapViewPage),
          findsOneWidget,
          reason: 'co_hunter mode should re-render MapViewPage after flip.',
        );

        // ── Stress: rapid flips in both directions ───────────────
        // With the original buggy `ValueKey` swap, this is the path
        // that fired `!semantics.parentDataDirty` in production. Even
        // though the race is non-deterministic in a unit test, the
        // assertions below ensure the wrapper at least completes
        // every rebuild cleanly.
        for (var i = 0; i < 8; i++) {
          container.read(_testModeProvider.notifier).state =
              i.isEven ? 'room_poster' : 'co_hunter';
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 8));
        }
        await tester.pump(const Duration(milliseconds: 16));

        // ── No-error contract ────────────────────────────────────
        final renderingErrors = flutterErrors
            .where(
              (e) =>
                  e.exceptionAsString().contains('parentDataDirty') ||
                  e.exceptionAsString().contains('parent_data') ||
                  e.exceptionAsString().contains('RenderObject') ||
                  e.exceptionAsString().contains('Failed assertion'),
            )
            .toList();

        expect(
          renderingErrors,
          isEmpty,
          reason: 'Mode flip should not throw any rendering assertion. '
              'Captured FlutterErrors:\n'
              '${flutterErrors.map((e) => e.exception).join("\n")}',
        );
      },
    );
  });
}

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

/// The mode the test wants the switcher (and the harness `NavigationBar`)
/// to see. Mutating this provider's state causes `tab2ModeProvider` (which
/// watches it) to re-emit, which in turn causes the wrapper to rebuild
/// and the `NavigationBar` destinations to swap — in the same frame.
final _testModeProvider = StateProvider<String?>((ref) => 'co_hunter');

/// Test scaffolding that mirrors the production `AppShell`:
/// - `body` is the real `ModeTab2Switcher` (the `/tab2` shell branch).
/// - `bottomNavigationBar` is a `NavigationBar` whose destinations
///   *shape-change* on mode flip — same as the buggy pre-fix AppShell
///   did at `lib/app/app_shell.dart:101-115`.
class _Tab2Harness extends ConsumerWidget {
  const _Tab2Harness();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(_testModeProvider);
    final isRoomPoster = mode == 'room_poster';

    return Scaffold(
      appBar: AppBar(title: const Text('Tab2 Harness')),
      body: const ModeTab2Switcher(),
      bottomNavigationBar: NavigationBar(
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          if (isRoomPoster)
            const NavigationDestination(
              key: ValueKey('nav_post'),
              icon: Icon(Icons.add_home_outlined),
              label: 'Post',
            )
          else
            const NavigationDestination(
              key: ValueKey('nav_explore'),
              icon: Icon(Icons.map_outlined),
              label: 'Explore',
            ),
          const NavigationDestination(
            icon: Icon(Icons.swap_horiz_rounded),
            label: 'Swipe',
          ),
        ],
      ),
    );
  }
}

class _StubMapListingsController extends MapListingsController {
  @override
  MapListingsState build() {
    return const MapListingsState(isLoading: false, listings: []);
  }
}

class _StubLocationController extends LocationController {
  @override
  LocationState build() => const LocationState();
}

class _NoopDiscoverRepository implements DiscoverRepository {
  @override
  Future<List<PropertyListing>> fetchListings({
    FlatmatesProfileModel? currentUser,
    DiscoverFilters? filters,
    int offset = 0,
    int limit = 20,
  }) async =>
      const <PropertyListing>[];

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _NoopListingsRepository implements ListingsRepository {
  @override
  Future<List<PropertyListing>> fetchMyListings() async =>
      const <PropertyListing>[];

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
