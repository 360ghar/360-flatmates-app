import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flatmates_app/core/config/endpoints.dart';
import 'package:flatmates_app/core/network/api_client.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/features/chats/application/chat_actions_controller.dart';
import 'package:flatmates_app/features/chats/chats_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('ChatActionsController invalidation', () {
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

    test('blockUser refreshes the conversation list', () async {
      // Prime the conversations cache (one GET).
      await container.read(conversationsProvider.future);
      final getsBefore = adapter.count('GET', FlatmatesEndpoints.conversations);
      expect(getsBefore, 1);

      await container.read(chatActionsControllerProvider).blockUser(44);

      // Invalidation makes the next read re-fetch from the backend.
      await container.read(conversationsProvider.future);
      expect(adapter.count('GET', FlatmatesEndpoints.conversations), 2);
      // And the block itself was POSTed.
      expect(adapter.count('POST', FlatmatesEndpoints.blocks), 1);
    });

    test('unmatchConversation refreshes the conversation list', () async {
      await container.read(conversationsProvider.future);
      expect(adapter.count('GET', FlatmatesEndpoints.conversations), 1);

      await container
          .read(chatActionsControllerProvider)
          .unmatchConversation(7, 44);

      await container.read(conversationsProvider.future);
      expect(adapter.count('GET', FlatmatesEndpoints.conversations), 2);
      expect(adapter.count('POST', FlatmatesEndpoints.blocks), 1);
    });
  });
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
    // Conversations endpoint now returns the cursor envelope `{ items, ... }`;
    // everything else a map.
    final body = options.path == FlatmatesEndpoints.conversations
        ? <String, dynamic>{
            'items': <Object>[],
            'next_cursor': null,
            'has_more': false,
            'limit': 20,
          }
        : <String, dynamic>{};
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
