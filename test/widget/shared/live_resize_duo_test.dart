import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flatmates_app/app/app_shell.dart';
import 'package:flatmates_app/core/location/location_data.dart';
import 'package:flatmates_app/core/network/api_client.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/core/theme/app_theme.dart';
import 'package:flatmates_app/features/auth/auth_controller.dart';
import 'package:flatmates_app/features/bootstrap/bootstrap_controller.dart';
import 'package:flatmates_app/features/discover/discover_page.dart';
import 'package:flatmates_app/features/location/application/location_controller.dart';
import 'package:flatmates_app/features/shared/presentation/flatmates_screen.dart';
import 'package:flatmates_app/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/foldable_surfaces.dart';
import '../../helpers/test_helpers.dart';

/// Live surface-size changes: the widget-level equivalent of folding and
/// unfolding the iPhone Duo.
///
/// Every other layout test in this repo pumps a widget *once* at a fixed size.
/// A fold is not that: the tree stays mounted and the metrics change
/// underneath it, so the framework re-runs layout against the new constraints
/// and re-decides which widgets survive. That is where foldables break — a
/// `RenderFlex overflowed` on the new width, a chrome swap that drops the page
/// `State`, or a scroll position that silently resets.
///
/// The transitions below are the fold / unfold pairs, in both directions:
///
/// | From | To | What it crosses |
/// |---|---|---|
/// | folded portrait 466x678 | open landscape 951x669 | both boundaries: 600 and 900, and the 720 reading-column cap |
/// | open landscape 951x669 | folded portrait 466x678 | the same, backwards |
/// | folded portrait 466x678 | open portrait 669x951 | 600 (phone layout -> 3-column grid) |
/// | open portrait 669x951 | folded landscape 678x466 | only the aspect ratio — no boundary |
/// | folded landscape 678x466 | open landscape 951x669 | 900 (bottom bar -> rail) |
const _transitions = <(Size, Size)>[
  (FoldableSurfaces.foldedPortrait, FoldableSurfaces.openLandscape),
  (FoldableSurfaces.openLandscape, FoldableSurfaces.foldedPortrait),
  (FoldableSurfaces.foldedPortrait, FoldableSurfaces.openPortrait),
  (FoldableSurfaces.openPortrait, FoldableSurfaces.foldedLandscape),
  (FoldableSurfaces.foldedLandscape, FoldableSurfaces.openLandscape),
];

String _label(Size size) => '${size.width.toInt()}x${size.height.toInt()}';

/// Walks every transition with the tree already mounted, returning one line
/// per transition that produced an exception.
///
/// Nothing here is swallowed: the caller asserts the list is empty and prints
/// it, so a failure names the exact fold that broke and the exact error.
Future<List<String>> _walkTransitions(
  WidgetTester tester, {
  bool pumpOnly = false,
}) async {
  final failures = <String>[];
  for (final (from, to) in _transitions) {
    await FoldableSurfaces.resizeTo(tester, to, pumpOnly: pumpOnly);
    final exception = tester.takeException();
    if (exception != null) {
      failures.add('${_label(from)} -> ${_label(to)}: $exception');
    }
  }
  return failures;
}

/// A branch body with a scroll controller and real [State], so a resize can be
/// asked whether either survived.
class _Probe extends StatefulWidget {
  const _Probe({required this.controller});

  final ScrollController controller;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: widget.controller,
      itemCount: 200,
      itemBuilder: (context, index) =>
          SizedBox(height: 48, child: Text('row $index')),
    );
  }
}

/// Pumps [AppShell] over a real `StatefulShellRoute` whose `/discover` branch
/// is a scrollable [_Probe].
Future<void> _pumpShell(WidgetTester tester, _Probe probe) async {
  final prefs = await testAppPreferences;
  final router = GoRouter(
    initialLocation: '/discover',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(navigationShell: shell),
        branches: [
          for (final path in [
            '/discover',
            '/tab2',
            '/swipe',
            '/chats',
            '/profile',
          ])
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: path,
                  builder: (_, _) =>
                      path == '/discover' ? probe : const SizedBox.shrink(),
                ),
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
}

/// Serves the two requests `DiscoverPage` makes on mount, so the page reaches
/// its loaded state (a shimmer skeleton never settles and would swallow the
/// layout signal).
class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter();

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final Object data = switch (options.path) {
      '/properties' => {
        'items': List.generate(8, _listingJson),
        'next_cursor': null,
        'has_more': false,
      },
      '/flatmates/profiles' => {
        'items': <dynamic>[],
        'next_cursor': null,
        'has_more': false,
      },
      _ => <String, dynamic>{},
    };
    return ResponseBody.fromString(
      jsonEncode(data),
      200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }
}

