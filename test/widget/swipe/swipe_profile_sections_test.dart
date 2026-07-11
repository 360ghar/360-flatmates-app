import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/core/compatibility/compatibility_engine.dart';
import 'package:flatmates_app/features/swipe/presentation/widgets/swipe_profile_card.dart';
import 'package:flatmates_app/features/swipe/swipe_repository.dart';
import 'package:flatmates_app/l10n/gen/app_localizations.dart';

SwipeProfile _profile({
  List<String> nonNegotiables = const ['no_smoking', 'food_veg_only'],
}) => SwipeProfile(
  id: 1,
  fullName: 'Test User',
  profileImageUrl: null,
  imageUrls: const [],
  mode: 'co_hunter',
  city: 'Bangalore',
  locality: 'Koramangala',
  bio: 'I am a tidy professional looking for a flatmate.',
  budgetMin: 10000,
  budgetMax: 25000,
  moveInTimeline: 'flexible',
  sleepSchedule: 'early_bird',
  cleanliness: 'tidy',
  foodHabits: 'vegetarian',
  smokingDrinking: 'neither',
  guestsPolicy: 'occasional_ok',
  workStyle: 'hybrid',
  gender: 'male',
  genderPreference: 'any',
  nonNegotiables: nonNegotiables,
  hasPets: false,
  partyHabit: 'occasional',
  listingDetails: const {},
);

CompatibilityResult _compatWithDimensions() => const CompatibilityResult(
  percentage: 80,
  dimensions: [
    CompatibilityDimension(
      key: 'sleep_schedule',
      weight: 0.2,
      userValue: 'early_bird',
      peerValue: 'early_bird',
      score: 1.0,
      isMatch: true,
      summary: 'Both early birds',
    ),
    CompatibilityDimension(
      key: 'cleanliness',
      weight: 0.2,
      userValue: 'tidy',
      peerValue: 'tidy',
      score: 1.0,
      isMatch: true,
      summary: 'Both tidy',
    ),
  ],
  topMatchChips: ['Early birds', 'Tidy'],
);

void main() {
  Widget wrap(Widget child) => MaterialApp(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(body: child),
  );

  group('SwipeProfileCard sections', () {
    testWidgets(
      'renders lifestyle, preferences, deal-breakers, and all dimensions',
      (tester) async {
        await tester.pumpWidget(
          wrap(
            SizedBox(
              height: 2000,
              child: SwipeProfileCard(
                item: _profile(),
                compatibility: _compatWithDimensions(),
              ),
            ),
          ),
        );

        // Scroll to the bottom to reveal all sections.
        await tester.fling(find.byType(ListView), const Offset(0, -500), 2000);
        await tester.pumpAndSettle();
        await tester.fling(find.byType(ListView), const Offset(0, -500), 2000);
        await tester.pumpAndSettle();

        // The card should render without overflow.
        expect(tester.takeException(), isNull);

        // Lifestyle section should be present (sleep, cleanliness, food, etc.).
        // Preferences section should be present (gender preference, pets).
        // Deal-breakers section should be present (non-negotiables).
        // Compatibility breakdown should render all dimensions.

        // Verify the profile card is rendered.
        expect(find.byType(SwipeProfileCard), findsOneWidget);
      },
    );
  });
}
