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
  String get splashTagline =>
      'Find the right flat, meet the right people, move in faster.';

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
  String get enterPhoneSubtitle => 'Use password login or continue with OTP.';

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
    return 'Hi, $name';
  }

  @override
  String get homeLocationFallback =>
      'Set your city and locality to personalize discovery.';

  @override
  String get homeSearchHint => 'Search by location, area or landmark';

  @override
  String get homePickedForYou => 'Picked for You';

  @override
  String get homePickedSubtitle =>
      'Top flats that match your preferences and vibe';

  @override
  String get homeNoResults => 'No listings match those filters.';

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
  String get likesChatTitle => 'Likes & Chat';

  @override
  String get likesTabLabel => 'Likes';

  @override
  String get chatsTabLabel => 'Chats';

  @override
  String get likesIncomingLabel =>
      'This connection is ready for a first message.';

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
  String get safetyFirstSubtitle =>
      'We verify profiles to keep the community safer.';

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
  String get profilePageTitle => 'Profile';

  @override
  String get profileTitle => 'Profile & Settings';

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
  String get profileMenuLikesChat => 'Likes & Chat';

  @override
  String get profileMenuPostListing => 'Post Listing';

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
  String get paletteElectricIndigo => 'Electric Indigo';

  @override
  String get paletteEmberCoral => 'Ember Coral';

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
  String get modeRoomPoster => 'Room Poster';

  @override
  String get modeSeeker => 'Seeker';

  @override
  String get modeCoHunter => 'Co-Hunter';

  @override
  String get modeOpenToBoth => 'Open to Both';

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
  String get navLikesChat => 'Likes & Chat';

  @override
  String get navSchedule => 'Schedule';

  @override
  String get navPost => 'Post';

  @override
  String get navProfile => 'Profile';

  @override
  String get onboardingGetStarted => 'Get Started';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingComplete => 'Complete';

  @override
  String get onboardingSubmitting => 'Setting up your profile...';

  @override
  String get modeSelectionTitle => 'How are you looking for a flatmate?';

  @override
  String get modeSelectionSubtitle =>
      'You can change this later from your profile.';

  @override
  String get modeRoomPosterDesc =>
      'I\'m living in a flat and looking for a flatmate to fill a spare room.';

  @override
  String get modeSeekerDesc =>
      'I\'m looking for a flatmate to search for a place together';

  @override
  String get modeCoHunterDesc =>
      'I\'m looking for someone to flat-search alongside.';

  @override
  String get modeOpenToBothDesc =>
      'I\'ll move into an existing flat or team up to find a new one.';

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
  String get emptySwipeDeck =>
      'No more profiles to show right now. Check back later!';

  @override
  String swipeDeckRemaining(int count) {
    return '$count remaining';
  }

  @override
  String get tapToSeeMore => 'Tap to see more';

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
  String get vibeQuiet => 'Quiet';

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
  String get waitlistConfirmed => 'You\'re on the list! We\'ll notify you.';

  @override
  String get privacyTitle => 'Privacy';

  @override
  String get hideLastNameLabel => 'Hide last name on public profile';

  @override
  String get hideExactLocationLabel => 'Hide exact location on listings';

  @override
  String get visitConfirmTitle => 'Confirm this visit?';

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
  String superLikeCapLabel(int count) {
    return '$count Super Likes left today';
  }

  @override
  String swipeCounterLabel(int count) {
    return '$count swipes remaining today';
  }

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
}
