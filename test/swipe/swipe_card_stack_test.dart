import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/core/compatibility/compatibility_engine.dart';
import 'package:flatmates_app/features/swipe/presentation/widgets/swipe_card_stack.dart';
import 'package:flatmates_app/features/swipe/swipe_repository.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('swipeLayerOpacity', () {
    test('foreground is always fully visible', () {
      expect(swipeLayerOpacity(depth: 0, progress: 0), 1.0);
      expect(swipeLayerOpacity(depth: 0, progress: 0.5), 1.0);
      expect(swipeLayerOpacity(depth: 0, progress: 1), 1.0);
    });

    test('next card is hidden at rest and fades in with progress', () {
      expect(swipeLayerOpacity(depth: 1, progress: 0), 0.0);
      expect(swipeLayerOpacity(depth: 1, progress: 0.4), closeTo(0.4, 1e-9));
      expect(swipeLayerOpacity(depth: 1, progress: 1), 1.0);
    });

    test('third card stays preloaded but invisible', () {
      expect(swipeLayerOpacity(depth: 2, progress: 0), 0.0);
      expect(swipeLayerOpacity(depth: 2, progress: 1), 0.0);
    });
  });

  group('SwipeCardStack', () {
    const compatibility = CompatibilityResult(
      percentage: 72,
      dimensions: [],
      topMatchChips: [],
    );

    SwipeProfile profile(int id, String name) => SwipeProfile(
      id: id,
      fullName: name,
      profileImageUrl: null,
      imageUrls: const [],
      mode: 'co_hunter',
      city: 'Gurugram',
      locality: 'Sector 45',
      bio: 'Bio for $name',
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
      nonNegotiables: const [],
      hasPets: false,
      partyHabit: null,
      listingDetails: const {},
    );

    testWidgets('preloads next/third but only foreground is opaque at rest', (
      tester,
    ) async {
      final current = profile(1, 'Current Peer');
      final next = profile(2, 'Next Peer');
      final third = profile(3, 'Third Peer');

      await tester.pumpWidget(
        testableWidget(
          child: SizedBox(
            width: 390,
            height: 700,
            child: SwipeCardStack(
              item: current,
              compatibility: compatibility,
              nextItem: next,
              nextCompatibility: compatibility,
              thirdItem: third,
              thirdCompatibility: compatibility,
              dragOffset: Offset.zero,
              dragProgress: 0,
              currentRotation: 0,
              isDragging: false,
              onHorizontalDragStart: (_) {},
              onHorizontalDragUpdate: (_) {},
              onHorizontalDragEnd: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // All three layers stay mounted for memory/preload (stable ValueKeys).
      expect(find.byKey(const ValueKey<int>(1)), findsOneWidget);
      expect(find.byKey(const ValueKey<int>(2)), findsOneWidget);
      expect(find.byKey(const ValueKey<int>(3)), findsOneWidget);

      // At rest only the foreground Opacity is fully visible.
      final opacities = tester
          .widgetList<Opacity>(find.byType(Opacity))
          .map((o) => o.opacity)
          .toList();
      expect(opacities.where((o) => o == 1.0), hasLength(1));
      expect(opacities.where((o) => o == 0.0), hasLength(2));
    });

    testWidgets('next card fades in during swipe progress', (tester) async {
      final current = profile(1, 'Current Peer');
      final next = profile(2, 'Next Peer');

      await tester.pumpWidget(
        testableWidget(
          child: SizedBox(
            width: 390,
            height: 700,
            child: SwipeCardStack(
              item: current,
              compatibility: compatibility,
              nextItem: next,
              nextCompatibility: compatibility,
              dragOffset: const Offset(120, 0),
              dragProgress: 0.75,
              currentRotation: 0.1,
              isDragging: true,
              onHorizontalDragStart: (_) {},
              onHorizontalDragUpdate: (_) {},
              onHorizontalDragEnd: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();

      final opacities = tester
          .widgetList<Opacity>(find.byType(Opacity))
          .map((o) => o.opacity)
          .toList();

      // Foreground fully visible + next partially revealed.
      expect(opacities, contains(1.0));
      expect(opacities, contains(0.75));
    });
  });
}
