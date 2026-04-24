import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

class PropertyListing {
  const PropertyListing({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.city,
    required this.state,
    required this.locality,
    required this.subLocality,
    required this.monthlyRent,
    required this.mainImageUrl,
    required this.areaSqft,
    required this.bedrooms,
    required this.bathrooms,
    required this.features,
    required this.tags,
    required this.ownerName,
    required this.availableFrom,
    required this.genderPreference,
    required this.sharingType,
    required this.interestCount,
    this.createdAt,
    this.preferences,
    this.status,
  });

  final int id;
  final int? ownerId;
  final String title;
  final String? description;
  final String? city;
  final String? state;
  final String? locality;
  final String? subLocality;
  final double? monthlyRent;
  final String? mainImageUrl;
  final double? areaSqft;
  final int? bedrooms;
  final int? bathrooms;
  final List<String> features;
  final List<String> tags;
  final String? ownerName;
  final DateTime? availableFrom;
  final String? genderPreference;
  final String? sharingType;
  final int interestCount;
  final DateTime? createdAt;
  final Map<String, dynamic>? preferences;
  final String? status;

  bool get isUnderReview => status == 'pending_review' || status == 'under_review';
  bool get isRejected => status == 'rejected';
  bool get isLive => status == 'live' || status == 'approved';

  factory PropertyListing.fromJson(Map<String, dynamic> json) {
    final preferences = Map<String, dynamic>.from(
      json['listing_preferences'] as Map? ?? const {},
    );
    return PropertyListing(
      id: (json['id'] as num?)?.toInt() ?? 0,
      ownerId: (json['owner_id'] as num?)?.toInt(),
      title: json['title'] as String? ?? 'Listing',
      description: json['description'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      locality: json['locality'] as String?,
      subLocality: json['sub_locality'] as String?,
      monthlyRent: (json['monthly_rent'] as num?)?.toDouble(),
      mainImageUrl: json['main_image_url'] as String?,
      areaSqft: (json['area_sqft'] as num?)?.toDouble(),
      bedrooms: (json['bedrooms'] as num?)?.toInt(),
      bathrooms: (json['bathrooms'] as num?)?.toInt(),
      features: (json['features'] as List? ?? const [])
          .map((item) => item.toString())
          .toList(),
      tags: (json['tags'] as List? ?? const [])
          .map((item) => item.toString())
          .toList(),
      ownerName: json['owner_name'] as String?,
      availableFrom: DateTime.tryParse(
        json['available_from']?.toString() ?? '',
      ),
      genderPreference: preferences['gender_preference'] as String?,
      sharingType: preferences['sharing_type'] as String?,
      interestCount: (json['interest_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(
        json['created_at']?.toString() ?? '',
      ),
      preferences: preferences,
      status: json['status'] as String?,
    );
  }

  bool get isFurnished =>
      features.any((feature) => feature.toLowerCase().contains('furnished'));
}

class DiscoverRepository {
  const DiscoverRepository(this._ref);

  final Ref _ref;

  Future<List<PropertyListing>> fetchListings({int offset = 0, int limit = 20}) async {
    final response = await _ref
        .watch(apiClientProvider)
        .get(
          '/properties',
          queryParameters: {
            'property_type': 'flatmate',
            'purpose': 'rent',
            'offset': offset,
            'limit': limit,
          },
        );
    final data = Map<String, dynamic>.from(response.data as Map);
    final properties = (data['properties'] as List? ?? const []);
    return properties
        .map(
          (item) =>
              PropertyListing.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<int?> likeListing(int propertyId) async {
    final response = await _ref
        .watch(apiClientProvider)
        .post(
          '/flatmates/swipes',
          data: {
            'target_type': 'property',
            'action': 'like',
            'property_id': propertyId,
          },
        );
    final data = Map<String, dynamic>.from(response.data as Map);
    return (data['conversation_id'] as num?)?.toInt();
  }
}

final discoverRepositoryProvider = Provider<DiscoverRepository>(
  (ref) => DiscoverRepository(ref),
);

final discoverListingsProvider = FutureProvider<List<PropertyListing>>(
  (ref) => ref.watch(discoverRepositoryProvider).fetchListings(),
);
