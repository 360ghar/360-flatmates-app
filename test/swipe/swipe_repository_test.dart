import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flatmates_app/core/config/endpoints.dart';
import 'package:flatmates_app/core/network/api_client.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/features/discover/discover_repository.dart';
import 'package:flatmates_app/features/swipe/swipe_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('SwipeRepository', () {
    test('recordProfileView posts profile duration tracking payload', () async {
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

      await container
          .read(swipeRepositoryProvider)
          .recordProfileView(
            targetUserId: 42,
            durationSeconds: 13,
            scrollDepthPercent: 100,
          );

      expect(adapter.lastRequest?.path, FlatmatesEndpoints.profileViews);
      expect(adapter.lastRequest?.method, 'POST');
      expect(adapter.lastRequest?.data, {
        'target_user_id': 42,
        'duration_seconds': 13,
        'source': 'swipe_deck',
        'scroll_depth_percent': 100,
      });
    });

    test(
      'fetchSwipeProfiles sends move-in filter and keeps matching profiles',
      () async {
        final adapter = _CapturingAdapter()
          ..responseBody = '''
[
  {"id": 1, "full_name": "A", "move_in_timeline": "within_1_month"},
  {"id": 2, "full_name": "B", "move_in_timeline": "next_month"}
]
''';
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

        final profiles = await container
            .read(swipeRepositoryProvider)
            .fetchSwipeProfiles(
              filters: const DiscoverFilters(moveInTimeline: 'this_month'),
            );

        expect(adapter.lastRequest?.path, FlatmatesEndpoints.flatmatesProfiles);
        expect(adapter.lastRequest?.queryParameters['move_in'], 'this_month');
        expect(profiles.map((profile) => profile.id), [1]);
      },
    );
  });
}

class _CapturingAdapter implements HttpClientAdapter {
  RequestOptions? lastRequest;
  String responseBody = '{}';

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
      responseBody,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
