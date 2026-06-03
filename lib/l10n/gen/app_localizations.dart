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
  /// **'Find. Connect. Live Together.'**
  String get splashTagline;

  /// No description provided for @splashSubtagline.
  ///
  /// In en, this message translates to:
  /// **'The smarter way to find your flat and flatmates.'**
  String get splashSubtagline;

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
  /// **'Sign in or create an account to get started.'**
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
  /// **'Good afternoon, {name}'**
  String homeGreeting(String name);

  /// No description provided for @homeGreetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning, {name}'**
  String homeGreetingMorning(String name);

  /// No description provided for @homeGreetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon, {name}'**
  String homeGreetingAfternoon(String name);

  /// No description provided for @homeGreetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening, {name}'**
  String homeGreetingEvening(String name);

  /// No description provided for @homeGuestName.
  ///
  /// In en, this message translates to:
  /// **'there'**
  String get homeGuestName;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find your next flatmate in {city}'**
  String homeSubtitle(String city);

  /// No description provided for @homeMarketInsight.
  ///
  /// In en, this message translates to:
  /// **'{count} verified people are actively looking nearby'**
  String homeMarketInsight(int count);

  /// No description provided for @homeMarketInsightCta.
  ///
  /// In en, this message translates to:
  /// **'View active seekers'**
  String get homeMarketInsightCta;

  /// No description provided for @homeLocationFallback.
  ///
  /// In en, this message translates to:
  /// **'Set your city and locality to personalize discovery.'**
  String get homeLocationFallback;

  /// No description provided for @locationUpdated.
  ///
  /// In en, this message translates to:
  /// **'Location updated'**
  String get locationUpdated;

  /// No description provided for @locationPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Location permission is required to detect your city.'**
  String get locationPermissionRequired;

  /// No description provided for @locationDetectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not detect your location. Please select manually.'**
  String get locationDetectionFailed;

  /// No description provided for @homeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search area, budget, flatmate...'**
  String get homeSearchHint;

  /// No description provided for @searchMapHint.
  ///
  /// In en, this message translates to:
  /// **'Search location, sector, society...'**
  String get searchMapHint;

  /// No description provided for @homePickedForYou.
  ///
  /// In en, this message translates to:
  /// **'Best matches for you'**
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

  /// No description provided for @homeNoResultsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your filters or search for a different location.'**
  String get homeNoResultsSubtitle;

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
  /// **'Inbox'**
  String get likesChatTitle;

  /// No description provided for @likesTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Likes You'**
  String get likesTabLabel;

  /// No description provided for @likedTabLabel.
  ///
  /// In en, this message translates to:
  /// **'You Liked'**
  String get likedTabLabel;

  /// No description provided for @chatsTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chatsTabLabel;

  /// No description provided for @likesIncomingLabel.
  ///
  /// In en, this message translates to:
  /// **'You matched. Start the conversation.'**
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
  /// **'Visit the room before paying.'**
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
  /// **'Me'**
  String get profilePageTitle;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile & Settings'**
  String get profileTitle;

  /// No description provided for @profileStrengthTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile strength: {percent}%'**
  String profileStrengthTitle(int percent);

  /// No description provided for @profileStrengthSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Complete 2 steps to get 3x more responses'**
  String get profileStrengthSubtitle;

  /// No description provided for @completeProfileCta.
  ///
  /// In en, this message translates to:
  /// **'Complete profile'**
  String get completeProfileCta;

  /// No description provided for @discoverySectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Discovery'**
  String get discoverySectionLabel;

  /// No description provided for @trustSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Trust'**
  String get trustSectionLabel;

  /// No description provided for @accountSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountSectionLabel;

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
  /// **'Matches & Chat'**
  String get profileMenuLikesChat;

  /// No description provided for @profileMenuPostListing.
  ///
  /// In en, this message translates to:
  /// **'Post Listing'**
  String get profileMenuPostListing;

  /// No description provided for @profileMenuShortlisted.
  ///
  /// In en, this message translates to:
  /// **'Shortlisted'**
  String get profileMenuShortlisted;

  /// No description provided for @profileMenuChats.
  ///
  /// In en, this message translates to:
  /// **'My Chats'**
  String get profileMenuChats;

  /// No description provided for @profileMenuDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get profileMenuDocuments;

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

  /// No description provided for @paletteInkOnPaper.
  ///
  /// In en, this message translates to:
  /// **'Ink on Paper'**
  String get paletteInkOnPaper;

  /// No description provided for @paletteElectricIndigo.
  ///
  /// In en, this message translates to:
  /// **'Paper Blue'**
  String get paletteElectricIndigo;

  /// No description provided for @paletteEmberCoral.
  ///
  /// In en, this message translates to:
  /// **'Warm Clay'**
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
  /// **'Has a room'**
  String get modeRoomPoster;

  /// No description provided for @modeSeeker.
  ///
  /// In en, this message translates to:
  /// **'Looking for a room'**
  String get modeSeeker;

  /// No description provided for @modeCoHunter.
  ///
  /// In en, this message translates to:
  /// **'Looking together'**
  String get modeCoHunter;

  /// No description provided for @modeOpenToBoth.
  ///
  /// In en, this message translates to:
  /// **'Looking for room + flatmate'**
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

  /// No description provided for @budgetMinMaxError.
  ///
  /// In en, this message translates to:
  /// **'Budget minimum cannot exceed maximum'**
  String get budgetMinMaxError;

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

  /// No description provided for @postListingCta.
  ///
  /// In en, this message translates to:
  /// **'List your space in minutes'**
  String get postListingCta;

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
  /// **'Inbox'**
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

  /// No description provided for @navExplore.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navExplore;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get navProfile;

  /// No description provided for @navVisits.
  ///
  /// In en, this message translates to:
  /// **'Visits'**
  String get navVisits;

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

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get onboardingComplete;

  /// No description provided for @onboardingHeadline1.
  ///
  /// In en, this message translates to:
  /// **'Find the right flat. The right flatmates.'**
  String get onboardingHeadline1;

  /// No description provided for @onboardingSubheadline1.
  ///
  /// In en, this message translates to:
  /// **'Verified homes. Compatible flatmates. Better living, together.'**
  String get onboardingSubheadline1;

  /// No description provided for @onboardingHeadline2.
  ///
  /// In en, this message translates to:
  /// **'Your lifestyle matters.'**
  String get onboardingHeadline2;

  /// No description provided for @onboardingSubheadline2.
  ///
  /// In en, this message translates to:
  /// **'We match you with flatmates who share your vibe and values.'**
  String get onboardingSubheadline2;

  /// No description provided for @onboardingHeadline3.
  ///
  /// In en, this message translates to:
  /// **'360 Flatmates finds both.'**
  String get onboardingHeadline3;

  /// No description provided for @onboardingSubheadline3.
  ///
  /// In en, this message translates to:
  /// **'The flat, the flatmate, and the perfect match.'**
  String get onboardingSubheadline3;

  /// No description provided for @onboardingHeadline4.
  ///
  /// In en, this message translates to:
  /// **'Your flatmate journey starts here.'**
  String get onboardingHeadline4;

  /// No description provided for @onboardingSubheadline4.
  ///
  /// In en, this message translates to:
  /// **'Sign up in under 4 minutes and start matching.'**
  String get onboardingSubheadline4;

  /// No description provided for @onboardingSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Setting up your profile...'**
  String get onboardingSubmitting;

  /// No description provided for @modeSelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'I am looking to'**
  String get modeSelectionTitle;

  /// No description provided for @modeSelectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select the option that best describes you'**
  String get modeSelectionSubtitle;

  /// No description provided for @modeRoomPosterDesc.
  ///
  /// In en, this message translates to:
  /// **'I want to list my flat or find a flatmate to fill a spare room.'**
  String get modeRoomPosterDesc;

  /// No description provided for @modeSeekerDesc.
  ///
  /// In en, this message translates to:
  /// **'I\'m looking for a flatmate to search for a place together'**
  String get modeSeekerDesc;

  /// No description provided for @modeCoHunterDesc.
  ///
  /// In en, this message translates to:
  /// **'I want to find a place or a flatmate to stay with.'**
  String get modeCoHunterDesc;

  /// No description provided for @modeOpenToBothDesc.
  ///
  /// In en, this message translates to:
  /// **'I\'ll move into an existing flat or team up to find a new one.'**
  String get modeOpenToBothDesc;

  /// No description provided for @modeContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get modeContinue;

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

  /// No description provided for @profilePhotoMinimumRequired.
  ///
  /// In en, this message translates to:
  /// **'Add at least one photo to continue.'**
  String get profilePhotoMinimumRequired;

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

  /// No description provided for @lifestyleQuizTitle.
  ///
  /// In en, this message translates to:
  /// **'Lifestyle preferences'**
  String get lifestyleQuizTitle;

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
  /// **'View full profile'**
  String get tapToSeeMore;

  /// No description provided for @whyThisMatchWorks.
  ///
  /// In en, this message translates to:
  /// **'WHY THIS MATCH WORKS'**
  String get whyThisMatchWorks;

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
  /// **'Quiet & Focused'**
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

  /// No description provided for @qnaBothAnsweredBanner.
  ///
  /// In en, this message translates to:
  /// **'Both answered'**
  String get qnaBothAnsweredBanner;

  /// No description provided for @qnaPeerAnsweredBanner.
  ///
  /// In en, this message translates to:
  /// **'{peerName} answered'**
  String qnaPeerAnsweredBanner(String peerName);

  /// No description provided for @qnaYouAnsweredBanner.
  ///
  /// In en, this message translates to:
  /// **'Your answers are saved'**
  String get qnaYouAnsweredBanner;

  /// No description provided for @qnaPeerAnsweredPrompt.
  ///
  /// In en, this message translates to:
  /// **'Share yours to unlock stronger context before you meet.'**
  String get qnaPeerAnsweredPrompt;

  /// No description provided for @qnaTheirAnswers.
  ///
  /// In en, this message translates to:
  /// **'{peerName}\'s answers'**
  String qnaTheirAnswers(String peerName);

  /// No description provided for @qnaYourAnswers.
  ///
  /// In en, this message translates to:
  /// **'Your answers'**
  String get qnaYourAnswers;

  /// No description provided for @waitlistConfirmed.
  ///
  /// In en, this message translates to:
  /// **'You\'re on the list! We\'ll notify you.'**
  String get waitlistConfirmed;

  /// No description provided for @waitlistInviteFriends.
  ///
  /// In en, this message translates to:
  /// **'Invite Friends'**
  String get waitlistInviteFriends;

  /// No description provided for @waitlistShareMessage.
  ///
  /// In en, this message translates to:
  /// **'360 FlatMates is opening in {city}. Join the waitlist and help bring more flatmates here:\n{url}'**
  String waitlistShareMessage(String city, String url);

  /// No description provided for @yourNumberIsPrivate.
  ///
  /// In en, this message translates to:
  /// **'Your number is kept private'**
  String get yourNumberIsPrivate;

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

  /// No description provided for @visitConfirmCta.
  ///
  /// In en, this message translates to:
  /// **'Confirm visit'**
  String get visitConfirmCta;

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

  /// No description provided for @videoTooShort.
  ///
  /// In en, this message translates to:
  /// **'Video must be at least 15 seconds'**
  String get videoTooShort;

  /// No description provided for @tapToUnmute.
  ///
  /// In en, this message translates to:
  /// **'Tap to unmute'**
  String get tapToUnmute;

  /// No description provided for @soundOn.
  ///
  /// In en, this message translates to:
  /// **'Sound on'**
  String get soundOn;

  /// No description provided for @superLikeCapLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} Super Likes left'**
  String superLikeCapLabel(int count);

  /// No description provided for @swipeCounterLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} swipes left today'**
  String swipeCounterLabel(int count);

  /// No description provided for @passActionLabel.
  ///
  /// In en, this message translates to:
  /// **'Pass'**
  String get passActionLabel;

  /// No description provided for @superLikeActionLabel.
  ///
  /// In en, this message translates to:
  /// **'Star Match'**
  String get superLikeActionLabel;

  /// No description provided for @likeActionLabel.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get likeActionLabel;

  /// No description provided for @photoPendingLabel.
  ///
  /// In en, this message translates to:
  /// **'Photo pending'**
  String get photoPendingLabel;

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

  /// No description provided for @reportListingTitle.
  ///
  /// In en, this message translates to:
  /// **'Report this listing'**
  String get reportListingTitle;

  /// No description provided for @reportListingReason.
  ///
  /// In en, this message translates to:
  /// **'Why are you reporting this listing?'**
  String get reportListingReason;

  /// No description provided for @reportListingSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Thank you. We will review this listing.'**
  String get reportListingSubmitted;

  /// No description provided for @reportReasonInappropriate.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate content'**
  String get reportReasonInappropriate;

  /// No description provided for @reportReasonScam.
  ///
  /// In en, this message translates to:
  /// **'Suspected scam or fraud'**
  String get reportReasonScam;

  /// No description provided for @reportReasonOutdated.
  ///
  /// In en, this message translates to:
  /// **'Listing is outdated or unavailable'**
  String get reportReasonOutdated;

  /// No description provided for @reportReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get reportReasonOther;

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

  /// No description provided for @perPersonCostLabel.
  ///
  /// In en, this message translates to:
  /// **'Per person (approx.)'**
  String get perPersonCostLabel;

  /// No description provided for @changePasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePasswordLabel;

  /// No description provided for @privacySecurityLabel.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Security'**
  String get privacySecurityLabel;

  /// No description provided for @preferencesLabel.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferencesLabel;

  /// No description provided for @notificationSettingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettingsLabel;

  /// No description provided for @notificationSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification Preferences'**
  String get notificationSettingsTitle;

  /// No description provided for @notificationSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose which notifications you want to receive'**
  String get notificationSettingsSubtitle;

  /// No description provided for @notifNewMessages.
  ///
  /// In en, this message translates to:
  /// **'New Messages'**
  String get notifNewMessages;

  /// No description provided for @notifNewMessagesDesc.
  ///
  /// In en, this message translates to:
  /// **'Get notified when you receive a new message'**
  String get notifNewMessagesDesc;

  /// No description provided for @notifVisitReminders.
  ///
  /// In en, this message translates to:
  /// **'Visit Reminders'**
  String get notifVisitReminders;

  /// No description provided for @notifVisitRemindersDesc.
  ///
  /// In en, this message translates to:
  /// **'Reminders for upcoming property visits'**
  String get notifVisitRemindersDesc;

  /// No description provided for @notifNewMatches.
  ///
  /// In en, this message translates to:
  /// **'New Matches'**
  String get notifNewMatches;

  /// No description provided for @notifNewMatchesDesc.
  ///
  /// In en, this message translates to:
  /// **'Get notified when someone likes your profile'**
  String get notifNewMatchesDesc;

  /// No description provided for @notifListingUpdates.
  ///
  /// In en, this message translates to:
  /// **'Listing Updates'**
  String get notifListingUpdates;

  /// No description provided for @notifListingUpdatesDesc.
  ///
  /// In en, this message translates to:
  /// **'Updates about your listing views and interest'**
  String get notifListingUpdatesDesc;

  /// No description provided for @notifPromotions.
  ///
  /// In en, this message translates to:
  /// **'Promotions & Tips'**
  String get notifPromotions;

  /// No description provided for @notifPromotionsDesc.
  ///
  /// In en, this message translates to:
  /// **'Offers, tips, and product updates'**
  String get notifPromotionsDesc;

  /// No description provided for @notifEnableAll.
  ///
  /// In en, this message translates to:
  /// **'Enable All'**
  String get notifEnableAll;

  /// No description provided for @notifDisableAll.
  ///
  /// In en, this message translates to:
  /// **'Disable All'**
  String get notifDisableAll;

  /// No description provided for @blockedUsersLabel.
  ///
  /// In en, this message translates to:
  /// **'Blocked Users'**
  String get blockedUsersLabel;

  /// No description provided for @noBlockedUsers.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t blocked anyone yet.'**
  String get noBlockedUsers;

  /// No description provided for @unblockCta.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblockCta;

  /// No description provided for @userUnblocked.
  ///
  /// In en, this message translates to:
  /// **'User has been unblocked.'**
  String get userUnblocked;

  /// No description provided for @unblockFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not unblock this user.'**
  String get unblockFailed;

  /// No description provided for @newPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPasswordLabel;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPasswordLabel;

  /// No description provided for @updatePasswordCta.
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get updatePasswordCta;

  /// No description provided for @passwordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated.'**
  String get passwordUpdated;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordsDoNotMatch;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters.'**
  String get passwordMinLength;

  /// No description provided for @aboutLabel.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutLabel;

  /// No description provided for @termsAndConditionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsAndConditionsLabel;

  /// No description provided for @termsAgreementPrefix.
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get termsAgreementPrefix;

  /// No description provided for @termsAgreementConjunction.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get termsAgreementConjunction;

  /// No description provided for @searchHelpPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search for help'**
  String get searchHelpPlaceholder;

  /// No description provided for @faqSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find answers to common questions'**
  String get faqSubtitle;

  /// No description provided for @popularTopicsLabel.
  ///
  /// In en, this message translates to:
  /// **'Popular Topics'**
  String get popularTopicsLabel;

  /// No description provided for @popularTopicsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Explore trending help topics'**
  String get popularTopicsSubtitle;

  /// No description provided for @bookingAgreementsLabel.
  ///
  /// In en, this message translates to:
  /// **'Booking & Agreements'**
  String get bookingAgreementsLabel;

  /// No description provided for @bookingAgreementsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Bookings, agreements & policies'**
  String get bookingAgreementsSubtitle;

  /// No description provided for @accountProfileLabel.
  ///
  /// In en, this message translates to:
  /// **'Account & Profile'**
  String get accountProfileLabel;

  /// No description provided for @accountProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your account and profile'**
  String get accountProfileSubtitle;

  /// No description provided for @contactSupportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get in touch with our support team'**
  String get contactSupportSubtitle;

  /// No description provided for @chatWithUsCta.
  ///
  /// In en, this message translates to:
  /// **'Chat with Us'**
  String get chatWithUsCta;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @replyTimeNote.
  ///
  /// In en, this message translates to:
  /// **'We usually reply in a few minutes'**
  String get replyTimeNote;

  /// No description provided for @helpFaqIntro.
  ///
  /// In en, this message translates to:
  /// **'Quick answers for the most common 360 FlatMates questions.'**
  String get helpFaqIntro;

  /// No description provided for @helpFaqStartTitle.
  ///
  /// In en, this message translates to:
  /// **'How do I start finding a flatmate?'**
  String get helpFaqStartTitle;

  /// No description provided for @helpFaqStartBody.
  ///
  /// In en, this message translates to:
  /// **'Complete onboarding, set your city and budget, then use Discover, Map, Swipe, and Chats to connect with relevant flatmates or listings.'**
  String get helpFaqStartBody;

  /// No description provided for @helpFaqSafetyTitle.
  ///
  /// In en, this message translates to:
  /// **'How should I stay safe before meeting?'**
  String get helpFaqSafetyTitle;

  /// No description provided for @helpFaqSafetyBody.
  ///
  /// In en, this message translates to:
  /// **'Keep early conversations in the app, meet in a familiar or shared place, verify rent and deposit details, and do not send sensitive documents before you trust the other person.'**
  String get helpFaqSafetyBody;

  /// No description provided for @helpFaqReportTitle.
  ///
  /// In en, this message translates to:
  /// **'How do I report or block someone?'**
  String get helpFaqReportTitle;

  /// No description provided for @helpFaqReportBody.
  ///
  /// In en, this message translates to:
  /// **'Open the chat with that person and use the report or block actions. Reports are sent to the 360 FlatMates team for review.'**
  String get helpFaqReportBody;

  /// No description provided for @helpFaqListingTitle.
  ///
  /// In en, this message translates to:
  /// **'How do I list my flat?'**
  String get helpFaqListingTitle;

  /// No description provided for @helpFaqListingBody.
  ///
  /// In en, this message translates to:
  /// **'Use Post Listing from your profile, complete the required flat details, and submit it for review before it appears to other users.'**
  String get helpFaqListingBody;

  /// No description provided for @helpPopularIntro.
  ///
  /// In en, this message translates to:
  /// **'The most useful safety and support topics for active users.'**
  String get helpPopularIntro;

  /// No description provided for @helpPopularMeetingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Safer first meetings'**
  String get helpPopularMeetingsTitle;

  /// No description provided for @helpPopularMeetingsBody.
  ///
  /// In en, this message translates to:
  /// **'Meet during the day when possible, tell someone you trust where you are going, and avoid cash handovers until terms are clear.'**
  String get helpPopularMeetingsBody;

  /// No description provided for @helpPopularVerifiedTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile trust basics'**
  String get helpPopularVerifiedTitle;

  /// No description provided for @helpPopularVerifiedBody.
  ///
  /// In en, this message translates to:
  /// **'Use your real name, add a clear profile photo, and keep lifestyle preferences accurate so matches can evaluate compatibility.'**
  String get helpPopularVerifiedBody;

  /// No description provided for @helpPopularVisitsTitle.
  ///
  /// In en, this message translates to:
  /// **'Chats and visits'**
  String get helpPopularVisitsTitle;

  /// No description provided for @helpPopularVisitsBody.
  ///
  /// In en, this message translates to:
  /// **'Use in-app chats to confirm availability, schedule visits from listing or conversation screens, and keep important decisions written down.'**
  String get helpPopularVisitsBody;

  /// No description provided for @helpBookingsIntro.
  ///
  /// In en, this message translates to:
  /// **'Guidance for visits, agreements, and listing review. 360 FlatMates helps you connect; final rental terms stay between the people involved.'**
  String get helpBookingsIntro;

  /// No description provided for @helpBookingsDecisionTitle.
  ///
  /// In en, this message translates to:
  /// **'Before confirming a move'**
  String get helpBookingsDecisionTitle;

  /// No description provided for @helpBookingsDecisionBody.
  ///
  /// In en, this message translates to:
  /// **'Confirm monthly rent, deposit, maintenance, move-in date, notice period, house rules, and who will be named on the agreement.'**
  String get helpBookingsDecisionBody;

  /// No description provided for @helpBookingsAgreementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Agreements and documents'**
  String get helpBookingsAgreementsTitle;

  /// No description provided for @helpBookingsAgreementsBody.
  ///
  /// In en, this message translates to:
  /// **'Keep written copies of agreed terms and verify IDs or ownership details through trusted channels before signing or paying outside the app.'**
  String get helpBookingsAgreementsBody;

  /// No description provided for @helpBookingsListingReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Listing review'**
  String get helpBookingsListingReviewTitle;

  /// No description provided for @helpBookingsListingReviewBody.
  ///
  /// In en, this message translates to:
  /// **'Submitted listings may be reviewed for quality and safety before going live. You can edit and resubmit if details change.'**
  String get helpBookingsListingReviewBody;

  /// No description provided for @helpAccountIntro.
  ///
  /// In en, this message translates to:
  /// **'Manage profile, password, privacy, and blocked users from one safe place.'**
  String get helpAccountIntro;

  /// No description provided for @helpAccountEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit profile details'**
  String get helpAccountEditTitle;

  /// No description provided for @helpAccountEditBody.
  ///
  /// In en, this message translates to:
  /// **'Keep your photo, location, budget, move-in timeline, and lifestyle answers current so recommendations stay relevant.'**
  String get helpAccountEditBody;

  /// No description provided for @helpAccountPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy controls'**
  String get helpAccountPrivacyTitle;

  /// No description provided for @helpAccountPrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'Use Settings to manage theme, language, and privacy preferences such as hiding your last name or exact location.'**
  String get helpAccountPrivacyBody;

  /// No description provided for @helpAccountBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Blocked users'**
  String get helpAccountBlockedTitle;

  /// No description provided for @helpAccountBlockedBody.
  ///
  /// In en, this message translates to:
  /// **'Blocked people cannot contact you through the app. You can review and unblock them from Blocked Users.'**
  String get helpAccountBlockedBody;

  /// No description provided for @helpContactIntro.
  ///
  /// In en, this message translates to:
  /// **'Contact support when something looks wrong, unsafe, or stuck.'**
  String get helpContactIntro;

  /// No description provided for @helpContactWhatToSendTitle.
  ///
  /// In en, this message translates to:
  /// **'What to include'**
  String get helpContactWhatToSendTitle;

  /// No description provided for @helpContactWhatToSendBody.
  ///
  /// In en, this message translates to:
  /// **'Send your phone number, the listing or conversation involved, screenshots if useful, and a short description of what happened.'**
  String get helpContactWhatToSendBody;

  /// No description provided for @helpContactUrgentTitle.
  ///
  /// In en, this message translates to:
  /// **'Urgent safety issues'**
  String get helpContactUrgentTitle;

  /// No description provided for @helpContactUrgentBody.
  ///
  /// In en, this message translates to:
  /// **'If there is immediate danger, contact local emergency services first, then report the issue to support with the details you can safely share.'**
  String get helpContactUrgentBody;

  /// No description provided for @emailSupportCta.
  ///
  /// In en, this message translates to:
  /// **'Email support'**
  String get emailSupportCta;

  /// No description provided for @supportEmailSubject.
  ///
  /// In en, this message translates to:
  /// **'360 FlatMates support request'**
  String get supportEmailSubject;

  /// No description provided for @supportEmailBody.
  ///
  /// In en, this message translates to:
  /// **'Hi 360 FlatMates Support, I need help with:'**
  String get supportEmailBody;

  /// No description provided for @supportEmailFallback.
  ///
  /// In en, this message translates to:
  /// **'Email us at {email}'**
  String supportEmailFallback(String email);

  /// No description provided for @externalLinkUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Could not open this link. Please try again.'**
  String get externalLinkUnavailable;

  /// No description provided for @stepLabel.
  ///
  /// In en, this message translates to:
  /// **'Step'**
  String get stepLabel;

  /// No description provided for @stepOfLabel.
  ///
  /// In en, this message translates to:
  /// **'of'**
  String get stepOfLabel;

  /// No description provided for @societyBuildingHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Prestige Lakeside'**
  String get societyBuildingHint;

  /// No description provided for @fullAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Enter full address'**
  String get fullAddressHint;

  /// No description provided for @monthlyRentHint.
  ///
  /// In en, this message translates to:
  /// **'Enter monthly rent'**
  String get monthlyRentHint;

  /// No description provided for @securityDepositHint.
  ///
  /// In en, this message translates to:
  /// **'Enter deposit amount'**
  String get securityDepositHint;

  /// No description provided for @maintenanceHint.
  ///
  /// In en, this message translates to:
  /// **'Enter maintenance charges'**
  String get maintenanceHint;

  /// No description provided for @electricityEstHint.
  ///
  /// In en, this message translates to:
  /// **'Estimated monthly electricity cost'**
  String get electricityEstHint;

  /// No description provided for @cookCostHint.
  ///
  /// In en, this message translates to:
  /// **'Cook charges per month'**
  String get cookCostHint;

  /// No description provided for @maidCostHint.
  ///
  /// In en, this message translates to:
  /// **'Maid charges per month'**
  String get maidCostHint;

  /// No description provided for @setupCostHint.
  ///
  /// In en, this message translates to:
  /// **'One-time setup cost'**
  String get setupCostHint;

  /// No description provided for @activeListingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Active Listings'**
  String get activeListingsLabel;

  /// No description provided for @draftsLabel.
  ///
  /// In en, this message translates to:
  /// **'Drafts'**
  String get draftsLabel;

  /// No description provided for @expiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expiredLabel;

  /// No description provided for @listingRejectedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your listing was not approved.'**
  String get listingRejectedMessage;

  /// No description provided for @reviewSubmittedMessage.
  ///
  /// In en, this message translates to:
  /// **'Thank you! Your listing has been submitted for review.'**
  String get reviewSubmittedMessage;

  /// No description provided for @reviewListingCta.
  ///
  /// In en, this message translates to:
  /// **'Review Listing'**
  String get reviewListingCta;

  /// No description provided for @etaHighlight.
  ///
  /// In en, this message translates to:
  /// **'We\'ll review your listing within 24 hours'**
  String get etaHighlight;

  /// No description provided for @step1Text.
  ///
  /// In en, this message translates to:
  /// **'Our team reviews your listing for quality and safety.'**
  String get step1Text;

  /// No description provided for @step2Text.
  ///
  /// In en, this message translates to:
  /// **'We\'ll notify you once your listing is live.'**
  String get step2Text;

  /// No description provided for @step3Text.
  ///
  /// In en, this message translates to:
  /// **'Go live and start connecting!'**
  String get step3Text;

  /// No description provided for @yourListingLabel.
  ///
  /// In en, this message translates to:
  /// **'Your listing'**
  String get yourListingLabel;

  /// No description provided for @budgetFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budgetFilterLabel;

  /// No description provided for @budgetRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'₹{min} – ₹{max}'**
  String budgetRangeLabel(String min, String max);

  /// No description provided for @roomTypeFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Room Type'**
  String get roomTypeFilterLabel;

  /// No description provided for @roomTypeAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get roomTypeAny;

  /// No description provided for @roomTypePrivate.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get roomTypePrivate;

  /// No description provided for @roomTypeShared.
  ///
  /// In en, this message translates to:
  /// **'Shared'**
  String get roomTypeShared;

  /// No description provided for @furnishingFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Furnishing'**
  String get furnishingFilterLabel;

  /// No description provided for @furnishingAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get furnishingAny;

  /// No description provided for @furnishingFurnished.
  ///
  /// In en, this message translates to:
  /// **'Furnished'**
  String get furnishingFurnished;

  /// No description provided for @furnishingUnfurnished.
  ///
  /// In en, this message translates to:
  /// **'Unfurnished'**
  String get furnishingUnfurnished;

  /// No description provided for @genderFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get genderFilterLabel;

  /// No description provided for @genderFilterAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get genderFilterAny;

  /// No description provided for @genderFilterMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderFilterMale;

  /// No description provided for @genderFilterFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFilterFemale;

  /// No description provided for @moveInFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Move-in'**
  String get moveInFilterLabel;

  /// No description provided for @moveInAnytime.
  ///
  /// In en, this message translates to:
  /// **'Anytime'**
  String get moveInAnytime;

  /// No description provided for @moveInImmediate.
  ///
  /// In en, this message translates to:
  /// **'Immediate'**
  String get moveInImmediate;

  /// No description provided for @moveInThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get moveInThisMonth;

  /// No description provided for @moveInNextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next Month'**
  String get moveInNextMonth;

  /// No description provided for @moreFiltersLabel.
  ///
  /// In en, this message translates to:
  /// **'More Filters'**
  String get moreFiltersLabel;

  /// No description provided for @petsLabel.
  ///
  /// In en, this message translates to:
  /// **'Pets'**
  String get petsLabel;

  /// No description provided for @petsYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get petsYes;

  /// No description provided for @petsNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get petsNo;

  /// No description provided for @petsNoPreference.
  ///
  /// In en, this message translates to:
  /// **'No Preference'**
  String get petsNoPreference;

  /// No description provided for @smokingLabel.
  ///
  /// In en, this message translates to:
  /// **'Smoking'**
  String get smokingLabel;

  /// No description provided for @smokingNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get smokingNo;

  /// No description provided for @smokingYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get smokingYes;

  /// No description provided for @smokingNoPreference.
  ///
  /// In en, this message translates to:
  /// **'No Preference'**
  String get smokingNoPreference;

  /// No description provided for @nearbyChipLabel.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get nearbyChipLabel;

  /// No description provided for @budgetPlusChipLabel.
  ///
  /// In en, this message translates to:
  /// **'Budget+'**
  String get budgetPlusChipLabel;

  /// No description provided for @chatInputHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get chatInputHint;

  /// No description provided for @phoneNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Phone number not available'**
  String get phoneNotAvailable;

  /// No description provided for @emojiPickerComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Emoji picker coming soon'**
  String get emojiPickerComingSoon;

  /// No description provided for @preferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferencesTitle;

  /// No description provided for @preferencesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us what matters to you so we can find the right flatmates and homes.'**
  String get preferencesSubtitle;

  /// No description provided for @prefGenderLabel.
  ///
  /// In en, this message translates to:
  /// **'Preferred Gender'**
  String get prefGenderLabel;

  /// No description provided for @prefFlatmatesLabel.
  ///
  /// In en, this message translates to:
  /// **'Allowed Flatmates'**
  String get prefFlatmatesLabel;

  /// No description provided for @prefFoodLabel.
  ///
  /// In en, this message translates to:
  /// **'Food Habits'**
  String get prefFoodLabel;

  /// No description provided for @prefPetsLabel.
  ///
  /// In en, this message translates to:
  /// **'Pets'**
  String get prefPetsLabel;

  /// No description provided for @prefSmokingLabel.
  ///
  /// In en, this message translates to:
  /// **'Smoking'**
  String get prefSmokingLabel;

  /// No description provided for @prefMoveInLabel.
  ///
  /// In en, this message translates to:
  /// **'Move-in Timeline'**
  String get prefMoveInLabel;

  /// No description provided for @prefNoPreference.
  ///
  /// In en, this message translates to:
  /// **'No Preference'**
  String get prefNoPreference;

  /// No description provided for @prefMaleOnly.
  ///
  /// In en, this message translates to:
  /// **'Male Only'**
  String get prefMaleOnly;

  /// No description provided for @prefFemaleOnly.
  ///
  /// In en, this message translates to:
  /// **'Female Only'**
  String get prefFemaleOnly;

  /// No description provided for @prefOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get prefOther;

  /// No description provided for @prefVeg.
  ///
  /// In en, this message translates to:
  /// **'Veg'**
  String get prefVeg;

  /// No description provided for @prefNonVeg.
  ///
  /// In en, this message translates to:
  /// **'Non-Veg'**
  String get prefNonVeg;

  /// No description provided for @prefEggetarian.
  ///
  /// In en, this message translates to:
  /// **'Eggetarian'**
  String get prefEggetarian;

  /// No description provided for @prefYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get prefYes;

  /// No description provided for @prefNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get prefNo;

  /// No description provided for @prefNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get prefNext;

  /// No description provided for @settingsGroupAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsGroupAccount;

  /// No description provided for @settingsGroupApp.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get settingsGroupApp;

  /// No description provided for @settingsGroupLegal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get settingsGroupLegal;

  /// No description provided for @qnaShareAnswers.
  ///
  /// In en, this message translates to:
  /// **'Share Answers'**
  String get qnaShareAnswers;

  /// No description provided for @qnaSkipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get qnaSkipForNow;

  /// No description provided for @qnaVeryPrivate.
  ///
  /// In en, this message translates to:
  /// **'Very private'**
  String get qnaVeryPrivate;

  /// No description provided for @qnaVerySocial.
  ///
  /// In en, this message translates to:
  /// **'Very social'**
  String get qnaVerySocial;

  /// No description provided for @aboutThisFlatSection.
  ///
  /// In en, this message translates to:
  /// **'About this Flat'**
  String get aboutThisFlatSection;

  /// No description provided for @shortlistCta.
  ///
  /// In en, this message translates to:
  /// **'Shortlist'**
  String get shortlistCta;

  /// No description provided for @contactCta.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contactCta;

  /// No description provided for @postedOnLabel.
  ///
  /// In en, this message translates to:
  /// **'Posted on'**
  String get postedOnLabel;

  /// No description provided for @verifiedListingLabel.
  ///
  /// In en, this message translates to:
  /// **'Verified listing'**
  String get verifiedListingLabel;

  /// No description provided for @moveInCountdownBadge.
  ///
  /// In en, this message translates to:
  /// **'Moving in {days} days'**
  String moveInCountdownBadge(int days);

  /// No description provided for @moveInToday.
  ///
  /// In en, this message translates to:
  /// **'Moving in today'**
  String get moveInToday;

  /// No description provided for @vibeSocial.
  ///
  /// In en, this message translates to:
  /// **'Social & Lively'**
  String get vibeSocial;

  /// No description provided for @vibeProfessional.
  ///
  /// In en, this message translates to:
  /// **'Professionals'**
  String get vibeProfessional;

  /// No description provided for @vibeStudent.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get vibeStudent;

  /// No description provided for @vibePet.
  ///
  /// In en, this message translates to:
  /// **'Pet Household'**
  String get vibePet;

  /// No description provided for @addPhotosTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Photos'**
  String get addPhotosTitle;

  /// No description provided for @addPhotosTips.
  ///
  /// In en, this message translates to:
  /// **'Tips'**
  String get addPhotosTips;

  /// No description provided for @addPhotosInstruction.
  ///
  /// In en, this message translates to:
  /// **'Add clear photos of the room and common areas to get more matches.'**
  String get addPhotosInstruction;

  /// No description provided for @photoTipNaturalLight.
  ///
  /// In en, this message translates to:
  /// **'• Use natural lighting — open curtains before shooting'**
  String get photoTipNaturalLight;

  /// No description provided for @photoTipFullRoom.
  ///
  /// In en, this message translates to:
  /// **'• Show the full room from corner to corner'**
  String get photoTipFullRoom;

  /// No description provided for @photoTipBathroomBalcony.
  ///
  /// In en, this message translates to:
  /// **'• Include bathroom and balcony if available'**
  String get photoTipBathroomBalcony;

  /// No description provided for @photoTipCleanRoom.
  ///
  /// In en, this message translates to:
  /// **'• Clean up before taking photos'**
  String get photoTipCleanRoom;

  /// No description provided for @addMorePhotosLabel.
  ///
  /// In en, this message translates to:
  /// **'Add more photos'**
  String get addMorePhotosLabel;

  /// No description provided for @waitlistNudgeTitle.
  ///
  /// In en, this message translates to:
  /// **'Not many flatmates in {city} yet'**
  String waitlistNudgeTitle(String city);

  /// No description provided for @waitlistNudgeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll notify you when more people join'**
  String get waitlistNudgeSubtitle;

  /// No description provided for @waitlistNotifyMe.
  ///
  /// In en, this message translates to:
  /// **'Notify Me'**
  String get waitlistNotifyMe;

  /// No description provided for @cityCounterShort.
  ///
  /// In en, this message translates to:
  /// **'{count} looking in {city}'**
  String cityCounterShort(int count, String city);

  /// No description provided for @scheduleVisitTitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule Visit'**
  String get scheduleVisitTitle;

  /// No description provided for @selectTimeSlot.
  ///
  /// In en, this message translates to:
  /// **'Select Time Slot'**
  String get selectTimeSlot;

  /// No description provided for @timeSlotMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get timeSlotMorning;

  /// No description provided for @timeSlotAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get timeSlotAfternoon;

  /// No description provided for @timeSlotEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get timeSlotEvening;

  /// No description provided for @addNoteOptional.
  ///
  /// In en, this message translates to:
  /// **'Add a Note (Optional)'**
  String get addNoteOptional;

  /// No description provided for @visitPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Your visit request will be shared with {name}.'**
  String visitPrivacyNote(String name);

  /// No description provided for @sendingLabel.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get sendingLabel;

  /// No description provided for @sendRequestCta.
  ///
  /// In en, this message translates to:
  /// **'Send Request'**
  String get sendRequestCta;

  /// No description provided for @matchedOnDate.
  ///
  /// In en, this message translates to:
  /// **'Matched on {date}'**
  String matchedOnDate(String date);

  /// No description provided for @locationSelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Select your preferred location'**
  String get locationSelectionTitle;

  /// No description provided for @searchLocationPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search location'**
  String get searchLocationPlaceholder;

  /// No description provided for @useCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my current location'**
  String get useCurrentLocation;

  /// No description provided for @detectingLocation.
  ///
  /// In en, this message translates to:
  /// **'Detecting location...'**
  String get detectingLocation;

  /// No description provided for @popularCitiesLabel.
  ///
  /// In en, this message translates to:
  /// **'POPULAR CITIES'**
  String get popularCitiesLabel;

  /// No description provided for @noLocationsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No locations available'**
  String get noLocationsAvailable;

  /// No description provided for @clusterListingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Listings in this area'**
  String get clusterListingsTitle;

  /// No description provided for @clusterListingsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} listings'**
  String clusterListingsCount(int count);

  /// No description provided for @shareToWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Share to WhatsApp'**
  String get shareToWhatsapp;

  /// No description provided for @whatsappNotInstalled.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp is not installed'**
  String get whatsappNotInstalled;

  /// No description provided for @scanToOpen.
  ///
  /// In en, this message translates to:
  /// **'Scan to open listing'**
  String get scanToOpen;

  /// No description provided for @matchItsAMatch.
  ///
  /// In en, this message translates to:
  /// **'Great Match!'**
  String get matchItsAMatch;

  /// No description provided for @matchLikedEachOther.
  ///
  /// In en, this message translates to:
  /// **'You and {peerName} liked each other'**
  String matchLikedEachOther(String peerName);

  /// No description provided for @matchSendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send a message'**
  String get matchSendMessage;

  /// No description provided for @matchKeepSwiping.
  ///
  /// In en, this message translates to:
  /// **'Keep swiping'**
  String get matchKeepSwiping;

  /// No description provided for @swipeNoMoreProfiles.
  ///
  /// In en, this message translates to:
  /// **'No more profiles'**
  String get swipeNoMoreProfiles;

  /// No description provided for @swipeCheckBackLater.
  ///
  /// In en, this message translates to:
  /// **'Check back later for new matches'**
  String get swipeCheckBackLater;

  /// No description provided for @swipeLikeLabel.
  ///
  /// In en, this message translates to:
  /// **'LIKE'**
  String get swipeLikeLabel;

  /// No description provided for @swipeNopeLabel.
  ///
  /// In en, this message translates to:
  /// **'PASS'**
  String get swipeNopeLabel;

  /// No description provided for @failedToLoadProfiles.
  ///
  /// In en, this message translates to:
  /// **'Failed to load profiles'**
  String get failedToLoadProfiles;

  /// No description provided for @actionFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'Action failed. Please try again.'**
  String get actionFailedRetry;

  /// No description provided for @wifiChipLabel.
  ///
  /// In en, this message translates to:
  /// **'WiFi'**
  String get wifiChipLabel;

  /// No description provided for @parkingChipLabel.
  ///
  /// In en, this message translates to:
  /// **'Parking'**
  String get parkingChipLabel;

  /// No description provided for @liftChipLabel.
  ///
  /// In en, this message translates to:
  /// **'Lift'**
  String get liftChipLabel;

  /// No description provided for @securityChipLabel.
  ///
  /// In en, this message translates to:
  /// **'24/7 Security'**
  String get securityChipLabel;

  /// No description provided for @noDescriptionAvailable.
  ///
  /// In en, this message translates to:
  /// **'No description available.'**
  String get noDescriptionAvailable;

  /// No description provided for @flexibleLabel.
  ///
  /// In en, this message translates to:
  /// **'Flexible'**
  String get flexibleLabel;

  /// No description provided for @recentlyLabel.
  ///
  /// In en, this message translates to:
  /// **'Recently'**
  String get recentlyLabel;

  /// No description provided for @safetyCheckedLabel.
  ///
  /// In en, this message translates to:
  /// **'Safety Checked'**
  String get safetyCheckedLabel;

  /// No description provided for @couldNotLoadListing.
  ///
  /// In en, this message translates to:
  /// **'Could not load listing'**
  String get couldNotLoadListing;

  /// No description provided for @startAConversation.
  ///
  /// In en, this message translates to:
  /// **'Start a conversation'**
  String get startAConversation;

  /// No description provided for @sayHelloOrIcebreaker.
  ///
  /// In en, this message translates to:
  /// **'Say hello or use an icebreaker'**
  String get sayHelloOrIcebreaker;

  /// No description provided for @messagesArePrivate.
  ///
  /// In en, this message translates to:
  /// **'Messages are private'**
  String get messagesArePrivate;

  /// No description provided for @viewLabel.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get viewLabel;

  /// No description provided for @byOwnerLabel.
  ///
  /// In en, this message translates to:
  /// **'by {name}'**
  String byOwnerLabel(String name);

  /// No description provided for @couldNotLoadMessages.
  ///
  /// In en, this message translates to:
  /// **'Could not load messages'**
  String get couldNotLoadMessages;

  /// No description provided for @failedToSendMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to send message. Please try again.'**
  String get failedToSendMessage;

  /// No description provided for @failedToBlockUser.
  ///
  /// In en, this message translates to:
  /// **'Failed to block user. Please try again.'**
  String get failedToBlockUser;

  /// No description provided for @failedToReportUser.
  ///
  /// In en, this message translates to:
  /// **'Failed to report user. Please try again.'**
  String get failedToReportUser;

  /// No description provided for @failedToUnmatch.
  ///
  /// In en, this message translates to:
  /// **'Failed to unmatch. Please try again.'**
  String get failedToUnmatch;

  /// No description provided for @failedToSendPhoto.
  ///
  /// In en, this message translates to:
  /// **'Failed to send photo. Please try again.'**
  String get failedToSendPhoto;

  /// No description provided for @couldNotLoadVisits.
  ///
  /// In en, this message translates to:
  /// **'Could not load visits'**
  String get couldNotLoadVisits;

  /// No description provided for @blockedUsersAppearHere.
  ///
  /// In en, this message translates to:
  /// **'People you block will appear here'**
  String get blockedUsersAppearHere;

  /// No description provided for @couldNotLoadBlockedUsers.
  ///
  /// In en, this message translates to:
  /// **'Could not load blocked users'**
  String get couldNotLoadBlockedUsers;

  /// No description provided for @passwordRuleMinLength.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get passwordRuleMinLength;

  /// No description provided for @passwordRuleUppercase.
  ///
  /// In en, this message translates to:
  /// **'1 uppercase letter'**
  String get passwordRuleUppercase;

  /// No description provided for @passwordRuleNumber.
  ///
  /// In en, this message translates to:
  /// **'1 number'**
  String get passwordRuleNumber;

  /// No description provided for @safetyIsPriority.
  ///
  /// In en, this message translates to:
  /// **'Your safety is our priority'**
  String get safetyIsPriority;

  /// No description provided for @supportAvailable247.
  ///
  /// In en, this message translates to:
  /// **'Support available 24/7'**
  String get supportAvailable247;

  /// No description provided for @notificationsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications about your matches, visits, and listings will appear here'**
  String get notificationsEmptySubtitle;

  /// No description provided for @couldNotLoadNotifications.
  ///
  /// In en, this message translates to:
  /// **'Could not load notifications'**
  String get couldNotLoadNotifications;

  /// No description provided for @yesterdayLabel.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterdayLabel;

  /// No description provided for @daysAgoLabel.
  ///
  /// In en, this message translates to:
  /// **'days ago'**
  String get daysAgoLabel;

  /// No description provided for @notificationNoAction.
  ///
  /// In en, this message translates to:
  /// **'No action available for this notification'**
  String get notificationNoAction;

  /// No description provided for @submittedLabel.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get submittedLabel;

  /// No description provided for @underReviewStepLabel.
  ///
  /// In en, this message translates to:
  /// **'Under Review'**
  String get underReviewStepLabel;

  /// No description provided for @liveStepLabel.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get liveStepLabel;

  /// No description provided for @pleaseReviewAndResubmit.
  ///
  /// In en, this message translates to:
  /// **'Please review the reason below and resubmit.'**
  String get pleaseReviewAndResubmit;

  /// No description provided for @rejectionReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Rejection reason'**
  String get rejectionReasonLabel;

  /// No description provided for @rejectionDetailText.
  ///
  /// In en, this message translates to:
  /// **'The listing did not meet our community guidelines. Please ensure all information is accurate and photos are clear.'**
  String get rejectionDetailText;

  /// No description provided for @activeStatus.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeStatus;

  /// No description provided for @draftStatus.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get draftStatus;

  /// No description provided for @expiredStatus.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expiredStatus;

  /// No description provided for @notificationsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTooltip;

  /// No description provided for @chatTooltip.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chatTooltip;

  /// No description provided for @listingStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Listing Stats'**
  String get listingStatsTitle;

  /// No description provided for @viewsStatLabel.
  ///
  /// In en, this message translates to:
  /// **'Views'**
  String get viewsStatLabel;

  /// No description provided for @likesStatLabel.
  ///
  /// In en, this message translates to:
  /// **'Likes'**
  String get likesStatLabel;

  /// No description provided for @matchesStatLabel.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get matchesStatLabel;

  /// No description provided for @closeCta.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeCta;

  /// No description provided for @matchCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Match Count ({count})'**
  String matchCountLabel(int count);

  /// No description provided for @boostAction.
  ///
  /// In en, this message translates to:
  /// **'Boost'**
  String get boostAction;

  /// No description provided for @viewStatsAction.
  ///
  /// In en, this message translates to:
  /// **'View Stats ({count})'**
  String viewStatsAction(String count);

  /// No description provided for @reviewAction.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get reviewAction;

  /// No description provided for @shareAction.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareAction;

  /// No description provided for @resumeAction.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resumeAction;

  /// No description provided for @expiresToday.
  ///
  /// In en, this message translates to:
  /// **'Expires today'**
  String get expiresToday;

  /// No description provided for @expiresInDays.
  ///
  /// In en, this message translates to:
  /// **'Expires in {days}d'**
  String expiresInDays(int days);

  /// No description provided for @failedToUpdateListingStatus.
  ///
  /// In en, this message translates to:
  /// **'Failed to update listing status.'**
  String get failedToUpdateListingStatus;

  /// No description provided for @noLikesYet.
  ///
  /// In en, this message translates to:
  /// **'No likes yet'**
  String get noLikesYet;

  /// No description provided for @noLikedYet.
  ///
  /// In en, this message translates to:
  /// **'No liked profiles yet'**
  String get noLikedYet;

  /// No description provided for @keepSwipingToFindMatches.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile to get more visibility.'**
  String get keepSwipingToFindMatches;

  /// No description provided for @noConversations.
  ///
  /// In en, this message translates to:
  /// **'No chats yet'**
  String get noConversations;

  /// No description provided for @startChatWithMatch.
  ///
  /// In en, this message translates to:
  /// **'Like a few profiles to start conversations.'**
  String get startChatWithMatch;

  /// No description provided for @matchAction.
  ///
  /// In en, this message translates to:
  /// **'Match'**
  String get matchAction;

  /// No description provided for @waitingForResponse.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get waitingForResponse;

  /// No description provided for @matchCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not create match. Try again.'**
  String get matchCreateFailed;

  /// No description provided for @couldNotLoadConversations.
  ///
  /// In en, this message translates to:
  /// **'Could not load conversations'**
  String get couldNotLoadConversations;

  /// No description provided for @downloadToConnect.
  ///
  /// In en, this message translates to:
  /// **'Download 360 FlatMates to connect'**
  String get downloadToConnect;

  /// No description provided for @scanToConnect.
  ///
  /// In en, this message translates to:
  /// **'Scan to connect'**
  String get scanToConnect;

  /// No description provided for @findYourFlatmateShare.
  ///
  /// In en, this message translates to:
  /// **'Find your flatmate on 360 FlatMates!'**
  String get findYourFlatmateShare;

  /// No description provided for @checkOutListingShare.
  ///
  /// In en, this message translates to:
  /// **'Check out this listing on 360 FlatMates!'**
  String get checkOutListingShare;

  /// No description provided for @passwordUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update password. Please try again.'**
  String get passwordUpdateFailed;

  /// No description provided for @visitRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send visit request. Please try again.'**
  String get visitRequestFailed;

  /// No description provided for @visitActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Action failed. Please try again.'**
  String get visitActionFailed;

  /// No description provided for @listingSubmitFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit listing. Please try again.'**
  String get listingSubmitFailed;

  /// No description provided for @listingHelperLocation.
  ///
  /// In en, this message translates to:
  /// **'Accurate location helps people find you'**
  String get listingHelperLocation;

  /// No description provided for @listingHelperSociety.
  ///
  /// In en, this message translates to:
  /// **'Tell us about the society to attract the right flatmates'**
  String get listingHelperSociety;

  /// No description provided for @listingHelperRoom.
  ///
  /// In en, this message translates to:
  /// **'Describe the room so flatmates know what to expect'**
  String get listingHelperRoom;

  /// No description provided for @listingHelperPhotos.
  ///
  /// In en, this message translates to:
  /// **'Good photos get 3x more responses'**
  String get listingHelperPhotos;

  /// No description provided for @listingHelperFlat.
  ///
  /// In en, this message translates to:
  /// **'Flat details help flatmates decide if it\'s the right fit'**
  String get listingHelperFlat;

  /// No description provided for @listingHelperCosts.
  ///
  /// In en, this message translates to:
  /// **'Transparent pricing builds trust'**
  String get listingHelperCosts;

  /// No description provided for @listingHelperAbout.
  ///
  /// In en, this message translates to:
  /// **'A good bio helps people know you'**
  String get listingHelperAbout;

  /// No description provided for @listingHelperReview.
  ///
  /// In en, this message translates to:
  /// **'Almost there! Review everything before going live'**
  String get listingHelperReview;

  /// No description provided for @listingRentRequired.
  ///
  /// In en, this message translates to:
  /// **'Monthly rent is required'**
  String get listingRentRequired;

  /// No description provided for @listingPhotosRequired.
  ///
  /// In en, this message translates to:
  /// **'Add at least 2 photos'**
  String get listingPhotosRequired;

  /// No description provided for @listingDepositInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get listingDepositInvalid;

  /// No description provided for @listingMaintenanceInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get listingMaintenanceInvalid;

  /// No description provided for @listingCostInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get listingCostInvalid;

  /// No description provided for @listingSummaryLocation.
  ///
  /// In en, this message translates to:
  /// **'{society}, {city}'**
  String listingSummaryLocation(String society, String city);

  /// No description provided for @listingSummarySociety.
  ///
  /// In en, this message translates to:
  /// **'{type}'**
  String listingSummarySociety(String type);

  /// No description provided for @listingSummaryRoom.
  ///
  /// In en, this message translates to:
  /// **'{roomType} • {furnishingCount} items'**
  String listingSummaryRoom(String roomType, int furnishingCount);

  /// No description provided for @listingSummaryPhotos.
  ///
  /// In en, this message translates to:
  /// **'{count} photo{plural}'**
  String listingSummaryPhotos(int count, String plural);

  /// No description provided for @listingSummaryFlat.
  ///
  /// In en, this message translates to:
  /// **'{config} • Floor {floor}'**
  String listingSummaryFlat(String config, String floor);

  /// No description provided for @listingSummaryCosts.
  ///
  /// In en, this message translates to:
  /// **'Rent: ₹{rent}/mo'**
  String listingSummaryCosts(String rent);

  /// No description provided for @listingSummaryAbout.
  ///
  /// In en, this message translates to:
  /// **'{gender} • Ages {ageMin}-{ageMax}'**
  String listingSummaryAbout(String gender, String ageMin, String ageMax);

  /// No description provided for @workStyleOffice.
  ///
  /// In en, this message translates to:
  /// **'Office'**
  String get workStyleOffice;

  /// No description provided for @workStyleHybrid.
  ///
  /// In en, this message translates to:
  /// **'Hybrid'**
  String get workStyleHybrid;

  /// No description provided for @workStyleWfh.
  ///
  /// In en, this message translates to:
  /// **'WFH'**
  String get workStyleWfh;

  /// No description provided for @phoneVerifiedLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone verified'**
  String get phoneVerifiedLabel;

  /// No description provided for @showResultsCta.
  ///
  /// In en, this message translates to:
  /// **'Show Results'**
  String get showResultsCta;

  /// No description provided for @searchFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Search & Filters'**
  String get searchFiltersTitle;

  /// No description provided for @clearAllFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAllFilters;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please check your network and try again.'**
  String get errorNetwork;

  /// No description provided for @errorAuthExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please sign in again.'**
  String get errorAuthExpired;

  /// No description provided for @errorServer.
  ///
  /// In en, this message translates to:
  /// **'Server error. Please try again later.'**
  String get errorServer;

  /// No description provided for @errorPermission.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to perform this action.'**
  String get errorPermission;

  /// No description provided for @errorNotFound.
  ///
  /// In en, this message translates to:
  /// **'The requested resource was not found.'**
  String get errorNotFound;

  /// No description provided for @errorValidation.
  ///
  /// In en, this message translates to:
  /// **'Invalid data. Please check your input.'**
  String get errorValidation;

  /// No description provided for @errorRateLimit.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please wait a moment and try again.'**
  String get errorRateLimit;

  /// No description provided for @errorConflict.
  ///
  /// In en, this message translates to:
  /// **'A conflict occurred. The data may have changed.'**
  String get errorConflict;

  /// No description provided for @errorUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload failed. Please try again.'**
  String get errorUpload;

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorUnknown;

  /// No description provided for @icebreakerTellMeRoom.
  ///
  /// In en, this message translates to:
  /// **'Tell me about the room!'**
  String get icebreakerTellMeRoom;

  /// No description provided for @icebreakerWhatFlatmates.
  ///
  /// In en, this message translates to:
  /// **'What are the flatmates like?'**
  String get icebreakerWhatFlatmates;

  /// No description provided for @icebreakerNegotiateRent.
  ///
  /// In en, this message translates to:
  /// **'Is the rent negotiable?'**
  String get icebreakerNegotiateRent;

  /// No description provided for @icebreakerSocietyVibe.
  ///
  /// In en, this message translates to:
  /// **'What\'s the society vibe?'**
  String get icebreakerSocietyVibe;

  /// No description provided for @icebreakerWeekendLook.
  ///
  /// In en, this message translates to:
  /// **'What does a weekend here look like?'**
  String get icebreakerWeekendLook;

  /// No description provided for @reviewRentAmount.
  ///
  /// In en, this message translates to:
  /// **'Rent: ₹{amount}/mo'**
  String reviewRentAmount(String amount);

  /// No description provided for @reviewDepositAmount.
  ///
  /// In en, this message translates to:
  /// **'Deposit: ₹{amount}'**
  String reviewDepositAmount(String amount);

  /// No description provided for @reviewMaintenanceAmount.
  ///
  /// In en, this message translates to:
  /// **'Maintenance: ₹{amount}'**
  String reviewMaintenanceAmount(String amount);

  /// No description provided for @reviewGenderAmount.
  ///
  /// In en, this message translates to:
  /// **'Gender: {gender}'**
  String reviewGenderAmount(String gender);

  /// No description provided for @reviewAgeAmount.
  ///
  /// In en, this message translates to:
  /// **'Age: {min} - {max}'**
  String reviewAgeAmount(String min, String max);

  /// No description provided for @reviewMoveInAmount.
  ///
  /// In en, this message translates to:
  /// **'Move-in: {date}'**
  String reviewMoveInAmount(String date);

  /// No description provided for @reviewPhotosAmount.
  ///
  /// In en, this message translates to:
  /// **'{count} photo{plural}'**
  String reviewPhotosAmount(int count, String plural);

  /// No description provided for @invalidListingId.
  ///
  /// In en, this message translates to:
  /// **'Invalid listing ID'**
  String get invalidListingId;

  /// No description provided for @invalidConversationId.
  ///
  /// In en, this message translates to:
  /// **'Invalid conversation ID'**
  String get invalidConversationId;

  /// No description provided for @youAreOffline.
  ///
  /// In en, this message translates to:
  /// **'You are offline. Check your connection.'**
  String get youAreOffline;

  /// No description provided for @visitScheduledNotificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Visit scheduled! Could not send notification.'**
  String get visitScheduledNotificationFailed;

  /// No description provided for @bootstrapErrorRetry.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Tap to retry.'**
  String get bootstrapErrorRetry;

  /// No description provided for @boostListingTitle.
  ///
  /// In en, this message translates to:
  /// **'Boost Listing'**
  String get boostListingTitle;

  /// No description provided for @boostListingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your listing will be shown to more people for the next 24 hours.'**
  String get boostListingSubtitle;

  /// No description provided for @boostNowCta.
  ///
  /// In en, this message translates to:
  /// **'Boost Now'**
  String get boostNowCta;

  /// No description provided for @listingBoosted.
  ///
  /// In en, this message translates to:
  /// **'Listing boosted for 24 hours!'**
  String get listingBoosted;

  /// No description provided for @pausedStatus.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get pausedStatus;

  /// No description provided for @renewAction.
  ///
  /// In en, this message translates to:
  /// **'Renew'**
  String get renewAction;

  /// No description provided for @refreshProfilesCta.
  ///
  /// In en, this message translates to:
  /// **'Refresh Profiles'**
  String get refreshProfilesCta;

  /// No description provided for @swipeEmptyNoProfilesTitle.
  ///
  /// In en, this message translates to:
  /// **'No profiles available right now'**
  String get swipeEmptyNoProfilesTitle;

  /// No description provided for @swipeEmptyNoProfilesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'re finding new matches for you! Check back soon.'**
  String get swipeEmptyNoProfilesSubtitle;

  /// No description provided for @swipeEmptyAllFilteredTitle.
  ///
  /// In en, this message translates to:
  /// **'No profiles match your preferences'**
  String get swipeEmptyAllFilteredTitle;

  /// No description provided for @swipeEmptyAllFilteredSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your non-negotiables to see more profiles.'**
  String get swipeEmptyAllFilteredSubtitle;

  /// No description provided for @swipeEmptyEndOfDeckTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'ve seen everyone for now'**
  String get swipeEmptyEndOfDeckTitle;

  /// No description provided for @swipeEmptyEndOfDeckSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'re finding new matches for you! Check back later.'**
  String get swipeEmptyEndOfDeckSubtitle;

  /// No description provided for @locationServicesDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are turned off. Please enable GPS/Location in your device settings.'**
  String get locationServicesDisabled;

  /// No description provided for @locationServicesDisabledAction.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get locationServicesDisabledAction;

  /// No description provided for @locationPermissionDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Location permission was denied. Please enable it in app settings.'**
  String get locationPermissionDeniedForever;

  /// No description provided for @locationOpenAppSettings.
  ///
  /// In en, this message translates to:
  /// **'Open App Settings'**
  String get locationOpenAppSettings;

  /// No description provided for @locationNoMatchFound.
  ///
  /// In en, this message translates to:
  /// **'Could not find a matching city nearby. Please select manually.'**
  String get locationNoMatchFound;

  /// No description provided for @searchCityOrAreaHint.
  ///
  /// In en, this message translates to:
  /// **'Search city or area'**
  String get searchCityOrAreaHint;

  /// No description provided for @suggestionsLabel.
  ///
  /// In en, this message translates to:
  /// **'SUGGESTIONS'**
  String get suggestionsLabel;

  /// No description provided for @locationPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Location'**
  String get locationPickerTitle;

  /// No description provided for @locationPickerSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search area, locality, city...'**
  String get locationPickerSearchHint;

  /// No description provided for @matchingCitiesLabel.
  ///
  /// In en, this message translates to:
  /// **'MATCHING CITIES'**
  String get matchingCitiesLabel;

  /// No description provided for @noCitiesFound.
  ///
  /// In en, this message translates to:
  /// **'No cities found'**
  String get noCitiesFound;

  /// No description provided for @searchRadiusLabel.
  ///
  /// In en, this message translates to:
  /// **'Search Radius'**
  String get searchRadiusLabel;

  /// No description provided for @distanceKmLabel.
  ///
  /// In en, this message translates to:
  /// **'{distance} km'**
  String distanceKmLabel(int distance);

  /// No description provided for @currentLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Location'**
  String get currentLocationLabel;

  /// No description provided for @locationDetailsFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not get location details'**
  String get locationDetailsFailed;

  /// No description provided for @selectLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Select Location'**
  String get selectLocationLabel;

  /// No description provided for @locationSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationSectionTitle;

  /// No description provided for @getDirectionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Get Directions'**
  String get getDirectionsLabel;

  /// No description provided for @propertyFallbackLabel.
  ///
  /// In en, this message translates to:
  /// **'Property'**
  String get propertyFallbackLabel;

  /// No description provided for @distanceMeters.
  ///
  /// In en, this message translates to:
  /// **'{distance}m away'**
  String distanceMeters(int distance);

  /// No description provided for @distanceKmDecimal.
  ///
  /// In en, this message translates to:
  /// **'{distance}km away'**
  String distanceKmDecimal(String distance);

  /// No description provided for @distanceKm.
  ///
  /// In en, this message translates to:
  /// **'{distance}km away'**
  String distanceKm(int distance);

  /// No description provided for @availableNowLabel.
  ///
  /// In en, this message translates to:
  /// **'Available Now'**
  String get availableNowLabel;

  /// No description provided for @availableLabel.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get availableLabel;

  /// No description provided for @availableFromShort.
  ///
  /// In en, this message translates to:
  /// **'From {date}'**
  String availableFromShort(String date);

  /// No description provided for @availableFromFull.
  ///
  /// In en, this message translates to:
  /// **'Available from {date}'**
  String availableFromFull(String date);

  /// No description provided for @genderSuffixMaleOnly.
  ///
  /// In en, this message translates to:
  /// **'M Only'**
  String get genderSuffixMaleOnly;

  /// No description provided for @genderSuffixFemaleOnly.
  ///
  /// In en, this message translates to:
  /// **'F Only'**
  String get genderSuffixFemaleOnly;

  /// No description provided for @genderSuffixAny.
  ///
  /// In en, this message translates to:
  /// **'Any Gender'**
  String get genderSuffixAny;

  /// No description provided for @activeRecentlyLabel.
  ///
  /// In en, this message translates to:
  /// **'Active recently'**
  String get activeRecentlyLabel;

  /// No description provided for @couldNotLoadContent.
  ///
  /// In en, this message translates to:
  /// **'Could not load content.'**
  String get couldNotLoadContent;

  /// No description provided for @forceUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Update required'**
  String get forceUpdateTitle;

  /// No description provided for @forceUpdateMessage.
  ///
  /// In en, this message translates to:
  /// **'A new version of 360 FlatMates is available. Please update to continue using the app.'**
  String get forceUpdateMessage;

  /// No description provided for @forceUpdateCta.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get forceUpdateCta;

  /// No description provided for @optionalUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get optionalUpdateTitle;

  /// No description provided for @optionalUpdateMessage.
  ///
  /// In en, this message translates to:
  /// **'A newer version of 360 FlatMates is available with improvements and bug fixes.'**
  String get optionalUpdateMessage;

  /// No description provided for @optionalUpdateCta.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get optionalUpdateCta;

  /// No description provided for @optionalUpdateLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get optionalUpdateLater;

  /// No description provided for @maintenanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Under maintenance'**
  String get maintenanceTitle;

  /// No description provided for @maintenanceMessage.
  ///
  /// In en, this message translates to:
  /// **'We\'re making things better. Please check back in a little while.'**
  String get maintenanceMessage;

  /// No description provided for @maintenanceRetry.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get maintenanceRetry;

  /// No description provided for @deleteAccountCta.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccountCta;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Your Account'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In en, this message translates to:
  /// **'This action is permanent and cannot be undone. All your data including profile, listings, chats, and matches will be permanently deleted.'**
  String get deleteAccountWarning;

  /// No description provided for @deleteAccountConfirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Type DELETE to confirm'**
  String get deleteAccountConfirmLabel;

  /// No description provided for @deleteAccountConfirmHint.
  ///
  /// In en, this message translates to:
  /// **'Type DELETE'**
  String get deleteAccountConfirmHint;

  /// No description provided for @deleteAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Delete My Account'**
  String get deleteAccountButton;

  /// No description provided for @deleteAccountCancelled.
  ///
  /// In en, this message translates to:
  /// **'Account deletion cancelled.'**
  String get deleteAccountCancelled;

  /// No description provided for @deleteAccountFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete account. Please try again or contact support.'**
  String get deleteAccountFailed;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number and we\'ll send you an OTP to reset your password.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @sendOtpCta.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOtpCta;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the OTP sent to {phone} and set your new password.'**
  String resetPasswordSubtitle(String phone);

  /// No description provided for @forgotPasswordCta.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPasswordCta;

  /// No description provided for @noAccountCta.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccountCta;

  /// No description provided for @passwordResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password reset successfully. Please sign in.'**
  String get passwordResetSuccess;

  /// No description provided for @phoneNotRegistered.
  ///
  /// In en, this message translates to:
  /// **'This phone number is not registered.'**
  String get phoneNotRegistered;

  /// No description provided for @loginWithPasswordCta.
  ///
  /// In en, this message translates to:
  /// **'Login with password'**
  String get loginWithPasswordCta;

  /// No description provided for @reportABug.
  ///
  /// In en, this message translates to:
  /// **'Report a Bug'**
  String get reportABug;

  /// No description provided for @reportABugSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Something not working? Let us know.'**
  String get reportABugSubtitle;

  /// No description provided for @requestAFeature.
  ///
  /// In en, this message translates to:
  /// **'Request a Feature'**
  String get requestAFeature;

  /// No description provided for @requestAFeatureSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share an idea to make the app better.'**
  String get requestAFeatureSubtitle;

  /// No description provided for @reportABugIntro.
  ///
  /// In en, this message translates to:
  /// **'Tell us what went wrong and we\'ll look into it.'**
  String get reportABugIntro;

  /// No description provided for @requestAFeatureIntro.
  ///
  /// In en, this message translates to:
  /// **'Tell us what you\'d love to see in the app.'**
  String get requestAFeatureIntro;

  /// No description provided for @feedbackTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get feedbackTitleLabel;

  /// No description provided for @feedbackTitleBugHint.
  ///
  /// In en, this message translates to:
  /// **'Brief summary of the bug'**
  String get feedbackTitleBugHint;

  /// No description provided for @feedbackTitleFeatureHint.
  ///
  /// In en, this message translates to:
  /// **'Brief summary of your idea'**
  String get feedbackTitleFeatureHint;

  /// No description provided for @feedbackTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title.'**
  String get feedbackTitleRequired;

  /// No description provided for @feedbackDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get feedbackDescriptionLabel;

  /// No description provided for @feedbackDescriptionBugHint.
  ///
  /// In en, this message translates to:
  /// **'Steps to reproduce, what you expected, and what happened'**
  String get feedbackDescriptionBugHint;

  /// No description provided for @feedbackDescriptionFeatureHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the feature and how it would help'**
  String get feedbackDescriptionFeatureHint;

  /// No description provided for @feedbackDescriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a description.'**
  String get feedbackDescriptionRequired;

  /// No description provided for @feedbackBugTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Bug type'**
  String get feedbackBugTypeLabel;

  /// No description provided for @feedbackBugTypeFunctionality.
  ///
  /// In en, this message translates to:
  /// **'Functionality bug'**
  String get feedbackBugTypeFunctionality;

  /// No description provided for @feedbackBugTypeUi.
  ///
  /// In en, this message translates to:
  /// **'UI bug'**
  String get feedbackBugTypeUi;

  /// No description provided for @feedbackBugTypePerformance.
  ///
  /// In en, this message translates to:
  /// **'Performance issue'**
  String get feedbackBugTypePerformance;

  /// No description provided for @feedbackBugTypeCrash.
  ///
  /// In en, this message translates to:
  /// **'Crash'**
  String get feedbackBugTypeCrash;

  /// No description provided for @feedbackBugTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get feedbackBugTypeOther;

  /// No description provided for @feedbackSeverityLabel.
  ///
  /// In en, this message translates to:
  /// **'Severity'**
  String get feedbackSeverityLabel;

  /// No description provided for @feedbackSeverityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get feedbackSeverityLow;

  /// No description provided for @feedbackSeverityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get feedbackSeverityMedium;

  /// No description provided for @feedbackSeverityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get feedbackSeverityHigh;

  /// No description provided for @feedbackSeverityCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get feedbackSeverityCritical;

  /// No description provided for @feedbackSubmitCta.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get feedbackSubmitCta;

  /// No description provided for @feedbackSubmitSuccess.
  ///
  /// In en, this message translates to:
  /// **'Thanks for your feedback!'**
  String get feedbackSubmitSuccess;
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
