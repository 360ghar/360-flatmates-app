import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'360 FlatMates'**
  String get appName;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Find the right flat, meet the right people, move in faster.'**
  String get splashTagline;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @seeAllCta.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAllCta;

  /// No description provided for @cancelCta.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelCta;

  /// No description provided for @enterPhoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get enterPhoneTitle;

  /// No description provided for @enterPhoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use password login or continue with OTP.'**
  String get enterPhoneSubtitle;

  /// No description provided for @phoneNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumberLabel;

  /// No description provided for @loginWithPassword.
  ///
  /// In en, this message translates to:
  /// **'Login with password'**
  String get loginWithPassword;

  /// No description provided for @continueWithOtp.
  ///
  /// In en, this message translates to:
  /// **'Continue with OTP'**
  String get continueWithOtp;

  /// No description provided for @createAccountCta.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccountCta;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginTitle;

  /// No description provided for @signupTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get signupTitle;

  /// No description provided for @fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullNameLabel;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @signInCta.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInCta;

  /// No description provided for @otpTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get otpTitle;

  /// No description provided for @otpCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'OTP code'**
  String get otpCodeLabel;

  /// No description provided for @verifyOtpCta.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyOtpCta;

  /// No description provided for @otpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the OTP sent to {phone}.'**
  String otpSubtitle(String phone);

  /// No description provided for @discoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discoverTitle;

  /// No description provided for @emptyListings.
  ///
  /// In en, this message translates to:
  /// **'No flatmate listings are available right now.'**
  String get emptyListings;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hi, {name}'**
  String homeGreeting(String name);

  /// No description provided for @homeLocationFallback.
  ///
  /// In en, this message translates to:
  /// **'Set your city and locality to personalize discovery.'**
  String get homeLocationFallback;

  /// No description provided for @homeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by location, area or landmark'**
  String get homeSearchHint;

  /// No description provided for @homePickedForYou.
  ///
  /// In en, this message translates to:
  /// **'Picked for You'**
  String get homePickedForYou;

  /// No description provided for @homePickedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Top flats that match your preferences and vibe'**
  String get homePickedSubtitle;

  /// No description provided for @homeNoResults.
  ///
  /// In en, this message translates to:
  /// **'No listings match those filters.'**
  String get homeNoResults;

  /// No description provided for @homeBedroomsChip.
  ///
  /// In en, this message translates to:
  /// **'{count} BHK'**
  String homeBedroomsChip(int count);

  /// No description provided for @homeBedsValue.
  ///
  /// In en, this message translates to:
  /// **'{count} Bed'**
  String homeBedsValue(int count);

  /// No description provided for @homeBathsValue.
  ///
  /// In en, this message translates to:
  /// **'{count} Bath'**
  String homeBathsValue(int count);

  /// No description provided for @homeAreaValue.
  ///
  /// In en, this message translates to:
  /// **'{area} sq.ft'**
  String homeAreaValue(String area);

  /// No description provided for @homeMoveInValue.
  ///
  /// In en, this message translates to:
  /// **'Move-in: {date}'**
  String homeMoveInValue(String date);

  /// No description provided for @homeInterestCount.
  ///
  /// In en, this message translates to:
  /// **'{count} interested'**
  String homeInterestCount(int count);

  /// No description provided for @badgeNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get badgeNew;

  /// No description provided for @badgePopular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get badgePopular;

  /// No description provided for @badgeTrending.
  ///
  /// In en, this message translates to:
  /// **'Trending'**
  String get badgeTrending;

  /// No description provided for @monthlyRentLabel.
  ///
  /// In en, this message translates to:
  /// **'Monthly rent: ₹{amount}'**
  String monthlyRentLabel(String amount);

  /// No description provided for @monthlyRentHeadline.
  ///
  /// In en, this message translates to:
  /// **'₹{amount} / month'**
  String monthlyRentHeadline(String amount);

  /// No description provided for @contactRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Interest sent. The owner can now chat with you.'**
  String get contactRequestSent;

  /// No description provided for @contactRequestWithConversation.
  ///
  /// In en, this message translates to:
  /// **'Interest sent. Conversation #{conversationId} is ready.'**
  String contactRequestWithConversation(int conversationId);

  /// No description provided for @likeListingCta.
  ///
  /// In en, this message translates to:
  /// **'Like listing'**
  String get likeListingCta;

  /// No description provided for @likesChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Likes & Chat'**
  String get likesChatTitle;

  /// No description provided for @likesTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Likes'**
  String get likesTabLabel;

  /// No description provided for @chatsTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chatsTabLabel;

  /// No description provided for @likesIncomingLabel.
  ///
  /// In en, this message translates to:
  /// **'This connection is ready for a first message.'**
  String get likesIncomingLabel;

  /// No description provided for @emptyLikes.
  ///
  /// In en, this message translates to:
  /// **'No new likes yet.'**
  String get emptyLikes;

  /// No description provided for @chatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chatsTitle;

  /// No description provided for @emptyChats.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet.'**
  String get emptyChats;

  /// No description provided for @chatReady.
  ///
  /// In en, this message translates to:
  /// **'Your chat is ready when you are.'**
  String get chatReady;

  /// No description provided for @messageHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get messageHint;

  /// No description provided for @sendCta.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendCta;

  /// No description provided for @messageAttachment.
  ///
  /// In en, this message translates to:
  /// **'Attachment'**
  String get messageAttachment;

  /// No description provided for @openConversationCta.
  ///
  /// In en, this message translates to:
  /// **'Open conversation'**
  String get openConversationCta;

  /// No description provided for @todayLabel.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayLabel;

  /// No description provided for @safetyFirstTitle.
  ///
  /// In en, this message translates to:
  /// **'Safety first'**
  String get safetyFirstTitle;

  /// No description provided for @safetyFirstSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We verify profiles to keep the community safer.'**
  String get safetyFirstSubtitle;

  /// No description provided for @scheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get scheduleTitle;

  /// No description provided for @scheduleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track your flat visits and meetups in one place.'**
  String get scheduleSubtitle;

  /// No description provided for @visitsTitle.
  ///
  /// In en, this message translates to:
  /// **'Visits'**
  String get visitsTitle;

  /// No description provided for @emptyVisits.
  ///
  /// In en, this message translates to:
  /// **'No visits scheduled yet.'**
  String get emptyVisits;

  /// No description provided for @visitRequested.
  ///
  /// In en, this message translates to:
  /// **'Visit request sent.'**
  String get visitRequested;

  /// No description provided for @flatmateMeetLabel.
  ///
  /// In en, this message translates to:
  /// **'Flatmate meet'**
  String get flatmateMeetLabel;

  /// No description provided for @propertyTourLabel.
  ///
  /// In en, this message translates to:
  /// **'Property tour'**
  String get propertyTourLabel;

  /// No description provided for @scheduleVisitCta.
  ///
  /// In en, this message translates to:
  /// **'Schedule visit'**
  String get scheduleVisitCta;

  /// No description provided for @profilePageTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profilePageTitle;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile & Settings'**
  String get profileTitle;

  /// No description provided for @profileFallbackName.
  ///
  /// In en, this message translates to:
  /// **'Your Flatmates profile'**
  String get profileFallbackName;

  /// No description provided for @profileStatListings.
  ///
  /// In en, this message translates to:
  /// **'Listings'**
  String get profileStatListings;

  /// No description provided for @profileStatChats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get profileStatChats;

  /// No description provided for @profileStatUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get profileStatUnread;

  /// No description provided for @profileMenuVisits.
  ///
  /// In en, this message translates to:
  /// **'My Schedule'**
  String get profileMenuVisits;

  /// No description provided for @profileMenuLikesChat.
  ///
  /// In en, this message translates to:
  /// **'Likes & Chat'**
  String get profileMenuLikesChat;

  /// No description provided for @profileMenuPostListing.
  ///
  /// In en, this message translates to:
  /// **'Post Listing'**
  String get profileMenuPostListing;

  /// No description provided for @editProfileCta.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfileCta;

  /// No description provided for @themeModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme mode'**
  String get themeModeTitle;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @paletteTitle.
  ///
  /// In en, this message translates to:
  /// **'Palette'**
  String get paletteTitle;

  /// No description provided for @paletteElectricIndigo.
  ///
  /// In en, this message translates to:
  /// **'Electric Indigo'**
  String get paletteElectricIndigo;

  /// No description provided for @paletteEmberCoral.
  ///
  /// In en, this message translates to:
  /// **'Ember Coral'**
  String get paletteEmberCoral;

  /// No description provided for @paletteMonsoonTeal.
  ///
  /// In en, this message translates to:
  /// **'Monsoon Teal'**
  String get paletteMonsoonTeal;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageHindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get languageHindi;

  /// No description provided for @logoutCta.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutCta;

  /// No description provided for @modeTitle.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get modeTitle;

  /// No description provided for @modeRoomPoster.
  ///
  /// In en, this message translates to:
  /// **'Room Poster'**
  String get modeRoomPoster;

  /// No description provided for @modeSeeker.
  ///
  /// In en, this message translates to:
  /// **'Seeker'**
  String get modeSeeker;

  /// No description provided for @modeCoHunter.
  ///
  /// In en, this message translates to:
  /// **'Co-Hunter'**
  String get modeCoHunter;

  /// No description provided for @modeOpenToBoth.
  ///
  /// In en, this message translates to:
  /// **'Open to Both'**
  String get modeOpenToBoth;

  /// No description provided for @cityLabel.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get cityLabel;

  /// No description provided for @localityLabel.
  ///
  /// In en, this message translates to:
  /// **'Locality'**
  String get localityLabel;

  /// No description provided for @subLocalityLabel.
  ///
  /// In en, this message translates to:
  /// **'Sub-locality'**
  String get subLocalityLabel;

  /// No description provided for @budgetMinLabel.
  ///
  /// In en, this message translates to:
  /// **'Budget min'**
  String get budgetMinLabel;

  /// No description provided for @budgetMaxLabel.
  ///
  /// In en, this message translates to:
  /// **'Budget max'**
  String get budgetMaxLabel;

  /// No description provided for @workStyleTitle.
  ///
  /// In en, this message translates to:
  /// **'Work style'**
  String get workStyleTitle;

  /// No description provided for @bioLabel.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bioLabel;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @listingTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Listing title'**
  String get listingTitleLabel;

  /// No description provided for @monthlyRentInputLabel.
  ///
  /// In en, this message translates to:
  /// **'Monthly rent'**
  String get monthlyRentInputLabel;

  /// No description provided for @securityDepositLabel.
  ///
  /// In en, this message translates to:
  /// **'Security deposit'**
  String get securityDepositLabel;

  /// No description provided for @maintenanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get maintenanceLabel;

  /// No description provided for @areaSqftLabel.
  ///
  /// In en, this message translates to:
  /// **'Area (sq.ft)'**
  String get areaSqftLabel;

  /// No description provided for @bedroomsLabel.
  ///
  /// In en, this message translates to:
  /// **'Bedrooms'**
  String get bedroomsLabel;

  /// No description provided for @bathroomsLabel.
  ///
  /// In en, this message translates to:
  /// **'Bathrooms'**
  String get bathroomsLabel;

  /// No description provided for @genderPreferenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Preferred gender'**
  String get genderPreferenceLabel;

  /// No description provided for @genderAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get genderAny;

  /// No description provided for @genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// No description provided for @visitStatusRequested.
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get visitStatusRequested;

  /// No description provided for @visitStatusScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get visitStatusScheduled;

  /// No description provided for @visitStatusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get visitStatusConfirmed;

  /// No description provided for @visitStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get visitStatusCompleted;

  /// No description provided for @visitStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get visitStatusCancelled;

  /// No description provided for @sharingTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Room type'**
  String get sharingTypeLabel;

  /// No description provided for @sharingPrivateRoom.
  ///
  /// In en, this message translates to:
  /// **'Private room'**
  String get sharingPrivateRoom;

  /// No description provided for @sharingSharedRoom.
  ///
  /// In en, this message translates to:
  /// **'Shared room'**
  String get sharingSharedRoom;

  /// No description provided for @featuresLabel.
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get featuresLabel;

  /// No description provided for @featuresHint.
  ///
  /// In en, this message translates to:
  /// **'Example: furnished, wifi, balcony'**
  String get featuresHint;

  /// No description provided for @featureFurnished.
  ///
  /// In en, this message translates to:
  /// **'Furnished'**
  String get featureFurnished;

  /// No description provided for @featureSemiFurnished.
  ///
  /// In en, this message translates to:
  /// **'Semi-furnished'**
  String get featureSemiFurnished;

  /// No description provided for @featureWifi.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi'**
  String get featureWifi;

  /// No description provided for @featureBalcony.
  ///
  /// In en, this message translates to:
  /// **'Balcony'**
  String get featureBalcony;

  /// No description provided for @featureAttachedBathroom.
  ///
  /// In en, this message translates to:
  /// **'Attached bathroom'**
  String get featureAttachedBathroom;

  /// No description provided for @featureParking.
  ///
  /// In en, this message translates to:
  /// **'Parking'**
  String get featureParking;

  /// No description provided for @featureAc.
  ///
  /// In en, this message translates to:
  /// **'AC'**
  String get featureAc;

  /// No description provided for @featureWashingMachine.
  ///
  /// In en, this message translates to:
  /// **'Washing machine'**
  String get featureWashingMachine;

  /// No description provided for @mainImageUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Main image URL'**
  String get mainImageUrlLabel;

  /// No description provided for @availableFromLabel.
  ///
  /// In en, this message translates to:
  /// **'Available from'**
  String get availableFromLabel;

  /// No description provided for @availableFromUnset.
  ///
  /// In en, this message translates to:
  /// **'Select move-in availability'**
  String get availableFromUnset;

  /// No description provided for @selectDateCta.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDateCta;

  /// No description provided for @postListingTitle.
  ///
  /// In en, this message translates to:
  /// **'Post your space'**
  String get postListingTitle;

  /// No description provided for @postListingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a real flatmate listing using the existing 360 Ghar inventory backend.'**
  String get postListingSubtitle;

  /// No description provided for @postListingBasics.
  ///
  /// In en, this message translates to:
  /// **'Basics'**
  String get postListingBasics;

  /// No description provided for @postListingPricing.
  ///
  /// In en, this message translates to:
  /// **'Pricing'**
  String get postListingPricing;

  /// No description provided for @postListingDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get postListingDetails;

  /// No description provided for @publishListingCta.
  ///
  /// In en, this message translates to:
  /// **'Publish listing'**
  String get publishListingCta;

  /// No description provided for @postingInProgress.
  ///
  /// In en, this message translates to:
  /// **'Publishing...'**
  String get postingInProgress;

  /// No description provided for @postListingSuccess.
  ///
  /// In en, this message translates to:
  /// **'Listing created successfully.'**
  String get postListingSuccess;

  /// No description provided for @ownerFallbackLabel.
  ///
  /// In en, this message translates to:
  /// **'Listing owner'**
  String get ownerFallbackLabel;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsProfileSection.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get settingsProfileSection;

  /// No description provided for @settingsAppearanceSection.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearanceSection;

  /// No description provided for @settingsSessionSection.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get settingsSessionSection;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navSwipe.
  ///
  /// In en, this message translates to:
  /// **'Swipe'**
  String get navSwipe;

  /// No description provided for @navLikesChat.
  ///
  /// In en, this message translates to:
  /// **'Likes & Chat'**
  String get navLikesChat;

  /// No description provided for @navSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get navSchedule;

  /// No description provided for @navPost.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get navPost;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingGetStarted;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get onboardingComplete;

  /// No description provided for @onboardingSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Setting up your profile...'**
  String get onboardingSubmitting;

  /// No description provided for @modeSelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'How are you looking for a flatmate?'**
  String get modeSelectionTitle;

  /// No description provided for @modeSelectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can change this later from your profile.'**
  String get modeSelectionSubtitle;

  /// No description provided for @modeRoomPosterDesc.
  ///
  /// In en, this message translates to:
  /// **'I\'m living in a flat and looking for a flatmate to fill a spare room.'**
  String get modeRoomPosterDesc;

  /// No description provided for @modeSeekerDesc.
  ///
  /// In en, this message translates to:
  /// **'I\'m looking for a flatmate to search for a place together'**
  String get modeSeekerDesc;

  /// No description provided for @modeCoHunterDesc.
  ///
  /// In en, this message translates to:
  /// **'I\'m looking for someone to flat-search alongside.'**
  String get modeCoHunterDesc;

  /// No description provided for @modeOpenToBothDesc.
  ///
  /// In en, this message translates to:
  /// **'I\'ll move into an existing flat or team up to find a new one.'**
  String get modeOpenToBothDesc;

  /// No description provided for @basicInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us about yourself'**
  String get basicInfoTitle;

  /// No description provided for @basicInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This helps us find the right flatmates for you.'**
  String get basicInfoSubtitle;

  /// No description provided for @ageLabel.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get ageLabel;

  /// No description provided for @ageHelperText.
  ///
  /// In en, this message translates to:
  /// **'You must be 18 or older'**
  String get ageHelperText;

  /// No description provided for @professionLabel.
  ///
  /// In en, this message translates to:
  /// **'Profession / Job title'**
  String get professionLabel;

  /// No description provided for @profilePhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Add your photos'**
  String get profilePhotoTitle;

  /// No description provided for @profilePhotoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A great photo helps you get more matches.'**
  String get profilePhotoSubtitle;

  /// No description provided for @profilePhotoNudge.
  ///
  /// In en, this message translates to:
  /// **'Profiles with 3+ photos get 4x more matches!'**
  String get profilePhotoNudge;

  /// No description provided for @addPhotoCta.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get addPhotoCta;

  /// No description provided for @quizProgress.
  ///
  /// In en, this message translates to:
  /// **'{answered} of {total} answered'**
  String quizProgress(int answered, int total);

  /// No description provided for @quizSleepSchedule.
  ///
  /// In en, this message translates to:
  /// **'What\'s your sleep schedule?'**
  String get quizSleepSchedule;

  /// No description provided for @quizEarlyBird.
  ///
  /// In en, this message translates to:
  /// **'Early bird (before 10pm)'**
  String get quizEarlyBird;

  /// No description provided for @quizFlexible.
  ///
  /// In en, this message translates to:
  /// **'Flexible'**
  String get quizFlexible;

  /// No description provided for @quizNightOwl.
  ///
  /// In en, this message translates to:
  /// **'Night owl (after midnight)'**
  String get quizNightOwl;

  /// No description provided for @quizCleanliness.
  ///
  /// In en, this message translates to:
  /// **'How clean do you keep things?'**
  String get quizCleanliness;

  /// No description provided for @quizCleanMinimal.
  ///
  /// In en, this message translates to:
  /// **'Minimal — lived-in is fine'**
  String get quizCleanMinimal;

  /// No description provided for @quizCleanTidy.
  ///
  /// In en, this message translates to:
  /// **'Tidy — things in their place'**
  String get quizCleanTidy;

  /// No description provided for @quizCleanSpotless.
  ///
  /// In en, this message translates to:
  /// **'Spotless — everything pristine'**
  String get quizCleanSpotless;

  /// No description provided for @quizFoodHabits.
  ///
  /// In en, this message translates to:
  /// **'What are your food habits?'**
  String get quizFoodHabits;

  /// No description provided for @quizVegetarian.
  ///
  /// In en, this message translates to:
  /// **'Vegetarian'**
  String get quizVegetarian;

  /// No description provided for @quizVegan.
  ///
  /// In en, this message translates to:
  /// **'Vegan'**
  String get quizVegan;

  /// No description provided for @quizNonVegetarian.
  ///
  /// In en, this message translates to:
  /// **'Non-vegetarian'**
  String get quizNonVegetarian;

  /// No description provided for @quizNoFoodPref.
  ///
  /// In en, this message translates to:
  /// **'No preference'**
  String get quizNoFoodPref;

  /// No description provided for @quizSmokingDrinking.
  ///
  /// In en, this message translates to:
  /// **'Smoking & drinking preferences?'**
  String get quizSmokingDrinking;

  /// No description provided for @quizNeither.
  ///
  /// In en, this message translates to:
  /// **'Neither'**
  String get quizNeither;

  /// No description provided for @quizSmokeOutside.
  ///
  /// In en, this message translates to:
  /// **'Smoke outside only'**
  String get quizSmokeOutside;

  /// No description provided for @quizDrinkOccasionally.
  ///
  /// In en, this message translates to:
  /// **'Drink occasionally'**
  String get quizDrinkOccasionally;

  /// No description provided for @quizBothFine.
  ///
  /// In en, this message translates to:
  /// **'Both are fine'**
  String get quizBothFine;

  /// No description provided for @quizGuestsPolicy.
  ///
  /// In en, this message translates to:
  /// **'How do you feel about guests?'**
  String get quizGuestsPolicy;

  /// No description provided for @quizNoGuests.
  ///
  /// In en, this message translates to:
  /// **'No overnight guests'**
  String get quizNoGuests;

  /// No description provided for @quizOccasionalGuests.
  ///
  /// In en, this message translates to:
  /// **'Occasional guests are ok'**
  String get quizOccasionalGuests;

  /// No description provided for @quizOpenHouse.
  ///
  /// In en, this message translates to:
  /// **'Open house — always welcome'**
  String get quizOpenHouse;

  /// No description provided for @quizParties.
  ///
  /// In en, this message translates to:
  /// **'How about parties at home?'**
  String get quizParties;

  /// No description provided for @quizPartiesNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get quizPartiesNever;

  /// No description provided for @quizPartiesWeekends.
  ///
  /// In en, this message translates to:
  /// **'Occasional weekends'**
  String get quizPartiesWeekends;

  /// No description provided for @quizPartyFriendly.
  ///
  /// In en, this message translates to:
  /// **'Party-friendly'**
  String get quizPartyFriendly;

  /// No description provided for @quizWorkStyle.
  ///
  /// In en, this message translates to:
  /// **'What\'s your work style?'**
  String get quizWorkStyle;

  /// No description provided for @quizWfh.
  ///
  /// In en, this message translates to:
  /// **'Work from home mostly'**
  String get quizWfh;

  /// No description provided for @quizOffice.
  ///
  /// In en, this message translates to:
  /// **'Office mostly'**
  String get quizOffice;

  /// No description provided for @quizHybrid.
  ///
  /// In en, this message translates to:
  /// **'Hybrid — mix of both'**
  String get quizHybrid;

  /// No description provided for @quizPets.
  ///
  /// In en, this message translates to:
  /// **'How do you feel about pets?'**
  String get quizPets;

  /// No description provided for @quizNoPets.
  ///
  /// In en, this message translates to:
  /// **'No pets'**
  String get quizNoPets;

  /// No description provided for @quizHavePets.
  ///
  /// In en, this message translates to:
  /// **'I have pets'**
  String get quizHavePets;

  /// No description provided for @quizPetFriendly.
  ///
  /// In en, this message translates to:
  /// **'Pet-friendly (no own pets)'**
  String get quizPetFriendly;

  /// No description provided for @budgetTimelineTitle.
  ///
  /// In en, this message translates to:
  /// **'Budget & move-in timeline'**
  String get budgetTimelineTitle;

  /// No description provided for @budgetTimelineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set your budget range and when you\'re looking to move.'**
  String get budgetTimelineSubtitle;

  /// No description provided for @monthlyBudgetLabel.
  ///
  /// In en, this message translates to:
  /// **'Monthly budget'**
  String get monthlyBudgetLabel;

  /// No description provided for @moveInTimelineLabel.
  ///
  /// In en, this message translates to:
  /// **'Move-in timeline'**
  String get moveInTimelineLabel;

  /// No description provided for @timelineImmediate.
  ///
  /// In en, this message translates to:
  /// **'Immediate'**
  String get timelineImmediate;

  /// No description provided for @timelineThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get timelineThisMonth;

  /// No description provided for @timelineNextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get timelineNextMonth;

  /// No description provided for @timelineFlexible.
  ///
  /// In en, this message translates to:
  /// **'Flexible'**
  String get timelineFlexible;

  /// No description provided for @nonNegotiablesTitle.
  ///
  /// In en, this message translates to:
  /// **'Your deal-breakers'**
  String get nonNegotiablesTitle;

  /// No description provided for @nonNegotiablesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick up to 3 things that are non-negotiable for you.'**
  String get nonNegotiablesSubtitle;

  /// No description provided for @nonNegotiablesLimit.
  ///
  /// In en, this message translates to:
  /// **'Select up to 3'**
  String get nonNegotiablesLimit;

  /// No description provided for @nonNegVegOnly.
  ///
  /// In en, this message translates to:
  /// **'Vegetarian flatmates only'**
  String get nonNegVegOnly;

  /// No description provided for @nonNegVeganOnly.
  ///
  /// In en, this message translates to:
  /// **'Vegan flatmates only'**
  String get nonNegVeganOnly;

  /// No description provided for @nonNegNoSmoking.
  ///
  /// In en, this message translates to:
  /// **'Non-smoker only'**
  String get nonNegNoSmoking;

  /// No description provided for @nonNegNoDrinking.
  ///
  /// In en, this message translates to:
  /// **'No alcohol at home'**
  String get nonNegNoDrinking;

  /// No description provided for @nonNegNoGuests.
  ///
  /// In en, this message translates to:
  /// **'No overnight guests'**
  String get nonNegNoGuests;

  /// No description provided for @nonNegNoPets.
  ///
  /// In en, this message translates to:
  /// **'No pets'**
  String get nonNegNoPets;

  /// No description provided for @nonNegFemaleOnly.
  ///
  /// In en, this message translates to:
  /// **'Female flatmates only'**
  String get nonNegFemaleOnly;

  /// No description provided for @nonNegMaleOnly.
  ///
  /// In en, this message translates to:
  /// **'Male flatmates only'**
  String get nonNegMaleOnly;

  /// No description provided for @nonNegNoParties.
  ///
  /// In en, this message translates to:
  /// **'No parties at home'**
  String get nonNegNoParties;

  /// No description provided for @nonNegMinTidy.
  ///
  /// In en, this message translates to:
  /// **'Minimum tidy standard'**
  String get nonNegMinTidy;

  /// No description provided for @emptySwipeDeck.
  ///
  /// In en, this message translates to:
  /// **'No more profiles to show right now. Check back later!'**
  String get emptySwipeDeck;

  /// No description provided for @swipeDeckRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} remaining'**
  String swipeDeckRemaining(int count);

  /// No description provided for @tapToSeeMore.
  ///
  /// In en, this message translates to:
  /// **'Tap to see more'**
  String get tapToSeeMore;

  /// No description provided for @tapToCollapse.
  ///
  /// In en, this message translates to:
  /// **'Tap to collapse'**
  String get tapToCollapse;

  /// No description provided for @aboutMeSection.
  ///
  /// In en, this message translates to:
  /// **'About me'**
  String get aboutMeSection;

  /// No description provided for @noBioYet.
  ///
  /// In en, this message translates to:
  /// **'No bio yet.'**
  String get noBioYet;

  /// No description provided for @compatibilityBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Compatibility breakdown'**
  String get compatibilityBreakdown;

  /// No description provided for @budgetLabel.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budgetLabel;

  /// No description provided for @blockConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Block this person?'**
  String get blockConfirmTitle;

  /// No description provided for @blockConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'They won\'t be able to see your profile or contact you.'**
  String get blockConfirmMessage;

  /// No description provided for @blockCta.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get blockCta;

  /// No description provided for @userBlocked.
  ///
  /// In en, this message translates to:
  /// **'User has been blocked.'**
  String get userBlocked;

  /// No description provided for @reportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report this person'**
  String get reportTitle;

  /// No description provided for @reportFakeProfile.
  ///
  /// In en, this message translates to:
  /// **'Fake profile'**
  String get reportFakeProfile;

  /// No description provided for @reportSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam'**
  String get reportSpam;

  /// No description provided for @reportInappropriate.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate content'**
  String get reportInappropriate;

  /// No description provided for @reportUncomfortable.
  ///
  /// In en, this message translates to:
  /// **'Uncomfortable interaction'**
  String get reportUncomfortable;

  /// No description provided for @reportOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get reportOther;

  /// No description provided for @reportCta.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get reportCta;

  /// No description provided for @reportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Report submitted. We\'ll review it shortly.'**
  String get reportSubmitted;

  /// No description provided for @unmatchConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Unmatch?'**
  String get unmatchConfirmTitle;

  /// No description provided for @unmatchConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This will remove your match and end the conversation.'**
  String get unmatchConfirmMessage;

  /// No description provided for @unmatchCta.
  ///
  /// In en, this message translates to:
  /// **'Unmatch'**
  String get unmatchCta;

  /// No description provided for @icebreakerTitle.
  ///
  /// In en, this message translates to:
  /// **'Break the ice'**
  String get icebreakerTitle;

  /// No description provided for @backCta.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backCta;

  /// No description provided for @listingBuilderTitle.
  ///
  /// In en, this message translates to:
  /// **'Post your space'**
  String get listingBuilderTitle;

  /// No description provided for @listingStepLocation.
  ///
  /// In en, this message translates to:
  /// **'Property location'**
  String get listingStepLocation;

  /// No description provided for @listingStepSociety.
  ///
  /// In en, this message translates to:
  /// **'The society'**
  String get listingStepSociety;

  /// No description provided for @listingStepRoom.
  ///
  /// In en, this message translates to:
  /// **'The room'**
  String get listingStepRoom;

  /// No description provided for @listingStepFlat.
  ///
  /// In en, this message translates to:
  /// **'The flat'**
  String get listingStepFlat;

  /// No description provided for @listingStepCosts.
  ///
  /// In en, this message translates to:
  /// **'Costs'**
  String get listingStepCosts;

  /// No description provided for @listingStepAbout.
  ///
  /// In en, this message translates to:
  /// **'About you & preferred flatmate'**
  String get listingStepAbout;

  /// No description provided for @societyBuildingLabel.
  ///
  /// In en, this message translates to:
  /// **'Society / Building name'**
  String get societyBuildingLabel;

  /// No description provided for @fullAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Full address'**
  String get fullAddressLabel;

  /// No description provided for @societyTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Society type'**
  String get societyTypeLabel;

  /// No description provided for @societyTypeGated.
  ///
  /// In en, this message translates to:
  /// **'Gated'**
  String get societyTypeGated;

  /// No description provided for @societyTypeIndependent.
  ///
  /// In en, this message translates to:
  /// **'Independent'**
  String get societyTypeIndependent;

  /// No description provided for @societyTypeCoLiving.
  ///
  /// In en, this message translates to:
  /// **'Co-living'**
  String get societyTypeCoLiving;

  /// No description provided for @societyTypePg.
  ///
  /// In en, this message translates to:
  /// **'PG'**
  String get societyTypePg;

  /// No description provided for @societyAmenitiesLabel.
  ///
  /// In en, this message translates to:
  /// **'Society amenities'**
  String get societyAmenitiesLabel;

  /// No description provided for @societyVibeLabel.
  ///
  /// In en, this message translates to:
  /// **'Society vibe'**
  String get societyVibeLabel;

  /// No description provided for @amenityPool.
  ///
  /// In en, this message translates to:
  /// **'Pool'**
  String get amenityPool;

  /// No description provided for @amenityGym.
  ///
  /// In en, this message translates to:
  /// **'Gym'**
  String get amenityGym;

  /// No description provided for @amenityClubhouse.
  ///
  /// In en, this message translates to:
  /// **'Clubhouse'**
  String get amenityClubhouse;

  /// No description provided for @amenitySports.
  ///
  /// In en, this message translates to:
  /// **'Sports'**
  String get amenitySports;

  /// No description provided for @amenityParking.
  ///
  /// In en, this message translates to:
  /// **'Parking'**
  String get amenityParking;

  /// No description provided for @amenityPowerBackup.
  ///
  /// In en, this message translates to:
  /// **'Power backup'**
  String get amenityPowerBackup;

  /// No description provided for @amenityWaterBackup.
  ///
  /// In en, this message translates to:
  /// **'Water backup'**
  String get amenityWaterBackup;

  /// No description provided for @amenitySecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get amenitySecurity;

  /// No description provided for @amenityLift.
  ///
  /// In en, this message translates to:
  /// **'Lift'**
  String get amenityLift;

  /// No description provided for @amenityCctv.
  ///
  /// In en, this message translates to:
  /// **'CCTV'**
  String get amenityCctv;

  /// No description provided for @amenityVisitorEntry.
  ///
  /// In en, this message translates to:
  /// **'Visitor entry'**
  String get amenityVisitorEntry;

  /// No description provided for @amenityGarden.
  ///
  /// In en, this message translates to:
  /// **'Garden'**
  String get amenityGarden;

  /// No description provided for @vibeBachelorFriendly.
  ///
  /// In en, this message translates to:
  /// **'Bachelor-friendly'**
  String get vibeBachelorFriendly;

  /// No description provided for @vibeQuiet.
  ///
  /// In en, this message translates to:
  /// **'Quiet'**
  String get vibeQuiet;

  /// No description provided for @vibeActiveCommunity.
  ///
  /// In en, this message translates to:
  /// **'Active community'**
  String get vibeActiveCommunity;

  /// No description provided for @vibeFamilyDominant.
  ///
  /// In en, this message translates to:
  /// **'Family-dominant'**
  String get vibeFamilyDominant;

  /// No description provided for @vibePetFriendly.
  ///
  /// In en, this message translates to:
  /// **'Pet-friendly'**
  String get vibePetFriendly;

  /// No description provided for @vibeVisitorFriendly.
  ///
  /// In en, this message translates to:
  /// **'Visitor-friendly'**
  String get vibeVisitorFriendly;

  /// No description provided for @roomTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Room type'**
  String get roomTypeLabel;

  /// No description provided for @roomTypeMasterBedroom.
  ///
  /// In en, this message translates to:
  /// **'Master bedroom'**
  String get roomTypeMasterBedroom;

  /// No description provided for @furnishingLabel.
  ///
  /// In en, this message translates to:
  /// **'Room furnishing'**
  String get furnishingLabel;

  /// No description provided for @furnishingBed.
  ///
  /// In en, this message translates to:
  /// **'Bed'**
  String get furnishingBed;

  /// No description provided for @furnishingWardrobe.
  ///
  /// In en, this message translates to:
  /// **'Wardrobe'**
  String get furnishingWardrobe;

  /// No description provided for @furnishingAc.
  ///
  /// In en, this message translates to:
  /// **'AC'**
  String get furnishingAc;

  /// No description provided for @furnishingGeyser.
  ///
  /// In en, this message translates to:
  /// **'Geyser'**
  String get furnishingGeyser;

  /// No description provided for @furnishingStudyTable.
  ///
  /// In en, this message translates to:
  /// **'Study table'**
  String get furnishingStudyTable;

  /// No description provided for @furnishingCurtains.
  ///
  /// In en, this message translates to:
  /// **'Curtains'**
  String get furnishingCurtains;

  /// No description provided for @roomFeaturesLabel.
  ///
  /// In en, this message translates to:
  /// **'Room features'**
  String get roomFeaturesLabel;

  /// No description provided for @roomFeatureBalcony.
  ///
  /// In en, this message translates to:
  /// **'Private balcony'**
  String get roomFeatureBalcony;

  /// No description provided for @roomFeatureSunlight.
  ///
  /// In en, this message translates to:
  /// **'Window with sunlight'**
  String get roomFeatureSunlight;

  /// No description provided for @roomFeatureStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage space'**
  String get roomFeatureStorage;

  /// No description provided for @roomPhotosLabel.
  ///
  /// In en, this message translates to:
  /// **'Room photos'**
  String get roomPhotosLabel;

  /// No description provided for @minPhotosRequired.
  ///
  /// In en, this message translates to:
  /// **'Min 2 photos required'**
  String get minPhotosRequired;

  /// No description provided for @flatConfigLabel.
  ///
  /// In en, this message translates to:
  /// **'Flat configuration'**
  String get flatConfigLabel;

  /// No description provided for @floorLabel.
  ///
  /// In en, this message translates to:
  /// **'Floor'**
  String get floorLabel;

  /// No description provided for @totalFloorsLabel.
  ///
  /// In en, this message translates to:
  /// **'Total floors'**
  String get totalFloorsLabel;

  /// No description provided for @flatAmenitiesLabel.
  ///
  /// In en, this message translates to:
  /// **'Flat amenities'**
  String get flatAmenitiesLabel;

  /// No description provided for @amenityRefrigerator.
  ///
  /// In en, this message translates to:
  /// **'Refrigerator'**
  String get amenityRefrigerator;

  /// No description provided for @amenityMicrowave.
  ///
  /// In en, this message translates to:
  /// **'Microwave'**
  String get amenityMicrowave;

  /// No description provided for @amenityTv.
  ///
  /// In en, this message translates to:
  /// **'TV'**
  String get amenityTv;

  /// No description provided for @amenityDiningTable.
  ///
  /// In en, this message translates to:
  /// **'Dining table'**
  String get amenityDiningTable;

  /// No description provided for @amenitySofa.
  ///
  /// In en, this message translates to:
  /// **'Sofa'**
  String get amenitySofa;

  /// No description provided for @amenityKitchenEquipped.
  ///
  /// In en, this message translates to:
  /// **'Kitchen equipped'**
  String get amenityKitchenEquipped;

  /// No description provided for @electricityLabel.
  ///
  /// In en, this message translates to:
  /// **'Electricity'**
  String get electricityLabel;

  /// No description provided for @includedLabel.
  ///
  /// In en, this message translates to:
  /// **'Included'**
  String get includedLabel;

  /// No description provided for @separateLabel.
  ///
  /// In en, this message translates to:
  /// **'Separate'**
  String get separateLabel;

  /// No description provided for @electricityEstLabel.
  ///
  /// In en, this message translates to:
  /// **'Electricity (est. monthly)'**
  String get electricityEstLabel;

  /// No description provided for @cookCostLabel.
  ///
  /// In en, this message translates to:
  /// **'Cook cost / month'**
  String get cookCostLabel;

  /// No description provided for @maidCostLabel.
  ///
  /// In en, this message translates to:
  /// **'Maid cost / month'**
  String get maidCostLabel;

  /// No description provided for @setupCostLabel.
  ///
  /// In en, this message translates to:
  /// **'One-time setup cost'**
  String get setupCostLabel;

  /// No description provided for @totalMonthlyOutflow.
  ///
  /// In en, this message translates to:
  /// **'Your estimated monthly cost: {amount}'**
  String totalMonthlyOutflow(String amount);

  /// No description provided for @typicalDayLabel.
  ///
  /// In en, this message translates to:
  /// **'Describe your typical day'**
  String get typicalDayLabel;

  /// No description provided for @typicalDayHint.
  ///
  /// In en, this message translates to:
  /// **'I wake up at 7, work from home till 6, cook dinner...'**
  String get typicalDayHint;

  /// No description provided for @ageRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Preferred flatmate age range'**
  String get ageRangeLabel;

  /// No description provided for @homeNewInCity.
  ///
  /// In en, this message translates to:
  /// **'New in {city}'**
  String homeNewInCity(String city);

  /// No description provided for @homeMovingSoon.
  ///
  /// In en, this message translates to:
  /// **'Moving soon'**
  String get homeMovingSoon;

  /// No description provided for @vibeAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get vibeAll;

  /// No description provided for @vibeQuietFocused.
  ///
  /// In en, this message translates to:
  /// **'Quiet & Focused'**
  String get vibeQuietFocused;

  /// No description provided for @vibeSocialLively.
  ///
  /// In en, this message translates to:
  /// **'Social & Lively'**
  String get vibeSocialLively;

  /// No description provided for @vibeWorkingProf.
  ///
  /// In en, this message translates to:
  /// **'Working Professionals'**
  String get vibeWorkingProf;

  /// No description provided for @vibeStudents.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get vibeStudents;

  /// No description provided for @vibePetHousehold.
  ///
  /// In en, this message translates to:
  /// **'Pet Household'**
  String get vibePetHousehold;

  /// No description provided for @cityCounter.
  ///
  /// In en, this message translates to:
  /// **'{count} people looking in {city} right now'**
  String cityCounter(int count, String city);

  /// No description provided for @waitlistTitle.
  ///
  /// In en, this message translates to:
  /// **'Not enough people yet'**
  String get waitlistTitle;

  /// No description provided for @waitlistSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll notify you when more flatmates join in {city}.'**
  String waitlistSubtitle(String city);

  /// No description provided for @waitlistNotifyCta.
  ///
  /// In en, this message translates to:
  /// **'Notify me'**
  String get waitlistNotifyCta;

  /// No description provided for @shareListingCta.
  ///
  /// In en, this message translates to:
  /// **'Share listing'**
  String get shareListingCta;

  /// No description provided for @listingUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Listing under review'**
  String get listingUnderReview;

  /// No description provided for @listingLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get listingLive;

  /// No description provided for @listingPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get listingPaused;

  /// No description provided for @listingExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get listingExpired;

  /// No description provided for @manageListingTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage listing'**
  String get manageListingTitle;

  /// No description provided for @boostListingCta.
  ///
  /// In en, this message translates to:
  /// **'Boost listing'**
  String get boostListingCta;

  /// No description provided for @pauseListingCta.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pauseListingCta;

  /// No description provided for @editListingCta.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editListingCta;

  /// No description provided for @shareCta.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareCta;

  /// No description provided for @verifiedFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verifiedFilterLabel;

  /// No description provided for @qnaNudgeTitle.
  ///
  /// In en, this message translates to:
  /// **'Break the ice first?'**
  String get qnaNudgeTitle;

  /// No description provided for @qnaNudgeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Answer 3 quick questions to start the conversation.'**
  String get qnaNudgeSubtitle;

  /// No description provided for @qnaQuestion1.
  ///
  /// In en, this message translates to:
  /// **'What does your ideal flatmate situation look like?'**
  String get qnaQuestion1;

  /// No description provided for @qnaQuestion1Hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Someone quiet who respects personal space...'**
  String get qnaQuestion1Hint;

  /// No description provided for @qnaQuestion2.
  ///
  /// In en, this message translates to:
  /// **'How social are you at home on a typical weekday?'**
  String get qnaQuestion2;

  /// No description provided for @qnaQuestion3.
  ///
  /// In en, this message translates to:
  /// **'One thing you absolutely need in a flatmate?'**
  String get qnaQuestion3;

  /// No description provided for @qnaQuestion3Hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Cleanliness, punctuality, honesty...'**
  String get qnaQuestion3Hint;

  /// No description provided for @qnaAnswerCta.
  ///
  /// In en, this message translates to:
  /// **'Answer questions'**
  String get qnaAnswerCta;

  /// No description provided for @qnaSkipCta.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get qnaSkipCta;

  /// No description provided for @waitlistConfirmed.
  ///
  /// In en, this message translates to:
  /// **'You\'re on the list! We\'ll notify you.'**
  String get waitlistConfirmed;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacyTitle;

  /// No description provided for @hideLastNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Hide last name on public profile'**
  String get hideLastNameLabel;

  /// No description provided for @hideExactLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Hide exact location on listings'**
  String get hideExactLocationLabel;

  /// No description provided for @visitConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm this visit?'**
  String get visitConfirmTitle;

  /// No description provided for @visitRescheduleCta.
  ///
  /// In en, this message translates to:
  /// **'Suggest another time'**
  String get visitRescheduleCta;

  /// No description provided for @visitCancelCta.
  ///
  /// In en, this message translates to:
  /// **'Cancel visit'**
  String get visitCancelCta;

  /// No description provided for @visitCancelConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this visit?'**
  String get visitCancelConfirm;

  /// No description provided for @visitConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Visit confirmed'**
  String get visitConfirmed;

  /// No description provided for @visitCancelled.
  ///
  /// In en, this message translates to:
  /// **'Visit cancelled.'**
  String get visitCancelled;

  /// No description provided for @videoTourLabel.
  ///
  /// In en, this message translates to:
  /// **'Video tour (optional)'**
  String get videoTourLabel;

  /// No description provided for @videoTourHint.
  ///
  /// In en, this message translates to:
  /// **'15-30 second vertical video, max 50MB'**
  String get videoTourHint;

  /// No description provided for @addVideoCta.
  ///
  /// In en, this message translates to:
  /// **'Add video tour'**
  String get addVideoCta;

  /// No description provided for @videoTourAdded.
  ///
  /// In en, this message translates to:
  /// **'Video tour added'**
  String get videoTourAdded;

  /// No description provided for @videoTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Video must be under 50MB'**
  String get videoTooLarge;

  /// No description provided for @videoTooLong.
  ///
  /// In en, this message translates to:
  /// **'Video must be under 30 seconds'**
  String get videoTooLong;

  /// No description provided for @superLikeCapLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} Super Likes left today'**
  String superLikeCapLabel(int count);

  /// No description provided for @swipeCounterLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} swipes remaining today'**
  String swipeCounterLabel(int count);

  /// No description provided for @readReceiptSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get readReceiptSent;

  /// No description provided for @readReceiptDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get readReceiptDelivered;

  /// No description provided for @readReceiptRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get readReceiptRead;

  /// No description provided for @chatPollingInfo.
  ///
  /// In en, this message translates to:
  /// **'Messages refresh automatically'**
  String get chatPollingInfo;

  /// No description provided for @flatDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Flat details'**
  String get flatDetailsTitle;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet.'**
  String get notificationEmpty;

  /// No description provided for @helpSafetyTitle.
  ///
  /// In en, this message translates to:
  /// **'Help & Safety'**
  String get helpSafetyTitle;

  /// No description provided for @safetyTips.
  ///
  /// In en, this message translates to:
  /// **'Safety tips'**
  String get safetyTips;

  /// No description provided for @reportProblem.
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get reportProblem;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get contactSupport;

  /// No description provided for @communityGuidelines.
  ///
  /// In en, this message translates to:
  /// **'Community guidelines'**
  String get communityGuidelines;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of service'**
  String get termsOfService;

  /// No description provided for @listingUnderReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Listing under review'**
  String get listingUnderReviewTitle;

  /// No description provided for @underReview.
  ///
  /// In en, this message translates to:
  /// **'Under Review'**
  String get underReview;

  /// No description provided for @reviewTimeline.
  ///
  /// In en, this message translates to:
  /// **'Review timeline'**
  String get reviewTimeline;

  /// No description provided for @goToHomeFeed.
  ///
  /// In en, this message translates to:
  /// **'Go to Home Feed'**
  String get goToHomeFeed;

  /// No description provided for @viewListing.
  ///
  /// In en, this message translates to:
  /// **'View Listing'**
  String get viewListing;

  /// No description provided for @editResubmit.
  ///
  /// In en, this message translates to:
  /// **'Edit & Resubmit'**
  String get editResubmit;

  /// No description provided for @reportListing.
  ///
  /// In en, this message translates to:
  /// **'Report listing'**
  String get reportListing;

  /// No description provided for @compatibilityScore.
  ///
  /// In en, this message translates to:
  /// **'Compatibility score'**
  String get compatibilityScore;

  /// No description provided for @aboutMe.
  ///
  /// In en, this message translates to:
  /// **'About me'**
  String get aboutMe;

  /// No description provided for @flatDetails.
  ///
  /// In en, this message translates to:
  /// **'Flat details'**
  String get flatDetails;

  /// No description provided for @costsBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Costs breakdown'**
  String get costsBreakdown;

  /// No description provided for @moveInDate.
  ///
  /// In en, this message translates to:
  /// **'Move-in date'**
  String get moveInDate;

  /// No description provided for @newMatch.
  ///
  /// In en, this message translates to:
  /// **'New match'**
  String get newMatch;

  /// No description provided for @newMessage.
  ///
  /// In en, this message translates to:
  /// **'New message'**
  String get newMessage;

  /// No description provided for @listingApproved.
  ///
  /// In en, this message translates to:
  /// **'Listing approved'**
  String get listingApproved;

  /// No description provided for @visitScheduled.
  ///
  /// In en, this message translates to:
  /// **'Visit scheduled'**
  String get visitScheduled;

  /// No description provided for @faqTitle.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get faqTitle;

  /// No description provided for @whatHappensNext.
  ///
  /// In en, this message translates to:
  /// **'What happens next'**
  String get whatHappensNext;

  /// No description provided for @aiPreScreen.
  ///
  /// In en, this message translates to:
  /// **'AI pre-screen'**
  String get aiPreScreen;

  /// No description provided for @manualReview.
  ///
  /// In en, this message translates to:
  /// **'Manual review'**
  String get manualReview;

  /// No description provided for @youWillBeNotified.
  ///
  /// In en, this message translates to:
  /// **'You\'ll be notified'**
  String get youWillBeNotified;

  /// No description provided for @notificationChannelName.
  ///
  /// In en, this message translates to:
  /// **'Messages & Matches'**
  String get notificationChannelName;

  /// No description provided for @notificationChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Notifications for new messages, matches, and visits'**
  String get notificationChannelDescription;

  /// No description provided for @reviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review your listing'**
  String get reviewTitle;

  /// No description provided for @reviewLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get reviewLocation;

  /// No description provided for @reviewSociety.
  ///
  /// In en, this message translates to:
  /// **'Society'**
  String get reviewSociety;

  /// No description provided for @reviewRoom.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get reviewRoom;

  /// No description provided for @reviewFlat.
  ///
  /// In en, this message translates to:
  /// **'Flat'**
  String get reviewFlat;

  /// No description provided for @reviewCosts.
  ///
  /// In en, this message translates to:
  /// **'Costs'**
  String get reviewCosts;

  /// No description provided for @reviewAbout.
  ///
  /// In en, this message translates to:
  /// **'About you & preferred flatmate'**
  String get reviewAbout;

  /// No description provided for @editStep.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editStep;

  /// No description provided for @filterApplied.
  ///
  /// In en, this message translates to:
  /// **'Filters applied'**
  String get filterApplied;

  /// No description provided for @noListingsMatchFilters.
  ///
  /// In en, this message translates to:
  /// **'No listings match your filters. Try adjusting them.'**
  String get noListingsMatchFilters;

  /// No description provided for @listingRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get listingRejected;

  /// No description provided for @reviewSupportText.
  ///
  /// In en, this message translates to:
  /// **'We\'ll review your listing within 24 hours'**
  String get reviewSupportText;

  /// No description provided for @reviewStep3Desc.
  ///
  /// In en, this message translates to:
  /// **'You\'ll receive a notification once your listing is approved and live.'**
  String get reviewStep3Desc;

  /// No description provided for @resendOtpCta.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get resendOtpCta;

  /// No description provided for @resendOtpCountdown.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String resendOtpCountdown(int seconds);

  /// No description provided for @otpAutoReadHint.
  ///
  /// In en, this message translates to:
  /// **'We\'ll auto-detect the OTP from your SMS.'**
  String get otpAutoReadHint;

  /// No description provided for @societySectionTitle.
  ///
  /// In en, this message translates to:
  /// **'The Society'**
  String get societySectionTitle;

  /// No description provided for @roomSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'The Room'**
  String get roomSectionTitle;

  /// No description provided for @flatAndFlatmatesSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'The Flat & Flatmates'**
  String get flatAndFlatmatesSectionTitle;

  /// No description provided for @costsBreakdownSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Costs Breakdown'**
  String get costsBreakdownSectionTitle;

  /// No description provided for @monthlyRentRow.
  ///
  /// In en, this message translates to:
  /// **'Monthly rent'**
  String get monthlyRentRow;

  /// No description provided for @securityDepositRow.
  ///
  /// In en, this message translates to:
  /// **'Security deposit'**
  String get securityDepositRow;

  /// No description provided for @maintenanceRow.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get maintenanceRow;

  /// No description provided for @estimatedTotalRow.
  ///
  /// In en, this message translates to:
  /// **'Estimated total / month'**
  String get estimatedTotalRow;

  /// No description provided for @existingFlatmatesLabel.
  ///
  /// In en, this message translates to:
  /// **'Existing flatmates'**
  String get existingFlatmatesLabel;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get notAvailable;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
