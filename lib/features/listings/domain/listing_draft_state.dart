enum ListingDraftStep {
  location, // Step 0
  society, // Step 1
  room, // Step 2
  flat, // Step 3
  costs, // Step 4
  about, // Step 5
  preferences, // Step 6
  review, // Step 7
}

class ListingDraftState {
  const ListingDraftState({
    this.step = ListingDraftStep.location,
    // Step 0 - Location
    this.society = '',
    this.address = '',
    this.city = '',
    this.locality = '',
    // Step 1 - Society
    this.societyType = 'gated',
    this.societyAmenities = const {},
    this.societyVibeTags = const {},
    // Step 2 - Room
    this.roomType = 'private_room',
    this.roomFurnishing = const {},
    this.roomFeatures = const {},
    this.roomPhotoUrls = const [],
    this.videoTourUrl,
    this.videoUploading = false,
    // Step 3 - Flat
    this.flatConfig = '2BHK',
    this.floor = '',
    this.totalFloors = '',
    this.flatAmenities = const {},
    // Step 4 - Costs
    this.rent = '',
    this.deposit = '',
    this.maintenance = '',
    this.electricityIncluded = 'separate',
    this.electricityEst = '',
    this.cookCost = '',
    this.maidCost = '',
    this.setupCost = '',
    // Step 5 - About & Flatmate
    this.typicalDay = '',
    this.genderPreference = 'any',
    this.ageMin = 18.0,
    this.ageMax = 40.0,
    this.nonNegotiables = const {},
    this.availableFrom,
    // Meta
    this.isSubmitting = false,
    this.validationError,
    this.submitError,
  });

  final ListingDraftStep step;

  final String society;
  final String address;
  final String city;
  final String locality;

  final String societyType;
  final Set<String> societyAmenities;
  final Set<String> societyVibeTags;

  final String roomType;
  final Set<String> roomFurnishing;
  final Set<String> roomFeatures;
  final List<String> roomPhotoUrls;
  final String? videoTourUrl;
  final bool videoUploading;

  final String flatConfig;
  final String floor;
  final String totalFloors;
  final Set<String> flatAmenities;

  final String rent;
  final String deposit;
  final String maintenance;
  final String electricityIncluded;
  final String electricityEst;
  final String cookCost;
  final String maidCost;
  final String setupCost;

  final String typicalDay;
  final String genderPreference;
  final double ageMin;
  final double ageMax;
  final Set<String> nonNegotiables;
  final DateTime? availableFrom;

  final bool isSubmitting;
  final String? validationError;
  final String? submitError;

  static const totalSteps = 8;
  int get stepIndex => step.index;
  double get progress => (stepIndex + 1) / totalSteps;

  ListingDraftState copyWith({
    ListingDraftStep? step,
    String? society,
    String? address,
    String? city,
    String? locality,
    String? societyType,
    Set<String>? societyAmenities,
    Set<String>? societyVibeTags,
    String? roomType,
    Set<String>? roomFurnishing,
    Set<String>? roomFeatures,
    List<String>? roomPhotoUrls,
    String? videoTourUrl,
    bool? videoUploading,
    String? flatConfig,
    String? floor,
    String? totalFloors,
    Set<String>? flatAmenities,
    String? rent,
    String? deposit,
    String? maintenance,
    String? electricityIncluded,
    String? electricityEst,
    String? cookCost,
    String? maidCost,
    String? setupCost,
    String? typicalDay,
    String? genderPreference,
    double? ageMin,
    double? ageMax,
    Set<String>? nonNegotiables,
    DateTime? availableFrom,
    bool? isSubmitting,
    String? validationError,
    bool clearValidationError = false,
    String? submitError,
    bool clearSubmitError = false,
  }) {
    return ListingDraftState(
      step: step ?? this.step,
      society: society ?? this.society,
      address: address ?? this.address,
      city: city ?? this.city,
      locality: locality ?? this.locality,
      societyType: societyType ?? this.societyType,
      societyAmenities: societyAmenities ?? this.societyAmenities,
      societyVibeTags: societyVibeTags ?? this.societyVibeTags,
      roomType: roomType ?? this.roomType,
      roomFurnishing: roomFurnishing ?? this.roomFurnishing,
      roomFeatures: roomFeatures ?? this.roomFeatures,
      roomPhotoUrls: roomPhotoUrls ?? this.roomPhotoUrls,
      videoTourUrl: videoTourUrl ?? this.videoTourUrl,
      videoUploading: videoUploading ?? this.videoUploading,
      flatConfig: flatConfig ?? this.flatConfig,
      floor: floor ?? this.floor,
      totalFloors: totalFloors ?? this.totalFloors,
      flatAmenities: flatAmenities ?? this.flatAmenities,
      rent: rent ?? this.rent,
      deposit: deposit ?? this.deposit,
      maintenance: maintenance ?? this.maintenance,
      electricityIncluded: electricityIncluded ?? this.electricityIncluded,
      electricityEst: electricityEst ?? this.electricityEst,
      cookCost: cookCost ?? this.cookCost,
      maidCost: maidCost ?? this.maidCost,
      setupCost: setupCost ?? this.setupCost,
      typicalDay: typicalDay ?? this.typicalDay,
      genderPreference: genderPreference ?? this.genderPreference,
      ageMin: ageMin ?? this.ageMin,
      ageMax: ageMax ?? this.ageMax,
      nonNegotiables: nonNegotiables ?? this.nonNegotiables,
      availableFrom: availableFrom ?? this.availableFrom,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      validationError:
          validationError ??
          (clearValidationError ? null : this.validationError),
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
    );
  }
}
