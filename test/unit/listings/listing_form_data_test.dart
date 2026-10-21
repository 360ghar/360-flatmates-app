import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/core/domain/wire_enums.dart';
import 'package:flatmates_app/features/discover/domain/property_listing.dart';
import 'package:flatmates_app/features/listings/presentation/widgets/listing_form_data.dart';

PropertyListing _listing({
  Map<String, dynamic>? preferences,
  String? fullAddress,
  List<String> features = const [],
  String? furnishingLevel,
}) {
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
    features: features,
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
    fullAddress: fullAddress,
    furnishingLevel: furnishingLevel,
  );
}

/// Runs [populateListingControllers] with disposable controllers and returns
/// the scalars plus the society field so callers can prove the load ran.
({
  ListingEditScalars scalars,
  String society,
  String address,
  Set<String> roomFurnishing,
})
_populate(PropertyListing listing, {Set<String>? societyVibeTags}) {
  final roomFurnishing = <String>{};
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
    roomFurnishing: roomFurnishing,
    roomFeatures: <String>{},
    societyAmenities: <String>{},
    societyVibeTags: societyVibeTags ?? <String>{},
    nonNegotiables: <String>{},
    roomPhotoUrls: <String>[],
    fallbackRoomType: 'private_room',
    fallbackSocietyType: 'apartment',
    fallbackGenderPreference: 'any',
  );
  return (
    scalars: scalars,
    society: society.text,
    address: address.text,
    roomFurnishing: roomFurnishing,
  );
}

/// A form with the answers a minimal listing needs and the given furnishing.
ListingFormData _formData({
  Set<String> roomFurnishing = const {},
  FurnishingLevel? keptFurnishingLevel,
}) {
  TextEditingController text(String value) {
    final controller = TextEditingController(text: value);
    addTearDown(controller.dispose);
    return controller;
  }

  return ListingFormData(
    societyController: text('Indiranagar'),
    addressController: text(''),
    cityController: text('Bangalore'),
    localityController: text('Indiranagar'),
    societyType: 'apartment',
    societyAmenities: <String>{},
    societyVibeTags: <String>{},
    roomType: 'private_room',
    roomFurnishing: {...roomFurnishing},
    roomFeatures: <String>{'wifi'},
    roomPhotoUrls: const ['https://cdn.example.com/a.jpg'],
    videoTourUrl: null,
    videoUploading: false,
    flatConfig: '2BHK',
    floorController: text(''),
    totalFloorsController: text(''),
    flatAmenities: <String>{},
    kitchenType: null,
    ventilationType: null,
    windowsController: text(''),
    ventilationShaftsController: text(''),
    rentController: text('25000'),
    depositController: text(''),
    maintenanceController: text(''),
    electricityIncluded: 'included',
    electricityEstController: text(''),
    cookCostController: text(''),
    maidCostController: text(''),
    setupCostController: text(''),
    otherChargesController: text(''),
    otherChargesDescriptionController: text(''),
    typicalDayController: text(''),
    genderPreference: 'any',
    ageMin: 18,
    ageMax: 40,
    nonNegotiables: <String>{},
    availableFrom: null,
    keptFurnishingLevel: keptFurnishingLevel,
  );
}

void main() {
  group('the update body keeps the stored furnishing', () {
    test('a picked chip sends the level and the rooms', () {
      final body = _formData(
        roomFurnishing: {'semi_furnished'},
      ).toRequest().toUpdateJson();

      expect(body['furnishing_level'], 'semi_furnished');
      expect((body['listing_preferences'] as Map)['rooms'], [
        {'furnishing_level': 'semi_furnished'},
      ]);
    });

    test('a form restored from a furnished listing does not clear it', () {
      final listing = _listing(features: ['furnished']);
      final picks = _populate(listing).roomFurnishing;
      final body = _formData(roomFurnishing: picks).toRequest().toUpdateJson();

      expect(body['furnishing_level'], 'furnished');
    });

    test('a stored unfurnished level survives an edit with no pick', () {
      final body = _formData(
        keptFurnishingLevel: FurnishingLevel.unfurnished,
      ).toRequest().toUpdateJson();

      expect(body['furnishing_level'], 'unfurnished');
    });

    test('the owner who drops the pick clears the level', () {
      final body = _formData().toRequest().toUpdateJson();

      expect(body.containsKey('furnishing_level'), isTrue);
      expect(body['furnishing_level'], isNull);
      expect((body['listing_preferences'] as Map)['rooms'], isEmpty);
    });
  });

  group('populateListingControllers furnishing', () {
    // The form sends furnishing_level (and rooms) on every update, and null
    // clears the stored value: the edit form must open with the stored pick.
    test('the furnished chip comes back from features', () {
      final result = _populate(_listing(features: ['furnished', 'wifi']));

      expect(result.roomFurnishing, {'furnished'});
    });

    test(
      'the level comes back from furnishing_level when features lack it',
      () {
        final result = _populate(_listing(furnishingLevel: 'semi_furnished'));

        expect(result.roomFurnishing, {'semi_furnished'});
      },
    );

    test('a listing with no furnishing opens with no pick', () {
      final result = _populate(_listing(features: ['wifi']));

      expect(result.roomFurnishing, isEmpty);
      expect(result.scalars.keptFurnishingLevel, isNull);
    });

    test('a stored unfurnished level has no chip and is kept', () {
      final result = _populate(_listing(furnishingLevel: 'unfurnished'));

      expect(result.roomFurnishing, isEmpty);
      expect(result.scalars.keptFurnishingLevel, FurnishingLevel.unfurnished);
    });
  });

  group('populateListingControllers street address', () {
    test('reads the street from the typed full_address field', () {
      final result = _populate(_listing(fullAddress: '12, 5th Cross Road'));

      expect(result.address, '12, 5th Cross Road');
    });

    test('an address the form composed reads back as no street typed', () {
      // The form sends society, locality and city as full_address when the
      // owner types no street; showing it as typed text would make the next
      // save keep an out-of-date copy.
      final result = _populate(
        _listing(fullAddress: 'Indiranagar, Indiranagar, Bangalore'),
      );

      expect(result.address, isEmpty);
    });

    test('a listing with no full_address has no street', () {
      expect(_populate(_listing()).address, isEmpty);
    });

    test('the street of an earlier build (a preference) is not read', () {
      // The server keeps only public listing_preferences keys for an owner,
      // so a street kept there never came back; the typed field is the source.
      final result = _populate(
        _listing(preferences: {'full_address': 'in preferences'}),
      );

      expect(result.address, isEmpty);
    });
  });

  group('populateListingControllers vibe tags', () {
    void populateTags(PropertyListing listing, Set<String> tags) =>
        _populate(listing, societyVibeTags: tags);

    test('reads society_vibe_tags and not the old society_vibes key', () {
      final tags = <String>{};
      populateTags(
        _listing(
          preferences: {
            'society_vibe_tags': ['quiet'],
            'society_vibes': ['party'],
          },
        ),
        tags,
      );
      expect(tags, {'quiet'});

      final old = <String>{};
      populateTags(
        _listing(
          preferences: {
            'society_vibes': ['party'],
          },
        ),
        old,
      );
      expect(old, isEmpty);
    });
  });

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
