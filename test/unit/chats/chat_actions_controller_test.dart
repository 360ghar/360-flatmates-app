import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/core/network/api_client.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/features/chats/application/chat_actions_controller.dart';
import 'package:flatmates_app/features/chats/application/cursor_list_controller.dart';
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
  group('ChatActionsController', () {
    test('blockUser refreshes the conversation list', () async {
      final blockPaths = <String>[];
      final conversationFetchCount = {'count': 0};
      final container = _containerWithAdapter((options) {
        if (options.path == '/flatmates/blocks' && options.method == 'POST') {
          blockPaths.add(options.path);
          return Response<dynamic>(
            data: {},
            statusCode: 200,
            requestOptions: options,
          );
        }
        // Any list endpoint returns an empty page so the refresh loads
        // without error.
        if (options.path == '/flatmates/conversations' ||
            options.path == '/flatmates/likes' ||
            options.path == '/flatmates/outgoing-likes') {
          if (options.path == '/flatmates/conversations') {
            conversationFetchCount['count'] =
                (conversationFetchCount['count'] ?? 0) + 1;
          }
          return Response<dynamic>(
            data: {'items': [], 'next_cursor': null, 'has_more': false},
            statusCode: 200,
            requestOptions: options,
          );
        }
        return Response<dynamic>(
          data: {},
          statusCode: 200,
          requestOptions: options,
        );
      });

      final controller = container.read(chatActionsControllerProvider);
      await controller.blockUser(5);

      expect(blockPaths, contains('/flatmates/blocks'));
      // The conversation list controller was invalidated + reloaded.
      final conversationsState = container.read(
        conversationsListControllerProvider,
      );
      expect(conversationsState.hasValue, isTrue);
      expect(conversationFetchCount['count']! >= 1, isTrue);
    });

    test('unmatchConversation refreshes the conversation list', () async {
      final unmatchData = <Map<String, dynamic>>[];
      final conversationFetchCount = {'count': 0};
      final container = _containerWithAdapter((options) {
        if (options.path == '/flatmates/blocks' && options.method == 'POST') {
          unmatchData.add(
            options.data is Map
                ? Map<String, dynamic>.from(options.data as Map)
                : <String, dynamic>{},
          );
          return Response<dynamic>(
            data: {},
            statusCode: 200,
            requestOptions: options,
          );
        }
        if (options.path == '/flatmates/conversations' ||
            options.path == '/flatmates/likes' ||
            options.path == '/flatmates/outgoing-likes') {
          if (options.path == '/flatmates/conversations') {
            conversationFetchCount['count'] =
                (conversationFetchCount['count'] ?? 0) + 1;
          }
          return Response<dynamic>(
            data: {'items': [], 'next_cursor': null, 'has_more': false},
            statusCode: 200,
            requestOptions: options,
          );
        }
        return Response<dynamic>(
          data: {},
          statusCode: 200,
          requestOptions: options,
        );
      });

      final controller = container.read(chatActionsControllerProvider);
      await controller.unmatchConversation(10, 5);

      expect(unmatchData, isNotEmpty);
      expect(unmatchData.last['blocked_user_id'], 5);
      expect(unmatchData.last['unmatch_only'], isTrue);
      final conversationsState = container.read(
        conversationsListControllerProvider,
      );
      expect(conversationsState.hasValue, isTrue);
      expect(conversationFetchCount['count']! >= 1, isTrue);
    });
  });
}
