import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flatmates_app/core/config/endpoints.dart';
import 'package:flatmates_app/core/network/api_client.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/features/chats/chats_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('ChatsRepository', () {
    test('fetchIncomingLikes reads backend likes payload', () async {
      final adapter = _CapturingAdapter(
        responseBody: [
          {
            'id': 7,
            'peer': {
              'id': 44,
              'full_name': 'Incoming User',
              'profile_image_url': 'https://example.com/p.jpg',
              'mode': 'seeker',
              'city': 'Gurugram',
              'match_percentage': 91,
            },
            'context_property': {
              'id': 99,
              'title': 'Sunny room',
              'monthly_rent': 18000,
            },
            'created_at': '2026-05-07T08:30:00Z',
          },
        ],
      );
      final apiClient = ApiClient(
        baseUrl: 'https://api.test.example.com',
        tokenProvider: FakeAuthTokenProvider(),
        enableLogging: false,
      );
      apiClient.dio.httpClientAdapter = adapter;
      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(apiClient)],
      );
      addTearDown(container.dispose);

      final likes = await container
          .read(chatsRepositoryProvider)
          .fetchIncomingLikes();

      expect(adapter.lastRequest?.path, FlatmatesEndpoints.incomingLikes);
      expect(adapter.lastRequest?.method, 'GET');
      expect(likes, hasLength(1));
      expect(likes.first.id, 7);
      expect(likes.first.peer.id, 44);
      expect(likes.first.peer.fullName, 'Incoming User');
      expect(likes.first.contextProperty?.id, 99);
    });

    test('matchIncomingLike posts reciprocal profile swipe', () async {
      final adapter = _CapturingAdapter(responseBody: {'conversation_id': 123});
      final apiClient = ApiClient(
        baseUrl: 'https://api.test.example.com',
        tokenProvider: FakeAuthTokenProvider(),
        enableLogging: false,
      );
      apiClient.dio.httpClientAdapter = adapter;
      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(apiClient)],
      );
      addTearDown(container.dispose);

      final conversationId = await container
          .read(chatsRepositoryProvider)
          .matchIncomingLike(peerId: 44, contextPropertyId: 99);

      expect(conversationId, 123);
      expect(adapter.lastRequest?.path, FlatmatesEndpoints.swipes);
      expect(adapter.lastRequest?.method, 'POST');
      expect(adapter.lastRequest?.data, {
        'target_type': 'user',
        'action': 'like',
        'target_user_id': 44,
        'context_property_id': 99,
      });
    });

    test('submitQnA posts backend-compatible nested numeric answers', () async {
      final adapter = _CapturingAdapter();
      final apiClient = ApiClient(
        baseUrl: 'https://api.test.example.com',
        tokenProvider: FakeAuthTokenProvider(),
        enableLogging: false,
      );
      apiClient.dio.httpClientAdapter = adapter;
      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(apiClient)],
      );
      addTearDown(container.dispose);

      await container.read(chatsRepositoryProvider).submitQnA(42, {
        'q1': '  Quiet home near work  ',
        'q2': '3',
        'q3': ' Clean kitchen ',
      });

      expect(adapter.lastRequest?.path, FlatmatesEndpoints.conversationQnA(42));
      expect(adapter.lastRequest?.method, 'POST');
      expect(adapter.lastRequest?.data, {
        'answers': {
          '0': 'Quiet home near work',
          '1': '3',
          '2': 'Clean kitchen',
        },
      });
    });
  });
}

class _CapturingAdapter implements HttpClientAdapter {
  _CapturingAdapter({this.responseBody = const {}});

  final Object responseBody;
  RequestOptions? lastRequest;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      jsonEncode(responseBody),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
