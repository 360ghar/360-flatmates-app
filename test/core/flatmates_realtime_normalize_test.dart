import 'package:flatmates_app/core/network/flatmates_realtime_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeFlatmatesBroadcastData', () {
    test('unwraps nested payload.data from backend broadcast shape', () {
      final data = normalizeFlatmatesBroadcastData({
        'type': 'broadcast',
        'event': 'new_match',
        'payload': {
          'type': 'new_match',
          'data': {'match_id': 9},
          'sent_at': '2026-07-10T00:00:00Z',
        },
      });
      expect(data['match_id'], 9);
    });

    test('accepts flat data maps', () {
      final data = normalizeFlatmatesBroadcastData({
        'type_key': 'flatmate_new_message',
        'route': '/chats/3',
      });
      expect(data['route'], '/chats/3');
    });
  });
}
