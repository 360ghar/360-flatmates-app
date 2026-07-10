import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/core/compatibility/compatibility_engine.dart';
import 'package:flatmates_app/features/swipe/presentation/widgets/swipe_card_components.dart';
import 'package:flatmates_app/features/swipe/swipe_repository.dart';

import '../helpers/test_helpers.dart';

void main() {
  const compatibility = CompatibilityResult(
    percentage: 80,
    dimensions: [],
    topMatchChips: ['Both early risers'],
  );

  SwipeProfile profileWithImages(List<String> urls) {
    return SwipeProfile(
      id: 42,
      fullName: 'Asha',
      profileImageUrl: urls.isEmpty ? null : urls.first,
      imageUrls: urls.length > 1 ? urls.sublist(1) : const [],
      mode: 'co_hunter',
      city: 'Gurugram',
      locality: 'Sector 45',
      bio: 'Hello',
      budgetMin: 15000,
      budgetMax: 25000,
      moveInTimeline: null,
      sleepSchedule: 'early_bird',
      cleanliness: 'tidy',
      foodHabits: 'veg',
      smokingDrinking: null,
      guestsPolicy: null,
      workStyle: null,
      gender: null,
      nonNegotiables: const ['no_smoking'],
      hasPets: true,
      partyHabit: 'rare',
      listingDetails: const {
        'society_vibes': ['quiet'],
        'room_features': ['balcony'],
        'society_amenities': ['gym'],
        'flat_amenities': ['wifi'],
      },
    );
  }

  testWidgets('photo tap zones advance without PageView', (tester) async {
    final images = [
      'https://example.com/a.jpg',
      'https://example.com/b.jpg',
      'https://example.com/c.jpg',
    ];
    final item = profileWithImages(images);

    await tester.pumpWidget(
      testableWidget(
        child: SizedBox(
          width: 390,
          height: 400,
          child: HeroCarousel(
            images: images,
            name: item.fullName,
            mode: item.mode ?? 'open_to_both',
            compatibility: compatibility,
            item: item,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(PageView), findsNothing);
    expect(find.byKey(const Key('swipe_photo_prev')), findsOneWidget);
    expect(find.byKey(const Key('swipe_photo_next')), findsOneWidget);
    expect(find.text('1/3'), findsOneWidget);

    await tester.tap(find.byKey(const Key('swipe_photo_next')));
    await tester.pump();
    expect(find.text('2/3'), findsOneWidget);

    await tester.tap(find.byKey(const Key('swipe_photo_next')));
    await tester.pump();
    expect(find.text('3/3'), findsOneWidget);

    // Already at last — stays put.
    await tester.tap(find.byKey(const Key('swipe_photo_next')));
    await tester.pump();
    expect(find.text('3/3'), findsOneWidget);

    await tester.tap(find.byKey(const Key('swipe_photo_prev')));
    await tester.pump();
    expect(find.text('2/3'), findsOneWidget);
  });

  testWidgets('single image has no photo tap zones', (tester) async {
    final images = ['https://example.com/only.jpg'];
    final item = profileWithImages(images);

    await tester.pumpWidget(
      testableWidget(
        child: SizedBox(
          width: 390,
          height: 400,
          child: HeroCarousel(
            images: images,
            name: item.fullName,
            mode: item.mode ?? 'open_to_both',
            compatibility: compatibility,
            item: item,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('swipe_photo_prev')), findsNothing);
    expect(find.byKey(const Key('swipe_photo_next')), findsNothing);
    expect(find.textContaining('/'), findsNothing);
  });
}
