import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/core/network/api_client.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/features/chats/application/cursor_list_controller.dart';
import 'package:flatmates_app/features/notifications/application/notifications_actions_controller.dart';
import 'package:flatmates_app/features/notifications/notifications_list_controller.dart';
import 'package:flatmates_app/features/notifications/notifications_repository.dart';
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

/// Waits (up to ~1 s) for the notifications list to leave its loading state.
Future<void> _waitUntilLoaded(ProviderContainer container) =>
    _waitUntil(container, (state) => !state.isLoading);

/// Waits (up to ~1 s) for [predicate] to hold on the notifications list.
/// Bounded polling instead of a fixed delay, which is flaky under load.
Future<void> _waitUntil(
  ProviderContainer container,
  bool Function(AsyncValue<CursorListState<NotificationModel>> state) predicate,
) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    if (predicate(container.read(notificationsListControllerProvider))) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  group('NotificationsActionsController', () {
    test(
      'markAllRead posts mark-all-read request and refreshes list',
      () async {
        final requests = <RequestOptions>[];
        final container = _containerWithAdapter((options) {
          requests.add(options);
          return Response<dynamic>(
            data: options.path == '/flatmates/notifications'
                ? {'items': [], 'next_cursor': null, 'has_more': false}
                : {},
            statusCode: 200,
            requestOptions: options,
          );
        });

        final controller = container.read(
          notificationsActionsControllerProvider,
        );
        await controller.markAllRead();

        // The mark-all-read PUT request was made.
        final markAllPut = requests.firstWhere(
          (r) => r.path == '/flatmates/notifications' && r.method == 'PUT',
          orElse: () => requests.first,
        );
        expect(markAllPut.method, 'PUT');
        final sentData = Map<String, dynamic>.from(markAllPut.data as Map);
        expect(sentData['mark_all_read'], isTrue);

        // The notifications list controller was invalidated + reloaded. Wait
        // for the microtask-driven rebuild + load to land (bounded poll: a
        // fixed delay is flaky under load).
        await _waitUntilLoaded(container);
        final state = container.read(notificationsListControllerProvider);
        expect(state.hasValue, isTrue);
      },
    );

    test(
      'markAllRead keeps cached notifications read when the refetch fails',
      () async {
        var marked = false;
        final container = _containerWithAdapter((options) {
          if (options.path == '/flatmates/notifications' &&
              options.method == 'PUT') {
            marked = true;
            return Response<dynamic>(
              data: {},
              statusCode: 200,
              requestOptions: options,
            );
          }
          if (options.path == '/flatmates/notifications' &&
              options.method == 'GET') {
            if (marked) {
              return Response<dynamic>(
                data: {'detail': 'Service unavailable'},
                statusCode: 500,
                requestOptions: options,
              );
            }
            return Response<dynamic>(
              data: {
                'items': [
                  {
                    'id': 'n1',
                    'type': 'new_message',
                    'title': 'New message',
                    'body': 'Hi',
                    'is_read': false,
                    'created_at': '2026-10-01T10:00:00Z',
                  },
                  {
                    'id': 'n2',
                    'type': 'new_match',
                    'title': 'New match',
                    'body': 'Hello',
                    'is_read': false,
                    'created_at': '2026-10-01T09:00:00Z',
                  },
                ],
                'next_cursor': null,
                'has_more': false,
              },
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

        // Keep the list alive and loaded, so the mutation has cached rows.
        final subscription = container.listen(
          notificationsListControllerProvider,
          (_, _) {},
        );
        addTearDown(subscription.close);
        await container
            .read(notificationsListControllerProvider.notifier)
            .load();
        expect(
          container
              .read(notificationsListControllerProvider)
              .valueOrNull!
              .items
              .every((n) => !n.isRead),
          isTrue,
        );

        await container
            .read(notificationsActionsControllerProvider)
            .markAllRead();
        await _waitUntil(
          container,
          (state) => state.valueOrNull?.hasError ?? false,
        );

        final state = container
            .read(notificationsListControllerProvider)
            .valueOrNull!;
        // Without the local update the failed refetch restored the unread
        // badges (the rows it keeps still had isRead == false).
        expect(state.items, hasLength(2));
        expect(state.items.every((n) => n.isRead), isTrue);
      },
    );

    test('markRead updates only the target notification locally', () async {
      var marked = false;
      final container = _containerWithAdapter((options) {
        if (options.method == 'PUT') {
          marked = true;
          return Response<dynamic>(
            data: {},
            statusCode: 200,
            requestOptions: options,
          );
        }
        if (options.path == '/flatmates/notifications' &&
            options.method == 'GET') {
          if (marked) {
            return Response<dynamic>(
              data: {'detail': 'Service unavailable'},
              statusCode: 500,
              requestOptions: options,
            );
          }
          return Response<dynamic>(
            data: {
              'items': [
                {
                  'id': 'n1',
                  'type': 'new_message',
                  'title': 'New message',
                  'body': 'Hi',
                  'is_read': false,
                  'created_at': '2026-10-01T10:00:00Z',
                },
                {
                  'id': 'n2',
                  'type': 'new_match',
                  'title': 'New match',
                  'body': 'Hello',
                  'is_read': false,
                  'created_at': '2026-10-01T09:00:00Z',
                },
              ],
              'next_cursor': null,
              'has_more': false,
            },
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

      final subscription = container.listen(
        notificationsListControllerProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);
      await container.read(notificationsListControllerProvider.notifier).load();

      await container
          .read(notificationsActionsControllerProvider)
          .markRead('n1');
      await _waitUntil(
        container,
        (state) => state.valueOrNull?.hasError ?? false,
      );

      final items = container
          .read(notificationsListControllerProvider)
          .valueOrNull!
          .items;
      expect(items.firstWhere((n) => n.id == 'n1').isRead, isTrue);
      expect(items.firstWhere((n) => n.id == 'n2').isRead, isFalse);
    });
  });
}
