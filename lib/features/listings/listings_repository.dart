import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/endpoints.dart';
import '../../core/providers.dart';
import '../discover/data/property_listing_dto.dart';
import '../discover/discover_repository.dart';

class ListingCreateRequest {
  const ListingCreateRequest({
    required this.title,
    required this.description,
    required this.city,
    required this.locality,
    required this.subLocality,
    required this.monthlyRent,
    required this.securityDeposit,
    required this.maintenanceCharges,
    required this.areaSqft,
    required this.bedrooms,
    required this.bathrooms,
    required this.features,
    required this.tags,
    required this.mainImageUrl,
    required this.imageUrls,
    required this.availableFrom,
    required this.genderPreference,
    required this.sharingType,
    required this.societyType,
    required this.societyAmenities,
    required this.societyVibeTags,
    this.videoTourUrl,
  });

  final String title;
  final String? description;
  final String? city;
  final String? locality;
  final String? subLocality;
  final double monthlyRent;
  final double? securityDeposit;
  final double? maintenanceCharges;
  final double? areaSqft;
  final int? bedrooms;
  final int? bathrooms;
  final List<String> features;
  final List<String> tags;
  final String? mainImageUrl;
  final List<String> imageUrls;
  final DateTime? availableFrom;
  final String genderPreference;
  final String sharingType;
  final String societyType;
  final List<String> societyAmenities;
  final List<String> societyVibeTags;
  final String? videoTourUrl;

  Map<String, dynamic> toJson() {
    final fullAddress = [
      if (subLocality != null && subLocality!.trim().isNotEmpty)
        subLocality!.trim(),
      if (locality != null && locality!.trim().isNotEmpty) locality!.trim(),
      if (city != null && city!.trim().isNotEmpty) city!.trim(),
    ].join(', ');

    final preferences = <String, dynamic>{
      'gender_preference': genderPreference,
      'sharing_type': sharingType,
      'society_type': societyType,
      'society_amenities': societyAmenities,
      'society_vibes': societyVibeTags,
    };

    if (videoTourUrl != null) {
      preferences['video_tour_url'] = videoTourUrl;
    }

    return {
      'title': title,
      'description': description,
      'property_type': 'flatmate',
      'purpose': 'rent',
      'base_price': monthlyRent,
      'monthly_rent': monthlyRent,
      'city': city,
      'locality': locality,
      'sub_locality': subLocality,
      'full_address': fullAddress.isEmpty ? null : fullAddress,
      'area_sqft': areaSqft,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'security_deposit': securityDeposit,
      'maintenance_charges': maintenanceCharges,
      'features': features.isEmpty ? null : features,
      'tags': tags.isEmpty ? null : tags,
      'main_image_url': mainImageUrl,
      'image_urls': imageUrls.isEmpty ? null : imageUrls,
      'available_from': availableFrom?.toUtc().toIso8601String(),
      'listing_preferences': preferences,
    };
  }
}

class ListingsRepository {
  const ListingsRepository(this._ref);

  final Ref _ref;

  Future<int?> createListing(ListingCreateRequest request) async {
    final response = await _ref
        .watch(apiClientProvider)
        .post(FlatmatesEndpoints.properties, data: request.toJson());
    final rawData = response.data;
    final data = Map<String, dynamic>.from(rawData is Map ? rawData : const {});
    return (data['id'] as num?)?.toInt();
  }

  Future<List<PropertyListing>> fetchMyListings() async {
    final response = await _ref
        .watch(apiClientProvider)
        .get(FlatmatesEndpoints.myProperties);
    final rawData = response.data;
    final rows = rawData is List ? rawData : const [];
    return rows
        .map(
          (item) => PropertyListingDto.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .where((listing) {
          final type = listing.propertyType;
          return type == null || type == 'flatmate' || type == 'pg';
        })
        .toList(growable: false);
  }

  Future<void> togglePause(int listingId, {required bool paused}) async {
    await _ref
        .watch(apiClientProvider)
        .put(
          FlatmatesEndpoints.property(listingId),
          data: {
            'listing_preferences': {
              'moderation_status': paused ? 'live' : 'paused',
            },
          },
        );
  }
}

final listingsRepositoryProvider = Provider<ListingsRepository>(
  (ref) => ListingsRepository(ref),
);

final myListingsProvider = FutureProvider<List<PropertyListing>>(
  (ref) => ref.watch(listingsRepositoryProvider).fetchMyListings(),
);
