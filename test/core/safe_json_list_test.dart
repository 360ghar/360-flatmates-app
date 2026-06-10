import 'package:flatmates_app/core/utils/safe_json_list.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeModel {
  const _FakeModel(this.id);

  final int id;

  factory _FakeModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! int) {
      throw const FormatException('id must be an int');
    }
    return _FakeModel(id);
  }
}

void main() {
  group('safeJsonList', () {
    test('parses all valid items', () {
      final result = safeJsonList(
        [
          {'id': 1},
          {'id': 2},
          {'id': 3},
        ],
        _FakeModel.fromJson,
        label: 'test',
      );
      expect(result.map((m) => m.id), [1, 2, 3]);
    });

    test('skips items whose fromJson throws and keeps the rest', () {
      final result = safeJsonList(
        [
          {'id': 1},
          {'id': 'broken'},
          {'id': 3},
        ],
        _FakeModel.fromJson,
        label: 'test',
      );
      expect(result.map((m) => m.id), [1, 3]);
    });

    test('skips non-Map items', () {
      final result = safeJsonList(
        [
          {'id': 1},
          'not a map',
          42,
          null,
          {'id': 2},
        ],
        _FakeModel.fromJson,
        label: 'test',
      );
      expect(result.map((m) => m.id), [1, 2]);
    });

    test('returns empty list for null input', () {
      expect(safeJsonList(null, _FakeModel.fromJson, label: 'test'), isEmpty);
    });

    test('returns empty list for empty input', () {
      expect(
        safeJsonList(const [], _FakeModel.fromJson, label: 'test'),
        isEmpty,
      );
    });

    test('returns empty list when every item is malformed', () {
      final result = safeJsonList(
        [
          {'id': 'a'},
          {'id': 'b'},
        ],
        _FakeModel.fromJson,
        label: 'test',
      );
      expect(result, isEmpty);
    });
  });
}
