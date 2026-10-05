import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/core/network/api_client.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/features/chats/application/cursor_list_controller.dart';
import 'package:flatmates_app/features/settings/data/blocked_users_list_controller.dart';
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

Map<String, dynamic> _blocksPage(List<Map<String, dynamic>> items) => {
  'items': items,
  'next_cursor': null,
  'has_more': false,
};

const _blockedUserJson = {
  'blocked_user_id': 7,
  'user': {'full_name': 'Asha Rao', 'city': 'Bengaluru'},
};

const _conversationJson = {
  'id': 10,
  'peer': {'id': 2, 'full_name': 'Asha Rao'},
  'last_message_preview': 'See you Saturday',
  'last_message_at': '2026-10-01T10:00:00Z',
};

void main() {
  group('BlockedUsersListController.unblock', () {
    test('keeps the loaded rows when the post-unblock reload fails', () async {
      var unblocked = false;
      final container = _containerWithAdapter((options) {
        if (options.method == 'DELETE') {
          unblocked = true;
          return Response<dynamic>(
            data: {},
            statusCode: 200,
            requestOptions: options,
          );
        }
        if (options.path == '/flatmates/blocks') {
          if (unblocked) {
            return Response<dynamic>(
              data: {'detail': 'Service unavailable'},
              statusCode: 500,
              requestOptions: options,
            );
          }
          return Response<dynamic>(
            data: _blocksPage([_blockedUserJson]),
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

      final notifier = container.read(
        blockedUsersListControllerProvider.notifier,
      );
      await notifier.load();
      expect(
        container.read(blockedUsersListControllerProvider).valueOrNull!.items,
        hasLength(1),
      );

      await notifier.unblock(7);

      // invalidateSelf() dropped the list into AsyncValue.error here; refresh()
      // keeps the rows on screen and attaches the reload error to them.
      final state = container.read(blockedUsersListControllerProvider);
      expect(state.hasValue, isTrue);
      expect(state.valueOrNull!.items, hasLength(1));
      expect(state.valueOrNull!.items.single.name, 'Asha Rao');
      expect(state.valueOrNull!.hasError, isTrue);
    });

    test('reloads the list after a successful unblock', () async {
      var unblocked = false;
      final container = _containerWithAdapter((options) {
        if (options.method == 'DELETE') {
          unblocked = true;
          return Response<dynamic>(
            data: {},
            statusCode: 200,
            requestOptions: options,
          );
        }
        if (options.path == '/flatmates/blocks') {
          return Response<dynamic>(
            data: _blocksPage(unblocked ? const [] : [_blockedUserJson]),
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

      final notifier = container.read(
        blockedUsersListControllerProvider.notifier,
      );
      await notifier.load();

      await notifier.unblock(7);

      final state = container.read(blockedUsersListControllerProvider);
      expect(state.valueOrNull!.items, isEmpty);
      expect(unblocked, isTrue);
    });

    test('keeps a live conversation list when its reload fails', () async {
      var conversationsFailing = false;
      final container = _containerWithAdapter((options) {
        if (options.path == '/flatmates/conversations') {
          if (conversationsFailing) {
            return Response<dynamic>(
              data: {'detail': 'Service unavailable'},
              statusCode: 500,
              requestOptions: options,
            );
          }
          return Response<dynamic>(
            data: _blocksPage([_conversationJson]),
            statusCode: 200,
            requestOptions: options,
          );
        }
        if (options.path == '/flatmates/blocks') {
          return Response<dynamic>(
            data: _blocksPage(const []),
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

      // Keep the conversation list alive and loaded, then make its reload fail.
      final subscription = container.listen(
        conversationsListControllerProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);
      await container.read(conversationsListControllerProvider.notifier).load();
      expect(
        container.read(conversationsListControllerProvider).valueOrNull!.items,
        hasLength(1),
      );
      conversationsFailing = true;

      await container
          .read(blockedUsersListControllerProvider.notifier)
          .unblock(7);
      // The chat/like reloads are fire-and-forget; poll (bounded) instead of
      // sleeping a fixed delay.
      for (var attempt = 0; attempt < 100; attempt++) {
        final pending = container.read(conversationsListControllerProvider);
        if (pending.valueOrNull?.hasError ?? false) break;
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      final state = container.read(conversationsListControllerProvider);
      expect(state.hasValue, isTrue);
      expect(state.valueOrNull!.items, hasLength(1));
      expect(state.valueOrNull!.hasError, isTrue);
    });
  });
}
