import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/features/discover/domain/property_listing.dart';

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

void main() {
  group('PropertyListing.copyWith liked/clearLiked', () {
    test('clearLiked: true resets liked to null', () {
      expect(_listing(liked: true).copyWith(clearLiked: true).liked, isNull);
    });

    test('clearLiked wins over an explicit value', () {
      expect(
        _listing(liked: true).copyWith(liked: false, clearLiked: true).liked,
        isNull,
      );
    });

    test('liked: false sets the value', () {
      expect(_listing(liked: true).copyWith(liked: false).liked, isFalse);
    });

    test('liked is kept when the argument is omitted', () {
      expect(_listing(liked: true).copyWith().liked, isTrue);
      expect(_listing().copyWith().liked, isNull);
    });

    test('other fields keep their copyWith behaviour', () {
      final updated = _listing(
        liked: true,
      ).copyWith(title: 'Renamed', likeCount: 5);
      expect(updated.title, 'Renamed');
      expect(updated.likeCount, 5);
      expect(updated.liked, isTrue);
    });
  });
}
