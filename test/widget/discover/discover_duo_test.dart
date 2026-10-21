import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flatmates_app/core/network/api_client.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/core/theme/app_breakpoints.dart';
import 'package:flatmates_app/core/theme/app_spacing.dart';
import 'package:flatmates_app/features/discover/discover_repository.dart';
import 'package:flatmates_app/features/discover/flat_details_page.dart';
import 'package:flatmates_app/features/discover/map_view_page.dart';
import 'package:flatmates_app/features/discover/presentation/widgets/browse_listings_card.dart';
import 'package:flatmates_app/features/discover/presentation/widgets/details_media_band.dart';
import 'package:flatmates_app/features/discover/presentation/widgets/discover_listing_card.dart';
import 'package:flatmates_app/features/discover/presentation/widgets/flat_details_carousel.dart';
import 'package:flatmates_app/features/discover/presentation/widgets/flat_details_location.dart';
import 'package:flatmates_app/features/discover/presentation/widgets/map_listings_bottom_sheet.dart';
import 'package:flatmates_app/features/discover/presentation/widgets/map_top_bar.dart';
import 'package:flatmates_app/features/location/presentation/map_widgets.dart';
import 'package:flatmates_app/features/shared/presentation/components.dart';
import 'package:flatmates_app/features/shared/presentation/skeleton/variants/browse_listings_skeleton.dart';
import 'package:flatmates_app/features/shared/presentation/skeleton/variants/discover_feed_skeleton.dart';
import 'package:flatmates_app/l10n/gen/app_localizations.dart';

import '../../helpers/foldable_surfaces.dart';
import '../../helpers/test_helpers.dart';

/// The open Duo's page width: 951 dp minus the shell's 96 dp rail.
const _openDuoPageWidth = 951 - FoldableSurfaces.railWidth;

PropertyListing _listing({
  int id = 1,
  int? ownerId = 2,
  String? locality = 'Koramangala',
  int? bedrooms,
  int? bathrooms,
  double? areaSqft,
  List<String> imageUrls = const [],
}) => PropertyListing(
  id: id,
  ownerId: ownerId,
  propertyType: 'flatmate',
  title: 'Modern 2BHK',
  description: 'A beautiful flat',
  city: 'Bangalore',
  state: 'Karnataka',
  locality: locality,
  subLocality: '5th Block',
  latitude: 12.9352,
  longitude: 77.6245,
  monthlyRent: 24000,
  mainImageUrl: null,
  imageUrls: imageUrls,
  areaSqft: areaSqft,
  bedrooms: bedrooms,
  bathrooms: bathrooms,
  features: const ['wifi'],
  tags: const [],
  ownerName: 'Rahul',
  availableFrom: null,
  genderPreference: 'any',
  sharingType: 'private_room',
  interestCount: 10,
  viewCount: 3800,
  likeCount: 24,
  isAvailable: true,
);