Map<String, dynamic> _listingJson(int index) => {
  'id': index + 1,
  'owner_id': 100 + index,
  'property_type': 'flatmate',
  'title': 'Listing ${index + 1}',
  'city': 'Bangalore',
  'state': 'Karnataka',
  'locality': 'Koramangala',
  'latitude': 12.9352,
  'longitude': 77.6245,
  'monthly_rent': 20000.0,
  'main_image_url': 'https://example.com/photo$index.jpg',
  'image_urls': ['https://example.com/photo$index.jpg'],
  'bedrooms': 2,
  'bathrooms': 2,
  'area_sqft': 1000.0,
  'features': ['wifi'],
  'available_from': '2025-06-01T00:00:00Z',
  'status': 'live',
  'interest_count': 5,
  'view_count': 100,
  'like_count': 10,
  'is_available': true,
  'listing_preferences': {
    'sharing_type': 'private_room',
    'gender_preference': 'any',
  },
  'owner': {
    'id': 100 + index,
    'full_name': 'Owner $index',
    'mode': 'room_poster',
  },
  'created_at': '2025-05-01T10:00:00Z',
};

/// A [LocationController] with a fixed location and no platform channels, so
/// the page does not touch GPS or the network for its location.
class _FixedLocationController extends LocationController {
  @override
  LocationState build() => const LocationState(
    selectedLocation: LocationData(
      name: 'Koramangala, Bangalore',
      latitude: 12.9352,
      longitude: 77.6245,
    ),
  );

  @override
  Future<void> getCurrentLocation({bool forceRefresh = false}) async {}

  @override
  void selectLocation(LocationData location) {}

  @override
  Future<void> selectAndPersistLocation(LocationData location) async {}
}

