import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/features/chats/chats_repository.dart';
import 'package:flatmates_app/features/discover/domain/property_listing.dart';
import 'package:flatmates_app/features/discover/flat_details_page.dart';

import '../../helpers/test_helpers.dart';

PropertyListing _listing(int id, {required int imageCount}) => PropertyListing(
  id: id,
  ownerId: 100 + id,
  propertyType: 'flatmate',
  title: 'Listing $id',
  description: 'A flat',
  city: 'Bangalore',
  state: 'Karnataka',
  locality: 'Koramangala',
  subLocality: '5th Block',
  latitude: 12.9352,
  longitude: 77.6245,
  monthlyRent: 24000,
  mainImageUrl: 'https://example.com/photo-$id.jpg',
  imageUrls: List.generate(
    imageCount,
    (i) => 'https://example.com/photo-$id-$i.jpg',
  ),
  areaSqft: 1200,
  bedrooms: 2,
  bathrooms: 2,
  features: const ['wifi'],
  tags: const [],
  ownerName: 'Owner $id',
  availableFrom: null,
  genderPreference: 'any',
  sharingType: 'private_room',
  interestCount: 0,
  viewCount: 0,
  likeCount: 0,
  isAvailable: true,
);

void main() {
  testWidgets(
    'switching listings resets the carousel index (GoRouter reuses the page)',
    (tester) async {
      final listingId = ValueNotifier<int>(1);

      await tester.pumpWidget(
        testableWidget(
          overrides: [
            // The owner sheet's match percentage is irrelevant here.
            peerProfileProvider.overrideWith((ref, userId) async => null),
          ],
          child: ValueListenableBuilder<int>(
            valueListenable: listingId,
            builder: (context, value, _) => FlatDetailsPage(
              listingId: value,
              seededListing: _listing(value, imageCount: value == 1 ? 3 : 2),
            ),
          ),
        ),
      );

      // Network photos never complete in the test environment, so settle with
      // fixed pumps instead of pumpAndSettle (see full_screen_gallery_test).
      const settle = Duration(milliseconds: 500);
      await tester.pump();
      await tester.pump(settle);

      expect(find.text('1 / 3'), findsOneWidget);

      // Move to the second photo of listing 1.
      await tester.fling(find.byType(PageView), const Offset(-300, 0), 2000);
      await tester.pump();
      await tester.pump(settle);
      expect(find.text('2 / 3'), findsOneWidget);

      // Same route (/flat-details/:id), new listing: the page State is reused,
      // so the old carousel index must not leak into listing 2.
      listingId.value = 2;
      await tester.pump();
      await tester.pump(settle);

      expect(find.text('Listing 2'), findsOneWidget);
      expect(find.text('1 / 2'), findsOneWidget);
      expect(find.text('2 / 2'), findsNothing);
    },
  );
}
