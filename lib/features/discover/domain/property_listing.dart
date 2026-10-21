import '../../../core/domain/wire_enums.dart';
import 'society_tag_vote.dart';

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
    this.kitchenType,
    this.ventilationType,
    this.windowsCount,
    this.ventilationShafts,
    this.setupCost,
    this.otherCharges,
    this.otherChargesDescription,
    this.furnishingLevel,
    this.hasLift,
    this.fullAddress,
    this.images = const [],
    this.amenities = const [],
    this.societyTagVotes = const {},
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
  final String? kitchenType;
  final String? ventilationType;
  final int? windowsCount;
  final int? ventilationShafts;
  final double? setupCost;
  final double? otherCharges;
  final String? otherChargesDescription;
  final String? furnishingLevel;
  final bool? hasLift;

  /// The street address the owner typed (`full_address`). Only the owner's
  /// edit form reads it back; it is not shown to other users.
  final String? fullAddress;
  final List<PropertyImageInfo> images;
  final List<PropertyAmenityInfo> amenities;

  /// The viewer's vote results by tag, filled from the vote POST answer. The
  /// listing payload has no vote counts (the server hides them).
  final Map<String, SocietyTagVote> societyTagVotes;

  /// Tags the owner picked (`listing_preferences.society_vibe_tags`, a public
  /// key). These are the tags a viewer can vote on.
  List<String> get societyVibeTags {
    final raw = preferences?['society_vibe_tags'];
    return raw is List ? [for (final t in raw) t.toString()] : const [];
  }

  PropertyListing copyWith({
    int? id,
    int? ownerId,
    String? propertyType,
    String? title,
    String? description,
    String? city,
    String? state,
    String? locality,
    String? subLocality,
    double? latitude,
    double? longitude,
    double? monthlyRent,
    String? mainImageUrl,
    List<String>? imageUrls,
    double? areaSqft,
    int? bedrooms,
    int? bathrooms,
    List<String>? features,
    List<String>? tags,
    String? ownerName,
    DateTime? availableFrom,
    String? genderPreference,
    String? sharingType,
    String? videoTourUrl,
    String? virtualTourUrl,
    String? floorPlanUrl,
    int? interestCount,
    int? viewCount,
    int? likeCount,
    bool? isAvailable,
    DateTime? createdAt,
    Map<String, dynamic>? preferences,
    String? status,
    String? propertyStatus,
    DateTime? expiresAt,
    double? securityDeposit,
    double? maintenanceCharges,
    double? distanceKm,
    bool? liked,
    // Clears [liked] back to null (unknown). Needed for optimistic rollbacks:
    // a plain `liked: null` means "keep the current value".
    bool clearLiked = false,
    bool? userHasScheduledVisit,
    DateTime? userNextVisitDate,
    String? googleStreetViewUrl,
    String? ownerContact,
    int? floorNumber,
    int? totalFloors,
    int? parkingSpaces,
    int? ageOfProperty,
    String? kitchenType,
    String? ventilationType,
    int? windowsCount,
    int? ventilationShafts,
    double? setupCost,
    double? otherCharges,
    String? otherChargesDescription,
    String? furnishingLevel,
    bool? hasLift,
    String? fullAddress,
    List<PropertyImageInfo>? images,
    List<PropertyAmenityInfo>? amenities,
    Map<String, SocietyTagVote>? societyTagVotes,
  }) {
    return PropertyListing(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      propertyType: propertyType ?? this.propertyType,
      title: title ?? this.title,
      description: description ?? this.description,
      city: city ?? this.city,
      state: state ?? this.state,
      locality: locality ?? this.locality,
      subLocality: subLocality ?? this.subLocality,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      monthlyRent: monthlyRent ?? this.monthlyRent,
      mainImageUrl: mainImageUrl ?? this.mainImageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      areaSqft: areaSqft ?? this.areaSqft,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      features: features ?? this.features,
      tags: tags ?? this.tags,
      ownerName: ownerName ?? this.ownerName,
      availableFrom: availableFrom ?? this.availableFrom,
      genderPreference: genderPreference ?? this.genderPreference,
      sharingType: sharingType ?? this.sharingType,
      videoTourUrl: videoTourUrl ?? this.videoTourUrl,
      virtualTourUrl: virtualTourUrl ?? this.virtualTourUrl,
      floorPlanUrl: floorPlanUrl ?? this.floorPlanUrl,
      interestCount: interestCount ?? this.interestCount,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
      preferences: preferences ?? this.preferences,
      status: status ?? this.status,
      propertyStatus: propertyStatus ?? this.propertyStatus,
      expiresAt: expiresAt ?? this.expiresAt,
      securityDeposit: securityDeposit ?? this.securityDeposit,
      maintenanceCharges: maintenanceCharges ?? this.maintenanceCharges,
      distanceKm: distanceKm ?? this.distanceKm,
      liked: clearLiked ? null : (liked ?? this.liked),
      userHasScheduledVisit:
          userHasScheduledVisit ?? this.userHasScheduledVisit,
      userNextVisitDate: userNextVisitDate ?? this.userNextVisitDate,
      googleStreetViewUrl: googleStreetViewUrl ?? this.googleStreetViewUrl,
      ownerContact: ownerContact ?? this.ownerContact,
      floorNumber: floorNumber ?? this.floorNumber,
      totalFloors: totalFloors ?? this.totalFloors,
      parkingSpaces: parkingSpaces ?? this.parkingSpaces,
      ageOfProperty: ageOfProperty ?? this.ageOfProperty,
      kitchenType: kitchenType ?? this.kitchenType,
      ventilationType: ventilationType ?? this.ventilationType,
      windowsCount: windowsCount ?? this.windowsCount,
      ventilationShafts: ventilationShafts ?? this.ventilationShafts,
      setupCost: setupCost ?? this.setupCost,
      otherCharges: otherCharges ?? this.otherCharges,
      otherChargesDescription:
          otherChargesDescription ?? this.otherChargesDescription,
      furnishingLevel: furnishingLevel ?? this.furnishingLevel,
      hasLift: hasLift ?? this.hasLift,
      fullAddress: fullAddress ?? this.fullAddress,
      images: images ?? this.images,
      amenities: amenities ?? this.amenities,
      societyTagVotes: societyTagVotes ?? this.societyTagVotes,
    );
  }

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

  /// The moderation state of the listing, or null when [status] carries a
  /// lifecycle value (`available`, `sold`, ...) or nothing. Matches the wire
  /// values without logging: [status] mixes both vocabularies.
  ListingModerationStatus? get moderationStatus {
    final value = status;
    if (value == null) return null;
    for (final candidate in ListingModerationStatus.values) {
      if (candidate.wire == value) return candidate;
    }
    return null;
  }

  /// In review: new, or sent back to review by a content edit (title, rent,
  /// description, photos). An availability toggle does not do this.
  bool get isUnderReview =>
      moderationStatus == ListingModerationStatus.pendingReview;
  bool get isPaused => moderationStatus == ListingModerationStatus.paused;
  bool get isRejected => moderationStatus == ListingModerationStatus.rejected;
  bool get isLive => moderationStatus == ListingModerationStatus.live;

  bool get isFurnished =>
      features.any((feature) => feature.toLowerCase().contains('furnished'));
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
