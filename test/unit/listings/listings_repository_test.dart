import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flatmates_app/core/network/api_client.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/features/listings/listings_repository.dart';

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
  group('ListingsRepository.fetchMyListings', () {
    test('returns flatmate/pg listings from cursor envelope', () async {
      final container = _containerWithAdapter((options) {
        return Response<dynamic>(
          data: {
            'items': [
              {
                'id': 1,
                'title': 'Flatmate listing',
                'property_type': 'flatmate',
                'monthly_rent': 15000,
                'is_available': true,
                'status': 'live',
              },
              {
                'id': 2,
                'title': 'PG listing',
                'property_type': 'pg',
                'monthly_rent': 8000,
                'is_available': true,
                'status': 'live',
              },
              {
                'id': 3,
                'title': 'Other listing',
                'property_type': 'apartment',
                'monthly_rent': 30000,
                'is_available': true,
                'status': 'live',
              },
            ],
            'next_cursor': null,
            'has_more': false,
          },
          statusCode: 200,
          requestOptions: options,
        );
      });

      final repo = container.read(listingsRepositoryProvider);
      final listings = await repo.fetchMyListings();

      expect(listings.length, 2);
      expect(listings[0].id, 1);
      expect(listings[0].propertyType, 'flatmate');
      expect(listings[1].id, 2);
      expect(listings[1].propertyType, 'pg');
    });

    test('aggregates multiple pages until has_more is false', () async {
      var callCount = 0;
      final container = _containerWithAdapter((options) {
        callCount++;
        if (callCount == 1) {
          return Response<dynamic>(
            data: {
              'items': [
                {
                  'id': 1,
                  'title': 'First',
                  'property_type': 'flatmate',
                  'monthly_rent': 10000,
                  'is_available': true,
                },
              ],
              'next_cursor': 'cursor2',
              'has_more': true,
            },
            statusCode: 200,
            requestOptions: options,
          );
        }
        return Response<dynamic>(
          data: {
            'items': [
              {
                'id': 2,
                'title': 'Second',
                'property_type': 'flatmate',
                'monthly_rent': 12000,
                'is_available': true,
              },
            ],
            'next_cursor': null,
            'has_more': false,
          },
          statusCode: 200,
          requestOptions: options,
        );
      });

      final repo = container.read(listingsRepositoryProvider);
      final listings = await repo.fetchMyListings();

      expect(listings.length, 2);
      expect(listings[0].id, 1);
      expect(listings[1].id, 2);
      expect(callCount, 2);
    });
  });

  group('ListingsRepository.fetchMyListingsPage', () {
    test('returns cursor metadata from the envelope', () async {
      String? path;
      final container = _containerWithAdapter((options) {
        path = options.path;
        return Response<dynamic>(
          data: {
            'items': [
              {
                'id': 10,
                'title': 'Page item',
                'property_type': 'flatmate',
                'monthly_rent': 20000,
                'is_available': true,
              },
            ],
            'next_cursor': 'next-page-cursor',
            'has_more': true,
          },
          statusCode: 200,
          requestOptions: options,
        );
      });

      final repo = container.read(listingsRepositoryProvider);
      final page = await repo.fetchMyListingsPage(cursor: 'current-cursor');

      expect(path, '/properties/me');
      expect(page.items.length, 1);
      expect(page.items.first.id, 10);
      expect(page.nextCursor, 'next-page-cursor');
      expect(page.hasMore, isTrue);
    });

    test(
      'returns empty items and hasMore false when envelope is empty',
      () async {
        final container = _containerWithAdapter((options) {
          return Response<dynamic>(
            data: {'items': [], 'next_cursor': null, 'has_more': false},
            statusCode: 200,
            requestOptions: options,
          );
        });

        final repo = container.read(listingsRepositoryProvider);
        final page = await repo.fetchMyListingsPage();

        expect(page.items, isEmpty);
        expect(page.nextCursor, isNull);
        expect(page.hasMore, isFalse);
      },
    );
  });

  group('ListingsRepository.createListing', () {
    test('posts correct payload to /properties', () async {
      String? method;
      String? path;
      Map<String, dynamic>? sentData;
      final container = _containerWithAdapter((options) {
        method = options.method;
        path = options.path;
        sentData = options.data is Map
            ? Map<String, dynamic>.from(options.data as Map)
            : null;
        return Response<dynamic>(
          data: {'id': 42},
          statusCode: 201,
          requestOptions: options,
        );
      });

      final repo = container.read(listingsRepositoryProvider);
      final id = await repo.createListing(
        const ListingCreateRequest(
          title: 'Test Listing',
          description: 'A test description',
          city: 'Bangalore',
          locality: 'Koramangala',
          subLocality: '5th Block',
          monthlyRent: 15000,
          securityDeposit: 30000,
          maintenanceCharges: 2000,
          areaSqft: 1200,
          bedrooms: 2,
          bathrooms: 2,
          features: ['wifi', 'parking'],
          tags: ['furnished'],
          mainImageUrl: 'https://example.com/photo.jpg',
          imageUrls: ['https://example.com/photo.jpg'],
          availableFrom: null,
          genderPreference: 'any',
          sharingType: 'private_room',
          societyType: 'gated',
          societyAmenities: ['gym'],
          societyVibeTags: ['quiet'],
        ),
      );

      expect(method, 'POST');
      expect(path, '/properties');
      expect(id, 42);
      expect(sentData!['title'], 'Test Listing');
      expect(sentData!['property_type'], 'flatmate');
      expect(sentData!['purpose'], 'rent');
      expect(sentData!['monthly_rent'], 15000);
      expect(sentData!['base_price'], 15000);
      expect(sentData!['city'], 'Bangalore');
      expect(sentData!['locality'], 'Koramangala');
      expect(sentData!['sub_locality'], '5th Block');
      expect(sentData!['security_deposit'], 30000);
      expect(sentData!['maintenance_charges'], 2000);
      expect(sentData!['bedrooms'], 2);
      expect(sentData!['bathrooms'], 2);
      expect(sentData!['features'], ['wifi', 'parking']);
      expect(sentData!['tags'], ['furnished']);
      expect(sentData!['main_image_url'], 'https://example.com/photo.jpg');
      final prefs = sentData!['listing_preferences'] as Map<String, dynamic>;
      expect(prefs['gender_preference'], 'any');
      expect(prefs['sharing_type'], 'private_room');
      expect(prefs['society_type'], 'gated');
      expect(prefs['society_amenities'], ['gym']);
      expect(prefs['society_vibes'], ['quiet']);
    });
  });

  group('ListingsRepository.updateListing', () {
    test('puts correct payload to /properties/:id and strips nulls', () async {
      String? method;
      String? path;
      Map<String, dynamic>? sentData;
      final container = _containerWithAdapter((options) {
        method = options.method;
        path = options.path;
        sentData = options.data is Map
            ? Map<String, dynamic>.from(options.data as Map)
            : null;
        return Response<dynamic>(
          data: {'id': 99},
          statusCode: 200,
          requestOptions: options,
        );
      });

      final repo = container.read(listingsRepositoryProvider);
      final id = await repo.updateListing(
        99,
        const ListingCreateRequest(
          title: 'Updated Listing',
          description: null,
          city: 'Bangalore',
          locality: 'Indiranagar',
          subLocality: '',
          monthlyRent: 18000,
          securityDeposit: null,
          maintenanceCharges: null,
          areaSqft: 1000,
          bedrooms: 1,
          bathrooms: 1,
          features: [],
          tags: [],
          mainImageUrl: null,
          imageUrls: [],
          availableFrom: null,
          genderPreference: 'any',
          sharingType: 'shared_room',
          societyType: 'standalone',
          societyAmenities: [],
          societyVibeTags: [],
        ),
      );

      expect(method, 'PUT');
      expect(path, '/properties/99');
      expect(id, 99);
      expect(sentData!['title'], 'Updated Listing');
      expect(sentData!['monthly_rent'], 18000);
      // Null fields should be stripped by updateListing.
      expect(sentData!.containsKey('description'), isFalse);
      expect(sentData!.containsKey('security_deposit'), isFalse);
      expect(sentData!.containsKey('main_image_url'), isFalse);
    });
  });
}
