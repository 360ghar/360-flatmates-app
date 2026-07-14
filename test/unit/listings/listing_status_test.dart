import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/features/discover/domain/property_listing.dart';
import 'package:flatmates_app/features/listings/domain/listing_status.dart';

PropertyListing _listing({
  String? status,
  String? propertyStatus,
  DateTime? expiresAt,
  bool isAvailable = false,
  Map<String, dynamic>? preferences,
}) {
  return PropertyListing(
    id: 1,
    ownerId: 1,
    propertyType: 'flatmate',
    title: 'Test',
    description: null,
    city: 'Bangalore',
    state: 'Karnataka',
    locality: 'Koramangala',
    subLocality: null,
    latitude: null,
    longitude: null,
    monthlyRent: 10000,
    mainImageUrl: null,
    imageUrls: const [],
    areaSqft: null,
    bedrooms: null,
    bathrooms: null,
    features: const [],
    tags: const [],
    ownerName: null,
    availableFrom: null,
    genderPreference: null,
    sharingType: null,
    interestCount: 0,
    viewCount: 0,
    likeCount: 0,
    isAvailable: isAvailable,
    status: status,
    propertyStatus: propertyStatus,
    expiresAt: expiresAt,
    preferences: preferences,
  );
}

void main() {
  group('listingStatus', () {
    test('active status is correctly identified', () {
      final listing = _listing(status: 'live');
      expect(listingStatus(listing), 'active');
    });

    test('approved status maps to active', () {
      final listing = _listing(status: 'approved');
      expect(listingStatus(listing), 'active');
    });

    test('isAvailable true with empty status maps to active', () {
      final listing = _listing(status: '', isAvailable: true);
      expect(listingStatus(listing), 'active');
    });

    test('paused status is correctly identified', () {
      final listing = _listing(status: 'paused');
      expect(listingStatus(listing), 'paused');
    });

    test('expired status is correctly identified', () {
      final listing = _listing(status: 'expired');
      expect(listingStatus(listing), 'expired');
    });

    test('expired by past expiresAt date is correctly identified', () {
      final listing = _listing(status: 'live', expiresAt: DateTime(2020));
      expect(listingStatus(listing), 'expired');
    });

    test(
      'expired by auto_paused_reason preference is correctly identified',
      () {
        final listing = _listing(
          status: 'live',
          preferences: {'auto_paused_reason': 'expired_move_in_date'},
        );
        expect(listingStatus(listing), 'expired');
      },
    );

    test('pending_review status is correctly identified', () {
      final listing = _listing(status: 'pending_review');
      expect(listingStatus(listing), 'pending_review');
    });

    test('under_review status maps to pending_review', () {
      final listing = _listing(status: 'under_review');
      expect(listingStatus(listing), 'pending_review');
    });
  });

  group('listingMatchesTab', () {
    test('active tab matches active listing', () {
      final listing = _listing(status: 'live');
      expect(listingMatchesTab(listing, 'active'), isTrue);
    });

    test('active tab matches paused listing', () {
      final listing = _listing(status: 'paused');
      expect(listingMatchesTab(listing, 'active'), isTrue);
    });

    test('active tab matches pending_review listing', () {
      final listing = _listing(status: 'pending_review');
      expect(listingMatchesTab(listing, 'active'), isTrue);
    });

    test('draft tab matches draft listing', () {
      final listing = _listing(status: 'draft');
      expect(listingMatchesTab(listing, 'draft'), isTrue);
    });

    test('draft tab matches rejected listing', () {
      final listing = _listing(status: 'rejected');
      expect(listingMatchesTab(listing, 'draft'), isTrue);
    });

    test('expired tab matches expired listing', () {
      final listing = _listing(status: 'expired');
      expect(listingMatchesTab(listing, 'expired'), isTrue);
    });

    test('active tab does not match expired listing', () {
      final listing = _listing(status: 'expired');
      expect(listingMatchesTab(listing, 'active'), isFalse);
    });
  });
}
