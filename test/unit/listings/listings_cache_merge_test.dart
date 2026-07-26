import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/features/discover/domain/property_listing.dart';
import 'package:flatmates_app/features/discover/data/property_listing_dto.dart';

PropertyListing _listing({
  required int id,
  String title = 'Listing',
  String? status = 'pending_review',
}) {
  return PropertyListing(
    id: id,
    ownerId: 1,
    propertyType: 'flatmate',
    title: title,
    description: null,
    city: 'Bangalore',
    state: null,
    locality: 'Koramangala',
    subLocality: null,
    latitude: null,
    longitude: null,
    monthlyRent: 12000,
    mainImageUrl: 'https://example.com/a.jpg',
    imageUrls: const ['https://example.com/a.jpg'],
    areaSqft: null,
    bedrooms: 1,
    bathrooms: 1,
    features: const [],
    tags: const [],
    ownerName: null,
    availableFrom: null,
    genderPreference: 'any',
    sharingType: 'private_room',
    interestCount: 0,
    viewCount: 0,
    likeCount: 0,
    isAvailable: false,
    createdAt: DateTime.utc(2026, 1, id),
    status: status,
    preferences: status == null ? null : {'moderation_status': status},
  );
}

void main() {
  group('PropertyListingDto cache round-trip', () {
    test('toCacheJson/fromJson preserves id and pending_review status', () {
      final original = _listing(id: 42, title: 'Sunny room');
      final cached = PropertyListingDto.toCacheJson(original);
      final restored = PropertyListingDto.fromJson(cached);

      expect(restored.id, 42);
      expect(restored.title, 'Sunny room');
      expect(restored.status, 'pending_review');
      expect(restored.isUnderReview, isTrue);
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

    test('toCacheJson writes moderation_status from domain status', () {
      final original = _listing(id: 7);
      final cached = PropertyListingDto.toCacheJson(original);
      final prefs = cached['listing_preferences'] as Map;
      expect(prefs['moderation_status'], 'pending_review');
    });
  });
}
