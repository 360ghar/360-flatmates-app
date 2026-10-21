import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flatmates_app/core/network/api_client.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/core/storage/app_preferences.dart';
import 'package:flatmates_app/features/bootstrap/bootstrap_controller.dart';
import 'package:flatmates_app/features/discover/data/property_listing_dto.dart';
import 'package:flatmates_app/features/discover/domain/property_listing.dart';
import 'package:flatmates_app/features/listings/listings_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';

class _EmptyPageAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode({
        'items': <dynamic>[],
        'next_cursor': null,
        'has_more': false,
        'limit': 20,
        'total': null,
      }),
      200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }
}

class _AccountBootstrap extends FakeBootstrapController {
  _AccountBootstrap(this.profileId);
  int profileId;

  /// Signs another account in on the same container.
  void switchAccount(int id) {
    profileId = id;
    final data = fakeBootstrapData();
    state = AsyncValue.data(
      BootstrapData(
        profile: data.profile.copyWith(id: id),
        catalogs: data.catalogs,
      ),
    );
  }

  @override
  Future<BootstrapData?> build() async {
    final data = fakeBootstrapData();
    final next = BootstrapData(
      profile: data.profile.copyWith(id: profileId),
      catalogs: data.catalogs,
    );
    state = AsyncValue.data(next);
    return next;
  }
}

PropertyListing _listing({required int id, String title = 'Listing'}) {
  return PropertyListingDto.fromJson({
    'id': id,
    'owner_id': 1,
    'title': title,
    'monthly_rent': 12000,
    'is_available': false,
    // A conflicting lifecycle status: the moderation status must win.
    'status': 'available',
    'listing_preferences': {'moderation_status': 'pending_review'},
  });
}

Future<ProviderContainer> _container({
  required int accountId,
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final preferences = await AppPreferences.create();
  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(fakeAppConfig()),
      authTokenProviderProvider.overrideWithValue(FakeAuthTokenProvider()),
      appPreferencesProvider.overrideWithValue(preferences),
      bootstrapControllerProvider.overrideWith(
        () => _AccountBootstrap(accountId),
      ),
      apiClientProvider.overrideWithValue(
        ApiClient(
          baseUrl: 'https://api.test.example.com',
          tokenProvider: FakeAuthTokenProvider(),
        )..dio.httpClientAdapter = _EmptyPageAdapter(),
      ),
    ],
  );
  addTearDown(container.dispose);
  await container.read(bootstrapControllerProvider.future);
  return container;
}

void main() {
  group('PropertyListingDto status', () {
    test('moderation_status wins over the lifecycle status', () {
      final listing = _listing(id: 42, title: 'Sunny room');

      expect(listing.status, 'pending_review');
      expect(listing.isUnderReview, isTrue);
      expect(listing.isLive, isFalse);
    });

    test('paused is a moderation status of its own', () {
      final listing = PropertyListingDto.fromJson({
        'id': 5,
        'title': 'Paused',
        'listing_preferences': {'moderation_status': 'paused'},
        'status': 'available',
      });

      expect(listing.isPaused, isTrue);
      expect(listing.isLive, isFalse);
      expect(listing.isUnderReview, isFalse);
    });

    test('a status this build does not know is not a moderation state', () {
      final listing = PropertyListingDto.fromJson({
        'id': 6,
        'title': 'Odd',
        'listing_preferences': {'moderation_status': 'approved'},
      });

      expect(listing.moderationStatus, isNull);
      expect(listing.isLive, isFalse);
    });

    test('fromJson tolerates string ids and numeric booleans', () {
      final listing = PropertyListingDto.fromJson({
        'id': '99',
        'title': 'Cozy',
        'monthly_rent': '15000',
        'is_available': 0,
        'listing_preferences': {
          'moderation_status': 'pending_review',
          'gender_preference': 'any',
          'sharing_type': 'private_room',
        },
        'status': 'available',
      });
      expect(listing.id, 99);
      expect(listing.monthlyRent, 15000);
      expect(listing.isAvailable, isFalse);
      expect(listing.status, 'pending_review');
    });
  });

  group('ListingsRepository owner cache', () {
    test('keeps a just-created listing when the server page lags', () async {
      final container = await _container(accountId: 7);
      final repo = container.read(listingsRepositoryProvider);

      await repo.cacheOwnerListing(_listing(id: 42, title: 'Sunny room'));
      final page = await repo.fetchMyListingsPage();

      expect(page.items.map((l) => l.id), [42]);
    });

    test('is scoped to the signed-in account', () async {
      final container = await _container(accountId: 7);
      final repo = container.read(listingsRepositoryProvider);
      await repo.cacheOwnerListing(_listing(id: 42));

      // The same repository and container, another account signed in: it
      // must not read the rows the first account cached.
      (container.read(bootstrapControllerProvider.notifier)
              as _AccountBootstrap)
          .switchAccount(8);
      final page = await repo.fetchMyListingsPage();

      expect(page.items, isEmpty);
    });

    test('is dropped on sign-out', () async {
      final container = await _container(accountId: 7);
      final repo = container.read(listingsRepositoryProvider);
      await repo.cacheOwnerListing(_listing(id: 42));

      await repo.clearOwnerListingsCache();
      final page = await repo.fetchMyListingsPage();

      expect(page.items, isEmpty);
    });

    test('writes nothing to disk and deletes a legacy disk cache', () async {
      final container = await _container(
        accountId: 7,
        prefs: {
          'my_listings_cache_latest_v1': '[{"id": 1}]',
          'my_listings_cache_v1_7': '[{"id": 1}]',
          'theme_mode': 'dark',
        },
      );
      final prefs = container.read(appPreferencesProvider);
      final repo = container.read(listingsRepositoryProvider);

      await repo.cacheOwnerListing(_listing(id: 42));
      // The cache is in memory: no key of it is written.
      expect(
        prefs.keys.where((k) => k.startsWith('my_listings_cache')),
        unorderedEquals([
          'my_listings_cache_latest_v1',
          'my_listings_cache_v1_7',
        ]),
      );

      await repo.clearOwnerListingsCache();
      // The legacy keys (no account scope, no schema version) are deleted;
      // unrelated keys stay.
      expect(
        prefs.keys.where((k) => k.startsWith('my_listings_cache')),
        isEmpty,
      );
      expect(prefs.keys, contains('theme_mode'));
    });
  });
}
