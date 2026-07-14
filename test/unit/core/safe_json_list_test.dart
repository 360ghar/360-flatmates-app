import 'package:flutter_test/flutter_test.dart';

import 'package:flatmates_app/core/utils/safe_json_list.dart';

/// A simple model for testing [safeJsonList].
class _TestItem {
  const _TestItem(this.value);
  final int value;

  static _TestItem fromJson(Map<String, dynamic> json) {
    final value = json['value'] as int;
    if (value < 0) throw const FormatException('Negative value not allowed');
    return _TestItem(value);
  }
}

void main() {
  group('safeJsonList', () {
    test('returns empty list when rows is null', () {
      final result = safeJsonList<_TestItem>(
        null,
        _TestItem.fromJson,
        label: 'test',
      );
      expect(result, isEmpty);
    });

    test('returns empty list when rows is empty', () {
      final result = safeJsonList<_TestItem>(
        <dynamic>[],
        _TestItem.fromJson,
        label: 'test',
      );
      expect(result, isEmpty);
    });

    test('parses all valid items', () {
      final result = safeJsonList<_TestItem>(
        <dynamic>[
          {'value': 1},
          {'value': 2},
          {'value': 3},
        ],
        _TestItem.fromJson,
        label: 'test',
      );
      expect(result, hasLength(3));
      expect(result[0].value, 1);
      expect(result[1].value, 2);
      expect(result[2].value, 3);
    });

    test('skips items whose fromJson throws', () {
      final result = safeJsonList<_TestItem>(
        <dynamic>[
          {'value': 1},
          {'value': -1}, // throws
          {'value': 3},
        ],
        _TestItem.fromJson,
        label: 'test',
      );
      expect(result, hasLength(2));
      expect(result[0].value, 1);
      expect(result[1].value, 3);
    });

    test('skips non-Map items', () {
      final result = safeJsonList<_TestItem>(
        <dynamic>[
          {'value': 1},
          'not a map',
          42,
          null,
          {'value': 5},
        ],
        _TestItem.fromJson,
        label: 'test',
      );
      expect(result, hasLength(2));
      expect(result[0].value, 1);
      expect(result[1].value, 5);
    });

    test('returns empty list when every item is malformed', () {
      final result = safeJsonList<_TestItem>(
        <dynamic>[
          {'value': -1},
          {'value': -2},
          'not a map',
          42,
        ],
        _TestItem.fromJson,
        label: 'test',
      );
      expect(result, isEmpty);
    });

    test('skips items where fromJson throws on missing key', () {
      final result = safeJsonList<_TestItem>(
        <dynamic>[
          {'value': 1},
          {'other': 2}, // missing 'value' → cast throws
          {'value': 3},
        ],
        _TestItem.fromJson,
        label: 'test',
      );
      expect(result, hasLength(2));
      expect(result[0].value, 1);
      expect(result[1].value, 3);
    });
  });
}
