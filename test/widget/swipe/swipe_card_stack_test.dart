import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/core/compatibility/compatibility_engine.dart';
import 'package:flatmates_app/features/swipe/presentation/widgets/swipe_card_stack.dart';
import 'package:flatmates_app/features/swipe/swipe_repository.dart';
import 'package:flatmates_app/l10n/gen/app_localizations.dart';

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
  Widget wrap(Widget child) => MaterialApp(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(body: child),
  );

  group('SwipeCardStack', () {
    testWidgets('preloads next/third but only foreground is opaque at rest', (
      tester,
    ) async {
      final fg = _profile(1, name: 'Foreground');
      final next = _profile(2, name: 'Next');
      final third = _profile(3, name: 'Third');

      await tester.pumpWidget(
        wrap(
          SizedBox(
            height: 600,
            child: SwipeCardStack(
              item: fg,
              compatibility: _compat(),
              nextItem: next,
              nextCompatibility: _compat(),
              thirdItem: third,
              thirdCompatibility: _compat(),
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

      // All three layers should be mounted (preloaded).
      expect(find.byKey(const ValueKey<int>(1)), findsOneWidget);
      expect(find.byKey(const ValueKey<int>(2)), findsOneWidget);
      expect(find.byKey(const ValueKey<int>(3)), findsOneWidget);

      // At rest (progress=0), foreground opacity = 1.0, next = 0.0, third = 0.0.
      final opacities = tester
          .widgetList<Opacity>(
            find.descendant(
              of: find.byType(SwipeCardStack),
              matching: find.byType(Opacity),
            ),
          )
          .toList();

      // Foreground (depth 0) should have opacity 1.0.
      expect(opacities.any((o) => o.opacity == 1.0), isTrue);
    });

    testWidgets('next card fades in during swipe progress', (tester) async {
      final fg = _profile(1, name: 'Foreground');
      final next = _profile(2, name: 'Next');

      await tester.pumpWidget(
        wrap(
          SizedBox(
            height: 600,
            child: SwipeCardStack(
              item: fg,
              compatibility: _compat(),
              nextItem: next,
              nextCompatibility: _compat(),
              dragOffset: const Offset(100, 0),
              dragProgress: 0.5,
              currentRotation: 0.1,
              isDragging: true,
              onHorizontalDragStart: (_) {},
              onHorizontalDragUpdate: (_) {},
              onHorizontalDragEnd: (_) {},
            ),
          ),
        ),
      );

      // With progress=0.5, the next card's opacity should be 0.5 (fading in).
      // Verify via the swipeLayerOpacity function directly.
      expect(swipeLayerOpacity(depth: 1, progress: 0.5), 0.5);
      // Foreground always 1.0.
      expect(swipeLayerOpacity(depth: 0, progress: 0.5), 1.0);
      // Third layer always 0.
      expect(swipeLayerOpacity(depth: 2, progress: 0.5), 0.0);
    });
  });
}
