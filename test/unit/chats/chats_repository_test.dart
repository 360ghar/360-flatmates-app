import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/core/network/api_client.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/features/chats/chats_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../helpers/test_helpers.dart';

class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this.handler);
  final Response<dynamic> Function(RequestOptions) handler;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final response = handler(options);
    return ResponseBody.fromString(
      jsonEncode(response.data),
      response.statusCode ?? 200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }
}

ProviderContainer _containerWithAdapter(
  Response<dynamic> Function(RequestOptions) handler,
) {
  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(fakeAppConfig()),
      authTokenProviderProvider.overrideWithValue(FakeAuthTokenProvider()),
      apiClientProvider.overrideWithValue(
        ApiClient(
          baseUrl: 'https://api.test.example.com',
          tokenProvider: FakeAuthTokenProvider(),
        )..dio.httpClientAdapter = _ScriptedAdapter(handler),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('ChatsRepository.fetchMessages', () {
    test('uses before_id and MessageListResponse envelope', () async {
      int? beforeId;
      String? path;
      final container = _containerWithAdapter((options) {
        path = options.path;
        beforeId = options.queryParameters['before_id'] as int?;
        return Response<dynamic>(
          data: {
            'messages': [
              {
                'id': 50,
                'conversation_id': 10,
                'sender_id': 2,
                'body': 'older',
                'message_type': 'text',
                'created_at': '2025-05-15T13:00:00Z',
              },
              {
                'id': 60,
                'conversation_id': 10,
                'sender_id': 1,
                'body': 'newer',
                'message_type': 'text',
                'created_at': '2025-05-15T14:00:00Z',
              },
            ],
            'total': 2,
            'has_more': true,
          },
          statusCode: 200,
          requestOptions: options,
        );
      });

      final repo = container.read(chatsRepositoryProvider);
      final response = await repo.fetchMessages(10, beforeId: 100);

      expect(path, '/flatmates/conversations/10/messages');
      expect(beforeId, 100);
      expect(response.messages.length, 2);
      expect(response.hasMore, isTrue);
      expect(response.total, 2);
      // Chronological page: index 0 is oldest — used as next before_id.
      expect(response.nextBeforeId, 50);
    });

    test('ignores CursorPage-shaped payloads', () async {
      final container = _containerWithAdapter((options) {
        // Backend contract for messages is { messages, total, has_more }.
        // A CursorPage-shaped payload ({ items, next_cursor }) has no
        // `messages` key, so messages should be empty.
        return Response<dynamic>(
          data: {
            'items': [
              {
                'id': 50,
                'conversation_id': 10,
                'sender_id': 2,
                'body': 'should be ignored',
                'message_type': 'text',
                'created_at': '2025-05-15T13:00:00Z',
              },
            ],
            'next_cursor': 'abc',
          },
          statusCode: 200,
          requestOptions: options,
        );
      });

      final repo = container.read(chatsRepositoryProvider);
      final response = await repo.fetchMessages(10);

      expect(response.messages, isEmpty);
      expect(response.hasMore, isFalse);
    });
  });

  group('ChatsRepository.watchMessages', () {
    test('emits the REST seed page', () async {
      final container = _containerWithAdapter((options) {
        return Response<dynamic>(
          data: {
            'messages': [
              {
                'id': 100,
                'conversation_id': 10,
                'sender_id': 1,
                'body': 'seed',
                'message_type': 'text',
                'created_at': '2025-05-15T14:30:00Z',
              },
            ],
            'total': 1,
            'has_more': false,
          },
          statusCode: 200,
          requestOptions: options,
        );
      });

      final repo = container.read(chatsRepositoryProvider);
      final stream = repo.watchMessages(10);
      final first = await stream.first;

      expect(first.length, 1);
      expect(first.first.id, 100);
      expect(first.first.body, 'seed');
    });
  });

  group('ChatsRepository.fetchIncomingLikes', () {
    test('reads backend likes payload', () async {
      final container = _containerWithAdapter((options) {
        return Response<dynamic>(
          data: {
            'items': [
              {
                'id': 1,
                'peer': {
                  'id': 2,
                  'full_name': 'Priya',
                  'profile_image_url': null,
                },
                'created_at': '2025-05-10T09:00:00Z',
              },
              {
                'id': 2,
                'peer': {'id': 3, 'full_name': 'Rahul'},
                'created_at': '2025-05-11T09:00:00Z',
              },
            ],
            'next_cursor': null,
            'has_more': false,
          },
          statusCode: 200,
          requestOptions: options,
        );
      });

      final repo = container.read(chatsRepositoryProvider);
      final likes = await repo.fetchIncomingLikes();

      expect(likes.length, 2);
      expect(likes[0].peer.fullName, 'Priya');
      expect(likes[1].peer.id, 3);
    });
  });

  group('ChatsRepository.matchIncomingLike', () {
    test('posts reciprocal profile swipe', () async {
      String? method;
      String? path;
      Map<String, dynamic>? sentData;
      final container = _containerWithAdapter((options) {
        method = options.method;
        path = options.path;
        sentData = options.data is Map
            ? Map<String, dynamic>.from(options.data as Map)
            : null;
        return Response<dynamic>(
          data: {'conversation_id': 42},
          statusCode: 200,
          requestOptions: options,
        );
      });

      final repo = container.read(chatsRepositoryProvider);
      final conversationId = await repo.matchIncomingLike(
        peerId: 7,
        contextPropertyId: 99,
      );

      expect(method, 'POST');
      expect(path, '/flatmates/swipes');
      expect(sentData!['target_type'], 'user');
      expect(sentData!['action'], 'like');
      expect(sentData!['target_user_id'], 7);
      expect(sentData!['context_property_id'], 99);
      expect(conversationId, 42);
    });
  });

  group('ChatsRepository.submitQnA', () {
    test('posts backend-compatible nested numeric answers', () async {
      Map<String, dynamic>? sentData;
      String? path;
      final container = _containerWithAdapter((options) {
        path = options.path;
        sentData = options.data is Map
            ? Map<String, dynamic>.from(options.data as Map)
            : null;
        return Response<dynamic>(
          data: {},
          statusCode: 200,
          requestOptions: options,
        );
      });

      final repo = container.read(chatsRepositoryProvider);
      await repo.submitQnA(10, {
        'q1': 'A calm place',
        'q2': 'Balanced',
        'q3': 'Clean shared spaces',
      });

      expect(path, '/flatmates/conversations/10/qna');
      final answers = sentData!['answers'] as Map<String, dynamic>;
      // q1 -> '0', q2 -> '1', q3 -> '2' (backend numeric keys).
      expect(answers['0'], 'A calm place');
      expect(answers['1'], 'Balanced');
      expect(answers['2'], 'Clean shared spaces');
    });
  });
}
