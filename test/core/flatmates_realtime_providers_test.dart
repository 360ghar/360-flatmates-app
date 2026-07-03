import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flatmates_app/core/config/endpoints.dart';
import 'package:flatmates_app/core/network/flatmates_realtime_service.dart';
import 'package:flatmates_app/core/network/api_client.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/features/chats/application/chats_realtime_router.dart';
import 'package:flatmates_app/features/chats/chats_repository.dart';
import 'package:flatmates_app/features/notifications/application/notifications_realtime_router.dart';
import 'package:flatmates_app/features/notifications/notifications_repository.dart';
import 'package:flatmates_app/features/visits/application/visits_realtime_router.dart';
import 'package:flatmates_app/features/visits/visits_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('Flatmates realtime feature routing', () {
    late _CountingAdapter adapter;
    late ProviderContainer container;

    setUp(() {
      adapter = _CountingAdapter();
      final apiClient = ApiClient(
        baseUrl: 'https://api.test.example.com',
        tokenProvider: FakeAuthTokenProvider(),
      );
      apiClient.dio.httpClientAdapter = adapter;
      container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(apiClient)],
      );
      addTearDown(container.dispose);
    });

    test('extracts conversation ids from chat routes', () {
      expect(conversationIdFromRoute('/chats/42'), 42);
      expect(conversationIdFromRoute('flatmates://app/chats/42'), 42);
      expect(conversationIdFromRoute('/home'), isNull);
      expect(conversationIdFromRoute('/chats/not-a-number'), isNull);
    });

    test(
      'flatmate_new_message refreshes conversations and thread messages',
      () async {
        await container.read(conversationsProvider.future);
        await container.read(messagesProvider(42).future);
        final conversationsBefore = adapter.count(
          'GET',
          FlatmatesEndpoints.conversations,
        );
        final messagesBefore = adapter.count(
          'GET',
          FlatmatesEndpoints.conversationMessages(42),
        );

        _routeChats(
          container,
          const FlatmatesRealtimeEvent(
            type: 'new_notification',
            data: {'type_key': 'flatmate_new_message', 'route': '/chats/42'},
          ),
        );
        await container.pump();

        await container.read(conversationsProvider.future);
        await container.read(messagesProvider(42).future);
        expect(
          adapter.count('GET', FlatmatesEndpoints.conversations),
          greaterThan(conversationsBefore),
        );
        expect(
          adapter.count('GET', FlatmatesEndpoints.conversationMessages(42)),
          greaterThan(messagesBefore),
        );
      },
    );

    test('new_message refreshes conversations and thread messages', () async {
      await container.read(conversationsProvider.future);
      await container.read(messagesProvider(42).future);
      final conversationsBefore = adapter.count(
        'GET',
        FlatmatesEndpoints.conversations,
      );
      final messagesBefore = adapter.count(
        'GET',
        FlatmatesEndpoints.conversationMessages(42),
      );

      _routeChats(
        container,
        const FlatmatesRealtimeEvent(
          type: 'new_message',
          data: {'conversation_id': '42'},
        ),
      );
      await container.pump();

      await container.read(conversationsProvider.future);
      await container.read(messagesProvider(42).future);
      expect(
        adapter.count('GET', FlatmatesEndpoints.conversations),
        greaterThan(conversationsBefore),
      );
      expect(
        adapter.count('GET', FlatmatesEndpoints.conversationMessages(42)),
        greaterThan(messagesBefore),
      );
    });

    test(
      'conversation_updated refreshes conversations and thread messages',
      () async {
        await container.read(conversationsProvider.future);
        await container.read(messagesProvider(42).future);
        final conversationsBefore = adapter.count(
          'GET',
          FlatmatesEndpoints.conversations,
        );
        final messagesBefore = adapter.count(
          'GET',
          FlatmatesEndpoints.conversationMessages(42),
        );

        _routeChats(
          container,
          const FlatmatesRealtimeEvent(
            type: 'conversation_updated',
            data: {'conversation_id': 42},
          ),
        );
        await container.pump();

        await container.read(conversationsProvider.future);
        await container.read(messagesProvider(42).future);
        expect(
          adapter.count('GET', FlatmatesEndpoints.conversations),
          greaterThan(conversationsBefore),
        );
        expect(
          adapter.count('GET', FlatmatesEndpoints.conversationMessages(42)),
          greaterThan(messagesBefore),
        );
      },
    );

    test('flatmate_new_match refreshes conversations and like tabs', () async {
      await container.read(conversationsProvider.future);
      await container.read(incomingLikesProvider.future);
      await container.read(outgoingLikesProvider.future);
      final conversationsBefore = adapter.count(
        'GET',
        FlatmatesEndpoints.conversations,
      );
      final incomingBefore = adapter.count(
        'GET',
        FlatmatesEndpoints.incomingLikes,
      );
      final outgoingBefore = adapter.count(
        'GET',
        FlatmatesEndpoints.outgoingLikes,
      );

      _routeChats(
        container,
        const FlatmatesRealtimeEvent(
          type: 'new_notification',
          data: {'type_key': 'flatmate_new_match'},
        ),
      );
      await container.pump();

      await container.read(conversationsProvider.future);
      await container.read(incomingLikesProvider.future);
      await container.read(outgoingLikesProvider.future);

      expect(
        adapter.count('GET', FlatmatesEndpoints.conversations),
        greaterThan(conversationsBefore),
      );
      expect(
        adapter.count('GET', FlatmatesEndpoints.incomingLikes),
        greaterThan(incomingBefore),
      );
      expect(
        adapter.count('GET', FlatmatesEndpoints.outgoingLikes),
        greaterThan(outgoingBefore),
      );
    });

    test('new_match events refresh conversations and like tabs', () async {
      await container.read(conversationsProvider.future);
      await container.read(incomingLikesProvider.future);
      await container.read(outgoingLikesProvider.future);
      final conversationsBefore = adapter.count(
        'GET',
        FlatmatesEndpoints.conversations,
      );
      final incomingBefore = adapter.count(
        'GET',
        FlatmatesEndpoints.incomingLikes,
      );
      final outgoingBefore = adapter.count(
        'GET',
        FlatmatesEndpoints.outgoingLikes,
      );

      _routeChats(
        container,
        const FlatmatesRealtimeEvent(type: 'new_match', data: {}),
      );
      await container.pump();

      await container.read(conversationsProvider.future);
      await container.read(incomingLikesProvider.future);
      await container.read(outgoingLikesProvider.future);

      expect(
        adapter.count('GET', FlatmatesEndpoints.conversations),
        greaterThan(conversationsBefore),
      );
      expect(
        adapter.count('GET', FlatmatesEndpoints.incomingLikes),
        greaterThan(incomingBefore),
      );
      expect(
        adapter.count('GET', FlatmatesEndpoints.outgoingLikes),
        greaterThan(outgoingBefore),
      );
    });

    test('generic notifications refresh notifications only', () async {
      await container.read(notificationsProvider.future);
      await container.read(conversationsProvider.future);

      _routeNotifications(
        container,
        const FlatmatesRealtimeEvent(
          type: 'new_notification',
          data: {'type_key': 'flatmate_listing_approved'},
        ),
      );
      await container.pump();

      await container.read(notificationsProvider.future);
      await container.read(conversationsProvider.future);

      expect(adapter.count('GET', FlatmatesEndpoints.notifications), 2);
      expect(adapter.count('GET', FlatmatesEndpoints.conversations), 1);
    });

    test('visit_updated refreshes visits', () async {
      await container.read(visitsProvider.future);
      final visitsBefore = adapter.count('GET', FlatmatesEndpoints.visits);

      _routeVisits(
        container,
        const FlatmatesRealtimeEvent(type: 'visit_updated', data: {}),
      );
      await container.pump();

      await container.read(visitsProvider.future);
      expect(
        adapter.count('GET', FlatmatesEndpoints.visits),
        greaterThan(visitsBefore),
      );
    });
  });
}

