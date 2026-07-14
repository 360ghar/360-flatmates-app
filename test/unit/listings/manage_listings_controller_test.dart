import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/features/discover/domain/property_listing.dart';
import 'package:flatmates_app/features/listings/application/manage_listings_actions_controller.dart';
import 'package:flatmates_app/features/listings/listings_repository.dart';

import '../../helpers/test_helpers.dart';

class _FakeListingsRepository implements ListingsRepository {
  _FakeListingsRepository(this._shouldFail);
  final bool _shouldFail;
  int togglePauseCalls = 0;
  int? lastListingId;
  bool? lastPaused;

  @override
  Future<void> togglePause(int listingId, {required bool paused}) async {
    togglePauseCalls++;
    lastListingId = listingId;
    lastPaused = paused;
    if (_shouldFail) throw Exception('Network error');
  }

  @override
  Future<int?> createListing(ListingCreateRequest request) async => 1;

  @override
  Future<int?> updateListing(
    int listingId,
    ListingCreateRequest request,
  ) async => listingId;

  @override
  Future<({List<PropertyListing> items, String? nextCursor, bool hasMore})>
  fetchMyListingsPage({String? cursor, int limit = 20}) async {
    return (items: <PropertyListing>[], nextCursor: null, hasMore: false);
  }

  @override
  Future<List<PropertyListing>> fetchMyListings({int limit = 20}) async =>
      <PropertyListing>[];
}

void main() {
  group('ManageListingsActionsController.togglePause', () {
    test('flips pause state optimistically when currently not paused', () async {
      final fakeRepo = _FakeListingsRepository(false);
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(fakeAppConfig()),
          listingsRepositoryProvider.overrideWithValue(fakeRepo),
          manageListingsActionsControllerProvider.overrideWith(
            () => ManageListingsActionsController(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(
        manageListingsActionsControllerProvider.notifier,
      );

      // Currently not paused → should optimistically set paused = true.
      await notifier.togglePause(5, currentlyPaused: false);

      final state = container.read(manageListingsActionsControllerProvider);
      // After success, optimistic override is cleared.
      expect(state.optimisticPaused.containsKey(5), isFalse);
      expect(state.pausingIds.contains(5), isFalse);
      expect(fakeRepo.togglePauseCalls, 1);
      expect(fakeRepo.lastListingId, 5);
      // currentlyPaused=false → repo.togglePause(paused: false) means "set to live"
      // per the repository's inverted semantics.
      expect(fakeRepo.lastPaused, false);
    });

    test('flips pause state optimistically when currently paused', () async {
      final fakeRepo = _FakeListingsRepository(false);
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(fakeAppConfig()),
          listingsRepositoryProvider.overrideWithValue(fakeRepo),
          manageListingsActionsControllerProvider.overrideWith(
            () => ManageListingsActionsController(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(
        manageListingsActionsControllerProvider.notifier,
      );

      // Currently paused → should optimistically set paused = false (resume).
      await notifier.togglePause(7, currentlyPaused: true);

      final state = container.read(manageListingsActionsControllerProvider);
      expect(state.optimisticPaused.containsKey(7), isFalse);
      expect(fakeRepo.togglePauseCalls, 1);
      expect(fakeRepo.lastListingId, 7);
      expect(fakeRepo.lastPaused, true);
    });

    test('rolls back on failure', () async {
      final fakeRepo = _FakeListingsRepository(true);
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(fakeAppConfig()),
          listingsRepositoryProvider.overrideWithValue(fakeRepo),
          manageListingsActionsControllerProvider.overrideWith(
            () => ManageListingsActionsController(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(
        manageListingsActionsControllerProvider.notifier,
      );

      // The toggle should throw because the repo fails.
      await expectLater(
        notifier.togglePause(10, currentlyPaused: false),
        throwsA(isA<Exception>()),
      );

      final state = container.read(manageListingsActionsControllerProvider);
      // Optimistic override should be rolled back (removed).
      expect(state.optimisticPaused.containsKey(10), isFalse);
      // pausingIds should also be cleared in finally.
      expect(state.pausingIds.contains(10), isFalse);
      expect(fakeRepo.togglePauseCalls, 1);
    });
  });
}
