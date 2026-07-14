import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/core/network/api_client.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/features/chats/application/cursor_list_controller.dart';

import '../../helpers/test_helpers.dart';

/// Adapter that introduces a small delay so callers can race a refresh()
/// while the initial load is still in-flight.
class _DelayedAdapter implements HttpClientAdapter {
  _DelayedAdapter(this._handler, this._delay);

  final Response Function(RequestOptions) _handler;
  final Duration _delay;
  final List<RequestOptions> requests = [];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (_delay > Duration.zero) {
      await Future<void>.delayed(_delay);
    }
    requests.add(options);
    final response = _handler(options);
    return ResponseBody.fromString(
      jsonEncode(response.data),
      response.statusCode ?? 200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }
}

Response _ok(Object data) =>
    Response(data: data, statusCode: 200, requestOptions: RequestOptions());

void main() {
  group('OutgoingLikesController refresh', () {
    test(
      'refresh requested during in-flight load runs after it settles',
      () async {
        var requestCount = 0;

        final adapter = _DelayedAdapter((options) {
          if (options.path == '/flatmates/outgoing-likes') {
            requestCount++;
            return _ok({
              'items': <dynamic>[],
              'next_cursor': null,
              'has_more': false,
            });
          }
          return _ok({});
        }, const Duration(milliseconds: 20));

        final apiClient = ApiClient(
          baseUrl: 'https://api.test.example.com',
          tokenProvider: FakeAuthTokenProvider(),
        );
        apiClient.dio.httpClientAdapter = adapter;

        final container = ProviderContainer(
          overrides: [
            appConfigProvider.overrideWithValue(fakeAppConfig()),
            apiClientProvider.overrideWithValue(apiClient),
          ],
        );
        addTearDown(container.dispose);

        // Reading the provider triggers build() which schedules a microtask
        // to call load().
        container.read(outgoingLikesListControllerProvider);

        // Let the microtask run so load() starts and hits the delayed adapter.
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(const Duration(milliseconds: 1));

        // At this point the initial load is in-flight (adapter has a 20ms
        // delay). Call refresh() — it should coalesce and wait for the
        // in-flight load to finish, then re-run.
        final refreshFuture = container
            .read(outgoingLikesListControllerProvider.notifier)
            .refresh();

        // Wait for the coalesced refresh to complete.
        await refreshFuture;

        // The initial load (1) plus the coalesced refresh load (2) should
        // have produced two outgoing-likes requests.
        expect(requestCount, greaterThanOrEqualTo(2));
      },
    );
  });
}
