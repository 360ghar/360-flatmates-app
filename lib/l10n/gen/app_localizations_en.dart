// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => '360 FlatMates';

  @override
  String get splashTagline => 'Find. Connect. Live Together.';

  @override
  String get splashSubtagline =>
      'The smarter way to find your flat and flatmates.';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonSave => 'Save';

  @override
  String get markAllRead => 'Mark all read';

  @override
  String get seeAllCta => 'See all';

  @override
  String get cancelCta => 'Cancel';

  @override
  String get enterPhoneTitle => 'Enter your phone number';

  @override
  String get enterPhoneSubtitle =>
      'Sign in or create an account to get started.';

  @override
  String get phoneNumberLabel => 'Phone number';

  @override
  String get loginWithPassword => 'Login with password';

  @override
  String get continueWithOtp => 'Continue with OTP';

  @override
  String get createAccountCta => 'Create account';

  @override
  String get loginTitle => 'Login';

  @override
  String get signupTitle => 'Create your account';

  @override
  String get fullNameLabel => 'Full name';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get signInCta => 'Sign in';

  @override
  String get otpTitle => 'Verify OTP';

  @override
  String get otpCodeLabel => 'OTP code';

  @override
  String get verifyOtpCta => 'Verify';

  @override
  String otpSubtitle(String phone) {
    return 'Enter the OTP sent to $phone.';
  }

  @override
  String get discoverTitle => 'Discover';

  @override
  String get emptyListings => 'No flatmate listings are available right now.';

  @override
  String homeGreeting(String name) {
    return 'Good afternoon, $name';
  }

  @override
  String homeGreetingMorning(String name) {
    return 'Good morning, $name';
  }

  @override
  String homeGreetingAfternoon(String name) {
    return 'Good afternoon, $name';
  }

  @override
  String homeGreetingEvening(String name) {
    return 'Good evening, $name';
  }

  @override
  String get homeGuestName => 'there';

  @override
  String homeSubtitle(String city) {
    return 'Find your next flatmate in $city';
  }

  @override
  String homeMarketInsight(int count) {
    return '$count verified people are actively looking nearby';
  }

  @override
  String get homeMarketInsightCta => 'View active seekers';

  @override
  String get homeLocationFallback =>
      'Set your city and locality to personalize discovery.';

  @override
  String get locationUpdated => 'Location updated';

  @override
  String get locationPermissionRequired =>
      'Location permission is required to detect your city.';

  @override
  String get locationDetectionFailed =>
      'Could not detect your location. Please select manually.';

  @override
  String get homeSearchHint => 'Search area, budget, flatmate...';

  @override
  String get searchMapHint => 'Search location, sector, society...';

  @override
  String get homePickedForYou => 'Best matches for you';

  @override
  String get homePickedSubtitle =>
      'Top flats that match your preferences and vibe';

  @override
  String get homeNoResults => 'No listings match those filters.';

  @override
  String get homeNoResultsSubtitle =>
      'Try adjusting your filters or search for a different location.';

  @override
  String homeBedroomsChip(int count) {
    return '$count BHK';
  }

  @override
  String homeBedsValue(int count) {
    return '$count Bed';
  }

  @override
  String homeBathsValue(int count) {
    return '$count Bath';
  }

  @override
  String homeAreaValue(String area) {
    return '$area sq.ft';
  }

  @override
  String homeMoveInValue(String date) {
    return 'Move-in: $date';
  }

  @override
  String homeInterestCount(int count) {
    return '$count interested';
  }

  @override
  String get badgeNew => 'New';

  @override
  String get badgePopular => 'Popular';

  @override
  String get badgeTrending => 'Trending';

  @override
  String monthlyRentLabel(String amount) {
    return 'Monthly rent: ₹$amount';
  }

  @override
  String monthlyRentHeadline(String amount) {
    return '₹$amount / month';
  }

  @override
  String get contactRequestSent =>
      'Interest sent. The owner can now chat with you.';

  @override
  String contactRequestWithConversation(int conversationId) {
    return 'Interest sent. Conversation #$conversationId is ready.';
  }

  @override
  String get likeListingCta => 'Like listing';

  @override
  String get likesChatTitle => 'Inbox';

  @override
  String get likesTabLabel => 'Likes You';

  @override
  String get likedTabLabel => 'You Liked';

  @override
  String get chatsTabLabel => 'Chats';

  @override
  String get likesIncomingLabel => 'You matched. Start the conversation.';

  @override
  String get emptyLikes => 'No new likes yet.';

  @override
  String get chatsTitle => 'Chats';

  @override
  String get emptyChats => 'No conversations yet.';

  @override
  String get chatReady => 'Your chat is ready when you are.';

  @override
  String get messageHint => 'Type a message...';

  @override
  String get sendCta => 'Send';

  @override
  String get messageAttachment => 'Attachment';

  @override
  String get openConversationCta => 'Open conversation';

  @override
  String get todayLabel => 'Today';

  @override
  String get safetyFirstTitle => 'Safety first';

  @override
  String get safetyFirstSubtitle => 'Visit the room before paying.';

  @override
  String get scheduleTitle => 'Schedule';

  @override
  String get scheduleSubtitle =>
      'Track your flat visits and meetups in one place.';

  @override
  String get visitsTitle => 'Visits';

  @override
  String get emptyVisits => 'No visits scheduled yet.';

  @override
  String get visitRequested => 'Visit request sent.';

  @override
  String get flatmateMeetLabel => 'Flatmate meet';

  @override
  String get propertyTourLabel => 'Property tour';

  @override
  String get scheduleVisitCta => 'Schedule visit';

  @override
  String get profilePageTitle => 'Me';

  @override
  String get profileTitle => 'Profile & Settings';

  @override
  String profileStrengthTitle(int percent) {
    return 'Profile strength: $percent%';
  }

  @override
  String get profileStrengthSubtitle =>
      'Complete 2 steps to get 3x more responses';

  @override
  String get completeProfileCta => 'Complete profile';

  @override
  String get discoverySectionLabel => 'Discovery';

  @override
  String get trustSectionLabel => 'Trust';

  @override
  String get accountSectionLabel => 'Account';

  @override
  String get profileFallbackName => 'Your Flatmates profile';

  @override
  String get profileStatListings => 'Listings';

  @override
  String get profileStatChats => 'Chats';

  @override
  String get profileStatUnread => 'Unread';

  @override
  String get profileMenuVisits => 'My Schedule';

  @override
  String get profileMenuLikesChat => 'Matches & Chat';

  @override
  String get profileMenuPostListing => 'Post Listing';

  @override
  String get profileMenuShortlisted => 'Shortlisted';

  @override
  String get profileMenuChats => 'My Chats';

  @override
  String get profileMenuDocuments => 'Documents';

  @override
  String get editProfileCta => 'Edit profile';

  @override
  String get themeModeTitle => 'Theme mode';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get paletteTitle => 'Palette';

  @override
  String get paletteInkOnPaper => 'Ink on Paper';

  @override
  String get paletteElectricIndigo => 'Paper Blue';

  @override
  String get paletteEmberCoral => 'Warm Clay';

  @override
  String get paletteMonsoonTeal => 'Monsoon Teal';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHindi => 'Hindi';

  @override
  String get logoutCta => 'Logout';

  @override
  String get modeTitle => 'Mode';

  @override
  String get modeRoomPoster => 'Has a room';

  @override
  String get modeSeeker => 'Looking for a room';

  @override
  String get modeCoHunter => 'Looking together';

  @override
  String get modeOpenToBoth => 'Looking for room + flatmate';

  @override
  String get cityLabel => 'City';

  @override
  String get localityLabel => 'Locality';

  @override
  String get subLocalityLabel => 'Sub-locality';

  @override
  String get budgetMinLabel => 'Budget min';

  @override
  String get budgetMaxLabel => 'Budget max';

  @override
  String get budgetMinMaxError => 'Budget minimum cannot exceed maximum';

  @override
  String get workStyleTitle => 'Work style';

  @override
  String get bioLabel => 'Bio';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get listingTitleLabel => 'Listing title';

  @override
  String get monthlyRentInputLabel => 'Monthly rent';

  @override
  String get securityDepositLabel => 'Security deposit';

  @override
  String get maintenanceLabel => 'Maintenance';

  @override
  String get areaSqftLabel => 'Area (sq.ft)';

  @override
  String get bedroomsLabel => 'Bedrooms';

  @override
  String get bathroomsLabel => 'Bathrooms';

  @override
  String get genderPreferenceLabel => 'Preferred gender';

  @override
  String get genderAny => 'Any';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get visitStatusRequested => 'Requested';

  @override
  String get visitStatusScheduled => 'Scheduled';

  @override
  String get visitStatusConfirmed => 'Confirmed';

  @override
  String get visitStatusCompleted => 'Completed';

  @override
  String get visitStatusCancelled => 'Cancelled';

  @override
  String get sharingTypeLabel => 'Room type';

  @override
  String get sharingPrivateRoom => 'Private room';

  @override
  String get sharingSharedRoom => 'Shared room';

  @override
  String get featuresLabel => 'Features';

  @override
  String get featuresHint => 'Example: furnished, wifi, balcony';

  @override
  String get featureFurnished => 'Furnished';

  @override
  String get featureSemiFurnished => 'Semi-furnished';

  @override
  String get featureWifi => 'Wi-Fi';

  @override
  String get featureBalcony => 'Balcony';

  @override
  String get featureAttachedBathroom => 'Attached bathroom';

  @override
  String get featureParking => 'Parking';

  @override
  String get featureAc => 'AC';

  @override
  String get featureWashingMachine => 'Washing machine';

  @override
  String get mainImageUrlLabel => 'Main image URL';

  @override
  String get availableFromLabel => 'Available from';

  @override
  String get availableFromUnset => 'Select move-in availability';

  @override
  String get selectDateCta => 'Select date';

  @override
  String get postListingTitle => 'Post your space';

  @override
  String get postListingCta => 'List your space in minutes';

  @override
  String get postListingSubtitle =>
      'Create a real flatmate listing using the existing 360 Ghar inventory backend.';

  @override
  String get postListingBasics => 'Basics';

  @override
  String get postListingPricing => 'Pricing';

  @override
  String get postListingDetails => 'Details';

  @override
  String get publishListingCta => 'Publish listing';

  @override
  String get postingInProgress => 'Publishing...';

  @override
  String get postListingSuccess => 'Listing created successfully.';

  @override
  String get ownerFallbackLabel => 'Listing owner';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsProfileSection => 'Profile';

  @override
  String get settingsAppearanceSection => 'Appearance';

  @override
  String get settingsSessionSection => 'Session';

  @override
  String get navHome => 'Home';

  @override
  String get navSwipe => 'Swipe';

  @override
  String get navLikesChat => 'Inbox';

  @override
  String get navSchedule => 'Schedule';

  @override
  String get navPost => 'Post';

  @override
  String get navExplore => 'Search';

  @override
  String get navProfile => 'Me';

  @override
  String get navVisits => 'Visits';

  @override
  String get onboardingGetStarted => 'Get Started';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingComplete => 'Complete';

  @override
  String get onboardingHeadline1 => 'Find the right flat. The right flatmates.';

  @override
  String get onboardingSubheadline1 =>
      'Verified homes. Compatible flatmates. Better living, together.';

  @override
  String get onboardingHeadline2 => 'Your lifestyle matters.';

  @override
  String get onboardingSubheadline2 =>
      'We match you with flatmates who share your vibe and values.';

  @override
  String get onboardingHeadline3 => '360 Flatmates finds both.';

  @override
  String get onboardingSubheadline3 =>
      'The flat, the flatmate, and the perfect match.';

  @override
  String get onboardingHeadline4 => 'Your flatmate journey starts here.';

  @override
  String get onboardingSubheadline4 =>
      'Sign up in under 4 minutes and start matching.';

  @override
  String get onboardingSubmitting => 'Setting up your profile...';

  @override
  String get modeSelectionTitle => 'I am looking to';

  @override
  String get modeSelectionSubtitle =>
      'Select the option that best describes you';

  @override
  String get modeRoomPosterDesc =>
      'I want to list my flat or find a flatmate to fill a spare room.';

  @override
  String get modeSeekerDesc =>
      'I\'m looking for a flatmate to search for a place together';

  @override
  String get modeCoHunterDesc =>
      'I want to find a place or a flatmate to stay with.';

  @override
  String get modeOpenToBothDesc =>
      'I\'ll move into an existing flat or team up to find a new one.';

  @override
  String get modeContinue => 'Continue';

  @override
  String get basicInfoTitle => 'Tell us about yourself';

  @override
  String get basicInfoSubtitle =>
      'This helps us find the right flatmates for you.';

  @override
  String get ageLabel => 'Age';

  @override
  String get ageHelperText => 'You must be 18 or older';

  @override
  String get professionLabel => 'Profession / Job title';

  @override
  String get profilePhotoTitle => 'Add your photos';

  @override
  String get profilePhotoSubtitle =>
      'A great photo helps you get more matches.';

  @override
  String get profilePhotoNudge =>
      'Profiles with 3+ photos get 4x more matches!';

  @override
  String get profilePhotoMinimumRequired =>
      'Add at least one photo to continue.';

  @override
  String get addPhotoCta => 'Add photo';

  @override
  String quizProgress(int answered, int total) {
    return '$answered of $total answered';
  }

  @override
  String get quizSleepSchedule => 'What\'s your sleep schedule?';

  @override
  String get quizEarlyBird => 'Early bird (before 10pm)';

  @override
  String get quizFlexible => 'Flexible';

  @override
  String get quizNightOwl => 'Night owl (after midnight)';

  @override
  String get quizCleanliness => 'How clean do you keep things?';

  @override
  String get quizCleanMinimal => 'Minimal — lived-in is fine';

  @override
  String get quizCleanTidy => 'Tidy — things in their place';

  @override
  String get quizCleanSpotless => 'Spotless — everything pristine';

  @override
  String get quizFoodHabits => 'What are your food habits?';

  @override
  String get quizVegetarian => 'Vegetarian';

  @override
  String get quizVegan => 'Vegan';

  @override
  String get quizNonVegetarian => 'Non-vegetarian';

  @override
  String get quizNoFoodPref => 'No preference';

  @override
  String get quizSmokingDrinking => 'Smoking & drinking preferences?';

  @override
  String get quizNeither => 'Neither';

  @override
  String get quizSmokeOutside => 'Smoke outside only';

  @override
  String get quizDrinkOccasionally => 'Drink occasionally';

  @override
  String get quizBothFine => 'Both are fine';

  @override
  String get quizGuestsPolicy => 'How do you feel about guests?';

  @override
  String get quizNoGuests => 'No overnight guests';

  @override
  String get quizOccasionalGuests => 'Occasional guests are ok';

  @override
  String get quizOpenHouse => 'Open house — always welcome';

  @override
  String get quizParties => 'How about parties at home?';

  @override
  String get quizPartiesNever => 'Never';

  @override
  String get quizPartiesWeekends => 'Occasional weekends';

  @override
  String get quizPartyFriendly => 'Party-friendly';

  @override
  String get quizWorkStyle => 'What\'s your work style?';

  @override
  String get quizWfh => 'Work from home mostly';

  @override
  String get quizOffice => 'Office mostly';

  @override
  String get quizHybrid => 'Hybrid — mix of both';

  @override
  String get quizPets => 'How do you feel about pets?';

  @override
  String get quizNoPets => 'No pets';

  @override
  String get quizHavePets => 'I have pets';

  @override
  String get quizPetFriendly => 'Pet-friendly (no own pets)';

  @override
  String get budgetTimelineTitle => 'Budget & move-in timeline';

  @override
  String get budgetTimelineSubtitle =>
      'Set your budget range and when you\'re looking to move.';

  @override
  String get monthlyBudgetLabel => 'Monthly budget';

  @override
  String get moveInTimelineLabel => 'Move-in timeline';

  @override
  String get timelineImmediate => 'Immediate';

  @override
  String get timelineThisMonth => 'This month';

  @override
  String get timelineNextMonth => 'Next month';

  @override
  String get timelineFlexible => 'Flexible';

  @override
  String get nonNegotiablesTitle => 'Your deal-breakers';

  @override
  String get nonNegotiablesSubtitle =>
      'Pick up to 3 things that are non-negotiable for you.';

  @override
  String get nonNegotiablesLimit => 'Select up to 3';

  @override
  String get nonNegVegOnly => 'Vegetarian flatmates only';

  @override
  String get nonNegVeganOnly => 'Vegan flatmates only';

  @override
  String get nonNegNoSmoking => 'Non-smoker only';

  @override
  String get nonNegNoDrinking => 'No alcohol at home';

  @override
  String get nonNegNoGuests => 'No overnight guests';

  @override
  String get nonNegNoPets => 'No pets';

  @override
  String get nonNegFemaleOnly => 'Female flatmates only';

  @override
  String get nonNegMaleOnly => 'Male flatmates only';

  @override
  String get nonNegNoParties => 'No parties at home';

  @override
  String get nonNegMinTidy => 'Minimum tidy standard';

  @override
  String get lifestyleQuizTitle => 'Lifestyle preferences';

  @override
  String get emptySwipeDeck =>
      'No more profiles to show right now. Check back later!';

  @override
  String swipeDeckRemaining(int count) {
    return '$count remaining';
  }

  @override
  String get tapToSeeMore => 'View full profile';

  @override
  String get whyThisMatchWorks => 'WHY THIS MATCH WORKS';

  @override
  String get tapToCollapse => 'Tap to collapse';

  @override
  String get aboutMeSection => 'About me';

  @override
  String get noBioYet => 'No bio yet.';

  @override
  String get compatibilityBreakdown => 'Compatibility breakdown';

  @override
  String get budgetLabel => 'Budget';

  @override
  String get blockConfirmTitle => 'Block this person?';

  @override
  String get blockConfirmMessage =>
      'They won\'t be able to see your profile or contact you.';

  @override
  String get blockCta => 'Block';

  @override
  String get userBlocked => 'User has been blocked.';

  @override
  String get reportTitle => 'Report this person';

  @override
  String get reportFakeProfile => 'Fake profile';

  @override
  String get reportSpam => 'Spam';

  @override
  String get reportInappropriate => 'Inappropriate content';

  @override
  String get reportUncomfortable => 'Uncomfortable interaction';

  @override
  String get reportOther => 'Other';

  @override
  String get reportCta => 'Report';

  @override
  String get reportSubmitted => 'Report submitted. We\'ll review it shortly.';

  @override
  String get unmatchConfirmTitle => 'Unmatch?';

  @override
  String get unmatchConfirmMessage =>
      'This will remove your match and end the conversation.';

  @override
  String get unmatchCta => 'Unmatch';

  @override
  String get icebreakerTitle => 'Break the ice';

  @override
  String get backCta => 'Back';

  @override
  String get listingBuilderTitle => 'Post your space';

  @override
  String get listingStepLocation => 'Property location';

  @override
  String get listingStepSociety => 'The society';

  @override
  String get listingStepRoom => 'The room';

  @override
  String get listingStepFlat => 'The flat';

  @override
  String get listingStepCosts => 'Costs';

  @override
  String get listingStepAbout => 'About you & preferred flatmate';

  @override
  String get societyBuildingLabel => 'Society / Building name';

  @override
  String get fullAddressLabel => 'Full address';

  @override
  String get societyTypeLabel => 'Society type';

  @override
  String get societyTypeGated => 'Gated';

  @override
  String get societyTypeIndependent => 'Independent';

  @override
  String get societyTypeCoLiving => 'Co-living';

  @override
  String get societyTypePg => 'PG';

  @override
  String get societyAmenitiesLabel => 'Society amenities';

  @override
  String get societyVibeLabel => 'Society vibe';

  @override
  String get amenityPool => 'Pool';

  @override
  String get amenityGym => 'Gym';

  @override
  String get amenityClubhouse => 'Clubhouse';

  @override
  String get amenitySports => 'Sports';

  @override
  String get amenityParking => 'Parking';

  @override
  String get amenityPowerBackup => 'Power backup';

  @override
  String get amenityWaterBackup => 'Water backup';

  @override
  String get amenitySecurity => 'Security';

  @override
  String get amenityLift => 'Lift';

  @override
  String get amenityCctv => 'CCTV';

  @override
  String get amenityVisitorEntry => 'Visitor entry';

  @override
  String get amenityGarden => 'Garden';

  @override
  String get vibeBachelorFriendly => 'Bachelor-friendly';

  @override
  String get vibeQuiet => 'Quiet & Focused';

  @override
  String get vibeActiveCommunity => 'Active community';

  @override
  String get vibeFamilyDominant => 'Family-dominant';

  @override
  String get vibePetFriendly => 'Pet-friendly';

  @override
  String get vibeVisitorFriendly => 'Visitor-friendly';

  @override
  String get roomTypeLabel => 'Room type';

  @override
  String get roomTypeMasterBedroom => 'Master bedroom';

  @override
  String get furnishingLabel => 'Room furnishing';

  @override
  String get furnishingBed => 'Bed';

  @override
  String get furnishingWardrobe => 'Wardrobe';

  @override
  String get furnishingAc => 'AC';

  @override
  String get furnishingGeyser => 'Geyser';

  @override
  String get furnishingStudyTable => 'Study table';

  @override
  String get furnishingCurtains => 'Curtains';

  @override
  String get roomFeaturesLabel => 'Room features';

  @override
  String get roomFeatureBalcony => 'Private balcony';

  @override
  String get roomFeatureSunlight => 'Window with sunlight';

  @override
  String get roomFeatureStorage => 'Storage space';

  @override
  String get roomPhotosLabel => 'Room photos';

  @override
  String get minPhotosRequired => 'Min 2 photos required';

  @override
  String get flatConfigLabel => 'Flat configuration';

  @override
  String get floorLabel => 'Floor';

  @override
  String get totalFloorsLabel => 'Total floors';

  @override
  String get flatAmenitiesLabel => 'Flat amenities';

  @override
  String get amenityRefrigerator => 'Refrigerator';

  @override
  String get amenityMicrowave => 'Microwave';

  @override
  String get amenityTv => 'TV';

  @override
  String get amenityDiningTable => 'Dining table';

  @override
  String get amenitySofa => 'Sofa';

  @override
  String get amenityKitchenEquipped => 'Kitchen equipped';

  @override
  String get electricityLabel => 'Electricity';

  @override
  String get includedLabel => 'Included';

  @override
  String get separateLabel => 'Separate';

  @override
  String get electricityEstLabel => 'Electricity (est. monthly)';

  @override
  String get cookCostLabel => 'Cook cost / month';

  @override
  String get maidCostLabel => 'Maid cost / month';

  @override
  String get setupCostLabel => 'One-time setup cost';

  @override
  String totalMonthlyOutflow(String amount) {
    return 'Your estimated monthly cost: $amount';
  }

  @override
  String get typicalDayLabel => 'Describe your typical day';

  @override
  String get typicalDayHint =>
      'I wake up at 7, work from home till 6, cook dinner...';

  @override
  String get ageRangeLabel => 'Preferred flatmate age range';

  @override
  String homeNewInCity(String city) {
    return 'New in $city';
  }

  @override
  String get homeMovingSoon => 'Moving soon';

  @override
  String get vibeAll => 'All';

  @override
  String get vibeQuietFocused => 'Quiet & Focused';

  @override
  String get vibeSocialLively => 'Social & Lively';

  @override
  String get vibeWorkingProf => 'Working Professionals';

  @override
  String get vibeStudents => 'Students';

  @override
  String get vibePetHousehold => 'Pet Household';

  @override
  String cityCounter(int count, String city) {
    return '$count people looking in $city right now';
  }

  @override
  String get waitlistTitle => 'Not enough people yet';

  @override
  String waitlistSubtitle(String city) {
    return 'We\'ll notify you when more flatmates join in $city.';
  }

  @override
  String get waitlistNotifyCta => 'Notify me';

  @override
  String get shareListingCta => 'Share listing';

  @override
  String get listingUnderReview => 'Listing under review';

  @override
  String get listingLive => 'Live';

  @override
  String get listingPaused => 'Paused';

  @override
  String get listingExpired => 'Expired';

  @override
  String get manageListingTitle => 'Manage listing';

  @override
  String get boostListingCta => 'Boost listing';

  @override
  String get pauseListingCta => 'Pause';

  @override
  String get editListingCta => 'Edit';

  @override
  String get shareCta => 'Share';

  @override
  String get verifiedFilterLabel => 'Verified';

  @override
  String get qnaNudgeTitle => 'Break the ice first?';

  @override
  String get qnaNudgeSubtitle =>
      'Answer 3 quick questions to start the conversation.';

  @override
  String get qnaQuestion1 =>
      'What does your ideal flatmate situation look like?';

  @override
  String get qnaQuestion1Hint =>
      'e.g. Someone quiet who respects personal space...';

  @override
  String get qnaQuestion2 => 'How social are you at home on a typical weekday?';

  @override
  String get qnaQuestion3 => 'One thing you absolutely need in a flatmate?';

  @override
  String get qnaQuestion3Hint => 'e.g. Cleanliness, punctuality, honesty...';

  @override
  String get qnaAnswerCta => 'Answer questions';

  @override
  String get qnaSkipCta => 'Skip for now';

  @override
  String get qnaBothAnsweredBanner => 'Both answered';

  @override
  String qnaPeerAnsweredBanner(String peerName) {
    return '$peerName answered';
  }

  @override
  String get qnaYouAnsweredBanner => 'Your answers are saved';

  @override
  String get qnaPeerAnsweredPrompt =>
      'Share yours to unlock stronger context before you meet.';

  @override
  String qnaTheirAnswers(String peerName) {
    return '$peerName\'s answers';
  }

  @override
  String get qnaYourAnswers => 'Your answers';

  @override
  String get waitlistConfirmed => 'You\'re on the list! We\'ll notify you.';

  @override
  String get waitlistInviteFriends => 'Invite Friends';

  @override
  String waitlistShareMessage(String city, String url) {
    return '360 FlatMates is opening in $city. Join the waitlist and help bring more flatmates here:\n$url';
  }

  @override
  String get yourNumberIsPrivate => 'Your number is kept private';

  @override
  String get privacyTitle => 'Privacy';

  @override
  String get hideLastNameLabel => 'Hide last name on public profile';

  @override
  String get hideExactLocationLabel => 'Hide exact location on listings';

  @override
  String get visitConfirmTitle => 'Confirm this visit?';

  @override
  String get visitConfirmCta => 'Confirm visit';

  @override
  String get visitRescheduleCta => 'Suggest another time';

  @override
  String get visitCancelCta => 'Cancel visit';

  @override
  String get visitCancelConfirm =>
      'Are you sure you want to cancel this visit?';

  @override
  String get visitConfirmed => 'Visit confirmed';

  @override
  String get visitCancelled => 'Visit cancelled.';

  @override
  String get videoTourLabel => 'Video tour (optional)';

  @override
  String get videoTourHint => '15-30 second vertical video, max 50MB';

  @override
  String get addVideoCta => 'Add video tour';

  @override
  String get videoTourAdded => 'Video tour added';

  @override
  String get videoTooLarge => 'Video must be under 50MB';

  @override
  String get videoTooLong => 'Video must be under 30 seconds';

  @override
  String get videoTooShort => 'Video must be at least 15 seconds';

  @override
  String get tapToUnmute => 'Tap to unmute';

  @override
  String get soundOn => 'Sound on';

  @override
  String superLikeCapLabel(int count) {
    return '$count Super Likes left';
  }

  @override
  String swipeCounterLabel(int count) {
    return '$count swipes left today';
  }

  @override
  String get passActionLabel => 'Pass';

  @override
  String get superLikeActionLabel => 'Star Match';

  @override
  String get likeActionLabel => 'Like';

  @override
  String get photoPendingLabel => 'Photo pending';

  @override
  String get readReceiptSent => 'Sent';

  @override
  String get readReceiptDelivered => 'Delivered';

  @override
  String get readReceiptRead => 'Read';

  @override
  String get chatPollingInfo => 'Messages refresh automatically';

  @override
  String get flatDetailsTitle => 'Flat details';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationEmpty => 'No notifications yet.';

  @override
  String get helpSafetyTitle => 'Help & Safety';

  @override
  String get safetyTips => 'Safety tips';

  @override
  String get reportProblem => 'Report a problem';

  @override
  String get contactSupport => 'Contact support';

  @override
  String get communityGuidelines => 'Community guidelines';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get termsOfService => 'Terms of service';

  @override
  String get listingUnderReviewTitle => 'Listing under review';

  @override
  String get underReview => 'Under Review';

  @override
  String get reviewTimeline => 'Review timeline';

  @override
  String get goToHomeFeed => 'Go to Home Feed';

  @override
  String get viewListing => 'View Listing';

  @override
  String get editResubmit => 'Edit & Resubmit';

  @override
  String get reportListing => 'Report listing';

  @override
  String get reportListingTitle => 'Report this listing';

  @override
  String get reportListingReason => 'Why are you reporting this listing?';

  @override
  String get reportListingSubmitted =>
      'Thank you. We will review this listing.';

  @override
  String get reportReasonInappropriate => 'Inappropriate content';

  @override
  String get reportReasonScam => 'Suspected scam or fraud';

  @override
  String get reportReasonOutdated => 'Listing is outdated or unavailable';

  @override
  String get reportReasonOther => 'Other';

  @override
  String get compatibilityScore => 'Compatibility score';

  @override
  String get aboutMe => 'About me';

  @override
  String get flatDetails => 'Flat details';

  @override
  String get costsBreakdown => 'Costs breakdown';

  @override
  String get moveInDate => 'Move-in date';

  @override
  String get newMatch => 'New match';

  @override
  String get newMessage => 'New message';

  @override
  String get listingApproved => 'Listing approved';

  @override
  String get visitScheduled => 'Visit scheduled';

  @override
  String get faqTitle => 'FAQ';

  @override
  String get whatHappensNext => 'What happens next';

  @override
  String get aiPreScreen => 'AI pre-screen';

  @override
  String get manualReview => 'Manual review';

  @override
  String get youWillBeNotified => 'You\'ll be notified';

  @override
  String get notificationChannelName => 'Messages & Matches';

  @override
  String get notificationChannelDescription =>
      'Notifications for new messages, matches, and visits';

  @override
  String get reviewTitle => 'Review your listing';

  @override
  String get reviewLocation => 'Location';

  @override
  String get reviewSociety => 'Society';

  @override
  String get reviewRoom => 'Room';

  @override
  String get reviewFlat => 'Flat';

  @override
  String get reviewCosts => 'Costs';

  @override
  String get reviewAbout => 'About you & preferred flatmate';

  @override
  String get editStep => 'Edit';

  @override
  String get filterApplied => 'Filters applied';

  @override
  String get noListingsMatchFilters =>
      'No listings match your filters. Try adjusting them.';

  @override
  String get listingRejected => 'Rejected';

  @override
  String get reviewSupportText => 'We\'ll review your listing within 24 hours';

  @override
  String get reviewStep3Desc =>
      'You\'ll receive a notification once your listing is approved and live.';

  @override
  String get resendOtpCta => 'Resend OTP';

  @override
  String resendOtpCountdown(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get otpAutoReadHint => 'We\'ll auto-detect the OTP from your SMS.';

  @override
  String get societySectionTitle => 'The Society';

  @override
  String get roomSectionTitle => 'The Room';

  @override
  String get flatAndFlatmatesSectionTitle => 'The Flat & Flatmates';

  @override
  String get costsBreakdownSectionTitle => 'Costs Breakdown';

  @override
  String get monthlyRentRow => 'Monthly rent';

  @override
  String get securityDepositRow => 'Security deposit';

  @override
  String get maintenanceRow => 'Maintenance';

  @override
  String get estimatedTotalRow => 'Estimated total / month';

  @override
  String get existingFlatmatesLabel => 'Existing flatmates';

  @override
  String get notAvailable => 'Not specified';

  @override
  String get perPersonCostLabel => 'Per person (approx.)';

  @override
  String get changePasswordLabel => 'Change Password';

  @override
  String get privacySecurityLabel => 'Privacy & Security';

  @override
  String get preferencesLabel => 'Preferences';

  @override
  String get notificationSettingsLabel => 'Notification Settings';

  @override
  String get notificationSettingsTitle => 'Notification Preferences';

  @override
  String get notificationSettingsSubtitle =>
      'Choose which notifications you want to receive';

  @override
  String get notifNewMessages => 'New Messages';

  @override
  String get notifNewMessagesDesc =>
      'Get notified when you receive a new message';

  @override
  String get notifVisitReminders => 'Visit Reminders';

  @override
  String get notifVisitRemindersDesc =>
      'Reminders for upcoming property visits';

  @override
  String get notifNewMatches => 'New Matches';

  @override
  String get notifNewMatchesDesc =>
      'Get notified when someone likes your profile';

  @override
  String get notifListingUpdates => 'Listing Updates';

  @override
  String get notifListingUpdatesDesc =>
      'Updates about your listing views and interest';

  @override
  String get notifPromotions => 'Promotions & Tips';

  @override
  String get notifPromotionsDesc => 'Offers, tips, and product updates';

  @override
  String get notifEnableAll => 'Enable All';

  @override
  String get notifDisableAll => 'Disable All';

  @override
  String get blockedUsersLabel => 'Blocked Users';

  @override
  String get noBlockedUsers => 'You haven\'t blocked anyone yet.';

  @override
  String get unblockCta => 'Unblock';

  @override
  String get userUnblocked => 'User has been unblocked.';

  @override
  String get unblockFailed => 'Could not unblock this user.';

  @override
  String get newPasswordLabel => 'New password';

  @override
  String get confirmPasswordLabel => 'Confirm password';

  @override
  String get updatePasswordCta => 'Update password';

  @override
  String get passwordUpdated => 'Password updated.';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match.';

  @override
  String get passwordMinLength => 'Password must be at least 8 characters.';

  @override
  String get aboutLabel => 'About';

  @override
  String get termsAndConditionsLabel => 'Terms & Conditions';

  @override
  String get termsAgreementPrefix => 'I agree to the ';

  @override
  String get termsAgreementConjunction => ' and ';

  @override
  String get searchHelpPlaceholder => 'Search for help';

  @override
  String get faqSubtitle => 'Find answers to common questions';

  @override
  String get popularTopicsLabel => 'Popular Topics';

  @override
  String get popularTopicsSubtitle => 'Explore trending help topics';

  @override
  String get bookingAgreementsLabel => 'Booking & Agreements';

  @override
  String get bookingAgreementsSubtitle => 'Bookings, agreements & policies';

  @override
  String get accountProfileLabel => 'Account & Profile';

  @override
  String get accountProfileSubtitle => 'Manage your account and profile';

  @override
  String get contactSupportSubtitle => 'Get in touch with our support team';

  @override
  String get chatWithUsCta => 'Chat with Us';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get replyTimeNote => 'We usually reply in a few minutes';

  @override
  String get helpFaqIntro =>
      'Quick answers for the most common 360 FlatMates questions.';

  @override
  String get helpFaqStartTitle => 'How do I start finding a flatmate?';

  @override
  String get helpFaqStartBody =>
      'Complete onboarding, set your city and budget, then use Discover, Map, Swipe, and Chats to connect with relevant flatmates or listings.';

  @override
  String get helpFaqSafetyTitle => 'How should I stay safe before meeting?';

  @override
  String get helpFaqSafetyBody =>
      'Keep early conversations in the app, meet in a familiar or shared place, verify rent and deposit details, and do not send sensitive documents before you trust the other person.';

  @override
  String get helpFaqReportTitle => 'How do I report or block someone?';

  @override
  String get helpFaqReportBody =>
      'Open the chat with that person and use the report or block actions. Reports are sent to the 360 FlatMates team for review.';

  @override
  String get helpFaqListingTitle => 'How do I list my flat?';

  @override
  String get helpFaqListingBody =>
      'Use Post Listing from your profile, complete the required flat details, and submit it for review before it appears to other users.';

  @override
  String get helpPopularIntro =>
      'The most useful safety and support topics for active users.';

  @override
  String get helpPopularMeetingsTitle => 'Safer first meetings';

  @override
  String get helpPopularMeetingsBody =>
      'Meet during the day when possible, tell someone you trust where you are going, and avoid cash handovers until terms are clear.';

  @override
  String get helpPopularVerifiedTitle => 'Profile trust basics';

  @override
  String get helpPopularVerifiedBody =>
      'Use your real name, add a clear profile photo, and keep lifestyle preferences accurate so matches can evaluate compatibility.';

  @override
  String get helpPopularVisitsTitle => 'Chats and visits';

  @override
  String get helpPopularVisitsBody =>
      'Use in-app chats to confirm availability, schedule visits from listing or conversation screens, and keep important decisions written down.';

  @override
  String get helpBookingsIntro =>
      'Guidance for visits, agreements, and listing review. 360 FlatMates helps you connect; final rental terms stay between the people involved.';

  @override
  String get helpBookingsDecisionTitle => 'Before confirming a move';

  @override
  String get helpBookingsDecisionBody =>
      'Confirm monthly rent, deposit, maintenance, move-in date, notice period, house rules, and who will be named on the agreement.';

  @override
  String get helpBookingsAgreementsTitle => 'Agreements and documents';

  @override
  String get helpBookingsAgreementsBody =>
      'Keep written copies of agreed terms and verify IDs or ownership details through trusted channels before signing or paying outside the app.';

  @override
  String get helpBookingsListingReviewTitle => 'Listing review';

  @override
  String get helpBookingsListingReviewBody =>
      'Submitted listings may be reviewed for quality and safety before going live. You can edit and resubmit if details change.';

  @override
  String get helpAccountIntro =>
      'Manage profile, password, privacy, and blocked users from one safe place.';

  @override
  String get helpAccountEditTitle => 'Edit profile details';

  @override
  String get helpAccountEditBody =>
      'Keep your photo, location, budget, move-in timeline, and lifestyle answers current so recommendations stay relevant.';

  @override
  String get helpAccountPrivacyTitle => 'Privacy controls';

  @override
  String get helpAccountPrivacyBody =>
      'Use Settings to manage theme, language, and privacy preferences such as hiding your last name or exact location.';

  @override
  String get helpAccountBlockedTitle => 'Blocked users';

  @override
  String get helpAccountBlockedBody =>
      'Blocked people cannot contact you through the app. You can review and unblock them from Blocked Users.';

  @override
  String get helpContactIntro =>
      'Contact support when something looks wrong, unsafe, or stuck.';

  @override
  String get helpContactWhatToSendTitle => 'What to include';

  @override
  String get helpContactWhatToSendBody =>
      'Send your phone number, the listing or conversation involved, screenshots if useful, and a short description of what happened.';

  @override
  String get helpContactUrgentTitle => 'Urgent safety issues';

  @override
  String get helpContactUrgentBody =>
      'If there is immediate danger, contact local emergency services first, then report the issue to support with the details you can safely share.';

  @override
  String get emailSupportCta => 'Email support';

  @override
  String get supportEmailSubject => '360 FlatMates support request';

  @override
  String get supportEmailBody => 'Hi 360 FlatMates Support, I need help with:';

  @override
  String supportEmailFallback(String email) {
    return 'Email us at $email';
  }

  @override
  String get externalLinkUnavailable =>
      'Could not open this link. Please try again.';

  @override
  String get stepLabel => 'Step';

  @override
  String get stepOfLabel => 'of';

  @override
  String get societyBuildingHint => 'e.g., Prestige Lakeside';

  @override
  String get fullAddressHint => 'Enter full address';

  @override
  String get monthlyRentHint => 'Enter monthly rent';

  @override
  String get securityDepositHint => 'Enter deposit amount';

  @override
  String get maintenanceHint => 'Enter maintenance charges';

  @override
  String get electricityEstHint => 'Estimated monthly electricity cost';

  @override
  String get cookCostHint => 'Cook charges per month';

  @override
  String get maidCostHint => 'Maid charges per month';

  @override
  String get setupCostHint => 'One-time setup cost';

  @override
  String get activeListingsLabel => 'Active Listings';

  @override
  String get draftsLabel => 'Drafts';

  @override
  String get expiredLabel => 'Expired';

  @override
  String get listingRejectedMessage => 'Your listing was not approved.';

  @override
  String get reviewSubmittedMessage =>
      'Thank you! Your listing has been submitted for review.';

  @override
  String get reviewListingCta => 'Review Listing';

  @override
  String get etaHighlight => 'We\'ll review your listing within 24 hours';

  @override
  String get step1Text =>
      'Our team reviews your listing for quality and safety.';

  @override
  String get step2Text => 'We\'ll notify you once your listing is live.';

  @override
  String get step3Text => 'Go live and start connecting!';

  @override
  String get yourListingLabel => 'Your listing';

  @override
  String get budgetFilterLabel => 'Budget';

  @override
  String budgetRangeLabel(String min, String max) {
    return '₹$min – ₹$max';
  }

  @override
  String get roomTypeFilterLabel => 'Room Type';

  @override
  String get roomTypeAny => 'Any';

  @override
  String get roomTypePrivate => 'Private';

  @override
  String get roomTypeShared => 'Shared';

  @override
  String get furnishingFilterLabel => 'Furnishing';

  @override
  String get furnishingAny => 'Any';

  @override
  String get furnishingFurnished => 'Furnished';

  @override
  String get furnishingUnfurnished => 'Unfurnished';

  @override
  String get genderFilterLabel => 'Gender';

  @override
  String get genderFilterAny => 'Any';

  @override
  String get genderFilterMale => 'Male';

  @override
  String get genderFilterFemale => 'Female';

  @override
  String get moveInFilterLabel => 'Move-in';

  @override
  String get moveInAnytime => 'Anytime';

  @override
  String get moveInImmediate => 'Immediate';

  @override
  String get moveInThisMonth => 'This Month';

  @override
  String get moveInNextMonth => 'Next Month';

  @override
  String get moreFiltersLabel => 'More Filters';

  @override
  String get petsLabel => 'Pets';

  @override
  String get petsYes => 'Yes';

  @override
  String get petsNo => 'No';

  @override
  String get petsNoPreference => 'No Preference';

  @override
  String get smokingLabel => 'Smoking';

  @override
  String get smokingNo => 'No';

  @override
  String get smokingYes => 'Yes';

  @override
  String get smokingNoPreference => 'No Preference';

  @override
  String get nearbyChipLabel => 'Nearby';

  @override
  String get budgetPlusChipLabel => 'Budget+';

  @override
  String get chatInputHint => 'Type a message...';

  @override
  String get phoneNotAvailable => 'Phone number not available';

  @override
  String get emojiPickerComingSoon => 'Emoji picker coming soon';

  @override
  String get preferencesTitle => 'Preferences';

  @override
  String get preferencesSubtitle =>
      'Tell us what matters to you so we can find the right flatmates and homes.';

  @override
  String get prefGenderLabel => 'Preferred Gender';

  @override
  String get prefFlatmatesLabel => 'Allowed Flatmates';

  @override
  String get prefFoodLabel => 'Food Habits';

  @override
  String get prefPetsLabel => 'Pets';

  @override
  String get prefSmokingLabel => 'Smoking';

  @override
  String get prefMoveInLabel => 'Move-in Timeline';

  @override
  String get prefNoPreference => 'No Preference';

  @override
  String get prefMaleOnly => 'Male Only';

  @override
  String get prefFemaleOnly => 'Female Only';

  @override
  String get prefOther => 'Other';

  @override
  String get prefVeg => 'Veg';

  @override
  String get prefNonVeg => 'Non-Veg';

  @override
  String get prefEggetarian => 'Eggetarian';

  @override
  String get prefYes => 'Yes';

  @override
  String get prefNo => 'No';

  @override
  String get prefNext => 'Next';

  @override
  String get settingsGroupAccount => 'Account';

  @override
  String get settingsGroupApp => 'App';

  @override
  String get settingsGroupLegal => 'Legal';

  @override
  String get qnaShareAnswers => 'Share Answers';

  @override
  String get qnaSkipForNow => 'Skip for now';

  @override
  String get qnaVeryPrivate => 'Very private';

  @override
  String get qnaVerySocial => 'Very social';

  @override
  String get aboutThisFlatSection => 'About this Flat';

  @override
  String get shortlistCta => 'Shortlist';

  @override
  String get contactCta => 'Contact';

  @override
  String get postedOnLabel => 'Posted on';

  @override
  String get verifiedListingLabel => 'Verified listing';

  @override
  String moveInCountdownBadge(int days) {
    return 'Moving in $days days';
  }

  @override
  String get moveInToday => 'Moving in today';

  @override
  String get vibeSocial => 'Social & Lively';

  @override
  String get vibeProfessional => 'Professionals';

  @override
  String get vibeStudent => 'Students';

  @override
  String get vibePet => 'Pet Household';

  @override
  String get addPhotosTitle => 'Add Photos';

  @override
  String get addPhotosTips => 'Tips';

  @override
  String get addPhotosInstruction =>
      'Add clear photos of the room and common areas to get more matches.';

  @override
  String get photoTipNaturalLight =>
      '• Use natural lighting — open curtains before shooting';

  @override
  String get photoTipFullRoom => '• Show the full room from corner to corner';

  @override
  String get photoTipBathroomBalcony =>
      '• Include bathroom and balcony if available';

  @override
  String get photoTipCleanRoom => '• Clean up before taking photos';

  @override
  String get addMorePhotosLabel => 'Add more photos';

  @override
  String waitlistNudgeTitle(String city) {
    return 'Not many flatmates in $city yet';
  }

  @override
  String get waitlistNudgeSubtitle => 'We\'ll notify you when more people join';

  @override
  String get waitlistNotifyMe => 'Notify Me';

  @override
  String cityCounterShort(int count, String city) {
    return '$count looking in $city';
  }

  @override
  String get scheduleVisitTitle => 'Schedule Visit';

  @override
  String get selectTimeSlot => 'Select Time Slot';

  @override
  String get timeSlotMorning => 'Morning';

  @override
  String get timeSlotAfternoon => 'Afternoon';

  @override
  String get timeSlotEvening => 'Evening';

  @override
  String get addNoteOptional => 'Add a Note (Optional)';

  @override
  String visitPrivacyNote(String name) {
    return 'Your visit request will be shared with $name.';
  }

  @override
  String get sendingLabel => 'Sending...';

  @override
  String get sendRequestCta => 'Send Request';

  @override
  String matchedOnDate(String date) {
    return 'Matched on $date';
  }

  @override
  String get locationSelectionTitle => 'Select your preferred location';

  @override
  String get searchLocationPlaceholder => 'Search location';

  @override
  String get useCurrentLocation => 'Use my current location';

  @override
  String get detectingLocation => 'Detecting location...';

  @override
  String get popularCitiesLabel => 'POPULAR CITIES';

  @override
  String get noLocationsAvailable => 'No locations available';

  @override
  String get clusterListingsTitle => 'Listings in this area';

  @override
  String clusterListingsCount(int count) {
    return '$count listings';
  }

  @override
  String get shareToWhatsapp => 'Share to WhatsApp';

  @override
  String get whatsappNotInstalled => 'WhatsApp is not installed';

  @override
  String get scanToOpen => 'Scan to open listing';

  @override
  String get matchItsAMatch => 'Great Match!';

  @override
  String matchLikedEachOther(String peerName) {
    return 'You and $peerName liked each other';
  }

  @override
  String get matchSendMessage => 'Send a message';

  @override
  String get matchKeepSwiping => 'Keep swiping';

  @override
  String get swipeNoMoreProfiles => 'No more profiles';

  @override
  String get swipeCheckBackLater => 'Check back later for new matches';

  @override
  String get swipeLikeLabel => 'LIKE';

  @override
  String get swipeNopeLabel => 'PASS';

  @override
  String get failedToLoadProfiles => 'Failed to load profiles';

  @override
  String get actionFailedRetry => 'Action failed. Please try again.';

  @override
  String get wifiChipLabel => 'WiFi';

  @override
  String get parkingChipLabel => 'Parking';

  @override
  String get liftChipLabel => 'Lift';

  @override
  String get securityChipLabel => '24/7 Security';

  @override
  String get noDescriptionAvailable => 'No description available.';

  @override
  String get flexibleLabel => 'Flexible';

  @override
  String get recentlyLabel => 'Recently';

  @override
  String get safetyCheckedLabel => 'Safety Checked';

  @override
  String get couldNotLoadListing => 'Could not load listing';

  @override
  String get startAConversation => 'Start a conversation';

  @override
  String get sayHelloOrIcebreaker => 'Say hello or use an icebreaker';

  @override
  String get messagesArePrivate => 'Messages are private';

  @override
  String get viewLabel => 'View';

  @override
  String byOwnerLabel(String name) {
    return 'by $name';
  }

  @override
  String get couldNotLoadMessages => 'Could not load messages';

  @override
  String get failedToSendMessage => 'Failed to send message. Please try again.';

  @override
  String get failedToBlockUser => 'Failed to block user. Please try again.';

  @override
  String get failedToReportUser => 'Failed to report user. Please try again.';

  @override
  String get failedToUnmatch => 'Failed to unmatch. Please try again.';

  @override
  String get failedToSendPhoto => 'Failed to send photo. Please try again.';

  @override
  String get couldNotLoadVisits => 'Could not load visits';

  @override
  String get blockedUsersAppearHere => 'People you block will appear here';

  @override
  String get couldNotLoadBlockedUsers => 'Could not load blocked users';

  @override
  String get passwordRuleMinLength => 'At least 8 characters';

  @override
  String get passwordRuleUppercase => '1 uppercase letter';

  @override
  String get passwordRuleNumber => '1 number';

  @override
  String get safetyIsPriority => 'Your safety is our priority';

  @override
  String get supportAvailable247 => 'Support available 24/7';

  @override
  String get notificationsEmptySubtitle =>
      'Notifications about your matches, visits, and listings will appear here';

  @override
  String get couldNotLoadNotifications => 'Could not load notifications';

  @override
  String get yesterdayLabel => 'Yesterday';

  @override
  String get daysAgoLabel => 'days ago';

  @override
  String get notificationNoAction =>
      'No action available for this notification';

  @override
  String get submittedLabel => 'Submitted';

  @override
  String get underReviewStepLabel => 'Under Review';

  @override
  String get liveStepLabel => 'Live';

  @override
  String get pleaseReviewAndResubmit =>
      'Please review the reason below and resubmit.';

  @override
  String get rejectionReasonLabel => 'Rejection reason';

  @override
  String get rejectionDetailText =>
      'The listing did not meet our community guidelines. Please ensure all information is accurate and photos are clear.';

  @override
  String get activeStatus => 'Active';

  @override
  String get draftStatus => 'Draft';

  @override
  String get expiredStatus => 'Expired';

  @override
  String get notificationsTooltip => 'Notifications';

  @override
  String get chatTooltip => 'Chat';

  @override
  String get listingStatsTitle => 'Listing Stats';

  @override
  String get viewsStatLabel => 'Views';

  @override
  String get likesStatLabel => 'Likes';

  @override
  String get matchesStatLabel => 'Matches';

  @override
  String get closeCta => 'Close';

  @override
  String matchCountLabel(int count) {
    return 'Match Count ($count)';
  }

  @override
  String get boostAction => 'Boost';

  @override
  String viewStatsAction(String count) {
    return 'View Stats ($count)';
  }

  @override
  String get reviewAction => 'Review';

  @override
  String get shareAction => 'Share';

  @override
  String get resumeAction => 'Resume';

  @override
  String get expiresToday => 'Expires today';

  @override
  String expiresInDays(int days) {
    return 'Expires in ${days}d';
  }

  @override
  String get failedToUpdateListingStatus => 'Failed to update listing status.';

  @override
  String get noLikesYet => 'No likes yet';

  @override
  String get noLikedYet => 'No liked profiles yet';

  @override
  String get keepSwipingToFindMatches =>
      'Complete your profile to get more visibility.';

  @override
  String get noConversations => 'No chats yet';

  @override
  String get startChatWithMatch =>
      'Like a few profiles to start conversations.';

  @override
  String get matchAction => 'Match';

  @override
  String get waitingForResponse => 'Waiting';

  @override
  String get matchCreateFailed => 'Could not create match. Try again.';

  @override
  String get couldNotLoadConversations => 'Could not load conversations';

  @override
  String get downloadToConnect => 'Download 360 FlatMates to connect';

  @override
  String get scanToConnect => 'Scan to connect';

  @override
  String get findYourFlatmateShare => 'Find your flatmate on 360 FlatMates!';

  @override
  String get checkOutListingShare => 'Check out this listing on 360 FlatMates!';

  @override
  String get passwordUpdateFailed =>
      'Failed to update password. Please try again.';

  @override
  String get visitRequestFailed =>
      'Failed to send visit request. Please try again.';

  @override
  String get visitActionFailed => 'Action failed. Please try again.';

  @override
  String get listingSubmitFailed =>
      'Failed to submit listing. Please try again.';

  @override
  String get listingHelperLocation => 'Accurate location helps people find you';

  @override
  String get listingHelperSociety =>
      'Tell us about the society to attract the right flatmates';

  @override
  String get listingHelperRoom =>
      'Describe the room so flatmates know what to expect';

  @override
  String get listingHelperPhotos => 'Good photos get 3x more responses';

  @override
  String get listingHelperFlat =>
      'Flat details help flatmates decide if it\'s the right fit';

  @override
  String get listingHelperCosts => 'Transparent pricing builds trust';

  @override
  String get listingHelperAbout => 'A good bio helps people know you';

  @override
  String get listingHelperReview =>
      'Almost there! Review everything before going live';

  @override
  String get listingRentRequired => 'Monthly rent is required';

  @override
  String get listingPhotosRequired => 'Add at least 2 photos';

  @override
  String get listingDepositInvalid => 'Enter a valid amount';

  @override
  String get listingMaintenanceInvalid => 'Enter a valid amount';

  @override
  String get listingCostInvalid => 'Enter a valid amount';

  @override
  String listingSummaryLocation(String society, String city) {
    return '$society, $city';
  }

  @override
  String listingSummarySociety(String type) {
    return '$type';
  }

  @override
  String listingSummaryRoom(String roomType, int furnishingCount) {
    return '$roomType • $furnishingCount items';
  }

  @override
  String listingSummaryPhotos(int count, String plural) {
    return '$count photo$plural';
  }

  @override
  String listingSummaryFlat(String config, String floor) {
    return '$config • Floor $floor';
  }

  @override
  String listingSummaryCosts(String rent) {
    return 'Rent: ₹$rent/mo';
  }

  @override
  String listingSummaryAbout(String gender, String ageMin, String ageMax) {
    return '$gender • Ages $ageMin-$ageMax';
  }

  @override
  String get workStyleOffice => 'Office';

  @override
  String get workStyleHybrid => 'Hybrid';

  @override
  String get workStyleWfh => 'WFH';

  @override
  String get phoneVerifiedLabel => 'Phone verified';

  @override
  String get showResultsCta => 'Show Results';

  @override
  String get searchFiltersTitle => 'Search & Filters';

  @override
  String get clearAllFilters => 'Clear all';

  @override
  String get errorNetwork =>
      'No internet connection. Please check your network and try again.';

  @override
  String get errorAuthExpired => 'Session expired. Please sign in again.';

  @override
  String get errorServer => 'Server error. Please try again later.';

  @override
  String get errorPermission =>
      'You do not have permission to perform this action.';

  @override
  String get errorNotFound => 'The requested resource was not found.';

  @override
  String get errorValidation => 'Invalid data. Please check your input.';

  @override
  String get errorRateLimit =>
      'Too many requests. Please wait a moment and try again.';

  @override
  String get errorConflict => 'A conflict occurred. The data may have changed.';

  @override
  String get errorUpload => 'Upload failed. Please try again.';

  @override
  String get errorUnknown => 'Something went wrong. Please try again.';

  @override
  String get icebreakerTellMeRoom => 'Tell me about the room!';

  @override
  String get icebreakerWhatFlatmates => 'What are the flatmates like?';

  @override
  String get icebreakerNegotiateRent => 'Is the rent negotiable?';

  @override
  String get icebreakerSocietyVibe => 'What\'s the society vibe?';

  @override
  String get icebreakerWeekendLook => 'What does a weekend here look like?';

  @override
  String reviewRentAmount(String amount) {
    return 'Rent: ₹$amount/mo';
  }

  @override
  String reviewDepositAmount(String amount) {
    return 'Deposit: ₹$amount';
  }

  @override
  String reviewMaintenanceAmount(String amount) {
    return 'Maintenance: ₹$amount';
  }

  @override
  String reviewGenderAmount(String gender) {
    return 'Gender: $gender';
  }

  @override
  String reviewAgeAmount(String min, String max) {
    return 'Age: $min - $max';
  }

  @override
  String reviewMoveInAmount(String date) {
    return 'Move-in: $date';
  }

  @override
  String reviewPhotosAmount(int count, String plural) {
    return '$count photo$plural';
  }

  @override
  String get invalidListingId => 'Invalid listing ID';

  @override
  String get invalidConversationId => 'Invalid conversation ID';

  @override
  String get youAreOffline => 'You are offline. Check your connection.';

  @override
  String get visitScheduledNotificationFailed =>
      'Visit scheduled! Could not send notification.';

  @override
  String get bootstrapErrorRetry => 'Something went wrong. Tap to retry.';

  @override
  String get boostListingTitle => 'Boost Listing';

  @override
  String get boostListingSubtitle =>
      'Your listing will be shown to more people for the next 24 hours.';

  @override
  String get boostNowCta => 'Boost Now';

  @override
  String get listingBoosted => 'Listing boosted for 24 hours!';

  @override
  String get pausedStatus => 'Paused';

  @override
  String get renewAction => 'Renew';

  @override
  String get refreshProfilesCta => 'Refresh Profiles';

  @override
  String get swipeEmptyNoProfilesTitle => 'No profiles available right now';

  @override
  String get swipeEmptyNoProfilesSubtitle =>
      'We\'re finding new matches for you! Check back soon.';

  @override
  String get swipeEmptyAllFilteredTitle => 'No profiles match your preferences';

  @override
  String get swipeEmptyAllFilteredSubtitle =>
      'Try adjusting your non-negotiables to see more profiles.';

  @override
  String get swipeEmptyEndOfDeckTitle => 'You\'ve seen everyone for now';

  @override
  String get swipeEmptyEndOfDeckSubtitle =>
      'We\'re finding new matches for you! Check back later.';

  @override
  String get locationServicesDisabled =>
      'Location services are turned off. Please enable GPS/Location in your device settings.';

  @override
  String get locationServicesDisabledAction => 'Open Settings';

  @override
  String get locationPermissionDeniedForever =>
      'Location permission was denied. Please enable it in app settings.';

  @override
  String get locationOpenAppSettings => 'Open App Settings';

  @override
  String get locationNoMatchFound =>
      'Could not find a matching city nearby. Please select manually.';

  @override
  String get searchCityOrAreaHint => 'Search city or area';

  @override
  String get suggestionsLabel => 'SUGGESTIONS';

  @override
  String get locationPickerTitle => 'Choose Location';

  @override
  String get locationPickerSearchHint => 'Search area, locality, city...';

  @override
  String get matchingCitiesLabel => 'MATCHING CITIES';

  @override
  String get noCitiesFound => 'No cities found';

  @override
  String get searchRadiusLabel => 'Search Radius';

  @override
  String distanceKmLabel(int distance) {
    return '$distance km';
  }

  @override
  String get currentLocationLabel => 'Current Location';

  @override
  String get locationDetailsFailed => 'Could not get location details';

  @override
  String get selectLocationLabel => 'Select Location';

  @override
  String get locationSectionTitle => 'Location';

  @override
  String get getDirectionsLabel => 'Get Directions';

  @override
  String get propertyFallbackLabel => 'Property';

  @override
  String distanceMeters(int distance) {
    return '${distance}m away';
  }

  @override
  String distanceKmDecimal(String distance) {
    return '${distance}km away';
  }

  @override
  String distanceKm(int distance) {
    return '${distance}km away';
  }

  @override
  String get availableNowLabel => 'Available Now';

  @override
  String get availableLabel => 'Available';

  @override
  String availableFromShort(String date) {
    return 'From $date';
  }

  @override
  String availableFromFull(String date) {
    return 'Available from $date';
  }

  @override
  String get genderSuffixMaleOnly => 'M Only';

  @override
  String get genderSuffixFemaleOnly => 'F Only';

  @override
  String get genderSuffixAny => 'Any Gender';

  @override
  String get activeRecentlyLabel => 'Active recently';

  @override
  String get couldNotLoadContent => 'Could not load content.';

  @override
  String get forceUpdateTitle => 'Update required';

  @override
  String get forceUpdateMessage =>
      'A new version of 360 FlatMates is available. Please update to continue using the app.';

  @override
  String get forceUpdateCta => 'Update now';

  @override
  String get optionalUpdateTitle => 'Update available';

  @override
  String get optionalUpdateMessage =>
      'A newer version of 360 FlatMates is available with improvements and bug fixes.';

  @override
  String get optionalUpdateCta => 'Update now';

  @override
  String get optionalUpdateLater => 'Later';

  @override
  String get maintenanceTitle => 'Under maintenance';

  @override
  String get maintenanceMessage =>
      'We\'re making things better. Please check back in a little while.';

  @override
  String get maintenanceRetry => 'Check again';

  @override
  String get deleteAccountCta => 'Delete Account';

  @override
  String get deleteAccountConfirmLabel => 'Type DELETE to confirm:';

  @override
  String get deleteAccountConfirmHint => 'Type DELETE here';

  @override
  String get deleteAccountButton => 'Send Deletion Request';

  @override
  String get deleteAccountTitle => 'Delete Your Account';

  @override
  String get deleteAccountWarning =>
      'This action is permanent and cannot be undone. All your data including profile, listings, chats, and matches will be permanently deleted. To proceed, send us a deletion request email below and our team will reach out to confirm.';

  @override
  String get deleteAccountEmailSubject => 'Account Deletion Request';

  @override
  String deleteAccountEmailBody(String email) {
    return 'Hello 360 Ghar Support,\n\nI would like to request the deletion of my account.\n\nRegistered email: $email\n\nThank you.';
  }

  @override
  String get deleteAccountRequestSent =>
      'Email draft opened. Send it to start your deletion request.';

  @override
  String deleteAccountEmailFallback(String email, String subject) {
    return 'Email us at $email with subject \"$subject\" to request account deletion.';
  }

  @override
  String get forgotPasswordTitle => 'Forgot Password';

  @override
  String get forgotPasswordSubtitle =>
      'Enter your phone number and we\'ll send you an OTP to reset your password.';

  @override
  String get sendOtpCta => 'Send OTP';

  @override
  String get resetPasswordTitle => 'Reset Password';

  @override
  String resetPasswordSubtitle(String phone) {
    return 'Enter the OTP sent to $phone and set your new password.';
  }

  @override
  String get forgotPasswordCta => 'Forgot Password?';

  @override
  String get noAccountCta => 'Don\'t have an account?';

  @override
  String get passwordResetSuccess =>
      'Password reset successfully. Please sign in.';

  @override
  String get phoneNotRegistered => 'This phone number is not registered.';

  @override
  String get loginWithPasswordCta => 'Login with password';

  @override
  String get reportABug => 'Report a Bug';

  @override
  String get reportABugSubtitle => 'Something not working? Let us know.';

  @override
  String get requestAFeature => 'Request a Feature';

  @override
  String get requestAFeatureSubtitle => 'Share an idea to make the app better.';

  @override
  String get reportABugIntro =>
      'Tell us what went wrong and we\'ll look into it.';

  @override
  String get requestAFeatureIntro =>
      'Tell us what you\'d love to see in the app.';

  @override
  String get feedbackTitleLabel => 'Title';

  @override
  String get feedbackTitleBugHint => 'Brief summary of the bug';

  @override
  String get feedbackTitleFeatureHint => 'Brief summary of your idea';

  @override
  String get feedbackTitleRequired => 'Please enter a title.';

  @override
  String get feedbackDescriptionLabel => 'Description';

  @override
  String get feedbackDescriptionBugHint =>
      'Steps to reproduce, what you expected, and what happened';

  @override
  String get feedbackDescriptionFeatureHint =>
      'Describe the feature and how it would help';

  @override
  String get feedbackDescriptionRequired => 'Please enter a description.';

  @override
  String get feedbackBugTypeLabel => 'Bug type';

  @override
  String get feedbackBugTypeFunctionality => 'Functionality bug';

  @override
  String get feedbackBugTypeUi => 'UI bug';

  @override
  String get feedbackBugTypePerformance => 'Performance issue';

  @override
  String get feedbackBugTypeCrash => 'Crash';

  @override
  String get feedbackBugTypeOther => 'Other';

  @override
  String get feedbackSeverityLabel => 'Severity';

  @override
  String get feedbackSeverityLow => 'Low';

  @override
  String get feedbackSeverityMedium => 'Medium';

  @override
  String get feedbackSeverityHigh => 'High';

  @override
  String get feedbackSeverityCritical => 'Critical';

  @override
  String get feedbackSubmitCta => 'Submit';

  @override
  String get feedbackSubmitSuccess => 'Thanks for your feedback!';

  @override
  String get signInWithGoogleCta => 'Sign in with Google';

  @override
  String get signUpWithGoogleCta => 'Sign up with Google';

  @override
  String get continueWithGoogleCta => 'Continue with Google';

  @override
  String get googleSignInCancelled => 'Google Sign-In was cancelled.';

  @override
  String get googleSignInFailed => 'Google Sign-In failed. Please try again.';

  @override
  String get pressBackAgainToExit => 'Press back again to exit';

  @override
  String get termsAgreementRequired => 'Please accept the terms to continue';
}
