import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show Locale;

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/core/network/api_client.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/features/chats/application/cursor_list_controller.dart';
import 'package:flatmates_app/features/visits/application/visits_actions_controller.dart';
import 'package:flatmates_app/l10n/gen/app_localizations.dart';
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
  group('VisitsActionsController.schedule', () {
    test('refreshes the conversations list after the visit message', () async {
      final requests = <String>[];
      final container = _containerWithAdapter((options) {
        requests.add('${options.method} ${options.path}');
        if (options.path == '/visits' && options.method == 'POST') {
          return Response<dynamic>(
            data: {'id': 77},
            statusCode: 200,
            requestOptions: options,
          );
        }
        if (options.path == '/flatmates/conversations' &&
            options.method == 'GET') {
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

      // Keep the conversation list alive so the invalidation re-runs its fetch.
      final subscription = container.listen(
        conversationsListControllerProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);
      await container.read(conversationsListControllerProvider.notifier).load();
      final before = requests
          .where((r) => r == 'GET /flatmates/conversations')
          .length;

      final locale = await AppLocalizations.delegate.load(const Locale('en'));
      final visitId = await container
          .read(visitsActionsControllerProvider)
          .schedule(
            propertyId: 42,
            counterpartyUserId: 2,
            conversationId: 10,
            scheduledDate: DateTime.utc(2025, 5, 20, 15),
            locale: locale,
          );
      expect(visitId, 77);
      // The visit request posts a chat message; without the invalidation the
      // retained conversation list kept the old preview and timestamp. The
      // refetch is fire-and-forget, so poll (bounded) rather than sleep.
      var after = requests
          .where((r) => r == 'GET /flatmates/conversations')
          .length;
      for (var attempt = 0; attempt < 100 && after <= before; attempt++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        after = requests
            .where((r) => r == 'GET /flatmates/conversations')
            .length;
      }
      expect(after, greaterThan(before));
    });

    test('keeps the loaded conversation rows when the refetch fails', () async {
      var conversationsFailing = false;
      final container = _containerWithAdapter((options) {
        if (options.path == '/flatmates/conversations' &&
            options.method == 'GET') {
          if (conversationsFailing) {
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
                  'id': 1,
                  'peer': {'id': 2, 'full_name': 'Priya'},
                },
              ],
              'next_cursor': null,
              'has_more': false,
            },
            statusCode: 200,
            requestOptions: options,
          );
        }
        if (options.path == '/visits' && options.method == 'POST') {
          return Response<dynamic>(
            data: {'id': 78},
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

      final locale = await AppLocalizations.delegate.load(const Locale('en'));
      final visitId = await container
          .read(visitsActionsControllerProvider)
          .schedule(
            propertyId: 42,
            counterpartyUserId: 2,
            conversationId: 10,
            scheduledDate: DateTime.utc(2025, 5, 20, 15),
            locale: locale,
          );
      expect(visitId, 78);

      // The in-place refresh is fire-and-forget; poll (bounded) until the
      // failure has landed instead of sleeping a fixed delay.
      for (var attempt = 0; attempt < 100; attempt++) {
        final pending = container.read(conversationsListControllerProvider);
        if (pending.valueOrNull?.hasError ?? false) break;
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      final state = container.read(conversationsListControllerProvider);
      expect(
        state.hasValue,
        isTrue,
        reason:
            'invalidate() would drop the list into a fresh loading/error state',
      );
      expect(
        state.valueOrNull!.items,
        hasLength(1),
        reason: 'the conversation row stays on screen after a failed refetch',
      );
      expect(state.valueOrNull!.hasError, isTrue);
    });
  });
}