/// The floor plan / map band the details page puts under the hero.
Widget _detailsSection(Widget child) => MaterialApp(
  locale: const Locale('en'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetTestAppPreferences();

    // Real plugins cannot answer in a widget test: an unhandled platform
    // channel message never completes, which would hang the location path.
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final name in _geolocatorChannels) {
      messenger.setMockMethodCallHandler(MethodChannel(name), (call) async {
        return call.method == 'isLocationServiceEnabled' ? false : null;
      });
    }
    messenger.setMockMethodCallHandler(
      const MethodChannel(_geocodingChannel),
      (call) async => <dynamic>[],
    );
  });

  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final name in _geolocatorChannels) {
      messenger.setMockMethodCallHandler(MethodChannel(name), null);
    }
    messenger.setMockMethodCallHandler(
      const MethodChannel(_geocodingChannel),
      null,
    );
  });

  // -------------------------------------------------------------------------
  // Task 2 — the video tour player cannot exceed a sane height.
  // -------------------------------------------------------------------------
  group('FlatmatesVideoTourPlayer', () {
    Future<void> pumpPlayer(WidgetTester tester, Size size) async {
      FoldableSurfaces.useSurface(tester, size);
      await tester.pumpWidget(
        testableWidget(
          child: MediaQuery(
            data: FoldableSurfaces.mediaQueryFor(size),
            child: const Scaffold(
              body: SingleChildScrollView(
                child: FlatmatesVideoTourPlayer(
                  videoUrl: 'https://cdn.example.com/tour.mp4',
                ),
              ),
            ),
          ),
        ),
      );
      // No video platform in a widget test, so the player settles into its
      // 9:16 fallback frame — the worst case for the height cap.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }

    for (final size in [
      const Size(466, 678),
      const Size(669, 951),
      const Size(951, 669),
    ]) {
      testWidgets('a portrait tour fits ${size.width.toInt()} x '
          '${size.height.toInt()}', (tester) async {
        await pumpPlayer(tester, size);

        final frame = find.descendant(
          of: find.byType(FlatmatesVideoTourPlayer),
          matching: find.byType(AspectRatio),
        );
        expect(frame, findsOneWidget);

        final frameSize = tester.getSize(frame);
        expect(
          frameSize.height,
          lessThanOrEqualTo(size.height * kVideoTourMaxViewportFraction + 0.5),
          reason: 'a 9:16 frame must not run past the viewport',
        );
        expect(frameSize.height, lessThanOrEqualTo(size.height));
        expect(frameSize.width / frameSize.height, closeTo(9 / 16, 0.001));

        // The narrower frame is centred in the card, not pinned left.
        final frameCentre = tester.getCenter(frame).dx;
        final cardCentre = tester
            .getCenter(find.byType(FlatmatesVideoTourPlayer))
            .dx;
        expect(frameCentre, closeTo(cardCentre, 0.5));
      });
    }

    testWidgets('the loading and error states stay centred in the frame', (
      tester,
    ) async {
      const size = Size(951, 669);
      FoldableSurfaces.useSurface(tester, size);
      await tester.pumpWidget(
        testableWidget(
          child: MediaQuery(
            data: FoldableSurfaces.mediaQueryFor(size),
            child: const Scaffold(
              body: SingleChildScrollView(
                child: FlatmatesVideoTourPlayer(
                  videoUrl: 'https://cdn.example.com/tour.mp4',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final frame = find.descendant(
        of: find.byType(FlatmatesVideoTourPlayer),
        matching: find.byType(AspectRatio),
      );
      final frameCentre = tester.getCenter(frame);

      final placeholder = find.descendant(
        of: frame,
        matching: find.byWidgetPredicate(
          (w) => w is CircularProgressIndicator || w is Icon,
        ),
      );
      expect(placeholder, findsWidgets);
      expect(
        tester.getCenter(placeholder.first).dx,
        closeTo(frameCentre.dx, 1),
      );
      expect(
        tester.getCenter(placeholder.first).dy,
        closeTo(frameCentre.dy, 1),
      );
    });
  });

  // -------------------------------------------------------------------------
  // Task 3 — the browse row adapts to the reading column.
  // -------------------------------------------------------------------------
  group('BrowseListingsCard', () {
    test('the thumbnail grows with the viewport, 110 dp on a phone', () {
      expect(AppBreakpoints.browseThumbSize(320), 110);
      expect(AppBreakpoints.browseThumbSize(466), 110);
      expect(AppBreakpoints.browseThumbSize(599), 110);
      expect(AppBreakpoints.browseThumbSize(AppBreakpoints.medium), 140);
      expect(AppBreakpoints.browseThumbSize(669), 140);
      expect(AppBreakpoints.browseThumbSize(AppBreakpoints.expanded), 160);
      expect(AppBreakpoints.browseThumbSize(951), 160);
    });

    testWidgets('renders without overflow at every Duo pose', (tester) async {
      for (final width in [466.0, 669.0, 951.0]) {
        FoldableSurfaces.useSurface(tester, Size(width, 678));
        await tester.pumpWidget(
          testableWidget(
            child: MediaQuery(
              data: FoldableSurfaces.mediaQueryFor(Size(width, 678)),
              child: Scaffold(
                body: Padding(
                  padding: AppSpacing.horizontalScreen,
                  child: BrowseListingsCard(item: _listing(), index: 0),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull, reason: '$width');
        expect(find.byType(BrowseListingsCard), findsOneWidget);
      }
    });

    testWidgets('the skeleton reserves the row the loaded card draws', (
      tester,
    ) async {
      // Regression guard. `BrowseListingsSkeleton` hard-coded a 110 dp row and
      // a 110 dp image bone while the loaded card grew its thumb with the
      // viewport, so from 600 dp the skeleton under-reserved by 30 dp and from
      // 900 dp by 50 dp — the list jumped the moment data arrived, which is
      // the reflow the skeleton exists to prevent (DESIGN.md §8).
      for (final width in [466.0, 669.0, 951.0]) {
        final size = Size(width, 800);
        FoldableSurfaces.useSurface(tester, size);

        Future<double> skeletonRowHeight() async {
          await tester.pumpWidget(
            testableWidget(
              child: MediaQuery(
                data: FoldableSurfaces.mediaQueryFor(size),
                child: const Scaffold(body: BrowseListingsSkeleton()),
              ),
            ),
          );
          await tester.pump();
          expect(tester.takeException(), isNull, reason: 'skeleton at $width');
          return tester.getSize(find.byType(Row).first).height;
        }

        Future<double> cardRowHeight() async {
          await tester.pumpWidget(
            testableWidget(
              child: MediaQuery(
                data: FoldableSurfaces.mediaQueryFor(size),
                child: Scaffold(
                  body: Padding(
                    padding: AppSpacing.horizontalScreen,
                    child: BrowseListingsCard(item: _listing(), index: 0),
                  ),
                ),
              ),
            ),
          );
          await tester.pump();
          expect(tester.takeException(), isNull, reason: 'card at $width');
          return tester.getSize(find.byType(Row).first).height;
        }

        final skeleton = await skeletonRowHeight();
        final card = await cardRowHeight();

        expect(
          skeleton,
          card,
          reason:
              'at $width the skeleton row must match the loaded card row '
              '(thumb ${AppBreakpoints.browseThumbSize(width)})',
        );
        expect(skeleton, AppBreakpoints.browseThumbSize(width));
      }
    });
  });

  // -------------------------------------------------------------------------
  // Task 5 — the framed media bands follow the content column.
  // -------------------------------------------------------------------------
  group('details media band', () {
    test('the phone band is untouched', () {
      // 466 - 2 * 16 gutter = 434, the band the phone layout always had.
      expect(detailsMediaBandHeight(434), 220);
    });

    test('the band grows with the reading column, capped at 360', () {
      expect(detailsMediaBandHeight(688), closeTo(348.7, 0.1));
      expect(detailsMediaBandHeight(688), greaterThan(220));
      expect(detailsMediaBandHeight(2000), 360);
    });
  });

  // -------------------------------------------------------------------------
  // Task 6 — the feed skeleton reserves the loaded card's footprint.
  // -------------------------------------------------------------------------
  group('discover feed skeleton', () {
    // (viewport, the width the page body actually gets, the column count
    // `cardGridColumns` picks for that viewport). The last case is the open
    // Duo: a 951 dp viewport, 4 columns, inside the 720 dp reading column.
    const cases = <(Size, double, int)>[
      (Size(466, 800), 466, 2),
      (Size(669, 800), 669, 3),
      (Size(951, 669), AppBreakpoints.readingColumn, 4),
    ];

    Future<void> pumpAt(
      WidgetTester tester,
      Size mediaSize,
      double body,
    ) async {
      FoldableSurfaces.useSurface(tester, mediaSize);
      await tester.pumpWidget(
        testableWidget(
          child: MediaQuery(
            data: FoldableSurfaces.mediaQueryFor(mediaSize),
            child: Scaffold(
              body: Align(
                alignment: Alignment.topCenter,
                // Width only: a tight height would stretch the skeleton row to
                // the viewport and hide the bug this test is for.
                child: SizedBox(
                  width: body,
                  child: const Padding(
                    padding: AppSpacing.horizontalScreen,
                    child: FlatmatesSkeleton.discoverFeedCards(),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      // The shimmer never settles; one pump lays it out.
      await tester.pump();
    }

    double cardWidthFor(double body, int columns) =>
        (body - AppSpacing.screen * 2 - (columns - 1) * AppSpacing.md) /
        columns;

    for (final (mediaSize, body, expectedColumns) in cases) {
      final cardWidth = cardWidthFor(body, expectedColumns);
      final label = '${mediaSize.width.toInt()} dp / $body body';

      testWidgets('$label reserves a $expectedColumns-column card', (
        tester,
      ) async {
        await pumpAt(tester, mediaSize, body);

        final row = find.byType(Row).first;
        final cards = find.descendant(
          of: find.byType(DiscoverFeedCardsSkeleton),
          matching: find.byType(AspectRatio),
        );
        expect(cards, findsNWidgets(expectedColumns));
        expect(
          AppBreakpoints.cardGridColumns(mediaSize.width),
          expectedColumns,
          reason: 'the loaded grid uses the same column count',
        );

        // The placeholder photo is 1:1 like the loaded card's, so the image
        // bone is the size the photo will be.
        final photoSize = tester.getSize(cards.first);
        expect(photoSize.width, closeTo(cardWidth, 0.01));
        expect(photoSize.height, closeTo(cardWidth, 0.01));

        // The row is the photo plus a text block, not the old fixed 320 that
        // over-reserved it (43 dp too much at 4 columns) and made the page
        // jump when the feed arrived.
        final rowHeight = tester.getSize(row).height;
        expect(rowHeight, greaterThan(cardWidth));
        expect(rowHeight, lessThan(320));
      });

      testWidgets('$label matches the loaded card height', (tester) async {
        await pumpAt(tester, mediaSize, body);
        final skeletonHeight = tester.getSize(find.byType(Row).first).height;

        // A card with a locality, no meta chips and no deposit is the shape the
        // skeleton's text block describes.
        await tester.pumpWidget(
          testableWidget(
            child: MediaQuery(
              data: FoldableSurfaces.mediaQueryFor(mediaSize),
              child: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: cardWidth,
                    child: DiscoverListingCard(item: _listing(), onLike: () {}),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        final loadedHeight = tester
            .getSize(find.byType(DiscoverListingCard))
            .height;

        // The skeleton's text block is a fixed 104 dp; the loaded card's is
        // 98 dp when the rent fits one line and 114 dp when it wraps to two
        // (which it does at the 163 dp card of a 4-column grid). A ~16 dp
        // residual is inherent — the wrap depends on the price string, which
        // the skeleton cannot know — and is bounded here so a future fixed
        // height cannot creep back in.
        expect((loadedHeight - skeletonHeight).abs(), lessThanOrEqualTo(16));
      });
    }
  });

  // -------------------------------------------------------------------------
  // Task 5 — the map carousel keeps the phone's peek count.
  // -------------------------------------------------------------------------
  group('map carousel', () {
    List<PropertyListing> sixListings() => [
      for (var i = 1; i <= 6; i++) _listing(id: i),
    ];

    Future<ScrollController> pumpSheet(
      WidgetTester tester, {
      required Size mediaSize,
      required double listWidth,
    }) async {
      FoldableSurfaces.useSurface(tester, mediaSize);
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        testableWidget(
          child: MediaQuery(
            data: FoldableSurfaces.mediaQueryFor(mediaSize),
            child: Scaffold(
              body: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: listWidth,
                  height: mediaSize.height,
                  child: MapListingsBottomSheet(
                    listings: sixListings(),
                    scrollController: controller,
                    onTap: (_) {},
                    onLike: (_) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      return controller;
    }

    // (MediaQuery size, the width the reading column actually hands the sheet).
    const poses = <(Size, double)>[
      (Size(466, 678), 466),
      (Size(951, 669), _openDuoPageWidth),
    ];

    for (final (mediaSize, listWidth) in poses) {
      testWidgets('shows ~2 cards at ${listWidth.toInt()} dp', (tester) async {
        await pumpSheet(tester, mediaSize: mediaSize, listWidth: listWidth);

        final cardWidth = tester
            .getSize(find.byKey(const Key('map_sheet_card_1')))
            .width;
        final listViewport = tester.getSize(find.byType(ListView)).width;

        // Card slots on screen: the gutters and the inter-card gap are part of
        // the slot, exactly as the phone's 2.26-slot layout is built.
        final slots =
            (listViewport - 2 * kMapCarouselPadding + AppSpacing.sm) /
            (cardWidth + AppSpacing.sm);
        expect(slots, inInclusiveRange(1.5, 2.5), reason: '$listWidth');
      });
    }
    testWidgets('the phone card is untouched, the reading column grows it', (
      tester,
    ) async {
      await pumpSheet(tester, mediaSize: const Size(466, 678), listWidth: 466);
      expect(
        tester.getSize(find.byKey(const Key('map_sheet_card_1'))).width,
        closeTo(kMapCarouselCardWidth, 1e-6),
      );
      expect(mapCarouselCardWidth(466), closeTo(kMapCarouselCardWidth, 1e-6));

      await pumpSheet(
        tester,
        mediaSize: const Size(951, 669),
        listWidth: _openDuoPageWidth,
      );
      final wide = tester
          .getSize(find.byKey(const Key('map_sheet_card_1')))
          .width;
      expect(wide, greaterThan(kMapCarouselCardWidth));
      expect(wide, lessThanOrEqualTo(kMapCarouselCardMaxWidth));

      // The slot height stays coherent with the width: 16:10 image plus the
      // phone's text block.
      final cardHeight = tester
          .getSize(find.byKey(const Key('map_sheet_card_1')))
          .height;
      expect(cardHeight, closeTo(wide * 10 / 16 + 50.5, 1.5));
    });

    testWidgets('the selected card follows the list centre, not the viewport', (
      tester,
    ) async {
      // The open Duo: a 951 dp MediaQuery around a list the reading column
      // caps at 720. The heuristic has to measure the list, not MediaQuery —
      // a MediaQuery centre sits 115 dp to the right, which is more than half
      // a card slot.
      const mediaSize = Size(951, 669);
      final controller = await pumpSheet(
        tester,
        mediaSize: mediaSize,
        listWidth: _openDuoPageWidth,
      );

      final container = ProviderScope.containerOf(
        tester.element(find.byType(MapListingsBottomSheet)),
        listen: false,
      );

      final cardWidth = tester
          .getSize(find.byKey(const Key('map_sheet_card_1')))
          .width;
      final listViewport = tester.getSize(find.byType(ListView)).width;

      // Aim the list centre 1.4 slots in: the nearest card is #2 (index 1).
      // A centre measured against the 951 dp MediaQuery width would land on
      // index 2 instead (1.4 + 115.5 / (cardWidth + 8) = 1.77).
      const targetSlot = 1.4;
      final offset =
          kMapCarouselPadding +
          targetSlot * (cardWidth + AppSpacing.sm) +
          cardWidth / 2 -
          listViewport / 2;
      controller.jumpTo(offset);
      await tester.pump();

      expect(
        container.read(selectedPropertyProvider)?.id,
        2,
        reason: 'the card at the list centre must win, not the MediaQuery one',
      );
    });
  });

  // -------------------------------------------------------------------------
  // Task 7 — the two `useSafeArea: false` pages clear the 84 dp right inset.
  // -------------------------------------------------------------------------
  group('right-edge safe area', () {
    Future<void> pumpMapPage(WidgetTester tester, Size size) async {
      FoldableSurfaces.useSurface(tester, size);

      final apiClient = ApiClient(
        baseUrl: 'https://api.test.example.com',
        tokenProvider: FakeAuthTokenProvider(),
      );
      apiClient.dio.httpClientAdapter = _ScriptedAdapter((options) {
        return Response<dynamic>(
          data: options.path == '/properties'
              ? {'items': <dynamic>[], 'next_cursor': null, 'has_more': false}
              : <String, dynamic>{},
          statusCode: 200,
          requestOptions: options,
        );
      });

      await tester.pumpWidget(
        await testableWidgetAsync(
          overrides: [apiClientProvider.overrideWithValue(apiClient)],
          child: MediaQuery(
            data: FoldableSurfaces.mediaQueryFor(size),
            child: const MapViewPage(),
          ),
        ),
      );
      // The listings fetch and the location probe both have to resolve before
      // the map chrome replaces the page skeleton.
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
    }

    testWidgets(
      'the map page keeps the map full-bleed and moves its controls',
      (tester) async {
        const size = Size(466, 678);
        await pumpMapPage(tester, size);
        final safeRight = FoldableSurfaces.safeRightEdgeFor(size);

        // The map itself deliberately runs under the status bar: a map is a
        // surface, and letterboxing it would leave a dead strip on the right.
        expect(tester.getRect(find.byType(FlutterMap)).right, size.width);

        expect(
          tester.getRect(find.byType(MapControlButtons)).right,
          lessThanOrEqualTo(safeRight),
        );
        expect(tester.getRect(find.byType(MapTopBar)).right, size.width);
        expect(
          tester
              .getRect(
                find.descendant(
                  of: find.byType(MapTopBar),
                  matching: find.byType(FlatmatesChromeIconButton),
                ),
              )
              .right,
          lessThanOrEqualTo(safeRight),
        );
      },
    );

    testWidgets('the flat details hero chrome clears the inset', (
      tester,
    ) async {
      const size = Size(466, 678);
      FoldableSurfaces.useSurface(tester, size);
      final safeRight = FoldableSurfaces.safeRightEdgeFor(size);

      await tester.pumpWidget(
        await testableWidgetAsync(
          child: MediaQuery(
            // Animations off: the page's `StaggeredCardAppear` entrances are
            // `Future.delayed` timers that outlive a two-pump test, and the
            // inset does not depend on them.
            data: FoldableSurfaces.mediaQueryFor(size, disableAnimations: true),
            child: FlatDetailsPage(
              listingId: 7,
              seededListing: _listing(
                imageUrls: const [
                  'https://cdn.example.com/a.jpg',
                  'https://cdn.example.com/b.jpg',
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // The photo stays edge to edge...
      expect(
        tester.getRect(find.byType(FlatDetailsCarousel)).right,
        size.width,
      );
      // ...its buttons do not.
      for (final key in [
        const Key('flat_share_button'),
        const Key('flat_header_shortlist_button'),
      ]) {
        expect(
          tester.getRect(find.byKey(key)).right,
          lessThanOrEqualTo(safeRight),
          reason: '$key',
        );
      }
      expect(
        tester.getRect(find.byKey(const Key('flat_back_button'))).left,
        greaterThanOrEqualTo(0),
      );
    });

    testWidgets('the details sections clear the inset', (tester) async {
      const size = Size(466, 678);
      FoldableSurfaces.useSurface(tester, size);

      await tester.pumpWidget(
        MediaQuery(
          data: FoldableSurfaces.mediaQueryFor(size),
          child: _detailsSection(
            FlatDetailsLocation(
              listing: _listing(),
              onVoteSocietyTag: (_, _) {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        tester.getRect(find.byType(MiniMapView)).right,
        lessThanOrEqualTo(FoldableSurfaces.safeRightEdgeFor(size)),
      );
    });

    testWidgets('the inset is zero on a plain phone', (tester) async {
      const size = Size(466, 678);
      FoldableSurfaces.useSurface(tester, size);

      await tester.pumpWidget(
        MediaQuery(
          data: FoldableSurfaces.mediaQueryFor(size, padding: EdgeInsets.zero),
          child: _detailsSection(
            FlatDetailsLocation(
              listing: _listing(),
              onVoteSocietyTag: (_, _) {},
            ),
          ),
        ),
      );
      await tester.pump();

      // Without the Duo's status bar the section keeps its plain 16 dp gutter.
      expect(tester.getRect(find.byType(MiniMapView)).right, 466 - 16);
    });
  });
}

const _geolocatorChannels = [
  'flutter.baseflow.com/geolocator',
  'flutter.baseflow.com/geolocator_apple',
  'flutter.baseflow.com/geolocator_android',
];
const _geocodingChannel = 'flutter.baseflow.com/geocoding';

/// An [HttpClientAdapter] whose responses are scripted by the test.
class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this.handler);

  final Response<dynamic> Function(RequestOptions) handler;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final response = handler(options);
    return ResponseBody.fromString(
      jsonEncode(response.data),
      response.statusCode ?? 200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }
}
