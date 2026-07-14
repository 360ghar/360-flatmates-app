import 'package:flutter_test/flutter_test.dart';

import 'package:flatmates_app/core/network/flatmates_realtime_service.dart';

void main() {
  group('normalizeFlatmatesBroadcastData', () {
    test('unwraps nested payload.data from backend broadcast shape', () {
      final payload = <String, dynamic>{
        'type': 'new_message',
        'payload': {
          'data': {'conversation_id': 42, 'message': 'hello'},
          'sent_at': '2024-01-01T00:00:00Z',
        },
      };
      final result = normalizeFlatmatesBroadcastData(payload);
      expect(result['conversation_id'], 42);
      expect(result['message'], 'hello');
    });

    test('returns payload.data when payload has no inner data', () {
      final payload = <String, dynamic>{
        'type': 'new_match',
        'payload': {'match_id': 99, 'sent_at': '2024-01-01T00:00:00Z'},
      };
      final result = normalizeFlatmatesBroadcastData(payload);
      expect(result['match_id'], 99);
    });

    test('returns body directly when no payload key exists', () {
      final payload = <String, dynamic>{
        'type': 'new_notification',
        'notification_id': 5,
      };
      final result = normalizeFlatmatesBroadcastData(payload);
      expect(result['notification_id'], 5);
    });

    test('returns body when payload is not a Map', () {
      final payload = <String, dynamic>{
        'type': 'new_message',
        'payload': 'not a map',
      };
      final result = normalizeFlatmatesBroadcastData(payload);
      // When payload is not a Map, body = payload (the original).
      expect(result['type'], 'new_message');
    });

    test('unwraps data from body when no payload wrapper exists', () {
      final payload = <String, dynamic>{
        'data': {'conversation_id': 77},
      };
      final result = normalizeFlatmatesBroadcastData(payload);
      expect(result['conversation_id'], 77);
    });

    test('handles deeply nested payload.data with nested maps', () {
      final payload = <String, dynamic>{
        'payload': {
          'data': {
            'nested': {'key': 'value'},
            'list': [1, 2, 3],
          },
        },
      };
      final result = normalizeFlatmatesBroadcastData(payload);
      expect(result['nested'], isA<Map>());
      expect(result['list'], [1, 2, 3]);
    });

    test('returns empty map for empty payload', () {
      final result = normalizeFlatmatesBroadcastData(<String, dynamic>{});
      expect(result, isEmpty);
    });
  });
}
