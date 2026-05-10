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
        enableLogging: false,
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
        enableLogging: false,
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
  });
}

class _CapturingAdapter implements HttpClientAdapter {
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
      '{}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
