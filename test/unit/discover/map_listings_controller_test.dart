import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/features/bootstrap/bootstrap_controller.dart';
import 'package:flatmates_app/features/discover/application/map_listings_controller.dart';
import 'package:flatmates_app/features/discover/discover_repository.dart';

import '../../helpers/test_helpers.dart';

PropertyListing _listing({bool? liked}) => PropertyListing(
  id: 1,
  ownerId: 2,
  propertyType: 'flatmate',
  title: 'Listing',
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
  liked: liked,
);

/// Repository whose like POST blocks until [likeGate] completes and then
/// always fails, so the optimistic flip and the rollback are both observable.
class _GatedFailingLikeRepository extends DiscoverRepository {
  _GatedFailingLikeRepository(super.ref);

  final Completer<void> likeGate = Completer<void>();
  int setLikedCalls = 0;

  @override
  Future<List<PropertyListing>> fetchListings({
    String? cursor,
    int limit = 20,
    FlatmatesProfileModel? currentUser,
    DiscoverFilters? filters,
  }) async => [_listing()];

  @override
  Future<int?> setLiked(int propertyId, bool liked) async {
    setLikedCalls++;
    await likeGate.future;
    throw StateError('like POST failed');
  }
}

void main() {
  test('a failed like toggle restores liked: null (unknown)', () async {
    late _GatedFailingLikeRepository repository;
    final container = ProviderContainer(
      overrides: [
        bootstrapControllerProvider.overrideWith(
          () => FakeBootstrapController(),
        ),
        discoverRepositoryProvider.overrideWith((ref) {
          repository = _GatedFailingLikeRepository(ref);
          return repository;
        }),
      ],
    );
    addTearDown(container.dispose);

    // Let the controller's initial load land.
    container.read(mapListingsProvider);
    await Future<void>.delayed(Duration.zero);

    final controller = container.read(mapListingsProvider.notifier);
    expect(container.read(mapListingsProvider).listings.single.liked, isNull);

    final toggle = controller.toggleLike(1);
    final expectation = expectLater(toggle, throwsA(isA<StateError>()));
    await Future<void>.delayed(Duration.zero);

    // Optimistic flip is visible while the request is in flight.
    expect(container.read(mapListingsProvider).listings.single.liked, isTrue);

    repository.likeGate.complete();
    await expectation;

    // Rollback must restore `null`, not leave the optimistic `true` behind.
    expect(container.read(mapListingsProvider).listings.single.liked, isNull);
    expect(repository.setLikedCalls, 1);
  });
}
