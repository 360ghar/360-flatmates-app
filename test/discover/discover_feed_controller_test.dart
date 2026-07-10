import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flatmates_app/core/config/endpoints.dart';
import 'package:flatmates_app/core/network/api_client.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/features/discover/application/discover_feed_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_helpers.dart';

/// Drives [DiscoverFeedController] through the real [DiscoverRepository] with a
/// scripted HTTP adapter so pagination + optimistic-like behaviour is covered
/// end-to-end (no mock repository).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Builds a JSON page of `count` listings with sequential ids starting at
  /// `startId`. All listings are available so no client-side move-in/deal
  /// breaker filtering trims them.
  String pageBody(int count, {int startId = 1, String? nextCursor}) {
    final items = List.generate(count, (i) {
      final id = startId + i;
      return {
        'id': id,
        'title': 'Listing $id',
        'is_available': true,
        'monthly_rent': 20000,
      };
    });
    return jsonEncode({
      'items': items,
      'next_cursor': nextCursor,
      'has_more': nextCursor != null,
      'limit': 20,
    });
  }

  ProviderContainer makeContainer(_ScriptedAdapter adapter) {
    final apiClient = ApiClient(
      baseUrl: 'https://api.test.example.com',
      tokenProvider: FakeAuthTokenProvider(),
    );
    apiClient.dio.httpClientAdapter = adapter;
    final container = ProviderContainer(
      overrides: [apiClientProvider.overrideWithValue(apiClient)],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<void> settle() async {
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  /// Reads the controller and deterministically completes the initial page
  /// load (the build()-time microtask also calls load(); awaiting an explicit
  /// load() here plus settle() guarantees the feed is populated before asserts).
  Future<DiscoverFeedController> primed(ProviderContainer container) async {
    final notifier = container.read(discoverFeedControllerProvider.notifier);
    await notifier.load();
    await settle();
    return notifier;
  }

  group('DiscoverFeedController pagination', () {
    test('full first page sets hasMore=true; short page clears it', () async {
      final adapter = _ScriptedAdapter(
        onProperties: (options) {
          final cursor = options.queryParameters['cursor'] as String?;
          // First page: full 20 items. Second page: 5 items (< _pageSize).
          return cursor == null
              ? pageBody(20, nextCursor: 'page-2')
              : pageBody(5, startId: 21);
        },
      );
      final container = makeContainer(adapter);

      final notifier = await primed(container);

      var state = container.read(discoverFeedControllerProvider);
      expect(state.listings.length, 20);
      expect(state.hasMore, isTrue, reason: 'a full page implies more remain');
      expect(state.isLoading, isFalse);

      await notifier.loadMore();
      await settle();

      state = container.read(discoverFeedControllerProvider);
      expect(state.listings.length, 25, reason: 'load-more appends, no dupes');
      expect(
        state.hasMore,
        isFalse,
        reason: 'a short page (<20) marks the end of the feed',
      );
    });

    test('loadMore does not append once hasMore is false', () async {
      final propertyCursors = <String?>[];
      final adapter = _ScriptedAdapter(
        onProperties: (options) {
          propertyCursors.add(options.queryParameters['cursor'] as String?);
          return pageBody(3); // first page ends the stream
        },
      );
      final container = makeContainer(adapter);
      final notifier = await primed(container);

      expect(container.read(discoverFeedControllerProvider).hasMore, isFalse);
      expect(container.read(discoverFeedControllerProvider).listings.length, 3);
      propertyCursors.clear();

      await notifier.loadMore();
      await settle();

      // hasMore=false short-circuits loadMore before it ever issues a paged
      // request, so the list stays at 3 with no duplicate append.
      expect(
        propertyCursors.where((c) => c != null),
        isEmpty,
        reason: 'loadMore must not fetch a next page when at the end',
      );
      expect(container.read(discoverFeedControllerProvider).listings.length, 3);
    });
  });

  group('DiscoverFeedController location filters', () {
    test('location update clears old listings and sends geo query', () async {
      final propertyRequests = <Map<String, dynamic>>[];
      final adapter = _ScriptedAdapter(
        onProperties: (options) {
          propertyRequests.add(
            Map<String, dynamic>.from(options.queryParameters),
          );
          return options.queryParameters.containsKey('lat')
              ? pageBody(1, startId: 101)
              : pageBody(2);
        },
      );
      final container = makeContainer(adapter);
      final notifier = await primed(container);

      expect(container.read(discoverFeedControllerProvider).listings.length, 2);

      notifier.updateLocationFilter(
        latitude: 28.464615,
        longitude: 77.029919,
        radiusKm: 10,
      );

      final restartingState = container.read(discoverFeedControllerProvider);
      expect(restartingState.listings, isEmpty);
      expect(restartingState.isLoading, isTrue);

      await settle();

      final state = container.read(discoverFeedControllerProvider);
      expect(state.listings.single.id, 101);
      expect(propertyRequests.last['lat'], '28.464615');
      expect(propertyRequests.last['lng'], '77.029919');
      expect(propertyRequests.last['radius'], 10);
    });
  });

  group('DiscoverFeedController optimistic like', () {
    test('toggleLike flips liked instantly and keeps it on success', () async {
      final adapter = _ScriptedAdapter(
        onProperties: (_) => pageBody(2),
        onSwipe: (_) => jsonEncode({'conversation_id': 42}),
      );
      final container = makeContainer(adapter);
      final notifier = await primed(container);

      final firstId = container
          .read(discoverFeedControllerProvider)
          .listings
          .first
          .id;
      expect(
        container.read(discoverFeedControllerProvider).listings.first.liked ??
            false,
        isFalse,
      );

      final cid = await notifier.toggleLike(firstId);
      await settle();

      expect(cid, 42);
      expect(
        container.read(discoverFeedControllerProvider).listings.first.liked,
        isTrue,
      );
    });

    test('toggleLike rolls back the optimistic flip on failure', () async {
      final adapter = _ScriptedAdapter(
        onProperties: (_) => pageBody(2),
        // Returning null triggers the adapter to throw, simulating a 500.
        onSwipe: (_) => null,
      );
      final container = makeContainer(adapter);
      final notifier = await primed(container);

      final firstId = container
          .read(discoverFeedControllerProvider)
          .listings
          .first
          .id;

      await expectLater(notifier.toggleLike(firstId), throwsA(anything));

      expect(
        container.read(discoverFeedControllerProvider).listings.first.liked ??
            false,
        isFalse,
        reason: 'failed like must roll back to the previous list',
      );
    });
  });
}

/// HTTP adapter that returns scripted bodies keyed by request path. A null
/// return from a handler simulates a server error (HTTP 500).
class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter({required this.onProperties, this.onSwipe});

  final String Function(RequestOptions options) onProperties;
  final String? Function(RequestOptions options)? onSwipe;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path == FlatmatesEndpoints.properties) {
      return _json(onProperties(options), 200);
    }
    if (options.path == FlatmatesEndpoints.swipes) {
      final body = onSwipe?.call(options);
      if (body == null) return _json('{"detail":"boom"}', 500);
      return _json(body, 200);
    }
    if (options.path == FlatmatesEndpoints.outgoingLikes ||
        options.path == FlatmatesEndpoints.conversations) {
      return _json(
        '{"items":[],"next_cursor":null,"has_more":false,"limit":20}',
        200,
      );
    }
    throw StateError('Unexpected request path: ${options.path}');
  }

  ResponseBody _json(String body, int status) => ResponseBody.fromString(
    body,
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}
