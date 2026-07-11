import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/core/network/api_client.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/features/notifications/application/notifications_actions_controller.dart';
import 'package:flatmates_app/features/notifications/notifications_list_controller.dart';
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

        // The notifications list controller was invalidated + reloaded.
        // Allow the microtask-driven rebuild + load to complete.
        await Future<void>.delayed(const Duration(milliseconds: 50));
        final state = container.read(notificationsListControllerProvider);
        expect(state.hasValue, isTrue);
      },
    );
  });
}
