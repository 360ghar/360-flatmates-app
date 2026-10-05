import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/features/discover/domain/property_listing.dart';
import 'package:flatmates_app/features/listings/presentation/widgets/listing_form_data.dart';

PropertyListing _listing({Map<String, dynamic>? preferences}) {
  return PropertyListing(
    id: 1,
    ownerId: 1,
    propertyType: 'flatmate',
    title: '2BHK in Indiranagar',
    description: null,
    city: 'Bangalore',
    state: null,
    locality: 'Indiranagar',
    subLocality: 'Indiranagar',
    latitude: null,
    longitude: null,
    monthlyRent: 25000,
    mainImageUrl: null,
    imageUrls: const [],
    areaSqft: null,
    bedrooms: 2,
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
    isAvailable: true,
    preferences: preferences,
  );
}

/// Runs [populateListingControllers] with disposable controllers and returns
/// the scalars plus the society field so callers can prove the load ran.
({ListingEditScalars scalars, String society}) _populate(
  PropertyListing listing,
) {
  final society = TextEditingController();
  final address = TextEditingController();
  final city = TextEditingController();
  final locality = TextEditingController();
  final rent = TextEditingController();
  final deposit = TextEditingController();
  final maintenance = TextEditingController();
  final typicalDay = TextEditingController();
  final floor = TextEditingController();
  final totalFloors = TextEditingController();
  final electricityEst = TextEditingController();
  final cookCost = TextEditingController();
  final maidCost = TextEditingController();
  final setupCost = TextEditingController();
  final otherCharges = TextEditingController();
  final otherChargesDescription = TextEditingController();
  final windowsCount = TextEditingController();
  final ventilationShafts = TextEditingController();
  addTearDown(() {
    for (final controller in [
      society,
      address,
      city,
      locality,
      rent,
      deposit,
      maintenance,
      typicalDay,
      floor,
      totalFloors,
      electricityEst,
      cookCost,
      maidCost,
      setupCost,
      otherCharges,
      otherChargesDescription,
      windowsCount,
      ventilationShafts,
    ]) {
      controller.dispose();
    }
  });

  final scalars = populateListingControllers(
    listing: listing,
    society: society,
    address: address,
    city: city,
    locality: locality,
    rent: rent,
    deposit: deposit,
    maintenance: maintenance,
    typicalDay: typicalDay,
    floor: floor,
    totalFloors: totalFloors,
    electricityEst: electricityEst,
    cookCost: cookCost,
    maidCost: maidCost,
    setupCost: setupCost,
    otherCharges: otherCharges,
    otherChargesDescription: otherChargesDescription,
    windowsCount: windowsCount,
    ventilationShafts: ventilationShafts,
    roomFeatures: <String>{},
    societyAmenities: <String>{},
    societyVibeTags: <String>{},
    nonNegotiables: <String>{},
    roomPhotoUrls: <String>[],
    fallbackRoomType: 'private_room',
    fallbackSocietyType: 'apartment',
    fallbackGenderPreference: 'any',
  );
  return (scalars: scalars, society: society.text);
}

void main() {
  group('populateListingControllers age preferences', () {
    test('parses string-valued age preferences', () {
      final result = _populate(
        _listing(
          preferences: {'preferred_age_min': '22', 'preferred_age_max': '40'},
        ),
      );

      // The cast to `num` used to throw here and abort the whole edit form.
      expect(result.scalars.ageMin, 22);
      expect(result.scalars.ageMax, 40);
      // The rest of the mapping completed.
      expect(result.scalars.roomType, 'private_room');
      expect(result.society, 'Indiranagar');
    });

    test('parses numeric age preferences', () {
      final result = _populate(
        _listing(
          preferences: {'preferred_age_min': 21.5, 'preferred_age_max': 35},
        ),
      );

      expect(result.scalars.ageMin, 21.5);
      expect(result.scalars.ageMax, 35);
    });

    test('treats an unparseable age preference as unset', () {
      final result = _populate(
        _listing(
          preferences: {
            'preferred_age_min': 'no-limit',
            'preferred_age_max': '',
          },
        ),
      );

      expect(result.scalars.ageMin, isNull);
      expect(result.scalars.ageMax, isNull);
    });

    test('returns null ages when the listing has no preferences', () {
      final result = _populate(_listing());

      expect(result.scalars.ageMin, isNull);
      expect(result.scalars.ageMax, isNull);
    });
  });
}
