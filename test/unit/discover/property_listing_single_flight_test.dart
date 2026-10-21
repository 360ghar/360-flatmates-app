import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/features/discover/application/property_listing_seed_store.dart';
import 'package:flatmates_app/features/discover/discover_repository.dart';

PropertyListing _listing({
  required int id,
  required String title,
  String status = 'live',
}) => PropertyListing(
  id: id,
  ownerId: 100,
  propertyType: 'flatmate',
  title: title,
  description: 'A flat',
  city: 'Bangalore',
  state: 'Karnataka',
  locality: 'Koramangala',
  subLocality: '5th Block',
  latitude: 12.9352,
  longitude: 77.6245,
  monthlyRent: 24000,
  mainImageUrl: 'https://example.com/photo.jpg',
  imageUrls: const ['https://example.com/photo.jpg'],
  areaSqft: 1200,
  bedrooms: 2,
  bathrooms: 2,
  features: const ['wifi'],
  tags: const [],
  ownerName: 'Owner',
  availableFrom: null,
  genderPreference: 'any',
  sharingType: 'private_room',
  interestCount: 0,
  viewCount: 0,
  likeCount: 0,
  isAvailable: true,
  status: status,
);

/// `fetchListing` blocks until the test releases the gate, so a second GET
/// started in parallel would be visible as an extra call.
class _GatedListingRepository extends DiscoverRepository {
  _GatedListingRepository(super.ref);

  final List<Completer<void>> gates = [];
  int fetchCalls = 0;

  @override
  Future<PropertyListing> fetchListing(int propertyId) async {
    fetchCalls++;
    final gate = Completer<void>();
    gates.add(gate);
    await gate.future;
    return _listing(id: propertyId, title: 'Fresh from network');
  }
}

void main() {
  test(
    'build/reconcile and refetchFromNetwork share one in-flight GET',
    () async {
      late _GatedListingRepository repository;
      final container = ProviderContainer(
        overrides: [
          discoverRepositoryProvider.overrideWith((ref) {
            repository = _GatedListingRepository(ref);
            return repository;
          }),
        ],
      );
      addTearDown(container.dispose);

      // Under-review seed: build() returns it immediately and starts the
      // background reconcile GET — the seeded detail-page path from the review.
      container
          .read(propertyListingSeedStoreProvider.notifier)
          .put(_listing(id: 42, title: 'Seed', status: 'pending_review'));

      container.read(propertyListingProvider(42));
      await Future<void>.delayed(Duration.zero);
      expect(repository.fetchCalls, 1);

      final refetch = container
          .read(propertyListingProvider(42).notifier)
          .refetchFromNetwork();
      await Future<void>.delayed(Duration.zero);

      expect(
        repository.fetchCalls,
        1,
        reason: 'the refresh joins the in-flight GET instead of racing it',
      );

      repository.gates.single.complete();
      final fresh = await refetch;
      expect(fresh.title, 'Fresh from network');
      expect(
        container.read(propertyListingProvider(42)).valueOrNull!.title,
        'Fresh from network',
      );
    },
  );
}
