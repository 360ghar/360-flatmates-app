import 'dart:convert';
import 'dart:io';

/// The backend-generated fixtures of `test/fixtures/api/<group>.json`, written
/// by `tool/api_fixtures.py` (every response is validated through the backend
/// Pydantic response model and dumped as FastAPI sends it).
Map<String, dynamic> apiFixtureGroup(String group) {
  final file = File('test/fixtures/api/$group.json');
  return Map<String, dynamic>.from(json.decode(file.readAsStringSync()) as Map);
}

/// One fixture (a JSON object) of [group].
Map<String, dynamic> apiFixture(String group, String name) {
  final value = apiFixtureGroup(group)[name];
  if (value is! Map) {
    throw StateError('fixture $group.$name is not a JSON object');
  }
  return Map<String, dynamic>.from(value);
}

/// The items of the CursorPage fixture [name] of [group].
List<Map<String, dynamic>> apiFixtureItems(String group, String name) {
  final items = apiFixture(group, name)['items'] as List;
  return [for (final item in items) Map<String, dynamic>.from(item as Map)];
}
