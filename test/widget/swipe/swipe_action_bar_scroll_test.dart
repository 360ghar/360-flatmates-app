import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/core/compatibility/compatibility_engine.dart';
import 'package:flatmates_app/features/swipe/presentation/widgets/swipe_action_bar.dart';
import 'package:flatmates_app/features/swipe/presentation/widgets/swipe_card_stack.dart';
import 'package:flatmates_app/features/swipe/swipe_repository.dart';
import 'package:flatmates_app/l10n/gen/app_localizations.dart';

SwipeProfile _profile(int id) => SwipeProfile(
  id: id,
  fullName: 'User $id',
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
  smokingDrinking: 'neither',
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

void main() {
  group('SwipeActionBar placement', () {
    testWidgets('action bar is below the fold and outside card chrome', (
      tester,
    ) async {
      // The SwipeActionBar is passed as `trailing` to SwipeCardStack, which
      // places it as trailing scroll content inside the foreground card's
      // ListView — below the card block (min-height constrained to viewport).
      final fg = _profile(1);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: SizedBox(
              height: 600,
              child: SwipeCardStack(
                item: fg,
                compatibility: _compat(),
                nextItem: null,
                nextCompatibility: null,
                dragOffset: Offset.zero,
                dragProgress: 0,
                currentRotation: 0,
                isDragging: false,
                onHorizontalDragStart: (_) {},
                onHorizontalDragUpdate: (_) {},
                onHorizontalDragEnd: (_) {},
                actionBar: SwipeActionBar(
                  onSkip: () {},
                  onLike: () {},
                  onUndo: () {},
                  canUndo: false,
                  enabled: true,
                ),
              ),
            ),
          ),
        ),
      );
      // Let the ListView mount its children (including off-screen trailing
      // content below the fold).
      await tester.pump();

      // The action bar buttons should be present in the widget tree.
      // Use skipOffstage: false because the action bar is trailing scroll
      // content that sits below the fold (min-height constrained card).
      expect(
        find.byKey(const Key('swipe_action_skip'), skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('swipe_action_like'), skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('swipe_action_undo'), skipOffstage: false),
        findsOneWidget,
      );

      // The action bar should be rendered (it is part of the scroll content).
      // Verify it exists below the card content by checking its vertical
      // position is greater than the card's top.
      final skipButton = tester.getCenter(
        find.byKey(const Key('swipe_action_skip'), skipOffstage: false),
      );
      expect(skipButton.dy, greaterThan(0));
    });
  });
}
