import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flatmates_app/features/discover/domain/property_listing.dart';
import 'package:flatmates_app/features/discover/presentation/widgets/discover_listing_card.dart';

import '../helpers/test_helpers.dart';

PropertyListing _listing() {
  return const PropertyListing(
    id: 1,
    ownerId: 2,
    propertyType: 'flatmate',
    title: 'Fully furnished private room near metro station',
    description: null,
    city: 'Gurgaon',
    state: 'Haryana',
    locality: 'Sector 45',
    subLocality: 'Near Cyber Park',
    latitude: 28.464615,
    longitude: 77.029919,
    monthlyRent: 28000,
    mainImageUrl: null,
    imageUrls: [],
    areaSqft: 950,
    bedrooms: 2,
    bathrooms: 2,
    features: ['furnished'],
    tags: [],
    ownerName: 'Owner',
    availableFrom: null,
    genderPreference: 'any',
    sharingType: 'private_room',
    interestCount: 0,
    viewCount: 0,
    likeCount: 0,
    isAvailable: true,
    securityDeposit: 56000,
  );
}

void main() {
  testWidgets('compact listing card fits map carousel constraints', (
    tester,
  ) async {
    await tester.pumpWidget(
      testableWidget(
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: 130,
              height: 180,
              child: DiscoverListingCard(
                item: _listing(),
                compact: true,
                onLike: () {},
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
