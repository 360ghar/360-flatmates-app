import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flatmates_app/core/domain/wire_enums.dart';
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
    test(
      'returns all listings from cursor envelope regardless of property_type',
      () async {
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

        // All three listings are returned — the owner sees all their own listings.
        expect(listings.length, 3);
        expect(listings[0].id, 1);
        expect(listings[1].id, 2);
        expect(listings[2].id, 3);
      },
    );

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
      final result = await repo.createListing(
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
      expect(result.id, 42);
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
      // The five society and preference fields are top-level contract keys,
      // and the vibe key is society_vibe_tags (not society_vibes).
      expect(sentData!['gender_preference'], 'any');
      expect(sentData!['sharing_type'], 'private_room');
      expect(sentData!['society_type'], 'gated');
      expect(sentData!['society_amenities'], ['gym']);
      expect(sentData!['society_vibe_tags'], ['quiet']);
      expect(sentData!.containsKey('society_vibes'), isFalse);
      final prefs = sentData!['listing_preferences'] as Map<String, dynamic>;
      expect(prefs.containsKey('society_vibes'), isFalse);
    });

    test(
      'a response in the old {data: ...} wrapper is not unwrapped',
      () async {
        final container = _containerWithAdapter(
          (options) => Response<dynamic>(
            data: {
              'data': {'id': 42},
            },
            statusCode: 201,
            requestOptions: options,
          ),
        );

        final result = await container
            .read(listingsRepositoryProvider)
            .createListing(
              const ListingCreateRequest(
                title: 'Wrapped response',
                description: null,
                city: 'Bangalore',
                locality: 'Koramangala',
                subLocality: '',
                monthlyRent: 15000,
                securityDeposit: null,
                maintenanceCharges: null,
                areaSqft: null,
                bedrooms: 1,
                features: [],
                tags: [],
                mainImageUrl: null,
                imageUrls: [],
                availableFrom: null,
                genderPreference: 'any',
                sharingType: 'private_room',
                societyType: 'standalone',
                societyAmenities: [],
                societyVibeTags: [],
              ),
            );

        // The contract returns the listing itself, so there is no id here.
        expect(result.id, isNull);
        expect(result.listing, isNull);
      },
    );

    test('sends no bathrooms when the owner entered none', () async {
      Map<String, dynamic>? sentData;
      final container = _containerWithAdapter((options) {
        sentData = Map<String, dynamic>.from(options.data as Map);
        return Response<dynamic>(
          data: {'id': 43},
          statusCode: 201,
          requestOptions: options,
        );
      });

      await container
          .read(listingsRepositoryProvider)
          .createListing(
            const ListingCreateRequest(
              title: 'No bathrooms entered',
              description: null,
              city: 'Bangalore',
              locality: 'Koramangala',
              subLocality: '',
              monthlyRent: 15000,
              securityDeposit: null,
              maintenanceCharges: null,
              areaSqft: null,
              bedrooms: 1,
              features: [],
              tags: [],
              mainImageUrl: null,
              imageUrls: [],
              availableFrom: null,
              genderPreference: 'any',
              sharingType: 'private_room',
              societyType: 'standalone',
              societyAmenities: [],
              societyVibeTags: [],
            ),
          );

      // A placeholder would be stored and shown as real listing data.
      expect(sentData!.containsKey('bathrooms'), isFalse);
    });

    test(
      'sends the date-only available_from and the furnishing level',
      () async {
        Map<String, dynamic>? sentData;
        final container = _containerWithAdapter((options) {
          sentData = Map<String, dynamic>.from(options.data as Map);
          return Response<dynamic>(
            data: {'id': 44},
            statusCode: 201,
            requestOptions: options,
          );
        });

        await container
            .read(listingsRepositoryProvider)
            .createListing(
              ListingCreateRequest(
                title: 'Furnished room',
                description: null,
                city: 'Bangalore',
                locality: 'Koramangala',
                subLocality: '',
                monthlyRent: 15000,
                securityDeposit: null,
                maintenanceCharges: null,
                areaSqft: null,
                bedrooms: 1,
                features: const ['furnished'],
                tags: const [],
                mainImageUrl: null,
                imageUrls: const [],
                availableFrom: DateTime(2026, 11, 3),
                genderPreference: 'any',
                sharingType: 'private_room',
                societyType: 'standalone',
                societyAmenities: const [],
                societyVibeTags: const [],
                furnishingLevel: FurnishingLevel.furnished,
              ),
            );

        expect(sentData!['available_from'], '2026-11-03');
        expect(sentData!['furnishing_level'], 'furnished');
        final prefs = sentData!['listing_preferences'] as Map<String, dynamic>;
        expect(prefs['rooms'], [
          {'furnishing_level': 'furnished'},
        ]);
      },
    );
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
      final result = await repo.updateListing(
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
      expect(result.id, 99);
      expect(sentData!['title'], 'Updated Listing');
      expect(sentData!['monthly_rent'], 18000);
      // A control the owner cleared sends an explicit null, so the server
      // clears the stored value.
      expect(sentData!.containsKey('description'), isTrue);
      expect(sentData!['description'], isNull);
      expect(sentData!.containsKey('security_deposit'), isTrue);
      expect(sentData!['security_deposit'], isNull);
      expect(sentData!.containsKey('main_image_url'), isTrue);
      expect(sentData!['main_image_url'], isNull);
      // Keys with a value are sent as they are.
      expect(sentData!['area_sqft'], 1000);
      expect(sentData!['bathrooms'], 1);
    });

    test('leaves out keys the form has no control for', () async {
      Map<String, dynamic>? sentData;
      final container = _containerWithAdapter((options) {
        sentData = Map<String, dynamic>.from(options.data as Map);
        return Response<dynamic>(
          data: {'id': 99},
          statusCode: 200,
          requestOptions: options,
        );
      });

      await container
          .read(listingsRepositoryProvider)
          .updateListing(
            99,
            const ListingCreateRequest(
              title: 'Updated Listing',
              description: 'Text',
              city: 'Bangalore',
              locality: 'Indiranagar',
              subLocality: '',
              monthlyRent: 18000,
              securityDeposit: null,
              maintenanceCharges: null,
              areaSqft: null,
              bedrooms: 1,
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

      // The form has no area or bathrooms control: the stored values stay.
      expect(sentData!.containsKey('area_sqft'), isFalse);
      expect(sentData!.containsKey('bathrooms'), isFalse);
      // Cleared controls are explicit nulls.
      expect(sentData!.containsKey('security_deposit'), isTrue);
      expect(sentData!['security_deposit'], isNull);
    });
  });
}
