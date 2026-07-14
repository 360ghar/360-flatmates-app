import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/core/network/api_client.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/features/auth/auth_controller.dart';
import 'package:flatmates_app/features/bootstrap/bootstrap_controller.dart';
import 'package:flatmates_app/features/discover/application/discover_feed_controller.dart';

import '../../helpers/test_helpers.dart';

class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this._handler);

  final Response Function(RequestOptions) _handler;
  final List<RequestOptions> requests = [];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
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

Map<String, dynamic> _listingJson(int id, {bool liked = false}) => {
  'id': id,
  'owner_id': 100 + id,
  'property_type': 'flatmate',
  'title': 'Listing $id',
  'city': 'Bangalore',
  'state': 'Karnataka',
  'locality': 'Koramangala',
  'latitude': 12.9352,
  'longitude': 77.6245,
  'monthly_rent': 20000.0,
  'main_image_url': 'https://example.com/photo$id.jpg',
  'image_urls': ['https://example.com/photo$id.jpg'],
  'bedrooms': 2,
  'bathrooms': 2,
  'area_sqft': 1000.0,
  'features': ['wifi'],
  'available_from': '2025-06-01T00:00:00Z',
  'status': 'live',
  'interest_count': 5,
  'view_count': 100,
  'like_count': 10,
  'is_available': true,
  'liked': liked,
  'listing_preferences': {
    'sharing_type': 'private_room',
    'gender_preference': 'any',
  },
  'owner': {'id': 100 + id, 'full_name': 'Owner $id', 'mode': 'room_poster'},
  'created_at': '2025-05-01T10:00:00Z',
};

Response _ok(Object data) =>
    Response(data: data, statusCode: 200, requestOptions: RequestOptions());

Response _pageResponse(
  List<Map<String, dynamic>> items, {
  String? nextCursor,
}) => _ok({
  'items': items,
  'next_cursor': nextCursor,
  'has_more': nextCursor != null,
});

Response _emptyListResponse() =>
    _ok({'items': <dynamic>[], 'next_cursor': null, 'has_more': false});

({ProviderContainer container, _ScriptedAdapter adapter, ApiClient apiClient})
_setupContainer(Response Function(RequestOptions) handler) {
  final adapter = _ScriptedAdapter(handler);
  final apiClient = ApiClient(
    baseUrl: 'https://api.test.example.com',
    tokenProvider: FakeAuthTokenProvider(),
  );
  apiClient.dio.httpClientAdapter = adapter;

  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(fakeAppConfig()),
      authControllerProvider.overrideWith(() => FakeAuthController()),
      bootstrapControllerProvider.overrideWith(() => FakeBootstrapController()),
      apiClientProvider.overrideWithValue(apiClient),
    ],
  );

  return (container: container, adapter: adapter, apiClient: apiClient);
}

/// Pumps microtasks until [condition] is true or [timeout] elapses.
Future<void> _pumpUntil(
  ProviderContainer container,
  ProviderListenable<bool> condition,
  Duration timeout,
) async {
  final completer = Completer<void>();
  final sub = container.listen<bool>(condition, (_, next) {
    if (next && !completer.isCompleted) completer.complete();
  }, fireImmediately: true);
  await completer.future.timeout(timeout);
  sub.close();
}

Future<void> _pumpFeedLoaded(ProviderContainer container) => _pumpUntil(
  container,
  discoverFeedControllerProvider.select((s) => !s.isLoading),
  const Duration(seconds: 5),
);

