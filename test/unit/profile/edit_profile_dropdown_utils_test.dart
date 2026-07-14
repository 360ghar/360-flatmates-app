import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/features/profile/presentation/widgets/edit_profile_dropdown_utils.dart';

void main() {
  group('dropdownValueInIds', () {
    test('returns value when it appears exactly once', () {
      expect(dropdownValueInIds('a', ['a', 'b', 'c']), 'a');
    });

    test('returns null when value is missing', () {
      expect(dropdownValueInIds('x', ['a', 'b', 'c']), isNull);
    });

    test('returns null when value is duplicated', () {
      expect(dropdownValueInIds('a', ['a', 'b', 'a']), isNull);
    });

    test('returns null when value is null', () {
      expect(dropdownValueInIds(null, ['a', 'b']), isNull);
    });

    test('returns value when it appears once among nullable ids', () {
      expect(dropdownValueInIds('b', ['a', null, 'b']), 'b');
    });
  });

  group('dropdownValueOrFirst', () {
    test('returns matched value when present', () {
      expect(dropdownValueOrFirst('b', ['a', 'b', 'c']), 'b');
    });

    test('falls back to first id when missing', () {
      expect(dropdownValueOrFirst('z', ['a', 'b', 'c']), 'a');
    });

    test('falls back to first non-null id', () {
      expect(dropdownValueOrFirst('z', [null, 'b', 'c']), 'b');
    });

    test('returns null when all ids are null', () {
      expect(dropdownValueOrFirst('z', [null, null]), isNull);
    });

    test('returns null when ids is empty', () {
      expect(dropdownValueOrFirst('a', const []), isNull);
    });
  });

  group('resolveMoveInTimelineId', () {
    test('maps legacy flexible onto just_exploring', () {
      expect(
        resolveMoveInTimelineId('flexible', ['immediately', 'just_exploring']),
        'just_exploring',
      );
    });

    test('maps immediate onto immediately', () {
      expect(
        resolveMoveInTimelineId('immediate', ['immediately', 'just_exploring']),
        'immediately',
      );
    });

    test('keeps exact catalog id', () {
      expect(
        resolveMoveInTimelineId('within_1_month', [
          'immediately',
          'within_1_month',
          'just_exploring',
        ]),
        'within_1_month',
      );
    });

    test('maps flexible onto flexible when only legacy fallback exists', () {
      // When the catalog only has 'flexible' (legacy) and not 'just_exploring',
      // the alias chain should still find 'flexible'.
      expect(
        resolveMoveInTimelineId('flexible', ['immediately', 'flexible']),
        'flexible',
      );
    });

    test('returns null when no alias matches available ids', () {
      expect(resolveMoveInTimelineId('flexible', ['within_2_weeks']), isNull);
    });

    test('returns null when ids is empty', () {
      expect(resolveMoveInTimelineId('flexible', const []), isNull);
    });

    test('normalizes hyphens to underscores', () {
      expect(
        resolveMoveInTimelineId('just-exploring', [
          'immediately',
          'just_exploring',
        ]),
        'just_exploring',
      );
    });

    test('handles null value gracefully', () {
      expect(
        resolveMoveInTimelineId(null, ['immediately', 'just_exploring']),
        'just_exploring',
      );
    });
  });
}
