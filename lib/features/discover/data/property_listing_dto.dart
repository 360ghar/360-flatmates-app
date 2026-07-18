import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/utils/safe_json_list.dart';
import '../domain/property_listing.dart';

class PropertyListingDto {
  /// Parses backend property JSON into a domain [PropertyListing].
  ///
  /// Intentionally tolerant of type noise (string/num enums, nested maps,
  /// optional fields) so a single malformed field never drops an entire
  /// owner listing from Manage after a cold start.
  static PropertyListing fromJson(Map<String, dynamic> json) {
    final preferences = _asStringKeyMap(json['listing_preferences']);
    final rawFeatures = json['features'];
    final features = rawFeatures is List
        ? rawFeatures.map((item) => item.toString()).toList()
        : rawFeatures is Map
        ? rawFeatures.entries
              .where((entry) => entry.value == true)
              .map((entry) => entry.key.toString())
              .toList()
        : <String>[];

    final ownerJson = _asStringKeyMapOrNull(json['owner']);

    final parsedImages = _parseImages(json);
    final parsedImageUrls = parsedImages
        .map((img) => img.imageUrl)
        .toList(growable: false);

    final parsedAmenities = _parseAmenities(json);

    final rawSocietyTagVotes = preferences['society_tag_vote_counts'];
    final societyTagVoteCounts = <String, Map<String, int>>{};
    if (rawSocietyTagVotes is Map) {
      rawSocietyTagVotes.forEach((tag, counts) {
        if (counts is Map) {
          societyTagVoteCounts[tag.toString()] = {
            'up': _asInt(counts['up']) ?? 0,
            'down': _asInt(counts['down']) ?? 0,
          };
        }
      });
    }

    // Backend shape: { "userId": { "tag": "up|down" } }. Flatten to
    // "$userId:$tag" -> vote so UI can look up the current user's vote per tag.
    final rawUserVotes = preferences['society_tag_user_votes'];
    final societyTagUserVotes = <String, String>{};
    if (rawUserVotes is Map) {
      rawUserVotes.forEach((userId, value) {
        if (value is Map) {
          value.forEach((tag, vote) {
            societyTagUserVotes['$userId:$tag'] = vote.toString();
          });
        } else if (value != null) {
          societyTagUserVotes[userId.toString()] = value.toString();
        }
      });
    }

    final moderationStatus = _asString(preferences['moderation_status']);
    final lifecycleStatus = _asString(json['status']);

    return PropertyListing(
      id: _asInt(json['id']) ?? 0,
      ownerId: _asInt(json['owner_id']),
      propertyType: _asString(json['property_type']),
      title: _asString(json['title']) ?? 'Listing',
      description: _asString(json['description']),
      city: _asString(json['city']),
      state: _asString(json['state']),
      locality: _asString(json['locality']),
      subLocality: _asString(json['sub_locality']),
      latitude: _asDouble(json['latitude']),
      longitude: _asDouble(json['longitude']),
      monthlyRent: _asDouble(json['monthly_rent']) ?? 0,
      mainImageUrl: _ensureAbsoluteUrl(_asString(json['main_image_url'])),
      imageUrls: parsedImageUrls.isNotEmpty
          ? parsedImageUrls
          : _parseFallbackImageUrls(json),
      virtualTourUrl: _ensureAbsoluteUrl(_asString(json['virtual_tour_url'])),
      floorPlanUrl: _ensureAbsoluteUrl(_asString(json['floor_plan_url'])),
      areaSqft: _asDouble(json['area_sqft']),
      bedrooms: _asInt(json['bedrooms']),
      bathrooms: _asInt(json['bathrooms']),
      features: features,
      tags: (json['tags'] is List ? json['tags'] as List : const [])
          .map((item) => item.toString())
          .toList(),
      ownerName: _asString(json['owner_name']),
      availableFrom: DateTime.tryParse(
        json['available_from']?.toString() ?? '',
      ),
      genderPreference: _asString(preferences['gender_preference']),
      sharingType: _asString(preferences['sharing_type']),
      videoTourUrl:
          _ensureAbsoluteUrl(_asString(preferences['video_tour_url'])) ??
          _ensureAbsoluteUrl(_asString(json['video_tour_url'])),
      interestCount: _asInt(json['interest_count']) ?? 0,
      viewCount: _asInt(json['view_count']) ?? 0,
      likeCount: _asInt(json['like_count']) ?? 0,
      isAvailable: _asBool(json['is_available']) ?? false,
      securityDeposit: _asDouble(json['security_deposit']),
      maintenanceCharges: _asDouble(json['maintenance_charges']),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      preferences: preferences.isEmpty ? null : preferences,
      status: moderationStatus ?? lifecycleStatus,
      propertyStatus: lifecycleStatus,
      expiresAt: DateTime.tryParse(
        (json['expires_at'] ?? preferences['expires_at'])?.toString() ?? '',
      ),
      owner: ownerJson != null
          ? PropertyOwner(
              id: _asInt(ownerJson['id']) ?? 0,
              fullName: _asString(ownerJson['full_name']) ?? '',
              profileImageUrl: _asString(ownerJson['profile_image_url']),
              mode: _asString(ownerJson['mode']),
            )
          : null,
      distanceKm: _asDouble(json['distance_km']),
      liked: _asBool(json['liked']),
      userHasScheduledVisit: _asBool(json['user_has_scheduled_visit']),
      userNextVisitDate: DateTime.tryParse(
        json['user_next_visit_date']?.toString() ?? '',
      ),
      googleStreetViewUrl: _ensureAbsoluteUrl(
        _asString(json['google_street_view_url']),
      ),
      ownerContact: _asString(json['owner_contact']),
      floorNumber: _asInt(json['floor_number']),
      totalFloors: _asInt(json['total_floors']),
      parkingSpaces: _asInt(json['parking_spaces']),
      ageOfProperty: _asInt(json['age_of_property']),
      images: parsedImages,
      amenities: parsedAmenities,
      societyTagVoteCounts: societyTagVoteCounts,
      societyTagUserVotes: societyTagUserVotes,
    );
  }