void main() {
  setUp(() {});

  group('DiscoverFeedController pagination', () {
    test('full first page sets hasMore=true', () async {
      final setup = _setupContainer((options) {
        if (options.path == '/properties') {
          return _pageResponse(
            List.generate(20, (i) => _listingJson(i + 1)),
            nextCursor: 'cursor-2',
          );
        }
        return _emptyListResponse();
      });

      final container = setup.container;
      addTearDown(container.dispose);

      // Trigger the controller build.
      container.read(discoverFeedControllerProvider);
      await _pumpFeedLoaded(container);

      final state = container.read(discoverFeedControllerProvider);
      expect(state.listings.length, 20);
      expect(state.hasMore, isTrue);
      expect(state.nextCursor, 'cursor-2');
    });

    test('short page clears hasMore', () async {
      final setup = _setupContainer((options) {
        if (options.path == '/properties') {
          return _pageResponse(List.generate(5, (i) => _listingJson(i + 1)));
        }
        return _emptyListResponse();
      });

      final container = setup.container;
      addTearDown(container.dispose);

      container.read(discoverFeedControllerProvider);
      await _pumpFeedLoaded(container);

      final state = container.read(discoverFeedControllerProvider);
      expect(state.listings.length, 5);
      expect(state.hasMore, isFalse);
      expect(state.nextCursor, isNull);
    });

    test('loadMore does not append once hasMore is false', () async {
      final setup = _setupContainer((options) {
        if (options.path == '/properties') {
          return _pageResponse(List.generate(3, (i) => _listingJson(i + 1)));
        }
        return _emptyListResponse();
      });

      final container = setup.container;
      addTearDown(container.dispose);

      container.read(discoverFeedControllerProvider);
      await _pumpFeedLoaded(container);

      final stateBefore = container.read(discoverFeedControllerProvider);
      expect(stateBefore.hasMore, isFalse);
      expect(stateBefore.listings.length, 3);

      // loadMore should be a no-op.
      await container.read(discoverFeedControllerProvider.notifier).loadMore();

      final stateAfter = container.read(discoverFeedControllerProvider);
      expect(stateAfter.listings.length, 3);
      expect(stateAfter.hasMore, isFalse);

      // No additional properties request beyond the first page.
      final propertiesRequests = setup.adapter.requests
          .where((r) => r.path == '/properties')
          .toList();
      expect(propertiesRequests.length, 1);
    });
  });

  group('DiscoverFeedController location filters', () {
    test('location update clears old listings and sends geo query', () async {
      final setup = _setupContainer((options) {
        if (options.path == '/properties') {
          return _pageResponse(List.generate(2, (i) => _listingJson(i + 1)));
        }
        return _emptyListResponse();
      });

      final container = setup.container;
      addTearDown(container.dispose);

      container.read(discoverFeedControllerProvider);
      await _pumpFeedLoaded(container);

      // Verify initial load happened.
      expect(container.read(discoverFeedControllerProvider).listings.length, 2);

      // Update location filter.
      container
          .read(discoverFeedControllerProvider.notifier)
          .updateLocationFilter(
            latitude: 12.9716,
            longitude: 77.5946,
            radiusKm: 5.0,
          );

      // Wait for the new load to settle (listings cleared then repopulated).
      await _pumpFeedLoaded(container);
      // Extra pump for any trailing microtasks.
      await Future<void>.delayed(Duration.zero);

      final state = container.read(discoverFeedControllerProvider);
      // New listings should be from the second fetch (same mock data).
      expect(state.listings.length, 2);
      // Filters should now contain geo coordinates.
      expect(state.filters.latitude, 12.9716);
      expect(state.filters.longitude, 77.5946);
      expect(state.filters.radiusKm, 5.0);

      // At least one properties request should include lat/lng/radius.
      final geoRequests = setup.adapter.requests
          .where(
            (r) =>
                r.path == '/properties' &&
                r.queryParameters.containsKey('lat') &&
                r.queryParameters.containsKey('lng') &&
                r.queryParameters.containsKey('radius'),
          )
          .toList();
      expect(geoRequests, isNotEmpty);
    });
  });

  group('DiscoverFeedController optimistic like', () {
    test('toggleLike flips liked instantly and keeps it on success', () async {
      final setup = _setupContainer((options) {
        if (options.path == '/properties') {
          return _pageResponse([_listingJson(1)]);
        }
        if (options.path == '/flatmates/swipes' && options.method == 'POST') {
          return _ok({'conversation_id': 42});
        }
        return _emptyListResponse();
      });

      final container = setup.container;
      addTearDown(container.dispose);

      container.read(discoverFeedControllerProvider);
      await _pumpFeedLoaded(container);

      // Verify initial liked state.
      final before = container.read(discoverFeedControllerProvider);
      expect(before.listings.first.liked, isFalse);

      // Call toggleLike but don't await yet — the optimistic flip happens
      // synchronously before the first await inside the async method.
      final future = container
          .read(discoverFeedControllerProvider.notifier)
          .toggleLike(1);

      // Optimistic state should already be flipped.
      final optimistic = container.read(discoverFeedControllerProvider);
      expect(optimistic.listings.first.liked, isTrue);

      // Await the network call.
      final conversationId = await future;
      expect(conversationId, 42);

      // After success, liked should still be true.
      await Future<void>.delayed(Duration.zero);
      final after = container.read(discoverFeedControllerProvider);
      expect(after.listings.first.liked, isTrue);
    });

    test('toggleLike rolls back the optimistic flip on failure', () async {
      final setup = _setupContainer((options) {
        if (options.path == '/properties') {
          return _pageResponse([_listingJson(1)]);
        }
        if (options.path == '/flatmates/swipes' && options.method == 'POST') {
          return Response(
            data: {'detail': 'Server error'},
            statusCode: 500,
            requestOptions: options,
          );
        }
        return _emptyListResponse();
      });

      final container = setup.container;
      addTearDown(container.dispose);

      container.read(discoverFeedControllerProvider);
      await _pumpFeedLoaded(container);

      final before = container.read(discoverFeedControllerProvider);
      expect(before.listings.first.liked, isFalse);

      // toggleLike should throw because the POST returns 500.
      final future = container
          .read(discoverFeedControllerProvider.notifier)
          .toggleLike(1);

      // Optimistic flip happened synchronously.
      final optimistic = container.read(discoverFeedControllerProvider);
      expect(optimistic.listings.first.liked, isTrue);

      // The await should throw.
      await expectLater(future, throwsA(isA<Object>()));

      // After failure, liked should be rolled back to false.
      await Future<void>.delayed(Duration.zero);
      final after = container.read(discoverFeedControllerProvider);
      expect(after.listings.first.liked, isFalse);
    });
  });
}
