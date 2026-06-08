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
    this.liked,
    this.userHasScheduledVisit,
    this.userNextVisitDate,
    this.googleStreetViewUrl,
    this.ownerContact,
    this.floorNumber,
    this.totalFloors,
    this.parkingSpaces,
    this.ageOfProperty,
    this.images = const [],
    this.amenities = const [],
    this.societyTagVoteCounts = const {},
    this.societyTagUserVotes = const {},
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
  final bool? liked;
  final bool? userHasScheduledVisit;
  final DateTime? userNextVisitDate;
  final String? googleStreetViewUrl;
  final String? ownerContact;
  final int? floorNumber;
  final int? totalFloors;
  final int? parkingSpaces;
  final int? ageOfProperty;
  final List<PropertyImageInfo> images;
  final List<PropertyAmenityInfo> amenities;
  final Map<String, Map<String, int>> societyTagVoteCounts;
  final Map<String, String> societyTagUserVotes;

  String? get effectiveMainImageUrl {
    if (mainImageUrl != null &&
        (mainImageUrl!.startsWith('http://') ||
            mainImageUrl!.startsWith('https://'))) {
      return mainImageUrl;
    }
    return imageUrls.isNotEmpty ? imageUrls.first : null;
  }

  String? get effectiveFloorPlanUrl {
    if (floorPlanUrl != null &&
        (floorPlanUrl!.startsWith('http://') ||
            floorPlanUrl!.startsWith('https://'))) {
      return floorPlanUrl;
    }
    final floorPlanImage = images.where(
      (img) => img.imageCategory == 'floor_plan',
    );
    if (floorPlanImage.isNotEmpty) return floorPlanImage.first.imageUrl;
    return null;
  }

  bool get isUnderReview =>
      status == 'pending_review' || status == 'under_review';
  bool get isRejected => status == 'rejected';
  bool get isLive => status == 'live' || status == 'approved';

  bool get isFurnished =>
      features.any((feature) => feature.toLowerCase().contains('furnished'));
}

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

class PropertyImageInfo {
  const PropertyImageInfo({
    required this.id,
    required this.imageUrl,
    this.caption,
    this.imageCategory,
    this.displayOrder,
    this.isMainImage = false,
  });

  final int id;
  final String imageUrl;
  final String? caption;
  final String? imageCategory;
  final int? displayOrder;
  final bool isMainImage;
}

class PropertyAmenityInfo {
  const PropertyAmenityInfo({
    required this.id,
    required this.title,
    this.icon,
    this.category,
  });

  final int id;
  final String title;
  final String? icon;
  final String? category;
}
