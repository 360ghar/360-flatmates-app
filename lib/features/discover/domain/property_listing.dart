/// Domain model for a property listing.
///
/// This is the clean model used throughout the UI and business logic.
/// Construction from raw backend JSON is handled by [PropertyListingDto].
class PropertyListing {
  const PropertyListing({
    required this.id,
    required this.ownerId,
    required this.propertyType,
    required this.title,
    required this.description,
    required this.city,
    required this.state,
    required this.locality,
    required this.subLocality,
    required this.latitude,
    required this.longitude,
    required this.monthlyRent,
    required this.mainImageUrl,
    required this.imageUrls,
    required this.areaSqft,
    required this.bedrooms,
    required this.bathrooms,
    required this.features,
    required this.tags,
    required this.ownerName,
    required this.availableFrom,
    required this.genderPreference,
    required this.sharingType,
    this.videoTourUrl,
    this.virtualTourUrl,
    this.floorPlanUrl,
    required this.interestCount,
    required this.viewCount,
    required this.likeCount,
    required this.isAvailable,
    this.createdAt,
    this.preferences,
    this.status,
    this.propertyStatus,
    this.expiresAt,
    this.securityDeposit,
    this.maintenanceCharges,
    this.owner,
    this.distanceKm,
  });

  final int id;
  final int? ownerId;
  final String? propertyType;
  final String title;
  final String? description;
  final String? city;
  final String? state;
  final String? locality;
  final String? subLocality;
  final double? latitude;
  final double? longitude;
  final double monthlyRent;
  final String? mainImageUrl;
  final List<String> imageUrls;
  final double? areaSqft;
  final int? bedrooms;
  final int? bathrooms;
  final List<String> features;
  final List<String> tags;
  final String? ownerName;
  final DateTime? availableFrom;
  final String? genderPreference;
  final String? sharingType;
  final String? videoTourUrl;
  final String? virtualTourUrl;
  final String? floorPlanUrl;
  final double? securityDeposit;
  final double? maintenanceCharges;
  final int interestCount;
  final int viewCount;
  final int likeCount;
  final bool isAvailable;
  final DateTime? createdAt;
  final Map<String, dynamic>? preferences;
  final String? status;
  final String? propertyStatus;
  final DateTime? expiresAt;
  final PropertyOwner? owner;
  final double? distanceKm;

  /// Returns [mainImageUrl] if it is an absolute URL, otherwise falls back to
  /// the first entry in [imageUrls]. Handles the case where the backend stores
  /// `main_image_url` as a relative path that cannot be resolved by the app.
  String? get effectiveMainImageUrl {
    if (mainImageUrl != null &&
        (mainImageUrl!.startsWith('http://') ||
            mainImageUrl!.startsWith('https://'))) {
      return mainImageUrl;
    }
    return imageUrls.isNotEmpty ? imageUrls.first : null;
  }

  /// Returns [floorPlanUrl] if it is an absolute URL, otherwise falls back to
  /// checking the [imageUrls] array for any entry whose `image_category` might
  /// be `floor_plan` (currently not parsed in the DTO, but future-proofed).
  /// Handles the case where the backend stores `floor_plan_url` as a relative
  /// path that cannot be resolved by the app (same issue as `main_image_url`).
  String? get effectiveFloorPlanUrl {
    if (floorPlanUrl != null &&
        (floorPlanUrl!.startsWith('http://') ||
            floorPlanUrl!.startsWith('https://'))) {
      return floorPlanUrl;
    }
    return null;
  }

  bool get isUnderReview =>
      status == 'pending_review' || status == 'under_review';
  bool get isRejected => status == 'rejected';
  bool get isLive => status == 'live' || status == 'approved';

  bool get isFurnished =>
      features.any((feature) => feature.toLowerCase().contains('furnished'));
}

/// Lightweight owner info embedded in a [PropertyListing].
class PropertyOwner {
  const PropertyOwner({
    required this.id,
    required this.fullName,
    this.profileImageUrl,
    this.mode,
  });

  final int id;
  final String fullName;
  final String? profileImageUrl;
  final String? mode;
}
