import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/core/compatibility/compatibility_engine.dart';
import 'package:flatmates_app/features/swipe/presentation/widgets/swipe_profile_card.dart';
import 'package:flatmates_app/features/swipe/swipe_repository.dart';

import '../helpers/test_helpers.dart';

void main() {
  const dimensions = [
    CompatibilityDimension(
      key: 'sleep_schedule',
      weight: 0.2,
      userValue: 'early_bird',
      peerValue: 'night_owl',
      score: 0,
      isMatch: false,
      summary: 'Sleep habits',
    ),
    CompatibilityDimension(
      key: 'cleanliness',
      weight: 0.2,
      userValue: 'tidy',
      peerValue: 'tidy',
      score: 100,
      isMatch: true,
      summary: 'Cleanliness',
    ),
    CompatibilityDimension(
      key: 'food_habits',
      weight: 0.15,
      userValue: 'vegetarian',
      peerValue: 'vegetarian',
      score: 100,
      isMatch: true,
      summary: 'Food habits',
    ),
    CompatibilityDimension(
      key: 'smoking_drinking',
      weight: 0.2,
      userValue: 'neither',
      peerValue: 'neither',
      score: 100,
      isMatch: true,
      summary: 'Smoking habits',
    ),
    CompatibilityDimension(
      key: 'guests_policy',
      weight: 0.15,
      userValue: 'occasional_ok',
      peerValue: 'occasional_ok',
      score: 100,
      isMatch: true,
      summary: 'Guest policy',
    ),
    CompatibilityDimension(
      key: 'work_style',
      weight: 0.1,
      userValue: 'hybrid',
      peerValue: 'hybrid',
      score: 100,
      isMatch: true,
      summary: 'Work style',
    ),
  ];

  const compatibility = CompatibilityResult(
    percentage: 75,
    dimensions: dimensions,
    topMatchChips: ['Cleanliness', 'Food habits'],
  );

  const profile = SwipeProfile(
    id: 1,
    fullName: 'Test Peer',
    profileImageUrl: null,
    imageUrls: [],
    mode: 'co_hunter',
    city: 'Gurugram',
    locality: 'Sector 45',
    bio: 'Looking for a quiet flatmate.',
    budgetMin: 15000,
    budgetMax: 25000,
    moveInTimeline: 'this_month',
    sleepSchedule: 'night_owl',
    cleanliness: 'tidy',
    foodHabits: 'vegetarian',
    smokingDrinking: 'neither',
    guestsPolicy: 'occasional_ok',
    workStyle: 'hybrid',
    gender: 'female',
    genderPreference: 'female',
    nonNegotiables: ['no_smoking', 'food_veg_only'],
    hasPets: false,
    partyHabit: 'rarely',
    listingDetails: {},
    age: 26,
    profession: 'Designer',
  );

  testWidgets('renders lifestyle, preferences, deal-breakers, and all dimensions', (
    tester,
  ) async {
    await tester.pumpWidget(
      testableWidget(
        child: const SizedBox(
          width: 390,
          height: 1200,
          child: SwipeProfileDetailBody(
            item: profile,
            compatibility: compatibility,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lifestyle'), findsOneWidget);
    expect(find.text('Preferences'), findsOneWidget);
    expect(find.text('Deal-breakers'), findsOneWidget);
    expect(find.text('Non-negotiables they set'), findsOneWidget);
    expect(find.text('Compatibility breakdown'), findsOneWidget);

    // Lifestyle grid dimension labels
    expect(find.text('Sleep'), findsOneWidget);
    expect(find.text('Cleanliness'), findsWidgets);

    // Peer lifestyle values (humanized)
    expect(find.textContaining('Night Owl'), findsWidgets);
    expect(find.textContaining('Vegetarian'), findsWidgets);

    // Deal-breakers
    expect(find.textContaining('No Smoking'), findsOneWidget);
    expect(find.textContaining('Food Veg Only'), findsOneWidget);

    // Compatibility summary tone + buckets
    expect(find.textContaining('Great match'), findsWidgets);
    expect(find.textContaining('aligned'), findsWidgets);

    // All 6 compatibility dimension summaries are present
    // (some labels may also appear as top-match chips)
    for (final dim in dimensions) {
      expect(find.text(dim.summary), findsWidgets);
    }
  });
}
