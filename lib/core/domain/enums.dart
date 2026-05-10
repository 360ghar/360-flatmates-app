// lib/core/domain/enums.dart
// Typed business enums for the 360 Flatmates app.
// Each enum has fromApi(String), toApi(), and a label getter.

enum UserMode {
  roomPoster,
  coHunter,
  openToBoth;

  static UserMode fromApi(String value) => switch (value) {
    'room_poster' => UserMode.roomPoster,
    'co_hunter' => UserMode.coHunter,
    'open_to_both' => UserMode.openToBoth,
    _ => UserMode.coHunter,
  };

  String toApi() => switch (this) {
    UserMode.roomPoster => 'room_poster',
    UserMode.coHunter => 'co_hunter',
    UserMode.openToBoth => 'open_to_both',
  };

  String get label => switch (this) {
    UserMode.roomPoster => 'List My Flat / Find Flatmate',
    UserMode.coHunter => 'Find a Flat / Flatmate',
    UserMode.openToBoth => 'Open to Both',
  };
}

enum ListingModerationStatus {
  draft,
  pendingReview,
  underReview,
  live,
  rejected,
  expired,
  paused;

  static ListingModerationStatus fromApi(String value) => switch (value) {
    'draft' => ListingModerationStatus.draft,
    'pending_review' => ListingModerationStatus.pendingReview,
    'under_review' => ListingModerationStatus.underReview,
    'live' => ListingModerationStatus.live,
    'rejected' => ListingModerationStatus.rejected,
    'expired' => ListingModerationStatus.expired,
    'paused' => ListingModerationStatus.paused,
    _ => ListingModerationStatus.draft,
  };

  String toApi() => switch (this) {
    ListingModerationStatus.draft => 'draft',
    ListingModerationStatus.pendingReview => 'pending_review',
    ListingModerationStatus.underReview => 'under_review',
    ListingModerationStatus.live => 'live',
    ListingModerationStatus.rejected => 'rejected',
    ListingModerationStatus.expired => 'expired',
    ListingModerationStatus.paused => 'paused',
  };
}

enum SharingType {
  privateRoom,
  sharedRoom,
  masterBedroom,
  entireFlat;

  static SharingType fromApi(String value) => switch (value) {
    'private_room' => SharingType.privateRoom,
    'shared_room' => SharingType.sharedRoom,
    'master_bedroom' => SharingType.masterBedroom,
    'entire_flat' => SharingType.entireFlat,
    _ => SharingType.privateRoom,
  };

  String toApi() => switch (this) {
    SharingType.privateRoom => 'private_room',
    SharingType.sharedRoom => 'shared_room',
    SharingType.masterBedroom => 'master_bedroom',
    SharingType.entireFlat => 'entire_flat',
  };
}

enum GenderPreference {
  male,
  female,
  any;

  static GenderPreference fromApi(String value) => switch (value) {
    'male' => GenderPreference.male,
    'female' => GenderPreference.female,
    'any' => GenderPreference.any,
    'no_preference' => GenderPreference.any,
    _ => GenderPreference.any,
  };

  String toApi() => switch (this) {
    GenderPreference.male => 'male',
    GenderPreference.female => 'female',
    GenderPreference.any => 'any',
  };
}

enum VisitStatus {
  requested,
  confirmed,
  rescheduleSuggested,
  cancelled,
  completed;

  static VisitStatus fromApi(String value) => switch (value) {
    'requested' => VisitStatus.requested,
    'confirmed' => VisitStatus.confirmed,
    'reschedule_suggested' => VisitStatus.rescheduleSuggested,
    'cancelled' => VisitStatus.cancelled,
    'completed' => VisitStatus.completed,
    _ => VisitStatus.requested,
  };

  String toApi() => switch (this) {
    VisitStatus.requested => 'requested',
    VisitStatus.confirmed => 'confirmed',
    VisitStatus.rescheduleSuggested => 'reschedule_suggested',
    VisitStatus.cancelled => 'cancelled',
    VisitStatus.completed => 'completed',
  };
}

enum SwipeAction {
  like,
  pass,
  superLike;

  static SwipeAction fromApi(String value) => switch (value) {
    'like' => SwipeAction.like,
    'pass' => SwipeAction.pass,
    'super_like' => SwipeAction.superLike,
    _ => SwipeAction.pass,
  };

  String toApi() => switch (this) {
    SwipeAction.like => 'like',
    SwipeAction.pass => 'pass',
    SwipeAction.superLike => 'super_like',
  };
}

enum TimeSlot {
  morning,
  afternoon,
  evening;

  static TimeSlot fromApi(String value) => switch (value) {
    'morning' => TimeSlot.morning,
    'afternoon' => TimeSlot.afternoon,
    'evening' => TimeSlot.evening,
    _ => TimeSlot.afternoon,
  };

  String toApi() => switch (this) {
    TimeSlot.morning => 'morning',
    TimeSlot.afternoon => 'afternoon',
    TimeSlot.evening => 'evening',
  };

  int get hour => switch (this) {
    TimeSlot.morning => 10,
    TimeSlot.afternoon => 15,
    TimeSlot.evening => 18,
  };
}

enum FoodHabits {
  vegetarian,
  nonVegetarian,
  eggetarian,
  noPreference;

  static FoodHabits fromApi(String value) => switch (value) {
    'vegetarian' || 'veg' => FoodHabits.vegetarian,
    'non_vegetarian' || 'non_veg' => FoodHabits.nonVegetarian,
    'eggetarian' => FoodHabits.eggetarian,
    _ => FoodHabits.noPreference,
  };

  String toApi() => switch (this) {
    FoodHabits.vegetarian => 'vegetarian',
    FoodHabits.nonVegetarian => 'non_vegetarian',
    FoodHabits.eggetarian => 'eggetarian',
    FoodHabits.noPreference => 'no_preference',
  };
}

enum SmokingPreference {
  neither,
  smokeOutside,
  noPreference;

  static SmokingPreference fromApi(String value) => switch (value) {
    'neither' || 'no' => SmokingPreference.neither,
    'smoke_outside' || 'yes' => SmokingPreference.smokeOutside,
    _ => SmokingPreference.noPreference,
  };

  String toApi() => switch (this) {
    SmokingPreference.neither => 'neither',
    SmokingPreference.smokeOutside => 'smoke_outside',
    SmokingPreference.noPreference => 'no_preference',
  };
}

enum PetPreference {
  havePets,
  noPets,
  noPreference;

  static PetPreference fromApi(String value) => switch (value) {
    'have_pets' || 'yes' => PetPreference.havePets,
    'no_pets' || 'no' => PetPreference.noPets,
    _ => PetPreference.noPreference,
  };

  String toApi() => switch (this) {
    PetPreference.havePets => 'have_pets',
    PetPreference.noPets => 'no_pets',
    PetPreference.noPreference => 'no_preference',
  };
}

enum ProfileStatus {
  draft,
  active,
  suspended;

  static ProfileStatus fromApi(String value) => switch (value) {
    'draft' => ProfileStatus.draft,
    'active' => ProfileStatus.active,
    'suspended' => ProfileStatus.suspended,
    _ => ProfileStatus.draft,
  };

  String toApi() => switch (this) {
    ProfileStatus.draft => 'draft',
    ProfileStatus.active => 'active',
    ProfileStatus.suspended => 'suspended',
  };
}
