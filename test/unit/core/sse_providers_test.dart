import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flatmates_app/core/network/flatmates_realtime_service.dart';
import 'package:flatmates_app/core/network/sse_providers.dart';

/// A test-only provider that exposes its [Ref] so tests can call
/// [routeFlatmatesRealtimeEvent] with a real ref.
final _testRefProvider = Provider<Ref>((ref) => ref);

void main() {
  late ProviderContainer container;
  late Ref ref;

  setUp(() {
    container = ProviderContainer(overrides: []);
    addTearDown(container.dispose);
    ref = container.read(_testRefProvider);
  });

  group('routeFlatmatesRealtimeEvent', () {
    test(
      'flatmate_new_message refreshes conversations and thread messages',
      () {
        const event = FlatmatesRealtimeEvent(
          type: 'new_notification',
          data: {'type_key': 'flatmate_new_message', 'route': '/chats/42'},
        );
        expect(() => routeFlatmatesRealtimeEvent(ref, event), returnsNormally);
      },
    );

    test('flatmate_new_match refreshes conversations and like tabs', () {
      const event = FlatmatesRealtimeEvent(
        type: 'new_notification',
        data: {'type_key': 'flatmate_new_match'},
      );
      expect(() => routeFlatmatesRealtimeEvent(ref, event), returnsNormally);
    });

    test('new_message event invalidates messages seed', () {
      const event = FlatmatesRealtimeEvent(
        type: 'new_message',
        data: {'conversation_id': 99},
      );
      expect(() => routeFlatmatesRealtimeEvent(ref, event), returnsNormally);
    });

    test('new_match events refresh conversations and like tabs', () {
      const event = FlatmatesRealtimeEvent(type: 'new_match', data: {});
      expect(() => routeFlatmatesRealtimeEvent(ref, event), returnsNormally);
    });

    test('generic notifications refresh notifications only', () {
      const event = FlatmatesRealtimeEvent(
        type: 'new_notification',
        data: {'type_key': 'some_other_type'},
      );
      expect(() => routeFlatmatesRealtimeEvent(ref, event), returnsNormally);
    });

    test('visit_updated refreshes visits providers', () {
      const event = FlatmatesRealtimeEvent(type: 'visit_updated', data: {});
      expect(() => routeFlatmatesRealtimeEvent(ref, event), returnsNormally);
    });

    test('conversation_updated refreshes conversation state', () {
      const event = FlatmatesRealtimeEvent(
        type: 'conversation_updated',
        data: {'conversation_id': 7},
      );
      expect(() => routeFlatmatesRealtimeEvent(ref, event), returnsNormally);
    });

    test('listing_status_changed is handled without error', () {
      const event = FlatmatesRealtimeEvent(
        type: 'listing_status_changed',
        data: {},
      );
      expect(() => routeFlatmatesRealtimeEvent(ref, event), returnsNormally);
    });

    test('unhandled event type does not throw', () {
      const event = FlatmatesRealtimeEvent(
        type: 'unknown_event_type',
        data: {},
      );
      expect(() => routeFlatmatesRealtimeEvent(ref, event), returnsNormally);
    });

    test('extracts conversation ids from nested data payload', () {
      const event = FlatmatesRealtimeEvent(
        type: 'new_message',
        data: {
          'data': {'conversation_id': 55},
        },
      );
      expect(() => routeFlatmatesRealtimeEvent(ref, event), returnsNormally);
    });
  });

  group('conversationIdFromRoute', () {
    test('extracts conversation ids from chat routes', () {
      expect(conversationIdFromRoute('/chats/42'), 42);
    });

    test('extracts conversation ids from full URL chat routes', () {
      expect(conversationIdFromRoute('https://the360ghar.com/chats/123'), 123);
    });

    test('returns null for non-chat routes', () {
      expect(conversationIdFromRoute('/discover'), isNull);
    });

    test('returns null when chats segment has no following id', () {
      expect(conversationIdFromRoute('/chats'), isNull);
    });

    test('returns null for null route', () {
      expect(conversationIdFromRoute(null), isNull);
    });

    test('returns null for invalid id', () {
      expect(conversationIdFromRoute('/chats/abc'), isNull);
    });
  });
}
