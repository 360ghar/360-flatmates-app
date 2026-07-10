import 'package:flutter_test/flutter_test.dart';

import 'package:flatmates_app/features/profile/presentation/widgets/edit_profile_dropdown_utils.dart';

void main() {
  group('dropdownValueInIds', () {
    test('returns value when it appears exactly once', () {
      expect(
        dropdownValueInIds('hybrid', ['office', 'hybrid', 'wfh']),
        'hybrid',
      );
    });

    test('returns null when value is missing', () {
      expect(
        dropdownValueInIds('flexible', ['immediately', 'just_exploring']),
        isNull,
      );
    });

    test('returns null when value is duplicated', () {
      expect(dropdownValueInIds('a', ['a', 'b', 'a']), isNull);
    });
  });

  group('dropdownValueOrFirst', () {
    test('returns matched value when present', () {
      expect(dropdownValueOrFirst('wfh', ['office', 'hybrid', 'wfh']), 'wfh');
    });

    test('falls back to first id when missing', () {
      expect(
        dropdownValueOrFirst('flexible', ['immediately', 'just_exploring']),
        'immediately',
      );
    });
  });

  group('resolveMoveInTimelineId', () {
    const catalogIds = [
      'immediately',
      'within_2_weeks',
      'within_1_month',
      'just_exploring',
    ];

    test('maps legacy flexible onto just_exploring', () {
      expect(resolveMoveInTimelineId('flexible', catalogIds), 'just_exploring');
    });

    test('maps immediate onto immediately', () {
      expect(resolveMoveInTimelineId('immediate', catalogIds), 'immediately');
    });

    test('keeps exact catalog id', () {
      expect(
        resolveMoveInTimelineId('within_1_month', catalogIds),
        'within_1_month',
      );
    });

    test('maps flexible onto flexible when only legacy fallback exists', () {
      expect(
        resolveMoveInTimelineId('just_exploring', [
          'immediate',
          'this_month',
          'flexible',
        ]),
        'flexible',
      );
    });
  });
}
