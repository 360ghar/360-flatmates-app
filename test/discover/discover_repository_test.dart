import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flatmates_app/core/config/endpoints.dart';
import 'package:flatmates_app/core/network/api_client.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/features/discover/discover_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('DiscoverRepository', () {
    test(
      'fetchListings sends move-in query and applies client fallback',
      () async {
        final now = DateTime.now();
        final thisMonth = DateTime(now.year, now.month).toIso8601String();
        final nextMonth = DateTime(
          now.year,
          now.month + 1,
          5,
        ).toIso8601String();
        final adapter = _CapturingAdapter()
          ..responseBody =
              '''
{
  "properties": [
    {"id": 1, "title": "This month", "available_from": "$thisMonth", "is_available": true},
    {"id": 2, "title": "Next month", "available_from": "$nextMonth", "is_available": true}
  ]
}
''';
        final apiClient = ApiClient(
          baseUrl: 'https://api.test.example.com',
          tokenProvider: FakeAuthTokenProvider(),
        );
        apiClient.dio.httpClientAdapter = adapter;
        final container = ProviderContainer(
          overrides: [apiClientProvider.overrideWithValue(apiClient)],
        );
        addTearDown(container.dispose);

        final listings = await container
            .read(discoverRepositoryProvider)
            .fetchListings(
              filters: const DiscoverFilters(moveInTimeline: 'this_month'),
            );

        expect(adapter.lastRequest?.path, FlatmatesEndpoints.properties);
        expect(adapter.lastRequest?.queryParameters['move_in'], 'this_month');
        expect(listings.map((listing) => listing.id), [1]);
      },
    );

    test('voteSocietyTag posts backend vote-count payload', () async {
      final adapter = _CapturingAdapter();
      final apiClient = ApiClient(
        baseUrl: 'https://api.test.example.com',
        tokenProvider: FakeAuthTokenProvider(),
      );
      apiClient.dio.httpClientAdapter = adapter;
      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(apiClient)],
      );
      addTearDown(container.dispose);

      await container
          .read(discoverRepositoryProvider)
          .voteSocietyTag(listingId: 99, tag: 'quiet', vote: 'down');

      expect(adapter.lastRequest?.path, FlatmatesEndpoints.societyTagVotes(99));
      expect(adapter.lastRequest?.method, 'POST');
      expect(adapter.lastRequest?.data, {'tag': 'quiet', 'vote': 'down'});
    });
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
