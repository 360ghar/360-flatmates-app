import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/core/compatibility/compatibility_engine.dart';
import 'package:flatmates_app/features/shared/presentation/flatmates_card.dart';
import 'package:flatmates_app/features/swipe/presentation/widgets/swipe_action_bar.dart';
import 'package:flatmates_app/features/swipe/presentation/widgets/swipe_profile_card.dart';
import 'package:flatmates_app/features/swipe/swipe_repository.dart';

import '../helpers/test_helpers.dart';

void main() {
  const compatibility = CompatibilityResult(
    percentage: 72,
    dimensions: [],
    topMatchChips: [],
  );

  const profile = SwipeProfile(
    id: 1,
    fullName: 'Test Peer',
    profileImageUrl: null,
    imageUrls: [],
    mode: 'co_hunter',
    city: 'Gurugram',
    locality: 'Sector 45',
    bio: 'Short bio',
    budgetMin: 15000,
    budgetMax: 25000,
    moveInTimeline: null,
    sleepSchedule: null,
    cleanliness: null,
    foodHabits: null,
    smokingDrinking: null,
    guestsPolicy: null,
    workStyle: null,
    gender: null,
    genderPreference: null,
    nonNegotiables: [],
    hasPets: false,
    partyHabit: null,
    listingDetails: {},
  );

  testWidgets('action bar is below the fold and outside card chrome', (
    tester,
  ) async {
    const viewportHeight = 700.0;

    await tester.pumpWidget(
      testableWidget(
        child: const SizedBox(
          width: 390,
          height: viewportHeight,
          child: SwipeProfileCard(
            item: profile,
            compatibility: compatibility,
            trailing: SwipeActionBar(
              onSkip: _noop,
              onLike: _noop,
              onUndo: _noop,
              canUndo: false,
              enabled: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Off-viewport ListView children are skipped by default finders.
    final like = find.byKey(
      const Key('swipe_action_like'),
      skipOffstage: false,
    );
    expect(like, findsOneWidget);
    expect(find.byType(SwipeActionBar, skipOffstage: false), findsOneWidget);

    // Floating: not painted inside FlatmatesCard chrome.
    expect(
      find.descendant(
        of: find.byType(FlatmatesCard),
        matching: find.byType(SwipeActionBar, skipOffstage: false),
      ),
      findsNothing,
    );

    // Still below the fold on first paint (use the actual ListView viewport,
    // not the requested SizedBox height — the test surface may clamp it).
    final listHeight = tester.getSize(find.byType(ListView)).height;
    final topBefore = tester.getRect(like).top;
    expect(topBefore, greaterThanOrEqualTo(listHeight));

    await tester.scrollUntilVisible(
      find.byKey(const Key('swipe_action_like'), skipOffstage: false),
      100,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();

    final topAfter = tester
        .getRect(find.byKey(const Key('swipe_action_like')))
        .top;
    expect(topAfter, lessThan(listHeight));
    expect(topAfter, lessThan(topBefore));

    // Still outside the card after scrolling into view.
    expect(
      find.descendant(
        of: find.byType(FlatmatesCard),
        matching: find.byType(SwipeActionBar),
      ),
      findsNothing,
    );
  });

  testWidgets('profile sheet body without trailing has no action bar', (
    tester,
  ) async {
    await tester.pumpWidget(
      testableWidget(
        child: const SizedBox(
          width: 390,
          height: 700,
          child: SwipeProfileDetailBody(
            item: profile,
            compatibility: compatibility,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('swipe_action_like'), skipOffstage: false),
      findsNothing,
    );
    expect(find.byType(SwipeActionBar, skipOffstage: false), findsNothing);
  });
}

void _noop() {}
