import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/features/discover/application/move_in_filter.dart';

void main() {
  // Fixed "now" for deterministic date math: 2025-01-15.
  final now = DateTime(2025, 1, 15);

  group('move_in_filter this_month', () {
    test('matches profiles with immediate move-in', () {
      // "immediate" filter: available within 8 days of today.
      final soon = DateTime(2025, 1, 20); // 5 days out
      expect(listingMatchesMoveInFilter(soon, 'this_month', now: now), isTrue);

      // Available today.
      expect(listingMatchesMoveInFilter(now, 'this_month', now: now), isTrue);
    });

    test('does not match profiles beyond the current month', () {
      // February 1 — beyond January (this_month boundary is Feb 1).
      final nextMonth = DateTime(2025, 2);
      expect(
        listingMatchesMoveInFilter(nextMonth, 'this_month', now: now),
        isFalse,
      );
    });
  });

  group('move_in_filter flexible', () {
    test('flexible filter matches profiles with flexible timeline', () {
      // "flexible" normalizes to null → all profiles match.
      final anyDate = DateTime(2025, 6);
      expect(listingMatchesMoveInFilter(anyDate, 'flexible', now: now), isTrue);
      // Even null availableFrom matches when filter is flexible.
      expect(listingMatchesMoveInFilter(null, 'flexible', now: now), isTrue);
    });

    test('any and anytime also normalize to flexible (null)', () {
      expect(normalizeMoveInFilter('any'), isNull);
      expect(normalizeMoveInFilter('anytime'), isNull);
      expect(normalizeMoveInFilter('flexible'), isNull);
      expect(normalizeMoveInFilter('just_exploring'), isNull);
    });
  });

  group('move_in_filter unknown timeline values', () {
    test('unknown values fall back gracefully (null → match all)', () {
      expect(normalizeMoveInFilter('unknown_timeline'), isNull);
      expect(normalizeMoveInFilter('whenever'), isNull);
      expect(normalizeMoveInFilter(''), isNull);
      expect(normalizeMoveInFilter(null), isNull);

      // Unknown filter → null → matches everything.
      expect(
        listingMatchesMoveInFilter(null, 'unknown_timeline', now: now),
        isTrue,
      );
      expect(
        listingMatchesMoveInFilter(
          DateTime(2025, 12),
          'unknown_timeline',
          now: now,
        ),
        isTrue,
      );
    });

    test('immediate and within_2_weeks normalize correctly', () {
      expect(normalizeMoveInFilter('immediate'), 'immediate');
      expect(normalizeMoveInFilter('now'), 'immediate');
      expect(normalizeMoveInFilter('within_2_weeks'), 'within_2_weeks');
      expect(normalizeMoveInFilter('two_weeks'), 'within_2_weeks');
    });
  });
}
