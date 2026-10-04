import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/core/theme/app_theme.dart';
import 'package:flatmates_app/features/listings/presentation/widgets/step_about_section.dart';
import 'package:flatmates_app/l10n/gen/app_localizations.dart';

/// Local midnight on the given date.
///
/// A helper rather than an inline `DateTime(y, m, 1)`: a trailing day `1` is
/// the constructor's default, so the literal form trips
/// `avoid_redundant_argument_values` and would be "fixed" into a less
/// readable `DateTime(y, m)`. All parameters are required so no argument
/// matches a default here either.
DateTime _date(int year, int month, int day) => DateTime(year, month, day);

void main() {
  group('availableFromPickerBounds', () {
    test('last is 180 local calendar days out, not 180 x 24 hours', () {
      final now = DateTime(2026, 3, 1, 12);
      final bounds = availableFromPickerBounds(now: now);

      expect(bounds.first, _date(2026, 3, 1));
      expect(bounds.last, _date(2026, 8, 28));
      // A local midnight, so showDatePicker's date-only truncation is a no-op.
      // `<= 1` because in zones whose DST transition is at midnight (e.g.
      // America/Santiago) Dart normalizes the non-existent midnight to 01:00.
      expect(bounds.last.hour, lessThanOrEqualTo(1));

      final naive = bounds.first.add(const Duration(days: 180));
      if (naive != bounds.last) {
        // The ambient zone has a DST transition inside the window: instant
        // math drifts off local midnight, which is what truncated the final
        // selectable day. Runs under TZ=America/New_York and any DST zone.
        expect(naive.hour, isNot(0));
        expect(bounds.last.hour, lessThanOrEqualTo(1));
      }
    });

    test(
      'a fall-back transition inside the window does not shift the limit',
      () {
        final now = DateTime(2026, 6, 15, 12);
        final bounds = availableFromPickerBounds(now: now);

        expect(bounds.last, _date(2026, 12, 12));
        expect(bounds.last.hour, lessThanOrEqualTo(1));

        final naive = _date(2026, 6, 15).add(const Duration(days: 180));
        if (naive != bounds.last) {
          // US fall-back (2026-11-01) sits inside this window: 180 x 24 h lands
          // on 23:00 the previous day and loses the last day of the range.
          expect(naive.hour, 23);
          expect(naive.day, bounds.last.day - 1);
        }
      },
    );

    test('an unset date defaults to tomorrow, across a year boundary', () {
      final bounds = availableFromPickerBounds(
        now: DateTime(2026, 12, 31, 23, 30),
      );

      expect(bounds.initial, _date(2027, 1, 1));
      expect(bounds.initial.hour, lessThanOrEqualTo(1));
    });

    test('a UTC instant for local midnight keeps today selectable', () {
      final now = DateTime(2026, 10, 5, 9, 30);
      // The instant of local midnight in a UTC+ zone (IST): its UTC calendar
      // date is the previous day, which is how the picker received an
      // out-of-range initialDate.
      final stored = DateTime.utc(2026, 10, 4, 18, 30);
      final bounds = availableFromPickerBounds(now: now, availableFrom: stored);

      expect(bounds.first, _date(2026, 10, 5));
      expect(bounds.initial, _date(2026, 10, 5));
      expect(bounds.initial.isBefore(bounds.first), isFalse);
      expect(bounds.initial.isAfter(bounds.last), isFalse);

      if (stored.toLocal().day != stored.day) {
        // UTC+ zone: comparing the raw instant's fields would have used the
        // previous day, so the normalization is what keeps this in range.
        expect(DateUtils.dateOnly(stored), isNot(bounds.initial));
      }
    });

    test('an older listing date is clamped to today', () {
      final bounds = availableFromPickerBounds(
        now: DateTime(2026, 10, 5, 9, 30),
        availableFrom: _date(2024, 1, 1),
      );

      expect(bounds.initial, bounds.first);
    });

    test('a date beyond the range is clamped to the last day', () {
      final bounds = availableFromPickerBounds(
        now: DateTime(2026, 10, 5, 9, 30),
        availableFrom: _date(2030, 1, 1),
      );

      expect(bounds.initial, bounds.last);
    });
  });

  group('StepAboutSection date picker', () {
    Widget harness(DateTime? availableFrom, void Function(DateTime?) onPicked) {
      return MaterialApp(
        theme: AppTheme.build(brightness: Brightness.light),
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: StepAboutSection(
            typicalDayController: TextEditingController(),
            genderPreference: 'any',
            ageMin: 20,
            ageMax: 40,
            nonNegotiables: const <String>{},
            availableFrom: availableFrom,
            catalog: (_) => const [],
            onGenderChanged: (_) {},
            onAgeRangeChanged: (_, _) {},
            onNonNegotiableToggled: (_, _) {},
            onAvailableFromChanged: onPicked,
          ),
        ),
      );
    }

    testWidgets('opens with a UTC-normalized stored date without asserting', (
      tester,
    ) async {
      // `toUtc()` of local today: in a UTC+ zone its UTC calendar date is the
      // previous day, so the picker's initialDate assert fired before the fix.
      final stored = DateUtils.dateOnly(DateTime.now()).toUtc();
      DateTime? picked;
      await tester.pumpWidget(harness(stored, (date) => picked = date));
      await tester.pumpAndSettle();

      final locale = await AppLocalizations.delegate.load(const Locale('en'));
      await tester.tap(find.text(locale.selectDateCta));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(DatePickerDialog), findsOneWidget);
      expect(picked, isNull);
    });

    testWidgets('opens with an older stored date without asserting', (
      tester,
    ) async {
      DateTime? picked;
      await tester.pumpWidget(
        harness(_date(2024, 1, 1), (date) => picked = date),
      );
      await tester.pumpAndSettle();

      final locale = await AppLocalizations.delegate.load(const Locale('en'));
      await tester.tap(find.text(locale.selectDateCta));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(DatePickerDialog), findsOneWidget);
      expect(picked, isNull);
    });
  });
}
