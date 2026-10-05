import 'package:flutter_test/flutter_test.dart';

import 'package:flatmates_app/features/shared/presentation/visit_date_picker_bounds.dart';

DateTime _date(int year, int month, int day) => DateTime(year, month, day);

void main() {
  group('visitDatePickerBounds', () {
    test('defaults to today and tomorrow, 90 calendar days apart', () {
      final bounds = visitDatePickerBounds(now: DateTime(2026, 3, 10, 14, 30));

      expect(bounds.first, _date(2026, 3, 10));
      expect(bounds.last, _date(2026, 6, 8));
      expect(bounds.initial, _date(2026, 3, 11));
    });

    test('last is a calendar date, not now + 90 x 24 h', () {
      // 23:30 the evening of a US fall-back day. `Duration(days: 90)` advances
      // 90 x 24 h, which lands on 23:00 of the preceding day in a DST zone and
      // silently drops the last selectable day. The date assertion holds in
      // every zone; the hour check is what fails in a DST zone pre-fix.
      final bounds = visitDatePickerBounds(now: DateTime(2026, 11, 1, 23, 30));

      expect(bounds.first, _date(2026, 11, 1));
      expect(bounds.last, _date(2027, 1, 30));
      expect(bounds.last.hour, 0);
      expect(bounds.last.minute, 0);
    });

    test('a preferred date is used as the initial value', () {
      final bounds = visitDatePickerBounds(
        now: DateTime(2026, 3, 10, 9),
        preferred: DateTime(2026, 3, 20, 18, 45),
      );

      expect(bounds.initial, _date(2026, 3, 20));
    });

    test('a UTC stored date is normalized to the local calendar day', () {
      // Midnight local on 20 March, stored as UTC.
      final stored = DateTime(2026, 3, 20).toUtc();
      final bounds = visitDatePickerBounds(
        now: DateTime(2026, 3, 10),
        preferred: stored,
      );

      expect(bounds.initial, _date(2026, 3, 20));
    });

    test('an initial date before the window is clamped to first', () {
      final bounds = visitDatePickerBounds(
        now: DateTime(2026, 3, 10),
        preferred: _date(2026, 3, 1),
      );

      expect(bounds.initial, _date(2026, 3, 10));
    });

    test('an initial date past the window is clamped to last', () {
      final bounds = visitDatePickerBounds(
        now: DateTime(2026, 3, 10),
        preferred: _date(2027, 6, 1),
      );

      expect(bounds.initial, bounds.last);
    });

    test('the window length is configurable', () {
      final bounds = visitDatePickerBounds(
        now: DateTime(2026, 3, 10),
        windowDays: 180,
      );

      expect(bounds.last, _date(2026, 9, 6));
    });

    test('every result keeps initialDate inside [first, last]', () {
      final cases = <DateTime?>[
        null,
        _date(2020, 1, 1),
        DateTime(2030, 12, 31),
        DateTime(2026, 3, 10, 23, 59),
      ];

      for (final preferred in cases) {
        final bounds = visitDatePickerBounds(
          now: DateTime(2026, 3, 10, 12),
          preferred: preferred,
        );
        expect(
          bounds.initial.isBefore(bounds.first),
          isFalse,
          reason: 'initial $preferred is before first',
        );
        expect(
          bounds.initial.isAfter(bounds.last),
          isFalse,
          reason: 'initial $preferred is after last',
        );
      }
    });
  });
}
