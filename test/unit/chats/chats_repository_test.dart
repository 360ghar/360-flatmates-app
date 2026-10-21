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
    test('sends cursor (not before_id) and reads the CursorPage', () async {
      String? cursor;
      String? path;
      Map<String, dynamic>? query;
      final container = _containerWithAdapter((options) {
        path = options.path;
        query = options.queryParameters;
        cursor = options.queryParameters['cursor'] as String?;
        return Response<dynamic>(
          data: {
            'items': [
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
                'sender_id': null,
                'body': 'System notice',
                'message_type': 'system',
                'created_at': '2025-05-15T14:00:00Z',
              },
            ],
            'next_cursor': 'opaque-older',
            'has_more': true,
            'limit': 50,
            'total': null,
          },
          statusCode: 200,
          requestOptions: options,
        );
      });

      final repo = container.read(chatsRepositoryProvider);
      final page = await repo.fetchMessages(10, cursor: 'opaque-newer');

      expect(path, '/flatmates/conversations/10/messages');
      expect(cursor, 'opaque-newer');
      expect(query, isNot(contains('before_id')));
      expect(page.messages.length, 2);
      expect(page.hasMore, isTrue);
      // The cursor of the older page is passed back unchanged.
      expect(page.nextCursor, 'opaque-older');
      // A null sender stays null: it is a system notice, not user 0.
      expect(page.messages.first.senderId, 2);
      expect(page.messages.last.senderId, isNull);
      expect(page.messages.last.isSystem, isTrue);
    });

    test('has no next cursor on the last page', () async {
      final container = _containerWithAdapter((options) {
        return Response<dynamic>(
          data: {
            'items': [
              {
                'id': 1,
                'conversation_id': 10,
                'sender_id': 1,
                'body': 'first',
                'message_type': 'text',
                'created_at': '2025-05-15T13:00:00Z',
              },
            ],
            'next_cursor': null,
            'has_more': false,
            'limit': 50,
            'total': null,
          },
          statusCode: 200,
          requestOptions: options,
        );
      });

      final page = await container
          .read(chatsRepositoryProvider)
          .fetchMessages(10);

      expect(page.hasMore, isFalse);
      expect(page.nextCursor, isNull);
    });

    test('ignores the old messages envelope', () async {
      final container = _containerWithAdapter((options) {
        // The removed shape ({messages, total, has_more}) has no `items`.
        return Response<dynamic>(
          data: {
            'messages': [
              {
                'id': 50,
                'conversation_id': 10,
                'sender_id': 2,
                'body': 'should be ignored',
                'message_type': 'text',
                'created_at': '2025-05-15T13:00:00Z',
              },
            ],
            'total': 1,
            'has_more': false,
          },
          statusCode: 200,
          requestOptions: options,
        );
      });

      final page = await container
          .read(chatsRepositoryProvider)
          .fetchMessages(10);

      expect(page.messages, isEmpty);
    });
  });

  group('ChatsRepository.fetchMatchPhone', () {
    Map<String, dynamic> match(int id, int peerId, String status) => {
      'id': id,
      'status': status,
      'peer': {'id': peerId, 'full_name': 'Peer $peerId'},
    };

    test('reads the phone from the match contact route only', () async {
      final paths = <String>[];
      final container = _containerWithAdapter((options) {
        paths.add(options.path);
        if (options.path == '/flatmates/matches') {
          return Response<dynamic>(
            data: {
              'items': [match(8, 7, 'active'), match(9, 3, 'active')],
              'next_cursor': null,
              'has_more': false,
              'limit': 100,
              'total': null,
            },
            statusCode: 200,
            requestOptions: options,
          );
        }
        return Response<dynamic>(
          data: {'match_id': 9, 'peer_user_id': 3, 'phone': '+919800000003'},
          statusCode: 200,
          requestOptions: options,
        );
      });

      final phone = await container
          .read(chatsRepositoryProvider)
          .fetchMatchPhone(3);

      expect(phone, '+919800000003');
      expect(paths, ['/flatmates/matches', '/flatmates/matches/9/contact']);
    });

    test('follows next_cursor to find the match', () async {
      final cursors = <String?>[];
      final container = _containerWithAdapter((options) {
        if (options.path == '/flatmates/matches') {
          final cursor = options.queryParameters['cursor'] as String?;
          cursors.add(cursor);
          return Response<dynamic>(
            data: cursor == null
                ? {
                    'items': [match(1, 2, 'active')],
                    'next_cursor': 'page-2',
                    'has_more': true,
                    'limit': 100,
                    'total': null,
                  }
                : {
                    'items': [match(5, 7, 'active')],
                    'next_cursor': null,
                    'has_more': false,
                    'limit': 100,
                    'total': null,
                  },
            statusCode: 200,
            requestOptions: options,
          );
        }
        return Response<dynamic>(
          data: {'match_id': 5, 'peer_user_id': 7, 'phone': '+919800000007'},
          statusCode: 200,
          requestOptions: options,
        );
      });

      final phone = await container
          .read(chatsRepositoryProvider)
          .fetchMatchPhone(7);

      expect(phone, '+919800000007');
      expect(cursors, [null, 'page-2']);
    });

    test('has no phone for a peer without an active match', () async {
      final paths = <String>[];
      final container = _containerWithAdapter((options) {
        paths.add(options.path);
        return Response<dynamic>(
          data: {
            'items': [match(8, 7, 'blocked'), match(9, 3, 'unmatched')],
            'next_cursor': null,
            'has_more': false,
            'limit': 100,
            'total': null,
          },
          statusCode: 200,
          requestOptions: options,
        );
      });

      final repo = container.read(chatsRepositoryProvider);

      expect(await repo.fetchMatchPhone(7), isNull);
      expect(await repo.fetchMatchPhone(3), isNull);
      expect(await repo.fetchMatchPhone(99), isNull);
      // No contact call is made without an active match.
      expect(paths.where((p) => p.endsWith('/contact')), isEmpty);
    });

    test('maps a 404 MATCH_NOT_FOUND to no phone', () async {
      final container = _containerWithAdapter((options) {
        if (options.path == '/flatmates/matches') {
          return Response<dynamic>(
            data: {
              'items': [match(8, 7, 'active')],
              'next_cursor': null,
              'has_more': false,
              'limit': 100,
              'total': null,
            },
            statusCode: 200,
            requestOptions: options,
          );
        }
        return Response<dynamic>(
          data: {
            'error': {'code': 'MATCH_NOT_FOUND', 'message': 'No active match'},
          },
          statusCode: 404,
          requestOptions: options,
        );
      });

      final phone = await container
          .read(chatsRepositoryProvider)
          .fetchMatchPhone(7);

      expect(phone, isNull);
    });
  });

  group('ChatsRepository.unmatchConversation', () {
    test('posts /flatmates/unmatch with the peer id and no block', () async {
      String? path;
      Map<String, dynamic>? sentData;
      final container = _containerWithAdapter((options) {
        path = options.path;
        sentData = Map<String, dynamic>.from(options.data as Map);
        return Response<dynamic>(
          data: {'id': 4, 'status': 'unmatched'},
          statusCode: 200,
          requestOptions: options,
        );
      });

      await container.read(chatsRepositoryProvider).unmatchConversation(10, 7);

      expect(path, '/flatmates/unmatch');
      expect(sentData, {'peer_user_id': 7});
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
