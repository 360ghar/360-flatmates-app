import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/core/network/api_client.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/features/discover/discover_repository.dart';

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

Response _ok(Object data) =>
    Response(data: data, statusCode: 200, requestOptions: RequestOptions());

Map<String, dynamic> _listingJson(int id) => {
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
  'listing_preferences': {
    'sharing_type': 'private_room',
    'gender_preference': 'any',
  },
  'owner': {'id': 100 + id, 'full_name': 'Owner $id', 'mode': 'room_poster'},
  'created_at': '2025-05-01T10:00:00Z',
};

void main() {
  late ProviderContainer container;
  late _ScriptedAdapter adapter;

  setUp(() {
    Response<dynamic> handler(RequestOptions options) {
      if (options.path == '/properties') {
        return _ok({
          'items': [_listingJson(1), _listingJson(2)],
          'next_cursor': null,
          'has_more': false,
        });
      }
      return _ok({});
    }

    adapter = _ScriptedAdapter(handler);
    final apiClient = ApiClient(
      baseUrl: 'https://api.test.example.com',
      tokenProvider: FakeAuthTokenProvider(),
    );
    apiClient.dio.httpClientAdapter = adapter;

    container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(fakeAppConfig()),
        apiClientProvider.overrideWithValue(apiClient),
      ],
    );
  });

  tearDown(() => container.dispose());

  group('DiscoverRepository.fetchListings', () {
    test('sends move-in query and applies client fallback', () async {
      // Use a handler that records the query params for /properties.
      adapter = _ScriptedAdapter((options) {
        if (options.path == '/properties') {
          return _ok({
            'items': [_listingJson(1), _listingJson(2)],
            'next_cursor': null,
            'has_more': false,
          });
        }
        return _ok({});
      });
      final apiClient = ApiClient(
        baseUrl: 'https://api.test.example.com',
        tokenProvider: FakeAuthTokenProvider(),
      );
      apiClient.dio.httpClientAdapter = adapter;
      container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(fakeAppConfig()),
          apiClientProvider.overrideWithValue(apiClient),
        ],
      );

      final repo = container.read(discoverRepositoryProvider);
      const filters = DiscoverFilters(moveInTimeline: 'this_month');
      final page = await repo.fetchListingsPage(filters: filters);

      // Two listings returned by the server.
      expect(page.items.length, 2);

      // The request should include a move_in query param.
      final propertiesRequest = adapter.requests.firstWhere(
        (r) => r.path == '/properties',
      );
      expect(propertiesRequest.queryParameters['move_in'], 'this_month');
    });
  });

  group('DiscoverRepository.voteSocietyTag', () {
    test('posts backend vote-count payload', () async {
      var capturedPath = '';
      var capturedData = <String, dynamic>{};

      adapter = _ScriptedAdapter((options) {
        if (options.path == '/flatmates/listings/42/society-tags/votes') {
          capturedPath = options.path;
          if (options.data is Map) {
            capturedData = Map<String, dynamic>.from(options.data as Map);
          }
          return _ok({'ok': true});
        }
        return _ok({});
      });
      final apiClient = ApiClient(
        baseUrl: 'https://api.test.example.com',
        tokenProvider: FakeAuthTokenProvider(),
      );
      apiClient.dio.httpClientAdapter = adapter;
      container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(fakeAppConfig()),
          apiClientProvider.overrideWithValue(apiClient),
        ],
      );

      final repo = container.read(discoverRepositoryProvider);
      await repo.voteSocietyTag(listingId: 42, tag: 'safe', vote: 'up');

      expect(capturedPath, '/flatmates/listings/42/society-tags/votes');
      expect(capturedData['tag'], 'safe');
      expect(capturedData['vote'], 'up');
    });
  });
}
