import 'package:flatmates_app/features/discover/application/move_in_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('move-in filters', () {
    final now = DateTime(2026, 5, 7, 13, 30);

    test('normalizes catalog aliases', () {
      expect(normalizeMoveInFilter('immediately'), 'immediate');
      expect(normalizeMoveInFilter('within_1_month'), 'this_month');
      expect(normalizeMoveInFilter('flexible'), isNull);
      expect(normalizeMoveInFilter('unknown'), isNull);
    });

    test('matches immediate and monthly availability windows', () {
      expect(
        listingMatchesMoveInFilter(
          DateTime(2026, 5, 14, 23, 59),
          'immediate',
          now: now,
        ),
        isTrue,
      );
      expect(
        listingMatchesMoveInFilter(
          DateTime(2026, 5, 15),
          'immediate',
          now: now,
        ),
        isFalse,
      );
      expect(
        listingMatchesMoveInFilter(
          DateTime(2026, 6, 10),
          'next_month',
          now: now,
        ),
        isTrue,
      );
      expect(
        listingMatchesMoveInFilter(
          DateTime(2026, 7, 1),
          'next_month',
          now: now,
        ),
        isFalse,
      );
    });
  });
}
