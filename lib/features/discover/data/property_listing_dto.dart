import '../domain/property_listing.dart';

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

    final parsedImages = _parseImages(json);
    final parsedImageUrls = parsedImages
        .map((img) => img.imageUrl)
        .toList(growable: false);

    final parsedAmenities = _parseAmenities(json);

    final rawSocietyTagVotes =
        preferences['society_tag_vote_counts'] as Map? ?? {};
    final societyTagVoteCounts = <String, Map<String, int>>{};
    rawSocietyTagVotes.forEach((tag, counts) {
      if (counts is Map) {
        societyTagVoteCounts[tag.toString()] = {
          'up': (counts['up'] as num?)?.toInt() ?? 0,
          'down': (counts['down'] as num?)?.toInt() ?? 0,
        };
      }
    });

    final rawUserVotes =
        preferences['society_tag_user_votes'] as Map? ?? {};
    final societyTagUserVotes = <String, String>{};
    rawUserVotes.forEach((userId, vote) {
      societyTagUserVotes[userId.toString()] = vote.toString();
    });

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
      mainImageUrl: _ensureAbsoluteUrl(json['main_image_url'] as String?),
      imageUrls: parsedImageUrls.isNotEmpty
          ? parsedImageUrls
          : _parseFallbackImageUrls(json),
      virtualTourUrl: _ensureAbsoluteUrl(json['virtual_tour_url'] as String?),
      floorPlanUrl: _ensureAbsoluteUrl(json['floor_plan_url'] as String?),
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
          _ensureAbsoluteUrl(preferences['video_tour_url'] as String?) ??
          _ensureAbsoluteUrl(json['video_tour_url'] as String?),
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
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      liked: json['liked'] as bool?,
      userHasScheduledVisit: json['user_has_scheduled_visit'] as bool?,
      userNextVisitDate: DateTime.tryParse(
        json['user_next_visit_date']?.toString() ?? '',
      ),
      googleStreetViewUrl: _ensureAbsoluteUrl(json['google_street_view_url'] as String?),
      ownerContact: json['owner_contact'] as String?,
      floorNumber: (json['floor_number'] as num?)?.toInt(),
      totalFloors: (json['total_floors'] as num?)?.toInt(),
      parkingSpaces: (json['parking_spaces'] as num?)?.toInt(),
      ageOfProperty: (json['age_of_property'] as num?)?.toInt(),
      images: parsedImages,
      amenities: parsedAmenities,
      societyTagVoteCounts: societyTagVoteCounts,
      societyTagUserVotes: societyTagUserVotes,
    );
  }

  static List<PropertyListing> fromJsonList(List<dynamic> list) {
    return list
        .map((item) => fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  static List<PropertyImageInfo> _parseImages(Map<String, dynamic> json) {
    final rows = json['images'];
    if (rows is! List || rows.isEmpty) return const [];
    final images = <PropertyImageInfo>[];
    for (final item in rows) {
      if (item is! Map) continue;
      final url = item['image_url']?.toString();
      if (url == null || url.isEmpty || !_isAbsoluteUrl(url)) continue;
      images.add(PropertyImageInfo(
        id: (item['id'] as num?)?.toInt() ?? 0,
        imageUrl: url,
        caption: item['caption']?.toString(),
        imageCategory: item['image_category']?.toString(),
        displayOrder: (item['display_order'] as num?)?.toInt(),
        isMainImage: item['is_main_image'] as bool? ?? false,
      ));
    }
    return images;
  }

  static List<String> _parseFallbackImageUrls(Map<String, dynamic> json) {
    final raw = json['image_urls'];
    if (raw is List && raw.isNotEmpty) {
      if (raw.every((e) => e is String)) {
        return List<String>.from(raw)
            .where(_isAbsoluteUrl)
            .toList(growable: false);
      }
    }
    final imageRows = json['images'];
    if (imageRows is List && imageRows.isNotEmpty) {
      final urls = imageRows
          .whereType<Map>()
          .map((item) => item['image_url']?.toString())
          .whereType<String>()
          .where((url) => url.isNotEmpty)
          .where(_isAbsoluteUrl)
          .toList(growable: false);
      if (urls.isNotEmpty) return urls;
    }
    final main = json['main_image_url'] as String?;
    if (main != null && main.isNotEmpty && _isAbsoluteUrl(main)) {
      return [main];
    }
    return const [];
  }

  static List<PropertyAmenityInfo> _parseAmenities(Map<String, dynamic> json) {
    final raw = json['amenities'] ?? json['property_amenities'];
    if (raw is! List || raw.isEmpty) return const [];
    final amenities = <PropertyAmenityInfo>[];
    for (final item in raw) {
      if (item is! Map) continue;
      amenities.add(PropertyAmenityInfo(
        id: (item['id'] as num?)?.toInt() ?? 0,
        title: item['title']?.toString() ?? '',
        icon: item['icon']?.toString(),
        category: item['category']?.toString(),
      ));
    }
    return amenities;
  }

  static bool _isAbsoluteUrl(String url) =>
      url.startsWith('http://') || url.startsWith('https://');

  /// Returns [url] only if it is an absolute http/https URL, otherwise null.
  /// Prevents relative paths from being joined with the API base URL (which
  /// would produce broken localhost URLs like
  /// `http://localhost:3600/api/v1/hc_properties/...`).
  static String? _ensureAbsoluteUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    return _isAbsoluteUrl(url) ? url : null;
  }
}