Future<void> _pumpDiscover(WidgetTester tester) async {
  final apiClient = ApiClient(
    baseUrl: 'https://api.test.example.com',
    tokenProvider: FakeAuthTokenProvider(),
  );
  apiClient.dio.httpClientAdapter = _ScriptedAdapter();

  await tester.pumpWidget(
    await testableWidgetAsync(
      overrides: [
        apiClientProvider.overrideWithValue(apiClient),
        locationControllerProvider.overrideWith(
          () => _FixedLocationController(),
        ),
      ],
      child: const DiscoverPage(),
    ),
  );
  // Fixed pumps rather than `pumpAndSettle`: the skeleton shimmer never
  // settles, so settling would time out instead of reporting a layout error.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('AppShell survives a live fold / unfold', () {
    testWidgets('every transition lays out without an exception', (
      tester,
    ) async {
      FoldableSurfaces.useSurface(tester, _transitions.first.$1);
      await _pumpShell(tester, _Probe(controller: ScrollController()));

      final failures = await _walkTransitions(tester);
      expect(failures, isEmpty, reason: failures.join('\n'));
    });

    testWidgets('the chrome really does swap, so the walk is not vacuous', (
      tester,
    ) async {
      FoldableSurfaces.useSurface(tester, FoldableSurfaces.foldedPortrait);
      await _pumpShell(tester, _Probe(controller: ScrollController()));

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);

      await FoldableSurfaces.resizeTo(tester, FoldableSurfaces.openLandscape);

      // The rail swap during a live resize is the riskiest transition in the
      // app: a bottom bar and a rail are different widget types in different
      // slots of the Scaffold.
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the branch page keeps its State and its scroll offset', (
      tester,
    ) async {
      FoldableSurfaces.useSurface(tester, FoldableSurfaces.foldedPortrait);
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await _pumpShell(tester, _Probe(controller: controller));

      final stateBefore = tester.state<_ProbeState>(find.byType(_Probe));
      await tester.drag(find.byType(_Probe), const Offset(0, -600));
      await tester.pumpAndSettle();
      final offsetBefore = controller.offset;
      expect(
        offsetBefore,
        greaterThan(0),
        reason: 'the probe must actually be scrolled for this test to bite',
      );

      // Folded portrait -> open landscape crosses 900 dp, so the shell swaps
      // the bottom bar for the rail and re-parents the branch subtree.
      await FoldableSurfaces.resizeTo(tester, FoldableSurfaces.openLandscape);
      expect(tester.takeException(), isNull);

      expect(
        identical(tester.state<_ProbeState>(find.byType(_Probe)), stateBefore),
        isTrue,
        reason: 'the branch page was remounted by the rail swap',
      );
      expect(
        controller.offset,
        offsetBefore,
        reason: 'the scroll position did not survive the rail swap',
      );

      // …and back again, which is the transition a user hits most often.
      await FoldableSurfaces.resizeTo(tester, FoldableSurfaces.foldedPortrait);
      expect(tester.takeException(), isNull);
      expect(
        identical(tester.state<_ProbeState>(find.byType(_Probe)), stateBefore),
        isTrue,
        reason: 'the branch page was remounted on the way back to folded',
      );
      expect(controller.offset, offsetBefore);
    });
  });

  group('FlatmatesScreen survives a live fold / unfold', () {
    /// The reading column plus the `LayoutBuilder` that computes `minHeight`:
    /// the scrollable branch is where the 720 dp cap changes the shape of the
    /// element tree underneath the scroll view.
    Future<ScrollController> pumpScrollable(WidgetTester tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.build(brightness: Brightness.light),
          home: FlatmatesScreen(
            scrollable: true,
            scrollController: controller,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < 120; i++)
                  SizedBox(height: 48, child: Text('row $i')),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return controller;
    }

    testWidgets('every transition lays out without an exception', (
      tester,
    ) async {
      FoldableSurfaces.useSurface(tester, _transitions.first.$1);
      await pumpScrollable(tester);

      final failures = await _walkTransitions(tester);
      expect(failures, isEmpty, reason: failures.join('\n'));
    });

    testWidgets('the LayoutBuilder minHeight tracks the new viewport height', (
      tester,
    ) async {
      FoldableSurfaces.useSurface(tester, FoldableSurfaces.foldedPortrait);
      const probeKey = Key('duo_min_height_probe');
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.build(brightness: Brightness.light),
          home: const FlatmatesScreen(
            scrollable: true,
            // `width: double.infinity` so the probe fills the column; the
            // explicit height is stretched up to the branch's minHeight.
            body: SizedBox(key: probeKey, width: double.infinity, height: 10),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The default padding is `AppSpacing.horizontalScreen`, so there is no
      // vertical padding and minHeight is the full viewport height.
      for (final size in [
        FoldableSurfaces.foldedPortrait,
        FoldableSurfaces.openPortrait,
        FoldableSurfaces.foldedLandscape,
        FoldableSurfaces.openLandscape,
      ]) {
        await FoldableSurfaces.resizeTo(tester, size);
        expect(tester.takeException(), isNull);
        expect(
          tester.getSize(find.byKey(probeKey)).height,
          size.height,
          reason: 'minHeight did not follow the resize to ${_label(size)}',
        );
      }
    });

    testWidgets('a page taller than the viewport still scrolls after a fold', (
      tester,
    ) async {
      FoldableSurfaces.useSurface(tester, FoldableSurfaces.foldedPortrait);
      final controller = await pumpScrollable(tester);

      await FoldableSurfaces.resizeTo(tester, FoldableSurfaces.openLandscape);
      expect(tester.takeException(), isNull);

      final scrollable = find.byType(Scrollable).first;
      expect(scrollable, findsOneWidget);
      // Scrolling after the resize must still work, which proves the viewport
      // was re-laid-out against the new height rather than left at the old
      // one (669 dp is shorter than 678 dp).
      await tester.drag(scrollable, const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(controller.offset, greaterThan(0));
      expect(tester.takeException(), isNull);
    });

    testWidgets('the scroll offset survives a fold inside the reading column', (
      tester,
    ) async {
      FoldableSurfaces.useSurface(tester, FoldableSurfaces.foldedPortrait);
      final controller = await pumpScrollable(tester);

      await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
      await tester.pumpAndSettle();
      final offsetBefore = controller.offset;
      expect(offsetBefore, greaterThan(0));

      // 466 -> 669 and 669 -> 678 both stay below the 720 dp cap, so the
      // LayoutBuilder in `_capped` hands its child straight through and the
      // element tree keeps its shape.
      for (final size in [
        FoldableSurfaces.openPortrait,
        FoldableSurfaces.foldedLandscape,
      ]) {
        await FoldableSurfaces.resizeTo(tester, size);
        expect(tester.takeException(), isNull);
        expect(
          controller.offset,
          offsetBefore,
          reason: 'the scroll position did not survive the resize to $size',
        );
      }
    });

    testWidgets('the reading-column cap keeps the scroll position', (
      tester,
    ) async {
      FoldableSurfaces.useSurface(tester, FoldableSurfaces.foldedPortrait);
      final controller = await pumpScrollable(tester);

      await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(controller.offset, greaterThan(0));
      final offsetBefore = controller.offset;

      // `FlatmatesScreen._capped` keeps one widget type in both branches and
      // applies the cap as a `maxWidth` constraint, so crossing the cap does
      // not swap the element at that slot.
      //
      // This used to be a defect: the uncapped branch returned the scroll view
      // directly and the capped branch wrapped it in `Align > SizedBox`, so
      // unfolding into landscape deactivated the scroll view's element,
      // inflated a new one, and dropped the offset to 0 — the reader lost
      // their place in the feed. This assertion is what caught it.
      await FoldableSurfaces.resizeTo(tester, FoldableSurfaces.openLandscape);
      expect(tester.takeException(), isNull);
      expect(
        controller.offset,
        offsetBefore,
        reason: 'unfolding past the reading-column cap must not reset scroll',
      );
    });
  });

  group('DiscoverPage (width-derived grid) survives a live fold / unfold', () {
    testWidgets('every transition lays out without an exception', (
      tester,
    ) async {
      FoldableSurfaces.useSurface(tester, _transitions.first.$1);
      await _pumpDiscover(tester);

      // `pumpOnly` throughout: the feed's shimmer skeletons animate forever,
      // so `pumpAndSettle` would time out rather than report a layout error.
      final failures = await _walkTransitions(tester, pumpOnly: true);
      expect(failures, isEmpty, reason: failures.join('\n'));
    });

    testWidgets('the "Picked for you" grid re-derives its column count', (
      tester,
    ) async {
      FoldableSurfaces.useSurface(tester, FoldableSurfaces.foldedPortrait);
      await _pumpDiscover(tester);

      // `AppBreakpoints.cardGridColumns`: 2 below 600 dp, 3 from 600, 4 from
      // 900. The card is an `Expanded` in a Row, so its width is the whole
      // observable of the column count:
      //   (width - 2 * 16 gutter - (columns - 1) * 12 gap) / columns
      // with the 720 dp reading column capping the 951 dp pose.
      const expectations = <(Size, int, double)>[
        (FoldableSurfaces.foldedPortrait, 2, 211),
        (FoldableSurfaces.openPortrait, 3, 204.33),
        (FoldableSurfaces.foldedLandscape, 3, 207.33),
        (FoldableSurfaces.openLandscape, 4, 163),
      ];

      for (final (size, columns, cardWidth) in expectations) {
        await FoldableSurfaces.resizeTo(tester, size, pumpOnly: true);
        expect(tester.takeException(), isNull);

        final card = find.byKey(const Key('discover_feed_card_0'));
        expect(card, findsOneWidget);
        expect(
          tester.getSize(card).width,
          closeTo(cardWidth, 0.5),
          reason:
              'at ${_label(size)} the grid should use $columns columns '
              '($cardWidth dp cards)',
        );
      }
    });
  });
}
