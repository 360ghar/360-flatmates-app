import 'package:flutter_test/flutter_test.dart';

import 'api_fixtures.dart';

/// Checks of what the app sends against the contract the backend publishes
/// (`test/fixtures/api/requests.json` and `operations.json`).
///
/// A write body rejects unknown keys (422), a PATCH sends only the keys it
/// changes, and an undeclared query key is a 422 too.

/// Fails when [body] breaks the body contract [requestName]: an undeclared key
/// (when the schema forbids extras), a missing required key, a null on a field
/// that is not nullable, a value of the wrong type, outside its enum, or
/// outside its length and number bounds.
void expectBodyMatchesContract(Map<dynamic, dynamic> body, String requestName) {
  final contract = apiFixture('requests', requestName);
  final properties = Map<String, dynamic>.from(contract['properties'] as Map);
  final required = (contract['required'] as List).cast<String>();
  final extraForbidden = contract['extra_forbidden'] as bool;

  for (final key in required) {
    expect(body.containsKey(key), isTrue, reason: '$requestName needs "$key"');
  }
  for (final entry in body.entries) {
    final key = entry.key as String;
    final spec = properties[key];
    if (spec == null) {
      expect(
        extraForbidden,
        isFalse,
        reason: '$requestName does not declare "$key" (422 extra_forbidden)',
      );
      continue;
    }
    _expectValue(
      requestName,
      key,
      entry.value,
      Map<String, dynamic>.from(spec as Map),
    );
  }
}

void _expectValue(
  String request,
  String key,
  Object? value,
  Map<String, dynamic> spec,
) {
  final where = '$request.$key';
  if (value == null) {
    expect(spec['nullable'], isTrue, reason: '$where is not nullable');
    return;
  }
  switch (spec['type']) {
    case 'string':
      expect(value, isA<String>(), reason: '$where is a string');
      final text = value as String;
      if (spec['maxLength'] != null) {
        expect(
          text.length,
          lessThanOrEqualTo(spec['maxLength'] as int),
          reason: '$where is too long',
        );
      }
      if (spec['minLength'] != null) {
        expect(
          text.length,
          greaterThanOrEqualTo(spec['minLength'] as int),
          reason: '$where is too short',
        );
      }
      if (spec['enum'] != null) {
        expect(
          spec['enum'],
          contains(text),
          reason: '$where is not in its enum',
        );
      }
    case 'integer':
      expect(value, isA<int>(), reason: '$where is an integer');
      _expectBounds(where, value as num, spec);
    case 'number':
      expect(value, isA<num>(), reason: '$where is a number');
      _expectBounds(where, value as num, spec);
    case 'boolean':
      expect(value, isA<bool>(), reason: '$where is a boolean');
    case 'array':
      expect(value, isA<List>(), reason: '$where is a list');
    case 'object':
      expect(value, isA<Map>(), reason: '$where is an object');
  }
}

void _expectBounds(String where, num value, Map<String, dynamic> spec) {
  if (spec['minimum'] != null) {
    expect(
      value,
      greaterThanOrEqualTo(spec['minimum'] as num),
      reason: '$where is below its minimum',
    );
  }
  if (spec['exclusiveMinimum'] != null) {
    expect(
      value,
      greaterThan(spec['exclusiveMinimum'] as num),
      reason: '$where is not above its exclusive minimum',
    );
  }
  if (spec['maximum'] != null) {
    expect(
      value,
      lessThanOrEqualTo(spec['maximum'] as num),
      reason: '$where is above its maximum',
    );
  }
}

/// The operation [operation] (for example `GET /api/v1/visits`) of the
/// published OpenAPI document.
Map<String, dynamic> operationContract(String operation) {
  final spec = apiFixtureGroup('operations')[operation];
  if (spec is! Map) {
    throw StateError('no operation "$operation" in the backend OpenAPI');
  }
  return Map<String, dynamic>.from(spec);
}

/// Fails when [query] has a key the operation does not declare (422), or a
/// number outside the declared bounds (for example `limit` above 100).
void expectQueryMatchesContract(Map<String, dynamic> query, String operation) {
  final declared = Map<String, dynamic>.from(
    operationContract(operation)['query'] as Map,
  );
  for (final entry in query.entries) {
    expect(
      declared.containsKey(entry.key),
      isTrue,
      reason: '$operation does not declare the query key "${entry.key}"',
    );
    final bounds = Map<String, dynamic>.from(declared[entry.key] as Map);
    final raw = entry.value;
    final number = raw is num
        ? raw
        : (raw is String ? num.tryParse(raw) : null);
    if (number != null) {
      _expectBounds('$operation ${entry.key}', number, bounds);
    }
  }
}

/// The values of a list of declared enum values of [name] in `enums.json`.
List<String> backendEnum(String name) {
  final values = apiFixtureGroup('enums')[name];
  if (values is! List) throw StateError('no enum "$name" in enums.json');
  return values.cast<String>();
}
