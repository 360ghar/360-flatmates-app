import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flatmates_app/core/compatibility/compatibility_engine.dart';
import 'package:flatmates_app/core/network/api_client.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/core/theme/app_spacing.dart';
import 'package:flatmates_app/features/swipe/presentation/widgets/swipe_card_components.dart';
import 'package:flatmates_app/features/swipe/presentation/widgets/swipe_card_stack.dart';
import 'package:flatmates_app/features/swipe/presentation/widgets/swipe_profile_card.dart';
import 'package:flatmates_app/features/swipe/swipe_deck_page.dart';
import 'package:flatmates_app/features/swipe/swipe_repository.dart';
import 'package:flatmates_app/l10n/gen/app_localizations.dart';

import '../../helpers/test_helpers.dart';

/// The four iPhone Duo poses, in logical points.
const _foldedPortrait = Size(466, 678);
const _foldedLandscape = Size(678, 466);
const _openPortrait = Size(669, 951);
const _openLandscape = Size(951, 669);

/// The card's own horizontal gutter (`SwipeProfileCard`).
const _cardGutter = AppSpacing.screen * 2;

SwipeProfile _profile(int id, {String? name}) => SwipeProfile(
  id: id,
  fullName: name ?? 'User $id',
  profileImageUrl: null,
  imageUrls: const [],
  mode: 'co_hunter',
  city: 'Bangalore',
  locality: 'Koramangala',
  bio: 'Hello',
  budgetMin: 10000,
  budgetMax: 25000,
  moveInTimeline: 'flexible',
  sleepSchedule: 'flexible',
  cleanliness: 'tidy',
  foodHabits: 'vegetarian',
  smoking: 'never',
  drinking: 'never',
  guestsPolicy: 'occasional_ok',
  workStyle: 'hybrid',
  gender: 'male',
  genderPreference: 'any',
  nonNegotiables: const [],
  hasPets: false,
  partyHabit: null,
  listingDetails: const {},
);

CompatibilityResult _compat() => const CompatibilityResult(
  percentage: 75,
  dimensions: [],
  topMatchChips: [],
);

Widget _wrap(Widget child) => MaterialApp(
  locale: const Locale('en'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: Scaffold(body: child),
);

/// Pumps the swipe card at [size] and returns the hero's rendered height.
Future<double> _heroHeightAt(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    _wrap(SwipeProfileCard(item: _profile(1), compatibility: _compat())),
  );
  await tester.pumpAndSettle();

  return tester.getSize(find.byType(HeroCarousel)).height;
}

// ── SwipeDeckPage drag harness ─────────────────────────────────────────

class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this._handler);

  final Response Function(RequestOptions) _handler;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final response = _handler(options);
    return ResponseBody.fromString(
      jsonEncode(response.data),
      response.statusCode ?? 200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }
}

Response _ok(Object data) =>
    Response(data: data, statusCode: 200, requestOptions: RequestOptions());

Map<String, dynamic> _profileJson(int id) => {
  'id': id,
  'full_name': 'User $id',
  'profile_image_url': null,
  'image_urls': <dynamic>[],
  'mode': 'co_hunter',
  'city': 'Bangalore',
  'locality': 'Koramangala',
  'bio': 'Looking for a flatmate',
  'budget_min': 10000.0,
  'budget_max': 25000.0,
  'move_in_timeline': 'flexible',
  'gender': 'male',
  'gender_preference': 'any',
  'non_negotiables': <dynamic>[],
  'has_pets': false,
};

/// Pumps the real deck at [size] with three scripted profiles.
Future<void> _pumpDeck(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final apiClient = ApiClient(
    baseUrl: 'https://api.test.example.com',
    tokenProvider: FakeAuthTokenProvider(),
  );
  apiClient.dio.httpClientAdapter = _ScriptedAdapter((options) {
    if (options.path == '/flatmates/profiles') {
      // Ids start at 2: the fake bootstrap profile is id 1 and the deck filters
      // the signed-in user out of the stack.
      return _ok({
        'items': [_profileJson(2), _profileJson(3), _profileJson(4)],
        'next_cursor': null,
        'has_more': false,
      });
    }
    return _ok({});
  });

  final widget = await testableWidgetAsync(
    child: const SwipeDeckPage(),
    overrides: [apiClientProvider.overrideWithValue(apiClient)],
  );

  await tester.pumpWidget(widget);
  // pump() rather than pumpAndSettle(): the page owns animations that never
  // settle.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
}

