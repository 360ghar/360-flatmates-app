import 'package:flatmates_app/features/discover/domain/property_listing.dart';
import 'package:flatmates_app/features/listings/domain/listing_status.dart';
import 'package:flutter_test/flutter_test.dart';

PropertyListing _listing({
  String? status,
  String? propertyStatus,
  DateTime? expiresAt,
  bool isAvailable = true,
  Map<String, dynamic>? preferences,
}) {
  return PropertyListing(
    id: 1,
    ownerId: null,
    propertyType: 'flatmate',
    title: 'Test',
    description: null,
    city: null,
    state: null,
    locality: null,
    subLocality: null,
    latitude: null,
    longitude: null,
    monthlyRent: 10000,
    mainImageUrl: null,
    imageUrls: const [],
    areaSqft: null,
    bedrooms: 2,
    bathrooms: 1,
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
    test('live/approved/available map to active', () {
      expect(listingStatus(_listing(status: 'live')), 'active');
      expect(listingStatus(_listing(status: 'approved')), 'active');
      expect(listingStatus(_listing()), 'active');
    });

    test('pending_review and under_review normalise to pending_review', () {
      expect(
        listingStatus(_listing(status: 'pending_review')),
        'pending_review',
      );
      expect(listingStatus(_listing(status: 'under_review')), 'pending_review');
    });

    test('paused and draft and rejected pass through', () {
      expect(listingStatus(_listing(status: 'paused')), 'paused');
      expect(listingStatus(_listing(status: 'draft')), 'draft');
      expect(listingStatus(_listing(status: 'rejected')), 'rejected');
    });

    test('past expiry date wins over a live status', () {
      final status = listingStatus(
        _listing(
          status: 'live',
          expiresAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      );
      expect(status, 'expired');
    });

    test('auto-paused expired move-in date marks expired', () {
      final status = listingStatus(
        _listing(
          status: 'live',
          preferences: const {'auto_paused_reason': 'expired_move_in_date'},
        ),
      );
      expect(status, 'expired');
    });
  });

  group('listingMatchesTab', () {
    test('active tab includes active, paused and under-review listings', () {
      expect(listingMatchesTab(_listing(status: 'live'), 'active'), isTrue);
      expect(listingMatchesTab(_listing(status: 'paused'), 'active'), isTrue);
      expect(
        listingMatchesTab(_listing(status: 'pending_review'), 'active'),
        isTrue,
      );
      expect(listingMatchesTab(_listing(status: 'draft'), 'active'), isFalse);
    });

    test('draft tab includes drafts and rejected listings', () {
      expect(listingMatchesTab(_listing(status: 'draft'), 'draft'), isTrue);
      expect(listingMatchesTab(_listing(status: 'rejected'), 'draft'), isTrue);
      expect(listingMatchesTab(_listing(status: 'live'), 'draft'), isFalse);
    });

    test('expired tab only matches expired listings', () {
      expect(
        listingMatchesTab(
          _listing(
            status: 'live',
            expiresAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
          'expired',
        ),
        isTrue,
      );
      expect(listingMatchesTab(_listing(status: 'live'), 'expired'), isFalse);
    });
  });
}
