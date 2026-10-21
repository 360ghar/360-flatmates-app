import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flatmates_app/core/location/location_data.dart';
import 'package:flatmates_app/core/network/api_client.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/features/auth/presentation/enter_phone_page.dart';
import 'package:flatmates_app/features/auth/presentation/splash_page.dart';
import 'package:flatmates_app/features/chats/chats_repository.dart';
import 'package:flatmates_app/features/discover/discover_repository.dart';
import 'package:flatmates_app/features/discover/domain/property_listing.dart';
import 'package:flatmates_app/features/discover/flat_details_page.dart';
import 'package:flatmates_app/features/discover/map_view_page.dart';
import 'package:flatmates_app/features/discover/presentation/widgets/flat_details_about.dart';
import 'package:flatmates_app/features/location/application/location_controller.dart';
import 'package:flatmates_app/features/location/presentation/map_widgets.dart';
import 'package:flatmates_app/features/shared/presentation/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/foldable_surfaces.dart';
import '../../helpers/test_helpers.dart';

/// Asserts that every page keeps its content inside the surface, with the
/// Duo's measured safe area applied.
///
/// ## What this file used to claim, and why it changed
///
/// This file was written on the premise that the Duo puts its status bar on the
/// **right edge**, giving every pose an 84 pt right inset and nothing on top.
/// **That premise is false.** Measured on the booted simulator, the device
/// reports `padding: EdgeInsets(0.0, 82.0, 0.0, 34.0)` — the inset is 82 pt on
/// **top**, and there is none on the right. Apple's own Settings app draws the
/// same horizontal top-right status bar the app does.
///
/// So the right-edge assertions here are now weaker than they look: with
/// `FoldableSurfaces.rightInset` measured at zero, "content stays left of the
/// safe edge" reduces to "content does not overflow the screen". That is still a
/// real invariant worth pinning, so the file stays — but it is **not** the
/// inset test the name suggests. The inset test that catches the real bug is
/// the top-edge one in `safe_area_duo_test.dart`.
///
/// ## Why the pages still get asserted at three poses
///
/// `FlatmatesScreen` caps its body at a 720 dp reading column and centres it,
/// so at 951 dp content ends at 115.5 + 720 = 835.5 dp — nowhere near the
/// surface edge. The narrow poses are where a page that sizes from the raw
/// viewport width shows up, so all three are kept.
///
/// ## Scope
///
/// Integration-level: the real pages, pumped with the repo's `testableWidget*`
/// harnesses with `MediaQueryData(padding: FoldableSurfaces.duoSafeArea)`
/// injected below `MaterialApp`. Each page gets its own test so one failure
/// cannot hide another. Failing tests are reported, never softened, and nothing
/// under `lib/` is edited to make one pass.

/// One page under test: how to pump it, and which on-screen widgets carry its
/// reading content.
///
/// The finders are lazy, so building them up front is safe — they resolve
/// against whatever tree exists when they are evaluated.
typedef _PageCase = ({
  String name,
  Future<void> Function(WidgetTester tester, Size pose) pump,
  List<({String label, Finder finder, bool required})> content,
});

String _poseLabel(Size pose) => '${pose.width.toInt()}x${pose.height.toInt()}';

/// Asserts every match of every content finder ends at or before the pose's
/// safe right edge.
///
/// The maximum right edge is what matters, not the first match: a page can
/// legitimately hold several instances of the same widget, and only the
/// rightmost can violate the inset. `tester.getRect` requires exactly one
/// match, so the rectangles are walked directly.
///
/// A probe marked `required: false` is only checked when it is on screen — a
/// short viewport can leave a lazily-built list child unbuilt, and "not
/// rendered" is not a layout violation. The `seen` check below keeps that from
/// turning the whole assertion vacuous.
void _assertPageClearOfRightInset(
  WidgetTester tester,
  _PageCase page,
  Size pose,
) {
  final safeRight = FoldableSurfaces.safeRightEdgeFor(pose);
  final offenders = <String>[];
  final seen = <String>[];

  for (final probe in page.content) {
    final matches = probe.finder.evaluate().toList();
    if (probe.required) {
      expect(
        matches,
        isNotEmpty,
        reason:
            '${page.name}: ${probe.label} is not on screen at '
            '${_poseLabel(pose)}, so the assertion would be vacuous',
      );
    }
    for (final element in matches) {
      final renderObject = element.renderObject;
      if (renderObject is! RenderBox || !renderObject.hasSize) continue;
      final rect = renderObject.localToGlobal(Offset.zero) & renderObject.size;
      seen.add('${probe.label} right=${rect.right.toStringAsFixed(1)}');
      if (rect.right > safeRight + 0.01) {
        offenders.add(
          '${page.name} / ${probe.label}: right edge '
          '${rect.right.toStringAsFixed(1)} dp, which is '
          '${(rect.right - safeRight).toStringAsFixed(1)} dp under the '
          'status bar',
        );
      }
    }
  }

  expect(
    seen,
    isNotEmpty,
    reason:
        '${page.name}: no content widget at ${_poseLabel(pose)} had a '
        'laid-out RenderBox, so nothing was actually asserted',
  );
  expect(
    offenders,
    isEmpty,
    reason:
        'content is laid out under the Duo status bar at ${_poseLabel(pose)} '
        '(84 dp right inset, safe edge $safeRight dp):\n${offenders.join('\n')}',
  );
}