/// Drags the foreground card [distance] logical points to the right.
///
/// Deliberately slow: a fling would commit through the velocity branch
/// (`vx.abs() > 800`) and hide the distance threshold under test. The
/// recogniser also swallows the 18 dp touch slop before it reports the first
/// update, so the accumulated drag is [distance] - 18.
Future<void> _dragCardSlowly(WidgetTester tester, double distance) async {
  const step = 5.0;
  final steps = (distance / step).round();
  final gesture = await tester.startGesture(
    tester.getCenter(find.byKey(const Key('swipe_card')).first),
  );
  for (var i = 0; i < steps; i++) {
    await gesture.moveBy(const Offset(step, 0));
    await tester.pump(const Duration(milliseconds: 16));
  }
  // Let the velocity estimate decay, so the release reads as a slow drag.
  await tester.pump(const Duration(milliseconds: 400));
  await gesture.up();
  await tester.pump();
  // Fly-off + deck advance.
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('swipe card hero is width aware', () {
    testWidgets('every phone pose renders the unchanged 460 dp hero', (
      tester,
    ) async {
      for (final size in [_foldedPortrait, _foldedLandscape, _openPortrait]) {
        expect(
          await _heroHeightAt(tester, size),
          460,
          reason: 'hero height at ${size.width}x${size.height}',
        );
      }
    });

    testWidgets('the open landscape foldable is no longer a 2:1 letterbox', (
      tester,
    ) async {
      final height = await _heroHeightAt(tester, _openLandscape);
      final cardWidth = _openLandscape.width - _cardGutter;

      // 4:3 at 919 dp of card width is 689 dp, capped by the 669 dp viewport
      // less one section of breathing room (64) = 605.
      expect(height, 605);
      expect(height, greaterThan(460));
      // The old fixed 460 dp hero was 919/460 = 2.0:1.
      expect(cardWidth / height, lessThan(1.6));
    });

    testWidgets('the real page caps the card, so 951 dp renders a 516 dp hero', (
      tester,
    ) async {
      await _pumpDeck(tester, _openLandscape);

      // `FlatmatesScreen` bounds the page body at 720 dp, so the card is
      // 720 - 2 * 16 = 688 dp wide and 4:3 of that is 516 (below the 605
      // viewport cap). That is the number the app actually ships at this pose.
      final hero = tester.getSize(find.byType(HeroCarousel).first);
      expect(hero.width, 688);
      expect(hero.height, 516);
      expect(hero.width / hero.height, lessThan(1.4));
    });

    testWidgets('the hero requests 2x the rect it paints, never more', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(919, 605);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _wrap(
          HeroCarousel(
            images: const [
              'https://res.cloudinary.com/demo/image/upload/v1/hero.jpg',
            ],
            name: 'Test',
            mode: 'co_hunter',
            compatibility: _compat(),
            item: _profile(2),
            heroHeight: 605,
          ),
        ),
      );
      await tester.pump();

      final image = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      // 919 x 605 painted, doubled for high-DPR screens: the delivery URL and
      // the in-memory decode are both bounded by the painted rect, and
      // Cloudinary's `c_limit` never upscales past it.
      expect(image.memCacheWidth, 1838);
      expect(image.memCacheHeight, 1210);
      expect(image.imageUrl, contains('w_1838,h_1210,c_limit'));
    });

    test(
      'the resolver keeps the phone height below the expanded breakpoint',
      () {
        for (final width in [320.0, 466.0, 669.0, 678.0, 899.0]) {
          expect(
            swipeCardHeroHeight(
              viewportWidth: width,
              viewportHeight: 900,
              cardWidth: width - _cardGutter,
            ),
            460,
            reason: 'viewport width $width',
          );
        }
      },
    );

    test('the resolver bounds the hero shape at and above 900 dp', () {
      // 900 dp viewport, plenty of height: 4:3 of the card, not a strip.
      expect(
        swipeCardHeroHeight(
          viewportWidth: 900,
          viewportHeight: 2000,
          cardWidth: 868,
        ),
        closeTo(651, 0.5),
      );
      // The landscape foldable caps at viewport height - section.
      expect(
        swipeCardHeroHeight(
          viewportWidth: 951,
          viewportHeight: 669,
          cardWidth: 919,
        ),
        605,
      );
      // A window shorter than the phone hero never shrinks below 460.
      expect(
        swipeCardHeroHeight(
          viewportWidth: 951,
          viewportHeight: 300,
          cardWidth: 919,
        ),
        460,
      );
    });
  });

  group('swipe commit threshold is a fixed distance', () {
    test('the distance is 96 dp and progress 1.0 is that same point', () {
      expect(kSwipeCommitDistance, 96);
      expect(calculateDragProgress(const Offset(96, 0)), 1.0);
      expect(calculateDragProgress(const Offset(-96, 0)), 1.0);
      expect(calculateDragProgress(const Offset(48, 0)), 0.5);
    });

    testWidgets('a 200 dp drag commits on a 466 dp phone', (tester) async {
      await _pumpDeck(tester, _foldedPortrait);
      expect(find.text('User 2'), findsOneWidget);

      await _dragCardSlowly(tester, 200);

      // ~182 dp of travel (200 less the touch slop) is past 96, so the deck
      // advanced past the first profile. (The next profile is always in the
      // tree — the stack preloads depth 1 and 2 at opacity 0 — so the
      // foreground leaving is the signal.)
      expect(find.text('User 2'), findsNothing);
    });

    testWidgets('a 200 dp drag commits on the 951 dp foldable too', (
      tester,
    ) async {
      await _pumpDeck(tester, _openLandscape);
      expect(find.text('User 2'), findsOneWidget);

      await _dragCardSlowly(tester, 200);

      // The old rule was 20 % of the viewport (190 dp), so the same 200 dp
      // drag snapped back here. The fixed 96 dp threshold commits.
      expect(find.text('User 2'), findsNothing);
    });

    testWidgets('an 80 dp drag snaps back on both widths', (tester) async {
      for (final size in [_foldedPortrait, _openLandscape]) {
        await _pumpDeck(tester, size);

        await _dragCardSlowly(tester, 80);

        // ~62 dp of travel is short of the threshold on either display, so the
        // foreground card stays where it was.
        expect(
          find.text('User 2'),
          findsOneWidget,
          reason: 'snap back at ${size.width}x${size.height}',
        );
      }
    });
  });
}
