import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/core/compatibility/compatibility_engine.dart';
import 'package:flatmates_app/features/swipe/presentation/widgets/swipe_card_components.dart';
import 'package:flatmates_app/features/swipe/swipe_repository.dart';
import 'package:flatmates_app/l10n/gen/app_localizations.dart';

import '../helpers/test_helpers.dart';

void main() {
  const compatibility = CompatibilityResult(
    percentage: 88,
    dimensions: [],
    topMatchChips: ['Both early risers', 'Similar budget', 'Quiet home'],
  );

  const profile = SwipeProfile(
    id: 7,
    fullName: 'Riya',
    profileImageUrl: null,
    imageUrls: [],
    mode: 'room_poster',
    city: 'Delhi',
    locality: 'Saket',
    bio: 'Long bio that used to bury match chips below the fold.',
    budgetMin: 20000,
    budgetMax: 30000,
    moveInTimeline: 'immediate',
    sleepSchedule: 'early_bird',
    cleanliness: 'very_clean',
    foodHabits: 'veg',
    smokingDrinking: 'no_smoking',
    guestsPolicy: 'occasional',
    workStyle: 'wfh',
    gender: null,
    nonNegotiables: ['no_pets', 'no_parties'],
    hasPets: false,
    partyHabit: 'rarely',
    listingDetails: {
      'society_amenities': ['gym'],
      'flat_amenities': ['wifi'],
      'society_vibes': ['family_friendly'],
      'room_features': ['attached_bath'],
      'room_type': 'private_room',
      'flat_config': '2 BHK',
    },
  );

  testWidgets('top match chips render outside AboutSection', (tester) async {
    await tester.pumpWidget(
      testableWidget(
        child: const Material(
          child: TopMatchChipsRow(
            chips: ['Both early risers', 'Similar budget'],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CompactMatchChip), findsNWidgets(2));
    expect(find.text('Both early risers'), findsOneWidget);
    expect(find.byType(AboutSection), findsNothing);
  });

  testWidgets('AboutSection no longer shows match chips', (tester) async {
    await tester.pumpWidget(
      testableWidget(
        child: Material(
          child: AboutSection(bio: profile.bio, videoTourUrl: null),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(profile.bio!), findsOneWidget);
    expect(find.byType(CompactMatchChip), findsNothing);
    // unused compatibility kept only to document the IA split
    expect(compatibility.topMatchChips, isNotEmpty);
  });

  testWidgets('lifestyle and dealbreakers sections surface tokens', (
    tester,
  ) async {
    await tester.pumpWidget(
      testableWidget(
        child: Material(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                LifestyleSection(item: profile),
                DealbreakersSection(nonNegotiables: ['no_pets', 'no_parties']),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final locale = AppLocalizations.of(
      tester.element(find.byType(LifestyleSection)),
    );
    expect(find.text(locale.lifestyleSectionTitle), findsOneWidget);
    expect(find.text(locale.dealBreakersSectionTitle), findsOneWidget);
    // humanizeFlatmatesToken('early_bird') → Early Bird
    expect(find.text('Early Bird'), findsOneWidget);
    expect(find.text('No Pets'), findsOneWidget);
  });

  testWidgets('ThePlaceSection merges vibes and room features', (tester) async {
    await tester.pumpWidget(
      testableWidget(
        child: const Material(
          child: SingleChildScrollView(
            child: ThePlaceSection(
              locality: 'Saket',
              city: 'Delhi',
              societyName: null,
              roomType: 'private_room',
              flatConfig: '2 BHK',
              floor: null,
              societyAmenities: ['gym'],
              flatAmenities: ['wifi'],
              societyVibes: ['family_friendly'],
              roomFeatures: ['attached_bath'],
              lat: null,
              lng: null,
              fallbackLabel: 'Saket',
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Family Friendly'), findsOneWidget);
    expect(find.text('Attached Bath'), findsOneWidget);
    expect(find.text('Gym'), findsOneWidget);
  });
}