// ---------------------------------------------------------------------------
// Page harnesses
// ---------------------------------------------------------------------------

Future<void> _pumpEnterPhone(WidgetTester tester, Size pose) async {
  await tester.pumpWidget(
    await testableWidgetAsync(
      child: MediaQuery(
        data: FoldableSurfaces.mediaQueryFor(pose),
        child: const EnterPhonePage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpSplash(WidgetTester tester, Size pose) async {
  await tester.pumpWidget(
    await testableWidgetAsync(
      child: MediaQuery(
        data: FoldableSurfaces.mediaQueryFor(pose),
        child: const SplashPage(),
      ),
    ),
  );
  // Past the 800 ms stagger without `pumpAndSettle`: the indeterminate
  // progress indicator never settles.
  await tester.pump(const Duration(milliseconds: 1200));
}

class _ScriptedAdapter implements HttpClientAdapter {
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

/// Fixed location and no platform channels: the map page must not reach GPS.
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

Future<void> _pumpMap(WidgetTester tester, Size pose) async {
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
      child: MediaQuery(
        data: FoldableSurfaces.mediaQueryFor(pose),
        child: const MapViewPage(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 600));
}

const PropertyListing _listing = PropertyListing(
  id: 1,
  ownerId: 101,
  propertyType: 'flatmate',
  title: 'Listing 1',
  description: 'A flat',
  city: 'Bangalore',
  state: 'Karnataka',
  locality: 'Koramangala',
  subLocality: '5th Block',
  latitude: 12.9352,
  longitude: 77.6245,
  monthlyRent: 24000,
  mainImageUrl: 'https://example.com/photo-1.jpg',
  imageUrls: ['https://example.com/photo-1-0.jpg'],
  areaSqft: 1200,
  bedrooms: 2,
  bathrooms: 2,
  features: ['wifi'],
  tags: [],
  ownerName: 'Owner 1',
  availableFrom: null,
  genderPreference: 'any',
  sharingType: 'private_room',
  interestCount: 0,
  viewCount: 0,
  likeCount: 0,
  isAvailable: true,
);

Future<void> _pumpFlatDetails(WidgetTester tester, Size pose) async {
  await tester.pumpWidget(
    testableWidget(
      overrides: [
        // The owner sheet's match percentage is irrelevant here.
        peerProfileProvider.overrideWith((ref, userId) async => null),
      ],
      child: MediaQuery(
        data: FoldableSurfaces.mediaQueryFor(pose),
        child: const FlatDetailsPage(listingId: 1, seededListing: _listing),
      ),
    ),
  );
  // Network photos never complete in the test environment, so settle with
  // fixed pumps instead of `pumpAndSettle`.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 600));
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const geolocatorChannels = [
    'flutter.baseflow.com/geolocator',
    'flutter.baseflow.com/geolocator_apple',
    'flutter.baseflow.com/geolocator_android',
  ];
  const geocodingChannel = 'flutter.baseflow.com/geocoding';

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetTestAppPreferences();

    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final name in geolocatorChannels) {
      messenger.setMockMethodCallHandler(MethodChannel(name), (call) async {
        return call.method == 'isLocationServiceEnabled' ? false : null;
      });
    }
    messenger.setMockMethodCallHandler(
      const MethodChannel(geocodingChannel),
      (call) async => <dynamic>[],
    );
  });

  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final name in geolocatorChannels) {
      messenger.setMockMethodCallHandler(MethodChannel(name), null);
    }
    messenger.setMockMethodCallHandler(
      const MethodChannel(geocodingChannel),
      null,
    );
  });

  final pages = <_PageCase>[
    (
      name: 'EnterPhonePage',
      pump: _pumpEnterPhone,
      content: [
        // `useSafeArea: false` + `padding: EdgeInsets.zero`, so the page owns
        // its own gutters: the card and the CTA are where the inset shows up.
        (
          label: 'identifier card',
          finder: find.byType(FlatmatesCard),
          required: true,
        ),
        (
          label: 'continue CTA',
          finder: find.byKey(const Key('enter_phone_continue_cta')),
          required: true,
        ),
      ],
    ),
    (
      name: 'SplashPage',
      pump: _pumpSplash,
      content: [
        (label: 'logo', finder: find.byType(FlatmatesLogo), required: true),
        (
          label: 'progress strip',
          finder: find.byType(LinearProgressIndicator),
          required: true,
        ),
      ],
    ),
    (
      name: 'MapViewPage',
      pump: _pumpMap,
      content: [
        (
          label: 'map control buttons',
          finder: find.byType(MapControlButtons),
          required: true,
        ),
        (
          label: 'top-bar filter button',
          finder: find.byType(FlatmatesChromeIconButton),
          required: true,
        ),
      ],
    ),
    (
      name: 'FlatDetailsPage',
      pump: _pumpFlatDetails,
      content: [
        // The card surfaces are deliberately full-bleed (a paper layer spans
        // the viewport), so the assertion is on the *text* they paint: no
        // glyph may sit under the status bar. Optional because a short
        // viewport leaves the about card below the lazy ListView's built
        // range.
        (
          label: 'about card text',
          finder: find.descendant(
            of: find.byType(FlatDetailsAbout),
            matching: find.byType(Text),
          ),
          required: false,
        ),
        (
          label: 'bottom action bar CTA',
          finder: find.byKey(const Key('flat_contact_button')),
          required: true,
        ),
      ],
    ),
  ];

  // The poses where the 84 dp inset actually bites: nothing caps the width, so
  // a page that hand-rolls its insets runs its content under the status bar.
  for (final pose in [
    FoldableSurfaces.openPortrait,
    FoldableSurfaces.foldedPortrait,
  ]) {
    group('right inset is respected at ${_poseLabel(pose)}', () {
      for (final page in pages) {
        testWidgets(page.name, (tester) async {
          FoldableSurfaces.useSurface(tester, pose);
          await page.pump(tester, pose);
          expect(tester.takeException(), isNull);
          _assertPageClearOfRightInset(tester, page, pose);
        });
      }
    });
  }

  // Control: the same pages at the widest pose. The 720 dp reading column
  // already ends 115.5 dp from the right edge, so a page that ignores the inset
  // still passes here — which is exactly how the bug survives. A failure in
  // this group means the page ignores the reading column too.
  group('reading column masks the inset at '
      '${_poseLabel(FoldableSurfaces.openLandscape)}', () {
    for (final page in pages) {
      testWidgets(page.name, (tester) async {
        FoldableSurfaces.useSurface(tester, FoldableSurfaces.openLandscape);
        await page.pump(tester, FoldableSurfaces.openLandscape);
        expect(tester.takeException(), isNull);
        _assertPageClearOfRightInset(
          tester,
          page,
          FoldableSurfaces.openLandscape,
        );
      });
    }
  });

  testWidgets('the injected MediaQuery reaches the page (non-vacuous)', (
    tester,
  ) async {
    FoldableSurfaces.useSurface(tester, FoldableSurfaces.openPortrait);
    double? seenRight;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: FoldableSurfaces.mediaQueryFor(FoldableSurfaces.openPortrait),
          child: Builder(
            builder: (context) {
              seenRight = MediaQuery.paddingOf(context).right;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    expect(seenRight, FoldableSurfaces.rightInset);

    // The arithmetic the control group rests on: at 951 dp the centred 720 dp
    // reading column ends at 835.5 dp, left of the 867 dp safe edge.
    final columnRight = (FoldableSurfaces.openLandscape.width - 720) / 2 + 720;
    expect(
      columnRight,
      lessThan(
        FoldableSurfaces.safeRightEdgeFor(FoldableSurfaces.openLandscape),
      ),
    );
    expect(
      columnRight,
      greaterThan(
        FoldableSurfaces.safeRightEdgeFor(FoldableSurfaces.openPortrait),
      ),
    );
  });
}
