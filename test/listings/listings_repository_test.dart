import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flatmates_app/core/config/endpoints.dart';
import 'package:flatmates_app/core/network/api_client.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/features/listings/listings_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('ListingsRepository', () {
    test(
      'ListingCreateRequest preserves society tags for backend data-only counts',
      () {
        final request = ListingCreateRequest(
          title: '2 BHK in Lakeside',
          description: 'Quiet home',
          city: 'Bangalore',
          locality: 'Koramangala',
          subLocality: 'Lakeside',
          monthlyRent: 24000,
          securityDeposit: 48000,
          maintenanceCharges: 2500,
          areaSqft: 900,
          bedrooms: 2,
          bathrooms: 1,
          features: const ['wifi', 'parking'],
          tags: const ['quiet', 'visitor_friendly'],
          mainImageUrl: 'https://example.com/room.jpg',
          imageUrls: const ['https://example.com/room.jpg'],
          availableFrom: DateTime.utc(2026, 5, 12),
          genderPreference: 'any',
          sharingType: 'private_room',
          societyType: 'gated',
          societyAmenities: const ['parking'],
          societyVibeTags: const ['quiet', 'visitor_friendly'],
        );

        final json = request.toJson();

        expect(json['tags'], ['quiet', 'visitor_friendly']);
        expect(json['listing_preferences'], {
          'gender_preference': 'any',
          'sharing_type': 'private_room',
          'society_type': 'gated',
          'society_amenities': ['parking'],
          'society_vibes': ['quiet', 'visitor_friendly'],
        });
      },
    );

    test('togglePause sends pause moderation status payload', () async {
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
          .read(listingsRepositoryProvider)
          .togglePause(42, paused: false);

      expect(adapter.lastRequest?.path, FlatmatesEndpoints.property(42));
      expect(adapter.lastRequest?.method, 'PUT');
      expect(adapter.lastRequest?.data, {
        'listing_preferences': {'moderation_status': 'paused'},
      });
    });

    test('togglePause sends resume moderation status payload', () async {
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
          .read(listingsRepositoryProvider)
          .togglePause(42, paused: true);

      expect(adapter.lastRequest?.path, FlatmatesEndpoints.property(42));
      expect(adapter.lastRequest?.method, 'PUT');
      expect(adapter.lastRequest?.data, {
        'listing_preferences': {'moderation_status': 'live'},
      });
    });

    test('createListing POSTs to /properties and parses returned id', () async {
      final adapter = _CapturingAdapter(responseBody: '{"id": 99}');
      final apiClient = ApiClient(
        baseUrl: 'https://api.test.example.com',
        tokenProvider: FakeAuthTokenProvider(),
      );
      apiClient.dio.httpClientAdapter = adapter;
      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(apiClient)],
      );
      addTearDown(container.dispose);

      final id = await container
          .read(listingsRepositoryProvider)
          .createListing(_sampleRequest());

      expect(adapter.lastRequest?.path, FlatmatesEndpoints.properties);
      expect(adapter.lastRequest?.method, 'POST');
      expect(id, 99);
    });

    test(
      'updateListing PUTs to /properties/{id} so edits never duplicate',
      () async {
        final adapter = _CapturingAdapter(responseBody: '{"id": 42}');
        final apiClient = ApiClient(
          baseUrl: 'https://api.test.example.com',
          tokenProvider: FakeAuthTokenProvider(),
        );
        apiClient.dio.httpClientAdapter = adapter;
        final container = ProviderContainer(
          overrides: [apiClientProvider.overrideWithValue(apiClient)],
        );
        addTearDown(container.dispose);

        final id = await container
            .read(listingsRepositoryProvider)
            .updateListing(42, _sampleRequest());

        expect(adapter.lastRequest?.path, FlatmatesEndpoints.property(42));
        expect(adapter.lastRequest?.method, 'PUT');
        expect(id, 42);
      },
    );

    test(
      'updateListing falls back to the given id when body omits it',
      () async {
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

        final id = await container
            .read(listingsRepositoryProvider)
            .updateListing(7, _sampleRequest());

        expect(id, 7);
      },
    );

    test(
      'fetchMyListings returns flatmate/pg listings from cursor envelope',
      () async {
        final adapter = _CapturingAdapter(
          responseBody: '''
{
  "items": [
    {"id": 1, "title": "A", "property_type": "flatmate", "monthly_rent": 20000, "is_available": true},
    {"id": 2, "title": "B", "property_type": "pg", "monthly_rent": 15000, "is_available": true},
    {"id": 3, "title": "C", "property_type": "apartment", "monthly_rent": 50000, "is_available": true}
  ],
  "next_cursor": null,
  "has_more": false,
  "limit": 20
}''',
        );
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
            .read(listingsRepositoryProvider)
            .fetchMyListings();

        expect(listings, hasLength(2));
        expect(listings.map((l) => l.id), [1, 2]);
        expect(adapter.lastRequest?.path, FlatmatesEndpoints.myProperties);
      },
    );

    test('fetchMyListingsPage returns cursor metadata', () async {
      final adapter = _CapturingAdapter(
        responseBody: '''
{
  "items": [],
  "next_cursor": "next-page",
  "has_more": true,
  "limit": 20
}''',
      );
      final apiClient = ApiClient(
        baseUrl: 'https://api.test.example.com',
        tokenProvider: FakeAuthTokenProvider(),
      );
      apiClient.dio.httpClientAdapter = adapter;
      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(apiClient)],
      );
      addTearDown(container.dispose);

      final page = await container
          .read(listingsRepositoryProvider)
          .fetchMyListingsPage();
      expect(page.nextCursor, 'next-page');
      expect(page.hasMore, isTrue);
      expect(page.items, isEmpty);
    });
  });
}

ListingCreateRequest _sampleRequest() => ListingCreateRequest(
  title: '2BHK in Lakeside',
  description: 'Quiet home',
  city: 'Bangalore',
  locality: 'Koramangala',
  subLocality: 'Lakeside',
  monthlyRent: 24000,
  securityDeposit: 48000,
  maintenanceCharges: 2500,
  areaSqft: null,
  bedrooms: 2,
  bathrooms: 1,
  features: const ['wifi'],
  tags: const ['quiet'],
  mainImageUrl: 'https://example.com/room.jpg',
  imageUrls: const ['https://example.com/room.jpg'],
  availableFrom: DateTime.utc(2026, 5, 12),
  genderPreference: 'any',
  sharingType: 'private_room',
  societyType: 'gated',
  societyAmenities: const ['parking'],
  societyVibeTags: const ['quiet'],
);

class _CapturingAdapter implements HttpClientAdapter {
  _CapturingAdapter({this.responseBody = '{}'});

  final String responseBody;
  RequestOptions? lastRequest;

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