void _routeChats(ProviderContainer container, FlatmatesRealtimeEvent event) {
  final triggerProvider = Provider<void>((ref) {
    routeChatsRealtimeEvent(ref, event);
  });
  container.read(triggerProvider);
}

void _routeNotifications(
  ProviderContainer container,
  FlatmatesRealtimeEvent event,
) {
  final triggerProvider = Provider<void>((ref) {
    routeNotificationsRealtimeEvent(ref, event);
  });
  container.read(triggerProvider);
}

void _routeVisits(ProviderContainer container, FlatmatesRealtimeEvent event) {
  final triggerProvider = Provider<void>((ref) {
    routeVisitsRealtimeEvent(ref, event);
  });
  container.read(triggerProvider);
}

class _CountingAdapter implements HttpClientAdapter {
  final List<String> _requests = [];

  int count(String method, String path) =>
      _requests.where((r) => r == '$method $path').length;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    _requests.add('${options.method} ${options.path}');
    return ResponseBody.fromString(
      jsonEncode(_bodyFor(options.path)),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  Object _bodyFor(String path) {
    if (path == FlatmatesEndpoints.conversationMessages(42)) {
      return {
        'items': [
          {
            'id': 1,
            'conversation_id': 42,
            'sender_id': 44,
            'body': 'hello',
            'message_type': 'text',
            'created_at': '2026-06-30T08:00:00Z',
          },
        ],
        'next_cursor': null,
        'has_more': false,
        'limit': 30,
      };
    }
    return {
      'items': <Object>[],
      'next_cursor': null,
      'has_more': false,
      'limit': 20,
    };
  }
}