  /// Compact cache representation so Manage listings survive process death
  /// until the next successful `/properties/me` reconcile.
  static Map<String, dynamic> toCacheJson(PropertyListing listing) {
    final preferences = Map<String, dynamic>.from(listing.preferences ?? {});
    if (listing.status != null &&
        preferences['moderation_status'] == null &&
        listing.status!.isNotEmpty) {
      preferences['moderation_status'] = listing.status;
    }
    return {
      'id': listing.id,
      'owner_id': listing.ownerId,
      'property_type': listing.propertyType,
      'title': listing.title,
      'description': listing.description,
      'city': listing.city,
      'state': listing.state,
      'locality': listing.locality,
      'sub_locality': listing.subLocality,
      'latitude': listing.latitude,
      'longitude': listing.longitude,
      'monthly_rent': listing.monthlyRent,
      'main_image_url': listing.mainImageUrl,
      'image_urls': listing.imageUrls,
      'area_sqft': listing.areaSqft,
      'bedrooms': listing.bedrooms,
      'bathrooms': listing.bathrooms,
      'features': listing.features,
      'tags': listing.tags,
      'owner_name': listing.ownerName,
      'available_from': listing.availableFrom?.toUtc().toIso8601String(),
      'interest_count': listing.interestCount,
      'view_count': listing.viewCount,
      'like_count': listing.likeCount,
      'is_available': listing.isAvailable,
      'security_deposit': listing.securityDeposit,
      'maintenance_charges': listing.maintenanceCharges,
      'created_at': listing.createdAt?.toUtc().toIso8601String(),
      'listing_preferences': preferences,
      'status': listing.propertyStatus,
      'expires_at': listing.expiresAt?.toUtc().toIso8601String(),
      'floor_number': listing.floorNumber,
      'total_floors': listing.totalFloors,
    };
  }

  static List<PropertyListing> fromJsonList(List<dynamic> list) {
    return safeJsonList(list, fromJson, label: 'propertyListings');
  }

  static List<PropertyImageInfo> _parseImages(Map<String, dynamic> json) {
    final rows = json['images'];
    if (rows is! List || rows.isEmpty) return const [];
    final images = <PropertyImageInfo>[];
    for (final item in rows) {
      if (item is! Map) continue;
      final url = item['image_url']?.toString();
      if (url == null || url.isEmpty || !_isAbsoluteUrl(url)) continue;
      images.add(
        PropertyImageInfo(
          id: _asInt(item['id']) ?? 0,
          imageUrl: url,
          caption: item['caption']?.toString(),
          imageCategory: item['image_category']?.toString(),
          displayOrder: _asInt(item['display_order']),
          isMainImage: _asBool(item['is_main_image']) ?? false,
        ),
      );
    }
    return images;
  }

  static List<String> _parseFallbackImageUrls(Map<String, dynamic> json) {
    final raw = json['image_urls'];
    if (raw is List && raw.isNotEmpty) {
      final strings = raw
          .map((item) => item?.toString() ?? '')
          .where(
            (url) => url.startsWith('http://') || url.startsWith('https://'),
          )
          .toList();
      if (strings.isNotEmpty) return strings;
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
    final main = _asString(json['main_image_url']);
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
      amenities.add(
        PropertyAmenityInfo(
          id: _asInt(item['id']) ?? 0,
          title: item['title']?.toString() ?? '',
          icon: item['icon']?.toString(),
          category: item['category']?.toString(),
        ),
      );
    }
    return amenities;
  }

  static Map<String, dynamic> _asStringKeyMap(Object? raw) {
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (e) {
        debugPrint('PropertyListingDto: listing_preferences string decode: $e');
      }
    }
    return <String, dynamic>{};
  }

  static Map<String, dynamic>? _asStringKeyMapOrNull(Object? raw) {
    if (raw is! Map) return null;
    return Map<String, dynamic>.from(raw);
  }

  static String? _asString(Object? raw) {
    if (raw == null) return null;
    final text = raw.toString();
    return text.isEmpty ? null : text;
  }

  static int? _asInt(Object? raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw.trim());
    return null;
  }

  static double? _asDouble(Object? raw) {
    if (raw is double) return raw;
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw.trim());
    return null;
  }

  static bool? _asBool(Object? raw) {
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    if (raw is String) {
      final lower = raw.trim().toLowerCase();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
    }
    return null;
  }

  static bool _isAbsoluteUrl(String url) =>
      url.startsWith('http://') || url.startsWith('https://');

  /// Returns [url] only if it is an absolute http/https URL, otherwise null.
  static String? _ensureAbsoluteUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    return _isAbsoluteUrl(url) ? url : null;
  }
}
