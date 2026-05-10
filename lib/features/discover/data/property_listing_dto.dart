import '../domain/property_listing.dart';

/// Data-transfer object that constructs a [PropertyListing] from raw backend JSON.
///
/// All backend-specific parsing logic lives here so the domain model stays clean.
class PropertyListingDto {
  static PropertyListing fromJson(Map<String, dynamic> json) {
    final preferences = Map<String, dynamic>.from(
      json['listing_preferences'] as Map? ?? const {},
    );
    final rawFeatures = json['features'];
    final features = rawFeatures is List
        ? rawFeatures.map((item) => item.toString()).toList()
        : rawFeatures is Map
        ? rawFeatures.entries
              .where((entry) => entry.value == true)
              .map((entry) => entry.key.toString())
              .toList()
        : <String>[];

    final ownerJson = json['owner'] as Map<String, dynamic>?;

    return PropertyListing(
      id: (json['id'] as num?)?.toInt() ?? 0,
      ownerId: (json['owner_id'] as num?)?.toInt(),
      propertyType: json['property_type']?.toString(),
      title: json['title'] as String? ?? 'Listing',
      description: json['description'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      locality: json['locality'] as String?,
      subLocality: json['sub_locality'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      monthlyRent: (json['monthly_rent'] as num?)?.toDouble() ?? 0,
      mainImageUrl: json['main_image_url'] as String?,
      imageUrls: _parseImageUrls(json),
      areaSqft: (json['area_sqft'] as num?)?.toDouble(),
      bedrooms: (json['bedrooms'] as num?)?.toInt(),
      bathrooms: (json['bathrooms'] as num?)?.toInt(),
      features: features,
      tags: (json['tags'] as List? ?? const [])
          .map((item) => item.toString())
          .toList(),
      ownerName: json['owner_name'] as String?,
      availableFrom: DateTime.tryParse(
        json['available_from']?.toString() ?? '',
      ),
      genderPreference: preferences['gender_preference'] as String?,
      sharingType: preferences['sharing_type'] as String?,
      videoTourUrl:
          preferences['video_tour_url'] as String? ??
          json['video_tour_url'] as String?,
      interestCount: (json['interest_count'] as num?)?.toInt() ?? 0,
      viewCount: (json['view_count'] as num?)?.toInt() ?? 0,
      likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
      isAvailable: json['is_available'] as bool? ?? false,
      securityDeposit: (json['security_deposit'] as num?)?.toDouble(),
      maintenanceCharges: (json['maintenance_charges'] as num?)?.toDouble(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      preferences: preferences,
      status:
          preferences['moderation_status'] as String? ??
          json['status'] as String?,
      propertyStatus: json['status'] as String?,
      expiresAt: DateTime.tryParse(
        (json['expires_at'] ?? preferences['expires_at'])?.toString() ?? '',
      ),
      owner: ownerJson != null
          ? PropertyOwner(
              id: (ownerJson['id'] as num?)?.toInt() ?? 0,
              fullName: ownerJson['full_name'] as String? ?? '',
              profileImageUrl: ownerJson['profile_image_url'] as String?,
              mode: ownerJson['mode'] as String?,
            )
          : null,
    );
  }

  static List<PropertyListing> fromJsonList(List<dynamic> list) {
    return list
        .map((item) => fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  static List<String> _parseImageUrls(Map<String, dynamic> json) {
    final raw = json['image_urls'];
    if (raw is List && raw.isNotEmpty) {
      return raw.map((item) => item.toString()).toList();
    }
    final imageRows = json['images'];
    if (imageRows is List && imageRows.isNotEmpty) {
      final urls = imageRows
          .whereType<Map>()
          .map((item) => item['image_url']?.toString())
          .whereType<String>()
          .where((url) => url.isNotEmpty)
          .toList(growable: false);
      if (urls.isNotEmpty) return urls;
    }
    final main = json['main_image_url'] as String?;
    if (main != null && main.isNotEmpty) return [main];
    return const [];
  }
}
