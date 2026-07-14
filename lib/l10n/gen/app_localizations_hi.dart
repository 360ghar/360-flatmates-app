// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => '360 फ्लैटमेट्स';

  @override
  String get splashTaglineLine1 => 'ढूंढें। जुड़ें।';

  @override
  String get splashTaglineLine2 => 'साथ रहें।';

  @override
  String get splashSubtagline =>
      'अपना फ्लैट और फ्लैटमेट ढूंढने का बेहतरीन तरीका।';

  @override
  String get commonRetry => 'फिर से प्रयास करें';

  @override
  String get commonSave => 'सहेजें';

  @override
  String get markAllRead => 'सभी पढ़े हुए चिह्नित करें';

  @override
  String get seeAllCta => 'सभी देखें';

  @override
  String get cancelCta => 'रद्द करें';

  @override
  String get enterPhoneTitle => 'अपना फोन नंबर दर्ज करें';

  @override
  String get enterPhoneSubtitle =>
      'शुरू करने के लिए साइन इन करें या खाता बनाएं।';

  @override
  String get authEntryTitle => 'स्वागत है';

  @override
  String get authEntrySubtitle =>
      'Google से जारी रखें, या अपना फोन या ईमेल उपयोग करें।';

  @override
  String get continueWithGoogleCta => 'Google से जारी रखें';

  @override
  String get authDividerOr => 'या';

  @override
  String get identifierLabel => 'फोन या ईमेल';

  @override
  String get continueCta => 'जारी रखें';

  @override
  String get phoneNumberLabel => 'फोन नंबर';

  @override
  String get loginWithPassword => 'पासवर्ड से लॉगिन करें';

  @override
  String get continueWithOtp => 'OTP के साथ जारी रखें';

  @override
  String get addPhoneTitle => 'अपना फोन नंबर जोड़ें';

  @override
  String get addPhoneSubtitle =>
      'ताकि फ्लैटमेट आप तक पहुंच सकें, फोन नंबर जोड़ें। आप इसे अभी छोड़ सकते हैं।';

  @override
  String get addPhoneCta => 'कोड भेजें';

  @override
  String get skipCta => 'अभी के लिए छोड़ें';

  @override
  String get setPasswordTitle => 'पासवर्ड सेट करें';

  @override
  String get setPasswordSubtitle =>
      'अपने खाते को सुरक्षित करने के लिए पासवर्ड बनाएं।';

  @override
  String lastUsedMethodHint(String method) {
    return 'आपने पिछली बार $method से साइन इन किया था';
  }

  @override
  String get loginTitle => 'लॉगिन';

  @override
  String get fullNameLabel => 'पूरा नाम';

  @override
  String get emailLabel => 'ईमेल';

  @override
  String get passwordLabel => 'पासवर्ड';

  @override
  String get signInCta => 'साइन इन';

  @override
  String get otpTitle => 'OTP सत्यापित करें';

  @override
  String get otpCodeLabel => 'OTP कोड';

  @override
  String get verifyOtpCta => 'सत्यापित करें';

  @override
  String otpSubtitle(String phone) {
    return '$phone पर भेजा गया OTP दर्ज करें।';
  }

  @override
  String get discoverTitle => 'डिस्कवर';

  @override
  String get emptyListings => 'अभी कोई फ्लैटमेट लिस्टिंग उपलब्ध नहीं है।';

  @override
  String get homeGreeting => 'नमस्ते';

  @override
  String get homeGreetingMorning => 'सुप्रभात';

  @override
  String get homeGreetingAfternoon => 'नमस्कार';

  @override
  String get homeGreetingEvening => 'शुभ संध्या';

  @override
  String get homeGuestName => 'दोस्त';

  @override
  String homeSubtitle(String city) {
    return '$city में अपना अगला फ्लैटमेट खोजें';
  }

  @override
  String homeMarketInsight(int count) {
    return 'पास में $count सत्यापित लोग सक्रिय रूप से खोज रहे हैं';
  }

  @override
  String get homeMarketInsightCta => 'सक्रिय सीकर देखें';

  @override
  String get homeLocationFallback =>
      'डिस्कवरी को बेहतर बनाने के लिए अपना शहर और लोकैलिटी सेट करें।';

  @override
  String get locationUpdated => 'स्थान अपडेट किया गया';

  @override
  String get locationPermissionRequired =>
      'आपका शहर पता लगाने के लिए स्थान अनुमति आवश्यक है।';

  @override
  String get locationDetectionFailed =>
      'आपका स्थान पता नहीं लगा सके। कृपया मैन्युअली चुनें।';

  @override
  String get couldNotDetectLocation => 'स्थान का पता नहीं लगा सके';

  @override
  String get homeSearchHint => 'इलाका, बजट, फ्लैटमेट खोजें...';

  @override
  String get searchMapHint => 'लोकेशन, सेक्टर, सोसाइटी खोजें...';

  @override
  String get homePickedForYou => 'आपके लिए बेहतरीन मैच';

  @override
  String get homePickedSubtitle => 'आपकी पसंद और वाइब से मेल खाने वाले फ्लैट्स';

  @override
  String get homeNoResults => 'इन फ़िल्टर्स से कोई लिस्टिंग नहीं मिली।';

  @override
  String get homeNoResultsSubtitle =>
      'अपने फ़िल्टर बदलकर देखें या किसी अन्य लोकेशन के लिए खोजें।';

  @override
  String get homeBroadenedRadius =>
      'आपके क्षेत्र में कोई लिस्टिंग नहीं — दूर की फ्लैट्स दिखाई जा रही हैं।';

  @override
  String homeBedroomsChip(int count) {
    return '$count BHK';
  }

  @override
  String homeBedsValue(int count) {
    return '$count बेड';
  }

  @override
  String homeBathsValue(int count) {
    return '$count बाथ';
  }

  @override
  String homeAreaValue(String area) {
    return '$area वर्ग फुट';
  }

  @override
  String homeMoveInValue(String date) {
    return 'मूव-इन: $date';
  }

  @override
  String homeInterestCount(int count) {
    return '$count इच्छुक';
  }

  @override
  String get badgeNew => 'नया';

  @override
  String get badgePopular => 'लोकप्रिय';

  @override
  String get badgeTrending => 'ट्रेंडिंग';

  @override
  String monthlyRentLabel(String amount) {
    return 'मासिक किराया: ₹$amount';
  }

  @override
  String monthlyRentHeadline(String amount) {
    return '₹$amount / महीना';
  }

  @override
  String get contactRequestSent =>
      'रुचि भेज दी गई है। अब मालिक आपसे चैट कर सकता है।';

  @override
  String get likeRemovedToast => 'आपकी पसंद से हटा दिया गया';

  @override
  String contactRequestWithConversation(int conversationId) {
    return 'रुचि भेज दी गई है। बातचीत #$conversationId तैयार है।';
  }

  @override
  String get likeListingCta => 'लिस्टिंग पसंद करें';

  @override
  String get likesChatTitle => 'इनबॉक्स';

  @override
  String get likesTabLabel => 'आपको लाइक किया';

  @override
  String get likedTabLabel => 'आपने लाइक किया';

  @override
  String get chatsTabLabel => 'चैट्स';

  @override
  String get likesIncomingLabel => 'आपका मैच हो गया। बातचीत शुरू करें।';

  @override
  String get emptyLikes => 'अभी कोई नया लाइक नहीं है।';

  @override
  String get chatsTitle => 'चैट्स';

  @override
  String get callCta => 'कॉल करें';

  @override
  String get messageCta => 'संदेश';

  @override
  String get listingDetails => 'लिस्टिंग विवरण';

  @override
  String percentMatch(int percent) {
    return '$percent% मैच';
  }

  @override
  String yearsOldLabel(int age) {
    return '$age वर्ष';
  }

  @override
  String get emptyChats => 'अभी कोई बातचीत नहीं है।';

  @override
  String get chatReady => 'जब आप तैयार हों, आपकी चैट भी तैयार है।';

  @override
  String get messageHint => 'संदेश टाइप करें...';

  @override
  String get sendCta => 'भेजें';

  @override
  String get messageAttachment => 'अटैचमेंट';

  @override
  String get openConversationCta => 'बातचीत खोलें';

  @override
  String get todayLabel => 'आज';

  @override
  String get safetyFirstTitle => 'सुरक्षा पहले';

  @override
  String get safetyFirstSubtitle => 'पेमेंट से पहले कमरा ज़रूर देखें।';

  @override
  String get scheduleTitle => 'शेड्यूल';

  @override
  String get scheduleSubtitle =>
      'अपने फ्लैट विज़िट और मीटअप एक ही जगह ट्रैक करें।';

  @override
  String get visitsTitle => 'विज़िट्स';

  @override
  String get emptyVisits => 'अभी कोई विज़िट निर्धारित नहीं है।';

  @override
  String get visitRequested => 'विज़िट अनुरोध भेज दिया गया है।';

  @override
  String get flatmateMeetLabel => 'फ्लैटमेट मीट';

  @override
  String get propertyTourLabel => 'प्रॉपर्टी टूर';

  @override
  String get scheduleVisitCta => 'विज़िट शेड्यूल करें';

  @override
  String get profilePageTitle => 'मैं';

  @override
  String get profileTitle => 'प्रोफ़ाइल और सेटिंग्स';

  @override
  String profileStrengthTitle(int percent) {
    return 'प्रोफ़ाइल मज़बूती: $percent%';
  }

  @override
  String get profileStrengthSubtitle =>
      '3x ज़्यादा रिस्पॉन्स के लिए 2 स्टेप पूरे करें';

  @override
  String get completeProfileCta => 'प्रोफ़ाइल पूरी करें';

  @override
  String get discoverySectionLabel => 'डिस्कवरी';

  @override
  String get trustSectionLabel => 'ट्रस्ट';

  @override
  String get accountSectionLabel => 'अकाउंट';

  @override
  String get profileFallbackName => 'आपकी फ्लैटमेट्स प्रोफ़ाइल';

  @override
  String get profileStatListings => 'लिस्टिंग्स';

  @override
  String get profileStatChats => 'चैट्स';

  @override
  String get profileStatUnread => 'अनरीड';

  @override
  String get profileMenuVisits => 'मेरा शेड्यूल';

  @override
  String get profileMenuLikesChat => 'मैच और चैट';

  @override
  String get profileMenuPostListing => 'लिस्टिंग पोस्ट करें';

  @override
  String get profileMenuShortlisted => 'लाइक्स';

  @override
  String get profileMenuChats => 'मेरी चैट';

  @override
  String get profileMenuDocuments => 'दस्तावेज़';

  @override
  String get editProfileCta => 'प्रोफ़ाइल संपादित करें';

  @override
  String get editProfileTabIdentity => 'पहचान';

  @override
  String get editProfileTabPreferences => 'प्राथमिकताएँ';

  @override
  String get editProfileTabLifestyle => 'जीवनशैली';

  @override
  String get editProfileTabAbout => 'बारे में';

  @override
  String get themeModeTitle => 'थीम मोड';

  @override
  String get themeSystem => 'सिस्टम';

  @override
  String get themeLight => 'लाइट';

  @override
  String get themeDark => 'डार्क';

  @override
  String get languageTitle => 'भाषा';

  @override
  String get languageEnglish => 'अंग्रेज़ी';

  @override
  String get languageHindi => 'हिंदी';

  @override
  String get logoutCta => 'लॉगआउट';

  @override
  String get modeTitle => 'मोड';

  @override
  String get modeRoomPoster => 'कमरा उपलब्ध है';

  @override
  String get modeSeeker => 'कमरा खोज रहे हैं';

  @override
  String get modeCoHunter => 'साथ में खोज रहे हैं';

  @override
  String get modeOpenToBoth => 'कमरा और फ्लैटमेट खोज रहे हैं';

  @override
  String get cityLabel => 'शहर';

  @override
  String get localityLabel => 'लोकैलिटी';

  @override
  String get subLocalityLabel => 'सब-लोकैलिटी';

  @override
  String get budgetMinLabel => 'न्यूनतम बजट';

  @override
  String get budgetMaxLabel => 'अधिकतम बजट';

  @override
  String get budgetMinMaxError => 'न्यूनतम बजट अधिकतम बजट से अधिक नहीं हो सकता';

  @override
  String get workStyleTitle => 'वर्क स्टाइल';

  @override
  String get bioLabel => 'बायो';

  @override
  String get descriptionLabel => 'विवरण';

  @override
  String get listingTitleLabel => 'लिस्टिंग शीर्षक';

  @override
  String get monthlyRentInputLabel => 'मासिक किराया';

  @override
  String get securityDepositLabel => 'सिक्योरिटी डिपॉज़िट';

  @override
  String get maintenanceLabel => 'मेंटेनेंस';

  @override
  String get areaSqftLabel => 'क्षेत्रफल (वर्ग फुट)';

  @override
  String get bedroomsLabel => 'बेडरूम';

  @override
  String get bathroomsLabel => 'बाथरूम';

  @override
  String get genderPreferenceLabel => 'पसंदीदा जेंडर';

  @override
  String get genderAny => 'कोई भी';

  @override
  String get genderMale => 'पुरुष';

  @override
  String get genderFemale => 'महिला';

  @override
  String get visitStatusRequested => 'अनुरोधित';

  @override
  String get visitStatusScheduled => 'निर्धारित';

  @override
  String get visitStatusConfirmed => 'पुष्ट';

  @override
  String get visitStatusCompleted => 'पूरा हुआ';

  @override
  String get visitStatusCancelled => 'रद्द';

  @override
  String get sharingTypeLabel => 'रूम टाइप';

  @override
  String get sharingPrivateRoom => 'प्राइवेट रूम';

  @override
  String get sharingSharedRoom => 'शेयर्ड रूम';

  @override
  String get featuresLabel => 'फीचर्स';

  @override
  String get featuresHint => 'उदाहरण: furnished, wifi, balcony';

  @override
  String get featureFurnished => 'फर्निश्ड';

  @override
  String get featureSemiFurnished => 'सेमी-फर्निश्ड';

  @override
  String get featureWifi => 'वाई-फाई';

  @override
  String get featureBalcony => 'बालकनी';

  @override
  String get featureAttachedBathroom => 'अटैच्ड बाथरूम';

  @override
  String get featureParking => 'पार्किंग';

  @override
  String get featureAc => 'एसी';

  @override
  String get featureWashingMachine => 'वॉशिंग मशीन';

  @override
  String get mainImageUrlLabel => 'मुख्य इमेज URL';

  @override
  String get availableFromLabel => 'उपलब्धता';

  @override
  String get availableFromUnset => 'मूव-इन उपलब्धता चुनें';

  @override
  String get selectDateCta => 'तारीख चुनें';

  @override
  String get postListingTitle => 'अपना स्पेस पोस्ट करें';

  @override
  String get postListingCta => 'कुछ ही मिनटों में अपना स्पेस लिस्ट करें';

  @override
  String get postListingSubtitle =>
      'मौजूदा 360 Ghar इन्वेंटरी बैकएंड का उपयोग करके असली फ्लैटमेट लिस्टिंग बनाएं।';

  @override
  String get postListingBasics => 'बेसिक्स';

  @override
  String get postListingPricing => 'प्राइसिंग';

  @override
  String get postListingDetails => 'डिटेल्स';

  @override
  String get publishListingCta => 'लिस्टिंग प्रकाशित करें';

  @override
  String get postingInProgress => 'प्रकाशित हो रहा है...';

  @override
  String get postListingSuccess => 'लिस्टिंग सफलतापूर्वक बन गई।';

  @override
  String get ownerFallbackLabel => 'लिस्टिंग मालिक';

  @override
  String get settingsTitle => 'सेटिंग्स';

  @override
  String get settingsProfileSection => 'प्रोफ़ाइल';

  @override
  String get settingsAppearanceSection => 'दिखावट';

  @override
  String get settingsSessionSection => 'सेशन';

  @override
  String get navHome => 'होम';

  @override
  String get navSwipe => 'स्वाइप';

  @override
  String get navLikesChat => 'इनबॉक्स';

  @override
  String get navSchedule => 'शेड्यूल';

  @override
  String get navPost => 'पोस्ट';

  @override
  String get navExplore => 'एक्सप्लोर';

  @override
  String get navProfile => 'मैं';

  @override
  String get navVisits => 'विज़िट';

  @override
  String get onboardingGetStarted => 'शुरू करें';

  @override
  String get onboardingNext => 'आगे';

  @override
  String get onboardingSkip => 'छोड़ें';

  @override
  String get onboardingComplete => 'पूरा करें';

  @override
  String get onboardingHeadline1 => 'सही फ्लैट। सही फ्लैटमेट्स।';

  @override
  String get onboardingSubheadline1 =>
      'वेरिफ़ाइड होम। कंपैटिबल फ्लैटमेट्स। बेहतर जीवन, साथ में।';

  @override
  String get onboardingHeadline2 => 'आपकी लाइफस्टाइल मायने रखती है।';

  @override
  String get onboardingSubheadline2 =>
      'हम आपको अपनी वाइब और वैल्यूज़ शेयर करने वाले फ्लैटमेट्स से मैच करते हैं।';

  @override
  String get onboardingHeadline3 => '360 फ्लैटमेट्स दोनों ढूंढता है।';

  @override
  String get onboardingSubheadline3 => 'फ्लैट, फ्लैटमेट, और परफेक्ट मैच।';

  @override
  String get onboardingHeadline4 =>
      'आपकी फ्लैटमेट यात्रा यहीं से शुरू होती है।';

  @override
  String get onboardingSubheadline4 =>
      '4 मिनट से कम में साइन अप करें और मैचिंग शुरू करें।';

  @override
  String get onboardingSubmitting => 'आपकी प्रोफ़ाइल सेट की जा रही है...';

  @override
  String get modeSelectionTitle => 'मैं ढूंढ रहा हूं';

  @override
  String get modeSelectionSubtitle =>
      'वह विकल्प चुनें जो आपको सबसे अच्छे से दर्शाता है';

  @override
  String get modeRoomPosterDesc =>
      'मैं अपना फ्लैट लिस्ट करना चाहता हूं या खाली कमरे के लिए फ्लैटमेट ढूंढ रहा हूं।';

  @override
  String get modeSeekerDesc =>
      'मैं साथ मिलकर फ्लैट ढूंढने के लिए फ्लैटमेट खोज रहा हूँ';

  @override
  String get modeCoHunterDesc =>
      'मैं फ्लैट या रहने के लिए फ्लैटमेट ढूंढ रहा हूं।';

  @override
  String get modeOpenToBothDesc =>
      'मैं मौजूदा फ्लैट में जा सकता हूं या नया ढूंढ सकता हूं।';

  @override
  String get modeContinue => 'जारी रखें';

  @override
  String get basicInfoTitle => 'अपने बारे में बताएं';

  @override
  String get basicInfoSubtitle =>
      'इससे हमें आपके लिए सही फ्लैटमेट्स मिलने में मदद मिलती है।';

  @override
  String get ageLabel => 'उम्र';

  @override
  String get ageHelperText => 'आपकी उम्र 18 या उससे अधिक होनी चाहिए';

  @override
  String get professionLabel => 'पेशा / जॉब टाइटल';

  @override
  String get profilePhotoTitle => 'अपनी फ़ोटो जोड़ें';

  @override
  String get profilePhotoSubtitle =>
      'जब तक आप फ़ोटो नहीं जोड़ते, हम आपके नाम के शुरुआती अक्षर दिखाएँगे। आप इसे बाद में भी जोड़ सकते हैं।';

  @override
  String get profilePhotoNudge =>
      'फ़ोटो वाली प्रोफ़ाइल्स को ज़्यादा मैच मिलते हैं।';

  @override
  String get addPhotoCta => 'फ़ोटो जोड़ें';

  @override
  String quizProgress(int answered, int total) {
    return '$total में से $answered जवाब दिए';
  }

  @override
  String get quizSleepSchedule => 'आपका स्लीप शेड्यूल क्या है?';

  @override
  String get quizEarlyBird => 'सुबह जल्दी (रात 10 बजे से पहले)';

  @override
  String get quizFlexible => 'लचीला';

  @override
  String get quizNightOwl => 'रात को जागने वाला (आधी रात के बाद)';

  @override
  String get quizCleanliness => 'आप कितने साफ-सुथरे रहते हैं?';

  @override
  String get quizCleanMinimal => 'कम — रहने वाला ठीक है';

  @override
  String get quizCleanTidy => 'सुव्यवस्थित — हर चीज़ अपनी जगह पर';

  @override
  String get quizCleanSpotless => 'बिल्कुल साफ — सब कुछ चमकदार';

  @override
  String get quizFoodHabits => 'आपकी खान-पान की आदतें?';

  @override
  String get quizVegetarian => 'शाकाहारी';

  @override
  String get quizVegan => 'वीगन';

  @override
  String get quizNonVegetarian => 'मांसाहारी';

  @override
  String get quizEggetarian => 'एगेटेरियन';

  @override
  String get quizNoFoodPref => 'कोई प्राथमिकता नहीं';

  @override
  String get quizSmokingDrinking => 'धूम्रपान और शराब की प्राथमिकता?';

  @override
  String get quizNeither => 'न धूम्रपान, न शराब';

  @override
  String get quizSmokeOutside => 'बाहर ही धूम्रपान';

  @override
  String get quizDrinkOccasionally => 'कभी-कभी शराब';

  @override
  String get quizBothFine => 'दोनों ठीक हैं';

  @override
  String get quizGuestsPolicy => 'मेहमानों के बारे में आपका क्या विचार है?';

  @override
  String get quizNoGuests => 'रात को मेहमान नहीं';

  @override
  String get quizOccasionalGuests => 'कभी-कभी मेहमान ठीक हैं';

  @override
  String get quizOpenHouse => 'खुला घर — हमेशा स्वागत है';

  @override
  String get quizParties => 'घर पर पार्टी के बारे में?';

  @override
  String get quizPartiesNever => 'कभी नहीं';

  @override
  String get quizPartiesWeekends => 'कभी-कभी वीकेंड पर';

  @override
  String get quizPartyFriendly => 'पार्टी-फ्रेंडली';

  @override
  String get quizWorkStyle => 'आपका वर्क स्टाइल क्या है?';

  @override
  String get quizWfh => 'ज़्यादातर घर से काम';

  @override
  String get quizOffice => 'ज़्यादातर ऑफिस से';

  @override
  String get quizHybrid => 'हाइब्रिड — दोनों का मिश्रण';

  @override
  String get quizPets => 'पालतू जानवरों के बारे में?';

  @override
  String get quizNoPets => 'कोई पालतू नहीं';

  @override
  String get quizHavePets => 'मेरे पालतू हैं';

  @override
  String get quizPetFriendly => 'पालतू-फ्रेंडली (अपने पालतू नहीं)';

  @override
  String get budgetTimelineTitle => 'बजट और मूव-इन टाइमलाइन';

  @override
  String get budgetTimelineSubtitle =>
      'अपनी बजट रेंज सेट करें और कब शिफ्ट होना चाहते हैं।';

  @override
  String get monthlyBudgetLabel => 'मासिक बजट';

  @override
  String get moveInTimelineLabel => 'मूव-इन टाइमलाइन';

  @override
  String get timelineImmediate => 'तुरंत';

  @override
  String get timelineThisMonth => 'इस महीने';

  @override
  String get timelineNextMonth => 'अगले महीने';

  @override
  String get timelineFlexible => 'लचीला';

  @override
  String get nonNegotiablesTitle => 'आपकी डील-ब्रेकर्स';

  @override
  String get nonNegotiablesSubtitle =>
      '3 चीज़ें चुनें जो आपके लिए बिल्कुल ज़रूरी हैं।';

  @override
  String get nonNegotiablesLimit => 'अधिकतम 3 चुनें';

  @override
  String get nonNegVegOnly => 'केवल शाकाहारी फ्लैटमेट्स';

  @override
  String get nonNegVeganOnly => 'केवल वीगन फ्लैटमेट्स';

  @override
  String get nonNegNoSmoking => 'केवल धूम्रपान न करने वाले';

  @override
  String get nonNegNoDrinking => 'घर पर शराब नहीं';

  @override
  String get nonNegNoGuests => 'रात को मेहमान नहीं';

  @override
  String get nonNegNoPets => 'पालतू नहीं';

  @override
  String get nonNegFemaleOnly => 'केवल महिला फ्लैटमेट्स';

  @override
  String get nonNegMaleOnly => 'केवल पुरुष फ्लैटमेट्स';

  @override
  String get nonNegNoParties => 'घर पर पार्टी नहीं';

  @override
  String get nonNegMinTidy => 'न्यूनतम सफाई स्तर';

  @override
  String get lifestyleQuizTitle => 'जीवनशैली प्राथमिकताएँ';

  @override
  String get emptySwipeDeck =>
      'अभी दिखाने के लिए कोई प्रोफ़ाइल नहीं है। बाद में दोबारा देखें!';

  @override
  String get tapToSeeMore => 'पूरी प्रोफ़ाइल देखें';

  @override
  String get whyThisMatchWorks => 'यह मैच क्यों काम करता है';

  @override
  String get tapToCollapse => 'छोटा करने के लिए टैप करें';

  @override
  String get aboutMeSection => 'मेरे बारे में';

  @override
  String get noBioYet => 'अभी कोई बायो नहीं है।';

  @override
  String get compatibilityBreakdown => 'कंपैटिबिलिटी विवरण';

  @override
  String get budgetLabel => 'बजट';

  @override
  String get blockConfirmTitle => 'इस व्यक्ति को ब्लॉक करें?';

  @override
  String get blockConfirmMessage =>
      'वे आपकी प्रोफ़ाइल नहीं देख पाएंगे या संपर्क नहीं कर पाएंगे।';

  @override
  String get blockCta => 'ब्लॉक करें';

  @override
  String get userBlocked => 'उपयोगकर्ता को ब्लॉक कर दिया गया है।';

  @override
  String get userUnmatched => 'आपने इस व्यक्ति को अनमैच कर दिया है।';

  @override
  String get reportTitle => 'इस व्यक्ति की रिपोर्ट करें';

  @override
  String get reportFakeProfile => 'नकली प्रोफ़ाइल';

  @override
  String get reportSpam => 'स्पैम';

  @override
  String get reportInappropriate => 'अनुचित सामग्री';

  @override
  String get reportUncomfortable => 'असहज इंटरैक्शन';

  @override
  String get reportOther => 'अन्य';

  @override
  String get reportCta => 'रिपोर्ट करें';

  @override
  String get reportSubmitted =>
      'रिपोर्ट भेज दी गई है। हम जल्द ही समीक्षा करेंगे।';

  @override
  String get unmatchConfirmTitle => 'अनमैच करें?';

  @override
  String get unmatchConfirmMessage =>
      'इससे आपका मैच हट जाएगा और बातचीत समाप्त हो जाएगी।';

  @override
  String get unmatchCta => 'अनमैच करें';

  @override
  String get icebreakerTitle => 'बर्फ तोड़ें';

  @override
  String get backCta => 'वापस';

  @override
  String get listingBuilderTitle => 'अपना स्पेस पोस्ट करें';

  @override
  String get listingStepLocation => 'प्रॉपर्टी लोकेशन';

  @override
  String get listingStepSociety => 'सोसायटी';

  @override
  String get listingStepRoom => 'कमरा';

  @override
  String get listingStepFlat => 'फ्लैट';

  @override
  String get listingStepCosts => 'लागत';

  @override
  String get listingStepAbout => 'आपके बारे में और पसंदीदा फ्लैटमेट';

  @override
  String get societyBuildingLabel => 'सोसायटी / बिल्डिंग का नाम';

  @override
  String get fullAddressLabel => 'पूरा पता';

  @override
  String get societyTypeLabel => 'सोसायटी प्रकार';

  @override
  String get societyTypeGated => 'गेटेड';

  @override
  String get societyTypeIndependent => 'इंडिपेंडेंट';

  @override
  String get societyTypeCoLiving => 'को-लिविंग';

  @override
  String get societyTypePg => 'PG';

  @override
  String get societyAmenitiesLabel => 'सोसायटी सुविधाएँ';

  @override
  String get societyVibeLabel => 'सोसायटी वाइब';

  @override
  String get amenityPool => 'स्विमिंग पूल';

  @override
  String get amenityGym => 'जिम';

  @override
  String get amenityClubhouse => 'क्लबहाउस';

  @override
  String get amenitySports => 'स्पोर्ट्स';

  @override
  String get amenityParking => 'पार्किंग';

  @override
  String get amenityPowerBackup => 'पावर बैकअप';

  @override
  String get amenityWaterBackup => 'वॉटर बैकअप';

  @override
  String get amenitySecurity => 'सिक्योरिटी';

  @override
  String get amenityLift => 'लिफ्ट';

  @override
  String get amenityCctv => 'CCTV';

  @override
  String get amenityVisitorEntry => 'विज़िटर एंट्री';

  @override
  String get amenityGarden => 'गार्डन';

  @override
  String get vibeBachelorFriendly => 'बैचलर-फ्रेंडली';

  @override
  String get vibeQuiet => 'शांत और फोकस्ड';

  @override
  String get vibeActiveCommunity => 'एक्टिव कम्युनिटी';

  @override
  String get vibeFamilyDominant => 'फैमिली-डॉमिनेंट';

  @override
  String get vibePetFriendly => 'पेट-फ्रेंडली';

  @override
  String get vibeVisitorFriendly => 'विज़िटर-फ्रेंडली';

  @override
  String get roomTypeLabel => 'कमरे का प्रकार';

  @override
  String get roomTypeMasterBedroom => 'मास्टर बेडरूम';

  @override
  String get furnishingLabel => 'कमरे की फर्निशिंग';

  @override
  String get furnishingBed => 'बेड';

  @override
  String get furnishingWardrobe => 'अलमारी';

  @override
  String get furnishingAc => 'AC';

  @override
  String get furnishingGeyser => 'गीज़र';

  @override
  String get furnishingStudyTable => 'स्टडी टेबल';

  @override
  String get furnishingCurtains => 'पर्दे';

  @override
  String get roomFeaturesLabel => 'कमरे की सुविधाएँ';

  @override
  String get roomFeatureBalcony => 'प्राइवेट बालकनी';

  @override
  String get roomFeatureSunlight => 'खिड़की से धूप';

  @override
  String get roomFeatureStorage => 'स्टोरेज स्पेस';

  @override
  String get roomPhotosLabel => 'कमरे की फ़ोटो';

  @override
  String get minPhotosRequired => 'कम से कम 2 फ़ोटो ज़रूरी';

  @override
  String get flatConfigLabel => 'फ्लैट कॉन्फ़िगरेशन';

  @override
  String get floorLabel => 'मंज़िल';

  @override
  String get totalFloorsLabel => 'कुल मंज़िलें';

  @override
  String get flatAmenitiesLabel => 'फ्लैट की सुविधाएँ';

  @override
  String get amenityRefrigerator => 'फ्रिज';

  @override
  String get amenityMicrowave => 'माइक्रोवेव';

  @override
  String get amenityTv => 'TV';

  @override
  String get amenityDiningTable => 'डाइनिंग टेबल';

  @override
  String get amenitySofa => 'सोफ़ा';

  @override
  String get amenityKitchenEquipped => 'किचन लैग्ज़';

  @override
  String get electricityLabel => 'बिजली';

  @override
  String get includedLabel => 'शामिल';

  @override
  String get separateLabel => 'अलग';

  @override
  String get electricityEstLabel => 'बिजली (अनुमानित मासिक)';

  @override
  String get cookCostLabel => 'कुक खर्चा / महीना';

  @override
  String get maidCostLabel => 'मेड खर्चा / महीना';

  @override
  String get setupCostLabel => 'वन-टाइम सेटअप खर्चा';

  @override
  String totalMonthlyOutflow(String amount) {
    return 'आपका अनुमानित मासिक खर्चा: $amount';
  }

  @override
  String get typicalDayLabel => 'अपना एक दिन बताएं';

  @override
  String get typicalDayHint =>
      'मैं 7 बजे उठता हूं, 6 तक घर से काम करता हूं, डिनर बनाता हूं...';

  @override
  String get ageRangeLabel => 'पसंदीदा फ्लैटमेट उम्र सीमा';

  @override
  String homeNewInCity(String city) {
    return '$city में नया';
  }

  @override
  String get homeMovingSoon => 'जल्दी शिफ्ट हो रहे हैं';

  @override
  String get vibeAll => 'सभी';

  @override
  String get vibeQuietFocused => 'शांत और फोकस्ड';

  @override
  String get vibeSocialLively => 'सोशल और लाइवली';

  @override
  String get vibeWorkingProf => 'वर्किंग प्रोफेशनल्स';

  @override
  String get vibeStudents => 'स्टूडेंट्स';

  @override
  String get vibePetHousehold => 'पालतू परिवार';

  @override
  String cityCounter(int count, String city) {
    return '$city में अभी $count लोग ढूंढ रहे हैं';
  }

  @override
  String get waitlistTitle => 'अभी लोग कम हैं';

  @override
  String waitlistSubtitle(String city) {
    return 'जब $city में ज़्यादा फ्लैटमेट्स जुड़ेंगे तब हम सूचित करेंगे।';
  }

  @override
  String get waitlistNotifyCta => 'मुझे सूचित करें';

  @override
  String get shareListingCta => 'लिस्टिंग शेयर करें';

  @override
  String get copyLinkAction => 'लिंक कॉपी करें';

  @override
  String get linkCopiedToast => 'लिंक कॉपी हो गया';

  @override
  String get listingUnderReview => 'लिस्टिंग समीक्षा में है';

  @override
  String get listingLive => 'लाइव';

  @override
  String get listingPaused => 'रोका हुआ';

  @override
  String get listingExpired => 'एक्सपायर';

  @override
  String get manageListingTitle => 'लिस्टिंग मैनेज करें';

  @override
  String get postHubTitle => 'आपकी लिस्टिंग';

  @override
  String get postHubPostSubtitle => 'मिनटों में नई रूम लिस्टिंग बनाएं';

  @override
  String get manageListingsTitle => 'लिस्टिंग प्रबंधित करें';

  @override
  String get postHubManageSubtitle =>
      'अपनी लिस्टिंग संपादित करें, रोकें या नवीनीकृत करें';

  @override
  String postHubActiveCount(int count) {
    return '$count सक्रिय';
  }

  @override
  String postHubDraftCount(int count) {
    return '$count ड्राफ्ट';
  }

  @override
  String get couldNotLoadListings => 'लिस्टिंग लोड नहीं हो सकीं';

  @override
  String get boostListingCta => 'लिस्टिंग बूस्ट करें';

  @override
  String get pauseListingCta => 'रोकें';

  @override
  String get editListingCta => 'संपादित करें';

  @override
  String get shareCta => 'शेयर करें';

  @override
  String get verifiedFilterLabel => 'वेरिफ़ाइड';

  @override
  String get qnaNudgeTitle => 'पहले बातचीत शुरू करें?';

  @override
  String get qnaNudgeSubtitle =>
      'बातचीत शुरू करने के लिए 3 सवालों के जवाब दें।';

  @override
  String get qnaQuestion1 => 'आपकी आदर्श फ्लैटमेट स्थिति कैसी होनी चाहिए?';

  @override
  String get qnaQuestion1Hint =>
      'जैसे कोई शांत व्यक्ति जो निजी स्पेस का सम्मान करता हो...';

  @override
  String get qnaQuestion2 => 'एक आम वर्कडे पर आप घर पर कितने सामाजिक रहते हैं?';

  @override
  String get qnaQuestion3 => 'फ्लैटमेट में आपको क्या बिल्कुल चाहिए?';

  @override
  String get qnaQuestion3Hint => 'जैसे सफाई, पंक्चुअलिटी, ईमानदारी...';

  @override
  String get qnaAnswerCta => 'सवालों के जवाब दें';

  @override
  String get qnaSkipCta => 'अभी छोड़ें';

  @override
  String get qnaBothAnsweredBanner => 'दोनों ने जवाब दिए';

  @override
  String qnaPeerAnsweredBanner(String peerName) {
    return '$peerName ने जवाब दिए';
  }

  @override
  String get qnaYouAnsweredBanner => 'आपके जवाब सेव हैं';

  @override
  String get qnaPeerAnsweredPrompt =>
      'मिलने से पहले बेहतर संदर्भ के लिए अपने जवाब भी शेयर करें।';

  @override
  String qnaTheirAnswers(String peerName) {
    return '$peerName के जवाब';
  }

  @override
  String get qnaYourAnswers => 'आपके जवाब';

  @override
  String get waitlistConfirmed => 'आप सूची में हैं! हम आपको सूचित करेंगे।';

  @override
  String get waitlistInviteFriends => 'दोस्तों को आमंत्रित करें';

  @override
  String waitlistShareMessage(String city, String url) {
    return '360 FlatMates $city में शुरू हो रहा है। वेटलिस्ट में जुड़ें और यहाँ और फ्लैटमेट्स लाने में मदद करें:\n$url';
  }

  @override
  String get yourNumberIsPrivate => 'आपका नंबर गोपनीय रखा जाता है';

  @override
  String get privacyTitle => 'गोपनीयता';

  @override
  String get hideLastNameLabel => 'सार्वजनिक प्रोफ़ाइल पर उपनाम छिपाएं';

  @override
  String get hideExactLocationLabel => 'लिस्टिंग पर सटीक लोकेशन छिपाएं';

  @override
  String get visitConfirmTitle => 'इस विज़िट की पुष्टि करें?';

  @override
  String get visitConfirmCta => 'विज़िट पुष्टि करें';

  @override
  String get visitRescheduleCta => 'दूसरा समय सुझाएं';

  @override
  String get visitCancelCta => 'विज़िट रद्द करें';

  @override
  String get visitCancelConfirm =>
      'क्या आप वाकई इस विज़िट को रद्द करना चाहते हैं?';

  @override
  String get visitConfirmed => 'विज़िट पुष्ट';

  @override
  String get visitCancelled => 'विज़िट रद्द की गई।';

  @override
  String get videoTourLabel => 'वीडियो टूर (वैकल्पिक)';

  @override
  String get videoTourHint => '15-60 सेकंड का वर्टिकल वीडियो, अधिकतम 50MB';

  @override
  String get addVideoCta => 'वीडियो टूर जोड़ें';

  @override
  String get videoTourAdded => 'वीडियो टूर जोड़ दिया गया';

  @override
  String get videoTooLarge => 'वीडियो 50MB से कम होना चाहिए';

  @override
  String get videoTooLong => 'वीडियो 60 सेकंड से कम होना चाहिए';

  @override
  String get videoTooShort => 'वीडियो कम से कम 15 सेकंड का होना चाहिए';

  @override
  String get tapToUnmute => 'अनम्यूट करने के लिए टैप करें';

  @override
  String get soundOn => 'आवाज़ चालू';

  @override
  String get passActionLabel => 'पास';

  @override
  String get likeActionLabel => 'लाइक';

  @override
  String get photoPendingLabel => 'फ़ोटो बाकी है';

  @override
  String get readReceiptSent => 'भेजा गया';

  @override
  String get readReceiptDelivered => 'पहुंचाया गया';

  @override
  String get readReceiptRead => 'पढ़ा गया';

  @override
  String get chatPollingInfo => 'मैसेज अपने आप रिफ्रेश होते हैं';

  @override
  String get flatDetailsTitle => 'फ्लैट विवरण';

  @override
  String get notificationsTitle => 'नोटिफिकेशन';

  @override
  String get notificationEmpty => 'अभी कोई नोटिफिकेशन नहीं है।';

  @override
  String get helpSafetyTitle => 'सहायता और सुरक्षा';

  @override
  String get safetyTips => 'सुरक्षा सुझाव';

  @override
  String get reportProblem => 'समस्या की रिपोर्ट करें';

  @override
  String get contactSupport => 'सहायता से संपर्क करें';

  @override
  String get communityGuidelines => 'समुदाय दिशानिर्देश';

  @override
  String get privacyPolicy => 'गोपनीयता नीति';

  @override
  String get termsOfService => 'सेवा की शर्तें';

  @override
  String get listingUnderReviewTitle => 'लिस्टिंग समीक्षा में है';

  @override
  String get underReview => 'समीक्षा में है';

  @override
  String get reviewTimeline => 'समीक्षा टाइमलाइन';

  @override
  String get goToHomeFeed => 'होम फ़ीड पर जाएं';

  @override
  String get viewListing => 'लिस्टिंग देखें';

  @override
  String get editResubmit => 'संपादित करें और फिर से भेजें';

  @override
  String get reportListing => 'लिस्टिंग की रिपोर्ट करें';

  @override
  String get reportListingTitle => 'इस लिस्टिंग की रिपोर्ट करें';

  @override
  String get reportListingReason => 'आप यह लिस्टिंग क्यों रिपोर्ट कर रहे हैं?';

  @override
  String get reportListingSubmitted =>
      'धन्यवाद। हम इस लिस्टिंग की समीक्षा करेंगे।';

  @override
  String get reportReasonInappropriate => 'अनुपयुक्त सामग्री';

  @override
  String get reportReasonScam => 'संदिग्ध घोटाला या धोखाधड़ी';

  @override
  String get reportReasonOutdated => 'लिस्टिंग पुरानी या अनुपलब्ध है';

  @override
  String get reportReasonOther => 'अन्य';

  @override
  String get compatibilityScore => 'कंपैटिबिलिटी स्कोर';

  @override
  String get aboutMe => 'मेरे बारे में';

  @override
  String get flatDetails => 'फ्लैट विवरण';

  @override
  String get costsBreakdown => 'लागत विवरण';

  @override
  String get moveInDate => 'मूव-इन तारीख';

  @override
  String get newMatch => 'नया मैच';

  @override
  String get newMessage => 'नया संदेश';

  @override
  String get listingApproved => 'लिस्टिंग स्वीकृत';

  @override
  String get visitScheduled => 'विज़िट निर्धारित';

  @override
  String get faqTitle => 'सामान्य प्रश्न';

  @override
  String get whatHappensNext => 'आगे क्या होगा';

  @override
  String get aiPreScreen => 'AI प्री-स्क्रीन';

  @override
  String get manualReview => 'मैन्युअल समीक्षा';

  @override
  String get youWillBeNotified => 'आपको सूचित किया जाएगा';

  @override
  String get notificationChannelName => 'संदेश और मैच';

  @override
  String get notificationChannelDescription =>
      'नए संदेश, मैच और विजिट की सूचनाएं';

  @override
  String get reviewTitle => 'अपनी लिस्टिंग की समीक्षा करें';

  @override
  String get reviewLocation => 'लोकेशन';

  @override
  String get reviewSociety => 'सोसायटी';

  @override
  String get reviewRoom => 'कमरा';

  @override
  String get reviewFlat => 'फ्लैट';

  @override
  String get reviewCosts => 'लागत';

  @override
  String get reviewAbout => 'आपके बारे में और पसंदीदा फ्लैटमेट';

  @override
  String get editStep => 'संपादित करें';

  @override
  String get filterApplied => 'फ़िल्टर लागू किए गए';

  @override
  String get noListingsMatchFilters =>
      'आपके फ़िल्टर्स से कोई लिस्टिंग नहीं मिली। उन्हें बदलकर देखें।';

  @override
  String get listingRejected => 'अस्वीकृत';

  @override
  String get reviewSupportText =>
      'हम 24 घंटे के भीतर आपकी लिस्टिंग की समीक्षा करेंगे';

  @override
  String get reviewStep3Desc =>
      'आपकी लिस्टिंग स्वीकृत और लाइव होने पर आपको सूचना मिलेगी।';

  @override
  String get resendOtpCta => 'OTP फिर से भेजें';

  @override
  String resendOtpCountdown(int seconds) {
    return '$seconds सेकंड में फिर से भेजें';
  }

  @override
  String get otpAutoReadHint => 'हम आपके SMS से OTP अपने आप पढ़ लेंगे।';

  @override
  String get societySectionTitle => 'सोसायटी';

  @override
  String get roomSectionTitle => 'कमरा';

  @override
  String get flatAndFlatmatesSectionTitle => 'फ्लैट और फ्लैटमेट्स';

  @override
  String get costsBreakdownSectionTitle => 'लागत विवरण';

  @override
  String get monthlyRentRow => 'मासिक किराया';

  @override
  String get securityDepositRow => 'सिक्योरिटी डिपॉज़िट';

  @override
  String get maintenanceRow => 'मेंटेनेंस';

  @override
  String get estimatedTotalRow => 'अनुमानित कुल / महीना';

  @override
  String get existingFlatmatesLabel => 'मौजूदा फ्लैटमेट्स';

  @override
  String get notAvailable => 'उपलब्ध नहीं';

  @override
  String get perPersonCostLabel => 'प्रति व्यक्ति (अनुमानित)';

  @override
  String get changePasswordLabel => 'पासवर्ड बदलें';

  @override
  String get privacySecurityLabel => 'गोपनीयता और सुरक्षा';

  @override
  String get preferencesLabel => 'पसंद';

  @override
  String get notificationSettingsLabel => 'नोटिफिकेशन सेटिंग्स';

  @override
  String get notificationSettingsTitle => 'नोटिफिकेशन प्राथमिकताएं';

  @override
  String get notificationSettingsSubtitle =>
      'चुनें कि आप कौन सी नोटिफिकेशन प्राप्त करना चाहते हैं';

  @override
  String get notifNewMessages => 'नए संदेश';

  @override
  String get notifNewMessagesDesc => 'नया संदेश मिलने पर सूचित करें';

  @override
  String get notifVisitReminders => 'विजिट रिमाइंडर';

  @override
  String get notifVisitRemindersDesc => 'आगामी प्रॉपर्टी विजिट के रिमाइंडर';

  @override
  String get notifNewMatches => 'नए मैच';

  @override
  String get notifNewMatchesDesc =>
      'जब कोई आपकी प्रोफ़ाइल को पसंद करे तो सूचित करें';

  @override
  String get notifListingUpdates => 'लिस्टिंग अपडेट';

  @override
  String get notifListingUpdatesDesc =>
      'आपकी लिस्टिंग व्यूज़ और रुचि के बारे में अपडेट';

  @override
  String get notifPromotions => 'प्रमोशन और टिप्स';

  @override
  String get notifPromotionsDesc => 'ऑफ़र, टिप्स और प्रोडक्ट अपडेट';

  @override
  String get notifEnableAll => 'सभी सक्षम करें';

  @override
  String get notifDisableAll => 'सभी अक्षम करें';

  @override
  String get blockedUsersLabel => 'ब्लॉक किए गए उपयोगकर्ता';

  @override
  String get noBlockedUsers => 'आपने अभी तक किसी को ब्लॉक नहीं किया है।';

  @override
  String get unblockCta => 'अनब्लॉक करें';

  @override
  String get userUnblocked => 'उपयोगकर्ता को अनब्लॉक कर दिया गया है।';

  @override
  String get unblockFailed => 'इस उपयोगकर्ता को अनब्लॉक नहीं किया जा सका।';

  @override
  String get newPasswordLabel => 'नया पासवर्ड';

  @override
  String get confirmPasswordLabel => 'पासवर्ड की पुष्टि करें';

  @override
  String get updatePasswordCta => 'पासवर्ड अपडेट करें';

  @override
  String get passwordUpdated => 'पासवर्ड अपडेट हो गया।';

  @override
  String get passwordsDoNotMatch => 'पासवर्ड मेल नहीं खाते।';

  @override
  String get passwordMinLength => 'पासवर्ड कम से कम 8 अक्षरों का होना चाहिए।';

  @override
  String get aboutLabel => 'के बारे में';

  @override
  String get termsAndConditionsLabel => 'नियम और शर्तें';

  @override
  String get termsAgreementPrefix => 'मैं इनसे सहमत हूं: ';

  @override
  String get termsAgreementConjunction => ' और ';

  @override
  String get searchHelpPlaceholder => 'सहायता खोजें';

  @override
  String get faqSubtitle => 'सामान्य प्रश्नों के उत्तर खोजें';

  @override
  String get popularTopicsLabel => 'लोकप्रिय विषय';

  @override
  String get popularTopicsSubtitle => 'लोकप्रिय मदद विषयों का अन्वेषण करें';

  @override
  String get bookingAgreementsLabel => 'बुकिंग और समझौते';

  @override
  String get bookingAgreementsSubtitle => 'बुकिंग, समझौते और नीतियाँ';

  @override
  String get accountProfileLabel => 'खाता और प्रोफ़ाइल';

  @override
  String get accountProfileSubtitle => 'अपने खाते और प्रोफ़ाइल का प्रबंधन करें';

  @override
  String get contactSupportSubtitle => 'हमारी सहायता टीम से संपर्क करें';

  @override
  String get chatWithUsCta => 'हमसे चैट करें';

  @override
  String get comingSoon => 'जल्द आ रहा है';

  @override
  String get replyTimeNote => 'हम आमतौर पर कुछ मिनटों में उत्तर देते हैं';

  @override
  String get helpFaqIntro =>
      '360 FlatMates के सबसे सामान्य सवालों के त्वरित जवाब।';

  @override
  String get helpFaqStartTitle => 'मैं फ्लैटमेट ढूंढना कैसे शुरू करूं?';

  @override
  String get helpFaqStartBody =>
      'ऑनबोर्डिंग पूरी करें, शहर और बजट सेट करें, फिर Discover, Map, Swipe और Chats का उपयोग करके उपयुक्त फ्लैटमेट या लिस्टिंग से जुड़ें।';

  @override
  String get helpFaqSafetyTitle => 'मिलने से पहले सुरक्षित कैसे रहें?';

  @override
  String get helpFaqSafetyBody =>
      'शुरुआती बातचीत ऐप में रखें, परिचित या साझा जगह पर मिलें, किराया और डिपॉजिट की जानकारी सत्यापित करें, और भरोसा बनने से पहले संवेदनशील दस्तावेज न भेजें।';

  @override
  String get helpFaqReportTitle => 'किसी को रिपोर्ट या ब्लॉक कैसे करूं?';

  @override
  String get helpFaqReportBody =>
      'उस व्यक्ति की चैट खोलें और रिपोर्ट या ब्लॉक एक्शन का उपयोग करें। रिपोर्ट समीक्षा के लिए 360 FlatMates टीम को भेजी जाती है।';

  @override
  String get helpFaqListingTitle => 'मैं अपना फ्लैट कैसे लिस्ट करूं?';

  @override
  String get helpFaqListingBody =>
      'प्रोफ़ाइल से Post Listing खोलें, जरूरी फ्लैट विवरण पूरे करें, और दूसरे उपयोगकर्ताओं को दिखने से पहले समीक्षा के लिए सबमिट करें।';

  @override
  String get helpPopularIntro =>
      'सक्रिय उपयोगकर्ताओं के लिए सबसे उपयोगी सुरक्षा और सहायता विषय।';

  @override
  String get helpPopularMeetingsTitle => 'पहली मुलाकात को सुरक्षित रखें';

  @override
  String get helpPopularMeetingsBody =>
      'संभव हो तो दिन में मिलें, किसी भरोसेमंद व्यक्ति को बताएं कि आप कहां जा रहे हैं, और शर्तें स्पष्ट होने तक नकद लेन-देन से बचें।';

  @override
  String get helpPopularVerifiedTitle => 'प्रोफ़ाइल भरोसा बढ़ाएं';

  @override
  String get helpPopularVerifiedBody =>
      'अपना असली नाम उपयोग करें, स्पष्ट प्रोफ़ाइल फोटो जोड़ें, और लाइफस्टाइल प्राथमिकताएं सही रखें ताकि मैच अनुकूलता समझ सकें।';

  @override
  String get helpPopularVisitsTitle => 'चैट और विज़िट';

  @override
  String get helpPopularVisitsBody =>
      'उपलब्धता की पुष्टि के लिए इन-ऐप चैट का उपयोग करें, लिस्टिंग या बातचीत स्क्रीन से विज़िट शेड्यूल करें, और जरूरी फैसले लिखित में रखें।';

  @override
  String get helpBookingsIntro =>
      'विज़िट, समझौतों और लिस्टिंग समीक्षा के लिए मार्गदर्शन। 360 FlatMates आपको जोड़ने में मदद करता है; अंतिम किराये की शर्तें संबंधित लोगों के बीच रहती हैं।';

  @override
  String get helpBookingsDecisionTitle => 'मूव करने से पहले';

  @override
  String get helpBookingsDecisionBody =>
      'मासिक किराया, डिपॉजिट, मेंटेनेंस, मूव-इन तारीख, नोटिस अवधि, घर के नियम और समझौते में किसका नाम होगा, यह पुष्टि करें।';

  @override
  String get helpBookingsAgreementsTitle => 'समझौते और दस्तावेज';

  @override
  String get helpBookingsAgreementsBody =>
      'तय शर्तों की लिखित कॉपी रखें और ऐप के बाहर साइन या भुगतान करने से पहले भरोसेमंद माध्यमों से ID या स्वामित्व विवरण सत्यापित करें।';

  @override
  String get helpBookingsListingReviewTitle => 'लिस्टिंग समीक्षा';

  @override
  String get helpBookingsListingReviewBody =>
      'सबमिट की गई लिस्टिंग लाइव होने से पहले गुणवत्ता और सुरक्षा के लिए समीक्षा में जा सकती है। विवरण बदलने पर आप संपादित करके फिर सबमिट कर सकते हैं।';

  @override
  String get helpAccountIntro =>
      'प्रोफ़ाइल, पासवर्ड, गोपनीयता और ब्लॉक किए गए उपयोगकर्ताओं को एक सुरक्षित जगह से संभालें।';

  @override
  String get helpAccountEditTitle => 'प्रोफ़ाइल विवरण संपादित करें';

  @override
  String get helpAccountEditBody =>
      'अपनी फोटो, लोकेशन, बजट, मूव-इन टाइमलाइन और लाइफस्टाइल जवाब अपडेट रखें ताकि सुझाव प्रासंगिक रहें।';

  @override
  String get helpAccountPrivacyTitle => 'गोपनीयता नियंत्रण';

  @override
  String get helpAccountPrivacyBody =>
      'थीम, भाषा और अंतिम नाम या सटीक लोकेशन छिपाने जैसी गोपनीयता प्राथमिकताओं को संभालने के लिए Settings का उपयोग करें।';

  @override
  String get helpAccountBlockedTitle => 'ब्लॉक किए गए उपयोगकर्ता';

  @override
  String get helpAccountBlockedBody =>
      'ब्लॉक किए गए लोग ऐप में आपसे संपर्क नहीं कर सकते। आप Blocked Users में उन्हें देख और अनब्लॉक कर सकते हैं।';

  @override
  String get helpContactIntro =>
      'कुछ गलत, असुरक्षित या अटका हुआ लगे तो सहायता से संपर्क करें।';

  @override
  String get helpContactWhatToSendTitle => 'क्या भेजें';

  @override
  String get helpContactWhatToSendBody =>
      'अपना फोन नंबर, संबंधित लिस्टिंग या बातचीत, उपयोगी स्क्रीनशॉट और क्या हुआ इसका छोटा विवरण भेजें।';

  @override
  String get helpContactUrgentTitle => 'तुरंत सुरक्षा समस्या';

  @override
  String get helpContactUrgentBody =>
      'अगर तत्काल खतरा है, तो पहले स्थानीय आपातकालीन सेवाओं से संपर्क करें, फिर सुरक्षित रूप से साझा की जा सकने वाली जानकारी के साथ सहायता को रिपोर्ट करें।';

  @override
  String get emailSupportCta => 'सपोर्ट को ईमेल करें';

  @override
  String get supportEmailSubject => '360 FlatMates सहायता अनुरोध';

  @override
  String get supportEmailBody =>
      'Hi 360 FlatMates Support, मुझे इसमें मदद चाहिए:';

  @override
  String supportEmailFallback(String email) {
    return 'हमें $email पर ईमेल करें';
  }

  @override
  String get externalLinkUnavailable =>
      'यह लिंक नहीं खुल सका। कृपया फिर कोशिश करें।';

  @override
  String get stepLabel => 'चरण';

  @override
  String get stepOfLabel => 'में से';

  @override
  String get societyBuildingHint => 'उदा., प्रेस्टीज लेकसाइड';

  @override
  String get fullAddressHint => 'पूरा पता दर्ज करें';

  @override
  String get monthlyRentHint => 'मासिक किराया दर्ज करें';

  @override
  String get securityDepositHint => 'सुरक्षा जमान राशि दर्ज करें';

  @override
  String get maintenanceHint => 'मेंटेनेंस शुल्क दर्ज करें';

  @override
  String get electricityEstHint => 'अनुमानित मासिक बिजली खर्च';

  @override
  String get cookCostHint => 'मासिक रसोई शुल्क';

  @override
  String get maidCostHint => 'मासिक मेड शुल्क';

  @override
  String get setupCostHint => 'एकमुश्त सेटअप खर्च';

  @override
  String get activeListingsLabel => 'सक्रिय लिस्टिंग';

  @override
  String get draftsLabel => 'ड्राफ्ट';

  @override
  String get expiredLabel => 'समाप्त';

  @override
  String get listingRejectedMessage => 'आपकी लिस्टिंग स्वीकृत नहीं हुई।';

  @override
  String get reviewSubmittedMessage =>
      'धन्यवाद! आपकी लिस्टिंग समीक्षा के लिए जमा कर दी गई है।';

  @override
  String get reviewListingCta => 'लिस्टिंग समीक्षा करें';

  @override
  String get etaHighlight =>
      'हम 24 घंटे के भीतर आपकी लिस्टिंग की समीक्षा करेंगे';

  @override
  String get step1Text =>
      'हमारी टीम गुणवत्ता और सुरक्षा के लिए आपकी लिस्टिंग की समीक्षा करती है।';

  @override
  String get step2Text => 'आपकी लिस्टिंग लाइव होने पर हम आपको सूचित करेंगे।';

  @override
  String get step3Text => 'लाइव हों और कनेक्ट करना शुरू करें!';

  @override
  String get yourListingLabel => 'आपकी लिस्टिंग';

  @override
  String get budgetFilterLabel => 'बजट';

  @override
  String budgetRangeLabel(String min, String max) {
    return '₹$min – ₹$max';
  }

  @override
  String get budgetPresetAny => 'कोई भी';

  @override
  String get budgetPresetUnder15k => '₹15k से कम';

  @override
  String get budgetPreset15to25k => '₹15–25k';

  @override
  String get budgetPreset25to40k => '₹25–40k';

  @override
  String get budgetPreset40to60k => '₹40–60k';

  @override
  String get budgetPreset60kPlus => '₹60k+';

  @override
  String get lifestyleFiltersLabel => 'लाइफ़स्टाइल';

  @override
  String get lifestyleFiltersSummaryAny => 'कोई प्राथमिकता नहीं';

  @override
  String get roomTypeFilterLabel => 'कमरे का प्रकार';

  @override
  String get roomTypeAny => 'कोई भी';

  @override
  String get roomTypePrivate => 'प्राइवेट';

  @override
  String get roomTypeShared => 'शेयर्ड';

  @override
  String get furnishingFilterLabel => 'फर्निशिंग';

  @override
  String get furnishingAny => 'कोई भी';

  @override
  String get furnishingFurnished => 'फर्निश्ड';

  @override
  String get furnishingUnfurnished => 'अनफर्निश्ड';

  @override
  String get genderFilterLabel => 'जेंडर';

  @override
  String get genderFilterAny => 'कोई भी';

  @override
  String get genderFilterMale => 'पुरुष';

  @override
  String get genderFilterFemale => 'महिला';

  @override
  String get moveInFilterLabel => 'मूव-इन';

  @override
  String get moveInAnytime => 'कभी भी';

  @override
  String get moveInImmediate => 'तुरंत';

  @override
  String get moveInWithin2Weeks => '2 सप्ताह में';

  @override
  String get moveInThisMonth => 'इस महीने';

  @override
  String get moveInNextMonth => 'अगले महीने';

  @override
  String get moveInJustExploring => 'अभी सिर्फ़ देख रहे हैं';

  @override
  String get moreFiltersLabel => 'अन्य फ़िल्टर';

  @override
  String get petsLabel => 'पालतू';

  @override
  String get petsYes => 'हाँ';

  @override
  String get petsNo => 'नहीं';

  @override
  String get petsNoPreference => 'कोई प्राथमिकता नहीं';

  @override
  String get smokingLabel => 'धूम्रपान';

  @override
  String get smokingNo => 'नहीं';

  @override
  String get smokingYes => 'हाँ';

  @override
  String get smokingNoPreference => 'कोई प्राथमिकता नहीं';

  @override
  String get nearbyChipLabel => 'निकटस्थ';

  @override
  String get budgetPlusChipLabel => 'बजट+';

  @override
  String get chatInputHint => 'संदेश टाइप करें...';

  @override
  String get emojiCta => 'इमोजी';

  @override
  String get dismissCta => 'बंद करें';

  @override
  String get phoneNotAvailable => 'फोन नंबर उपलब्ध नहीं है';

  @override
  String get emailNotAvailable => 'ईमेल उपलब्ध नहीं है';

  @override
  String get emojiPickerComingSoon => 'इमोजी पिकर जल्द आ रहा है';

  @override
  String get preferencesTitle => 'पसंद';

  @override
  String get preferencesSubtitle =>
      'हमें बताएं कि आपके लिए क्या मायने रखता है ताकि हम सही फ्लैटमेट्स और होम्स ढूंढ सकें।';

  @override
  String get prefGenderLabel => 'पसंदीदा जेंडर';

  @override
  String get prefFlatmatesLabel => 'अनुमत फ्लैटमेट्स';

  @override
  String get prefFoodLabel => 'खान-पान की आदतें';

  @override
  String get prefPetsLabel => 'पालतू जानवर';

  @override
  String get prefSmokingLabel => 'धूम्रपान';

  @override
  String get prefMoveInLabel => 'मूव-इन टाइमलाइन';

  @override
  String get prefNoPreference => 'कोई प्राथमिकता नहीं';

  @override
  String get prefMaleOnly => 'केवल पुरुष';

  @override
  String get prefFemaleOnly => 'केवल महिला';

  @override
  String get prefOther => 'अन्य';

  @override
  String get prefVeg => 'शाकाहारी';

  @override
  String get prefNonVeg => 'मांसाहारी';

  @override
  String get prefEggetarian => 'अंडाहारी';

  @override
  String get prefYes => 'हाँ';

  @override
  String get prefNo => 'नहीं';

  @override
  String get prefNext => 'आगे';

  @override
  String get settingsGroupAccount => 'खाता';

  @override
  String get settingsGroupApp => 'ऐप';

  @override
  String get settingsGroupLegal => 'कानूनी';

  @override
  String get qnaShareAnswers => 'जवाब साझा करें';

  @override
  String get qnaSkipForNow => 'अभी छोड़ें';

  @override
  String get qnaVeryPrivate => 'बहुत प्राइवेट';

  @override
  String get qnaMostlyPrivate => 'ज़्यादातर प्राइवेट';

  @override
  String get qnaBalanced => 'संतुलित';

  @override
  String get qnaMostlySocial => 'ज़्यादातर सामाजिक';

  @override
  String get qnaVerySocial => 'बहुत सामाजिक';

  @override
  String get closeSearch => 'खोज बंद करें';

  @override
  String get profileSetup => 'प्रोफ़ाइल सेटअप';

  @override
  String get aboutThisFlatSection => 'इस फ्लैट के बारे में';

  @override
  String get shortlistCta => 'लाइक';

  @override
  String get contactCta => 'संपर्क करें';

  @override
  String get postedOnLabel => 'पोस्ट की गई';

  @override
  String get verifiedListingLabel => 'वेरिफ़ाइड लिस्टिंग';

  @override
  String moveInCountdownBadge(int days) {
    return '$days दिनों में शिफ्ट';
  }

  @override
  String get moveInToday => 'आज शिफ्ट';

  @override
  String get vibeSocial => 'सोशल और लाइवली';

  @override
  String get vibeProfessional => 'प्रोफेशनल्स';

  @override
  String get vibeStudent => 'स्टूडेंट्स';

  @override
  String get vibePet => 'पालतू परिवार';

  @override
  String get addPhotosTitle => 'फ़ोटो जोड़ें';

  @override
  String get addPhotosTips => 'सुझाव';

  @override
  String get addPhotosInstruction =>
      'ज़्यादा मैच पाने के लिए कमरे और कॉमन एरिया की साफ़ फ़ोटो जोड़ें।';

  @override
  String get photoTipNaturalLight =>
      '• प्राकृतिक रोशनी में शूट करें — पर्दे खोल लें';

  @override
  String get photoTipFullRoom => '• कमरे को कोने से कोने तक पूरा दिखाएं';

  @override
  String get photoTipBathroomBalcony =>
      '• उपलब्ध हो तो बाथरूम और बालकनी भी दिखाएं';

  @override
  String get photoTipCleanRoom => '• फ़ोटो लेने से पहले कमरा साफ़ कर लें';

  @override
  String get addMorePhotosLabel => 'और फ़ोटो जोड़ें';

  @override
  String get scheduleVisitTitle => 'विज़िट शेड्यूल करें';

  @override
  String get selectTimeSlot => 'समय चुनें';

  @override
  String get timeSlotMorning => 'सुबह';

  @override
  String get timeSlotAfternoon => 'दोपहर';

  @override
  String get timeSlotEvening => 'शाम';

  @override
  String get addNoteOptional => 'नोट जोड़ें (वैकल्पिक)';

  @override
  String visitPrivacyNote(String name) {
    return 'आपका विज़िट अनुरोध $name के साथ साझा किया जाएगा।';
  }

  @override
  String get sendingLabel => 'भेज रहे हैं...';

  @override
  String get sendRequestCta => 'अनुरोध भेजें';

  @override
  String matchedOnDate(String date) {
    return '$date को मैच हुआ';
  }

  @override
  String get locationSelectionTitle => 'अपनी पसंदीदा लोकेशन चुनें';

  @override
  String get searchLocationPlaceholder => 'लोकेशन खोजें';

  @override
  String get useCurrentLocation => 'मेरी वर्तमान लोकेशन का उपयोग करें';

  @override
  String get detectingLocation => 'लोकेशन पता कर रहे हैं...';

  @override
  String get popularCitiesLabel => 'लोकप्रिय शहर';

  @override
  String get noLocationsAvailable => 'कोई लोकेशन उपलब्ध नहीं';

  @override
  String get clusterListingsTitle => 'इस क्षेत्र में लिस्टिंग';

  @override
  String clusterListingsCount(int count) {
    return '$count लिस्टिंग';
  }

  @override
  String get shareToWhatsapp => 'WhatsApp पर शेयर करें';

  @override
  String get whatsappNotInstalled => 'WhatsApp इंस्टॉल नहीं है';

  @override
  String get scanToOpen => 'लिस्टिंग खोलने के लिए स्कैन करें';

  @override
  String get matchItsAMatch => 'बढ़िया मैच!';

  @override
  String matchLikedEachOther(String peerName) {
    return 'आप और $peerName ने एक-दूसरे को पसंद किया';
  }

  @override
  String get matchSendMessage => 'संदेश भेजें';

  @override
  String get matchKeepSwiping => 'स्वाइप करते रहें';

  @override
  String get swipeNoMoreProfiles => 'और प्रोफ़ाइल नहीं हैं';

  @override
  String get swipeCheckBackLater => 'नए मैच के लिए बाद में देखें';

  @override
  String get swipeLikeLabel => 'पसंद';

  @override
  String get swipeNopeLabel => 'नहीं';

  @override
  String get failedToLoadProfiles => 'प्रोफ़ाइल लोड नहीं हो सकीं';

  @override
  String get actionFailedRetry =>
      'कार्रवाई विफल हुई। कृपया फिर से प्रयास करें।';

  @override
  String get wifiChipLabel => 'वाई-फ़ाई';

  @override
  String get parkingChipLabel => 'पार्किंग';

  @override
  String get liftChipLabel => 'लिफ्ट';

  @override
  String get securityChipLabel => '24/7 सुरक्षा';

  @override
  String get noDescriptionAvailable => 'कोई विवरण उपलब्ध नहीं।';

  @override
  String get flexibleLabel => 'लचीला';

  @override
  String get recentlyLabel => 'हाल ही में';

  @override
  String get safetyCheckedLabel => 'सुरक्षा जाँच की गई';

  @override
  String get couldNotLoadListing => 'लिस्टिंग लोड नहीं हो सकी';

  @override
  String get startAConversation => 'बातचीत शुरू करें';

  @override
  String get sayHelloOrIcebreaker => 'नमस्ते कहें या आइसब्रेकर इस्तेमाल करें';

  @override
  String get noMessagesYet => 'अभी कोई संदेश नहीं...';

  @override
  String get noMessagesYetHint =>
      'संदेश भेजें या नीचे दिए गए आइसब्रेकर्स पर टैप करें।';

  @override
  String get messagesArePrivate => 'संदेश निजी हैं';

  @override
  String get viewLabel => 'देखें';

  @override
  String byOwnerLabel(String name) {
    return '$name द्वारा';
  }

  @override
  String get couldNotLoadMessages => 'संदेश लोड नहीं हो सके';

  @override
  String get failedToSendMessage =>
      'संदेश भेजना विफल हुआ। कृपया फिर से प्रयास करें।';

  @override
  String get failedToBlockUser =>
      'उपयोगकर्ता को ब्लॉक करना विफल हुआ। कृपया फिर से प्रयास करें।';

  @override
  String get failedToReportUser =>
      'उपयोगकर्ता की रिपोर्ट करना विफल हुआ। कृपया फिर से प्रयास करें।';

  @override
  String get failedToUnmatch =>
      'अनमैच करना विफल हुआ। कृपया फिर से प्रयास करें।';

  @override
  String get failedToSendPhoto =>
      'फ़ोटो भेजना विफल हुआ। कृपया फिर से प्रयास करें।';

  @override
  String get couldNotLoadVisits => 'विज़िट लोड नहीं हो सकीं';

  @override
  String get blockedUsersAppearHere =>
      'जिन्हें आप ब्लॉक करेंगे वे यहां दिखेंगे';

  @override
  String get couldNotLoadBlockedUsers =>
      'ब्लॉक किए गए उपयोगकर्ता लोड नहीं हो सके';

  @override
  String get passwordRuleMinLength => 'कम से कम 8 अक्षर';

  @override
  String get passwordRuleUppercase => '1 बड़ा अक्षर';

  @override
  String get passwordRuleNumber => '1 अंक';

  @override
  String get safetyIsPriority => 'आपकी सुरक्षा हमारी प्राथमिकता है';

  @override
  String get supportAvailable247 => 'सहायता 24/7 उपलब्ध';

  @override
  String get notificationsEmptySubtitle =>
      'आपके मैच, विज़िट और लिस्टिंग की सूचनाएं यहां दिखेंगी';

  @override
  String get couldNotLoadNotifications => 'नोटिफिकेशन लोड नहीं हो सके';

  @override
  String get yesterdayLabel => 'कल';

  @override
  String get daysAgoLabel => 'दिन पहले';

  @override
  String get notificationNoAction =>
      'इस नोटिफिकेशन के लिए कोई कार्रवाई उपलब्ध नहीं है';

  @override
  String get submittedLabel => 'जमा किया गया';

  @override
  String get underReviewStepLabel => 'समीक्षा में है';

  @override
  String get liveStepLabel => 'लाइव';

  @override
  String get pleaseReviewAndResubmit =>
      'कृपया नीचे दिए गए कारण की समीक्षा करें और फिर से जमा करें।';

  @override
  String get rejectionReasonLabel => 'अस्वीकृति का कारण';

  @override
  String get rejectionDetailText =>
      'लिस्टिंग हमारे समुदाय दिशानिर्देशों को पूरा नहीं करती। कृपया सुनिश्चित करें कि सभी जानकारी सटीक हो और फ़ोटो साफ़ हों।';

  @override
  String get activeStatus => 'सक्रिय';

  @override
  String get draftStatus => 'ड्राफ्ट';

  @override
  String get expiredStatus => 'समाप्त';

  @override
  String get notificationsTooltip => 'नोटिफिकेशन';

  @override
  String get chatTooltip => 'चैट';

  @override
  String get listingStatsTitle => 'लिस्टिंग आँकड़े';

  @override
  String get viewsStatLabel => 'व्यूज़';

  @override
  String get likesStatLabel => 'लाइक्स';

  @override
  String get matchesStatLabel => 'मैच';

  @override
  String get closeCta => 'बंद करें';

  @override
  String matchCountLabel(int count) {
    return 'मैच गिनती ($count)';
  }

  @override
  String get boostAction => 'बूस्ट';

  @override
  String viewStatsAction(String count) {
    return 'आँकड़े देखें ($count)';
  }

  @override
  String get reviewAction => 'समीक्षा';

  @override
  String get shareAction => 'शेयर';

  @override
  String get resumeAction => 'फिर शुरू करें';

  @override
  String get expiresToday => 'आज समाप्त';

  @override
  String expiresInDays(int days) {
    return '$days दिन में समाप्त';
  }

  @override
  String get failedToUpdateListingStatus =>
      'लिस्टिंग स्टेटस अपडेट नहीं हो सका।';

  @override
  String get noLikesYet => 'अभी कोई लाइक नहीं';

  @override
  String get noLikedYet => 'अभी कोई प्रोफ़ाइल पसंद नहीं';

  @override
  String get keepSwipingToFindMatches =>
      'ज़्यादा विज़िबिलिटी के लिए अपनी प्रोफ़ाइल पूरी करें।';

  @override
  String get noConversations => 'अभी कोई चैट नहीं';

  @override
  String get startChatWithMatch =>
      'बातचीत शुरू करने के लिए कुछ प्रोफ़ाइल लाइक करें।';

  @override
  String get matchAction => 'मैच करें';

  @override
  String get waitingForResponse => 'प्रतीक्षा';

  @override
  String get matchCreateFailed => 'मैच नहीं बन सका। फिर से प्रयास करें।';

  @override
  String get couldNotLoadConversations => 'बातचीत लोड नहीं हो सकी';

  @override
  String get downloadToConnect => 'जुड़ने के लिए 360 फ्लैटमेट्स डाउनलोड करें';

  @override
  String get findYourFlatmateShare => '360 फ्लैटमेट्स पर अपना फ्लैटमेट ढूंढें!';

  @override
  String get checkOutListingShare => '360 फ्लैटमेट्स पर इस लिस्टिंग को देखें!';

  @override
  String get passwordUpdateFailed =>
      'पासवर्ड अपडेट करने में विफल। कृपया पुनः प्रयास करें।';

  @override
  String get visitRequestFailed =>
      'विज़िट अनुरोध भेजने में विफल। कृपया पुनः प्रयास करें।';

  @override
  String get visitActionFailed => 'कार्रवाई विफल। कृपया पुनः प्रयास करें।';

  @override
  String get listingSubmitFailed =>
      'लिस्टिंग सबमिट करने में विफल। कृपया पुनः प्रयास करें।';

  @override
  String get listingHelperLocation =>
      'सही लोकेशन लोगों को आपको ढूंढने में मदद करती है';

  @override
  String get listingHelperSociety =>
      'सही फ्लैटमेट्स को आकर्षित करने के लिए सोसायटी के बारे में बताएं';

  @override
  String get listingHelperRoom =>
      'फ्लैटमेट्स को पता चले कि कमरा कैसा है, ऐसा बताएं';

  @override
  String get listingHelperPhotos =>
      'अच्छी फ़ोटो से 3 गुना ज़्यादा रिस्पॉन्स मिलता है';

  @override
  String get listingHelperFlat =>
      'फ्लैट डिटेल्स से फ्लैटमेट्स तय कर सकते हैं कि यह सही है या नहीं';

  @override
  String get listingHelperCosts => 'पारदर्शी मूल्य निर्धारण भरोसा बनाता है';

  @override
  String get listingHelperAbout =>
      'एक अच्छी बायो लोगों को आपको जानने में मदद करती है';

  @override
  String get listingHelperReview =>
      'लगभग हो गया! लाइव होने से पहले सब कुछ जांचें';

  @override
  String get listingRentRequired => 'मासिक किराया ज़रूरी है';

  @override
  String get listingPhotosRequired => 'कम से कम 2 फ़ोटो जोड़ें';

  @override
  String get listingDepositInvalid => 'सही राशि दर्ज करें';

  @override
  String get listingMaintenanceInvalid => 'सही राशि दर्ज करें';

  @override
  String get listingCostInvalid => 'सही राशि दर्ज करें';

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
    return '$roomType • $furnishingCount आइटम';
  }

  @override
  String listingSummaryPhotos(int count, String plural) {
    return '$count फ़ोटो$plural';
  }

  @override
  String listingSummaryFlat(String config, String floor) {
    return '$config • मंज़िल $floor';
  }

  @override
  String listingSummaryCosts(String rent) {
    return 'किराया: ₹$rent/महीना';
  }

  @override
  String listingSummaryAbout(String gender, String ageMin, String ageMax) {
    return '$gender • उम्र $ageMin-$ageMax';
  }

  @override
  String get workStyleOffice => 'ऑफिस';

  @override
  String get workStyleHybrid => 'हाइब्रिड';

  @override
  String get workStyleWfh => 'वर्क फ्रॉम होम';

  @override
  String get phoneVerifiedLabel => 'फ़ोन सत्यापित';

  @override
  String get showResultsCta => 'परिणाम दिखाएं';

  @override
  String showResultsWithFiltersCta(int count) {
    return 'परिणाम दिखाएं · $count फ़िल्टर';
  }

  @override
  String get searchFiltersTitle => 'खोजें और फ़िल्टर';

  @override
  String get clearAllFilters => 'सभी हटाएं';

  @override
  String get errorNetwork =>
      'कोई इंटरनेट कनेक्शन नहीं। कृपया अपना नेटवर्क जांचें और पुनः प्रयास करें।';

  @override
  String get errorAuthExpired => 'सत्र समाप्त हो गया। कृपया पुनः साइन इन करें।';

  @override
  String get errorAuth => 'प्रमाणीकरण विफल। कृपया पुनः प्रयास करें।';

  @override
  String get errorServer => 'सर्वर त्रुटि। कृपया बाद में पुनः प्रयास करें।';

  @override
  String get errorPermission => 'आपको यह क्रिया करने की अनुमति नहीं है।';

  @override
  String get errorNotFound => 'अनुरोधित संसाधन नहीं मिला।';

  @override
  String get errorValidation => 'अमान्य डेटा। कृपया अपना इनपुट जांचें।';

  @override
  String get errorRateLimit =>
      'बहुत अधिक अनुरोध। कृपया थोड़ी देर प्रतीक्षा करें और पुनः प्रयास करें।';

  @override
  String get errorConflict => 'एक विरोधाभास हुआ। डेटा बदल गया होगा।';

  @override
  String get errorUpload => 'अपलोड विफल। कृपया पुनः प्रयास करें।';

  @override
  String get errorOtpInvalid => 'अमान्य या समाप्त कोड। कृपया पुनः प्रयास करें।';

  @override
  String get errorInvalidCredentials => 'गलत पासवर्ड। कृपया पुनः प्रयास करें।';

  @override
  String get errorAuthSessionMissing => 'सत्यापन विफल। कृपया पुनः प्रयास करें।';

  @override
  String get errorUnknown => 'कुछ गलत हो गया। कृपया पुनः प्रयास करें।';

  @override
  String get icebreakerTellMeRoom => 'मुझे कमरे के बारे में बताएं!';

  @override
  String get icebreakerWhatFlatmates => 'फ्लैटमेट्स कैसे हैं?';

  @override
  String get icebreakerNegotiateRent => 'क्या किराया पर बातचीत हो सकती है?';

  @override
  String get icebreakerSocietyVibe => 'सोसाइटी का माहौल कैसा है?';

  @override
  String get icebreakerWeekendLook => 'यहाँ सप्ताहांत कैसा दिखता है?';

  @override
  String reviewRentAmount(String amount) {
    return 'किराया: ₹$amount/माह';
  }

  @override
  String reviewDepositAmount(String amount) {
    return 'जमा राशि: ₹$amount';
  }

  @override
  String reviewMaintenanceAmount(String amount) {
    return 'रखरखाव: ₹$amount';
  }

  @override
  String reviewGenderAmount(String gender) {
    return 'लिंग: $gender';
  }

  @override
  String reviewAgeAmount(String min, String max) {
    return 'आयु: $min - $max';
  }

  @override
  String reviewMoveInAmount(String date) {
    return 'स्थानांतरण तिथि: $date';
  }

  @override
  String reviewPhotosAmount(int count, String plural) {
    return '$count फोटो$plural';
  }

  @override
  String get invalidListingId => 'अमान्य लिस्टिंग ID';

  @override
  String get invalidConversationId => 'अमान्य वार्तालाप ID';

  @override
  String get youAreOffline => 'आप ऑफ़लाइन हैं। अपना कनेक्शन जांचें।';

  @override
  String get visitScheduledNotificationFailed =>
      'यात्रा शेड्यूल की गई! सूचना भेजी नहीं जा सकी।';

  @override
  String get bootstrapErrorRetry => 'कुछ गलत हो गया। पुनः प्रयास करें।';

  @override
  String get boostListingTitle => 'लिस्टिंग बूस्ट करें';

  @override
  String get boostListingSubtitle =>
      'आपकी लिस्टिंग अगले 24 घंटों के लिए अधिक लोगों को दिखाई जाएगी।';

  @override
  String get boostNowCta => 'अभी बूस्ट करें';

  @override
  String get listingBoosted => 'लिस्टिंग 24 घंटों के लिए बूस्ट की गई!';

  @override
  String get pausedStatus => 'रोका हुआ';

  @override
  String get renewAction => 'नवीनीकरण';

  @override
  String get refreshProfilesCta => 'प्रोफ़ाइल रीफ़्रेश करें';

  @override
  String get swipeEmptyNoProfilesTitle => 'अभी कोई प्रोफ़ाइल उपलब्ध नहीं है';

  @override
  String get swipeEmptyNoProfilesSubtitle =>
      'हम आपके लिए नए मैच ढूंढ रहे हैं! जल्द ही दोबारा देखें।';

  @override
  String get swipeEmptyAllFilteredTitle =>
      'आपकी प्राथमिकताओं से कोई प्रोफ़ाइल मेल नहीं खाती';

  @override
  String get swipeEmptyAllFilteredSubtitle =>
      'अधिक प्रोफ़ाइल देखने के लिए अपनी शर्तें बदलें।';

  @override
  String get swipeEmptyEndOfDeckTitle => 'आपने अभी सभी को देख लिया है';

  @override
  String get swipeEmptyEndOfDeckSubtitle =>
      'हम आपके लिए नए मैच ढूंढ रहे हैं! बाद में दोबारा देखें।';

  @override
  String get locationServicesDisabled =>
      'लोकेशन सेवाएं बंद हैं। कृपया अपनी डिवाइस सेटिंग में GPS/लोकेशन चालू करें।';

  @override
  String get locationServicesDisabledAction => 'सेटिंग खोलें';

  @override
  String get locationPermissionDeniedForever =>
      'लोकेशन की अनुमति अस्वीकार की गई। कृपया ऐप सेटिंग में इसे चालू करें।';

  @override
  String get locationOpenAppSettings => 'ऐप सेटिंग खोलें';

  @override
  String get locationNoMatchFound =>
      'आस-पास कोई मेल खाता शहर नहीं मिला। कृपया मैन्युअल रूप से चुनें।';

  @override
  String get searchCityOrAreaHint => 'शहर या क्षेत्र खोजें';

  @override
  String get suggestionsLabel => 'सुझाव';

  @override
  String get locationPickerTitle => 'लोकेशन चुनें';

  @override
  String get locationPickerSearchHint => 'क्षेत्र, लोकैलिटी, शहर खोजें...';

  @override
  String get matchingCitiesLabel => 'मेल खाते शहर';

  @override
  String get noCitiesFound => 'कोई शहर नहीं मिला';

  @override
  String get moreCitiesLabel => 'अन्य शहर';

  @override
  String get searchRadiusLabel => 'खोज त्रिज्या';

  @override
  String distanceKmLabel(int distance) {
    return '$distance किमी';
  }

  @override
  String get currentLocationLabel => 'वर्तमान लोकेशन';

  @override
  String get locationDetailsFailed => 'लोकेशन विवरण नहीं मिल सका';

  @override
  String get selectLocationLabel => 'लोकेशन चुनें';

  @override
  String get locationSectionTitle => 'लोकेशन';

  @override
  String get getDirectionsLabel => 'दिशा-निर्देश प्राप्त करें';

  @override
  String get openInMapsLabel => 'मैप्स में खोलें';

  @override
  String get propertyFallbackLabel => 'प्रॉपर्टी';

  @override
  String distanceMeters(int distance) {
    return '$distanceमी दूर';
  }

  @override
  String distanceKmDecimal(String distance) {
    return '$distanceकिमी दूर';
  }

  @override
  String distanceKm(int distance) {
    return '$distanceकिमी दूर';
  }

  @override
  String get availableNowLabel => 'अभी उपलब्ध';

  @override
  String get availableLabel => 'उपलब्ध';

  @override
  String availableFromShort(String date) {
    return '$date से';
  }

  @override
  String availableFromFull(String date) {
    return '$date से उपलब्ध';
  }

  @override
  String get genderSuffixMaleOnly => 'केवल पुरुष';

  @override
  String get genderSuffixFemaleOnly => 'केवल महिला';

  @override
  String get genderSuffixAny => 'कोई भी जेंडर';

  @override
  String get activeRecentlyLabel => 'हाल ही में सक्रिय';

  @override
  String get couldNotLoadContent => 'सामग्री लोड नहीं हो सकी।';

  @override
  String get forceUpdateTitle => 'अपडेट ज़रूरी है';

  @override
  String get forceUpdateMessage =>
      '360 फ्लैटमेट्स का एक नया वर्शन उपलब्ध है। कृपया ऐप इस्तेमाल करने के लिए अपडेट करें।';

  @override
  String get forceUpdateCta => 'अभी अपडेट करें';

  @override
  String get optionalUpdateTitle => 'अपडेट उपलब्ध';

  @override
  String get optionalUpdateMessage =>
      '360 फ्लैटमेट्स का एक नया वर्शन सुधार और बग फिक्स के साथ उपलब्ध है।';

  @override
  String get optionalUpdateCta => 'अभी अपडेट करें';

  @override
  String get optionalUpdateLater => 'बाद में';

  @override
  String get maintenanceTitle => 'मेंटेनेंस चल रहा है';

  @override
  String get maintenanceMessage =>
      'हम चीज़ें बेहतर बना रहे हैं। कृपया कुछ देर बाद दोबारा देखें।';

  @override
  String get maintenanceRetry => 'फिर से जांचें';

  @override
  String get deleteAccountCta => 'खाता हटाएं';

  @override
  String get deleteAccountTitle => 'अपना खाता हटाएं';

  @override
  String get deleteAccountWarning =>
      'यह कार्रवाई स्थायी है और इसे पूर्ववत नहीं किया जा सकता। आपका सारा डेटा जिसमें प्रोफ़ाइल, लिस्टिंग, चैट और मैच शामिल हैं, स्थायी रूप से हटा दिया जाएगा।';

  @override
  String get deleteAccountConfirmLabel => 'पुष्टि करने के लिए DELETE टाइप करें';

  @override
  String get deleteAccountConfirmHint => 'DELETE टाइप करें';

  @override
  String get deleteAccountButton => 'मेरा खाता हटाएं';

  @override
  String get deleteAccountCancelled => 'खाता हटाना रद्द किया गया।';

  @override
  String get deleteAccountFailed =>
      'खाता हटाने में विफल। कृपया पुनः प्रयास करें या सहायता से संपर्क करें।';

  @override
  String get forgotPasswordTitle => 'पासवर्ड भूल गए';

  @override
  String get forgotPasswordSubtitle =>
      'अपना फोन नंबर दर्ज करें और हम पासवर्ड रीसेट करने के लिए OTP भेजेंगे।';

  @override
  String get sendOtpCta => 'OTP भेजें';

  @override
  String get resetPasswordTitle => 'पासवर्ड रीसेट करें';

  @override
  String resetPasswordSubtitle(String phone) {
    return '$phone पर भेजा गया OTP दर्ज करें और अपना नया पासवर्ड सेट करें।';
  }

  @override
  String get forgotPasswordCta => 'पासवर्ड भूल गए?';

  @override
  String get noAccountCta => 'खाता नहीं है?';

  @override
  String get passwordResetSuccess =>
      'पासवर्ड सफलतापूर्वक रीसेट किया गया। कृपया साइन इन करें।';

  @override
  String get phoneNotRegistered => 'यह फोन नंबर पंजीकृत नहीं है।';

  @override
  String get loginWithPasswordCta => 'पासवर्ड से लॉगिन करें';

  @override
  String get reportABug => 'बग की रिपोर्ट करें';

  @override
  String get reportABugSubtitle => 'कुछ काम नहीं कर रहा? हमें बताएं।';

  @override
  String get requestAFeature => 'फीचर का अनुरोध करें';

  @override
  String get requestAFeatureSubtitle => 'ऐप को बेहतर बनाने का सुझाव साझा करें।';

  @override
  String get reportABugIntro => 'हमें बताएं कि क्या गलत हुआ और हम इसे देखेंगे।';

  @override
  String get requestAFeatureIntro =>
      'हमें बताएं कि आप ऐप में क्या देखना चाहेंगे।';

  @override
  String get feedbackTitleLabel => 'शीर्षक';

  @override
  String get feedbackTitleBugHint => 'बग का संक्षिप्त सारांश';

  @override
  String get feedbackTitleFeatureHint => 'आपके विचार का संक्षिप्त सारांश';

  @override
  String get feedbackTitleRequired => 'कृपया एक शीर्षक दर्ज करें।';

  @override
  String get feedbackDescriptionLabel => 'विवरण';

  @override
  String get feedbackDescriptionBugHint =>
      'दोहराने के चरण, आपने क्या उम्मीद की थी और क्या हुआ';

  @override
  String get feedbackDescriptionFeatureHint =>
      'फीचर का वर्णन करें और यह कैसे मदद करेगा';

  @override
  String get feedbackDescriptionRequired => 'कृपया एक विवरण दर्ज करें।';

  @override
  String get feedbackBugTypeLabel => 'बग का प्रकार';

  @override
  String get feedbackBugTypeFunctionality => 'कार्यक्षमता बग';

  @override
  String get feedbackBugTypeUi => 'यूआई बग';

  @override
  String get feedbackBugTypePerformance => 'प्रदर्शन समस्या';

  @override
  String get feedbackBugTypeCrash => 'क्रैश';

  @override
  String get feedbackBugTypeOther => 'अन्य';

  @override
  String get feedbackSeverityLabel => 'गंभीरता';

  @override
  String get feedbackSeverityLow => 'कम';

  @override
  String get feedbackSeverityMedium => 'मध्यम';

  @override
  String get feedbackSeverityHigh => 'उच्च';

  @override
  String get feedbackSeverityCritical => 'गंभीर';

  @override
  String get feedbackSubmitCta => 'सबमिट करें';

  @override
  String get feedbackSubmitSuccess => 'आपकी प्रतिक्रिया के लिए धन्यवाद!';

  @override
  String get profileUpdated => 'प्रोफ़ाइल सफलतापूर्वक अपडेट की गई';

  @override
  String get listingPublished => 'लिस्टिंग सफलतापूर्वक प्रकाशित हुई';

  @override
  String get listingResumed => 'लिस्टिंग फिर से शुरू की गई';

  @override
  String get shortlisted => 'लाइक किया गया';

  @override
  String get shortlistRemoved => 'लाइक हटाया गया';

  @override
  String get contactRequestSentToast => 'संपर्क अनुरोध भेजा गया';

  @override
  String get listingLabel => 'लिस्टिंग';

  @override
  String get liveBadge => 'लाइव';

  @override
  String get floorPlanSectionTitle => 'फ़्लोर प्लान';

  @override
  String get tapToZoomHint => 'ज़ूम करने के लिए टैप करें';

  @override
  String get factBedsLabel => 'बेड';

  @override
  String get factBathsLabel => 'बाथ';

  @override
  String get factAreaLabel => 'वर्ग फ़ुट';

  @override
  String get factFloorLabel => 'मंज़िल';

  @override
  String galleryPhotoSemantic(int current, int total) {
    return 'फ़ोटो $current / $total';
  }

  @override
  String get virtualTourSectionTitle => '360° वर्चुअल टूर';

  @override
  String get exploreVirtualTourPrompt => 'इस प्रॉपर्टी को 360° में देखें';

  @override
  String get openVirtualTourCta => 'वर्चुअल टूर खोलें';

  @override
  String get streetViewCta => 'स्ट्रीट व्यू';

  @override
  String get societyVibeSectionTitle => 'सोसाइटी वाइब';

  @override
  String get safetyBannerTitle => 'सुरक्षित रहें';

  @override
  String get safetyBannerBody =>
      'भुगतान करने से पहले प्रॉपर्टी को व्यक्तिगत रूप से देखें। बिना देखे डिपॉज़िट या किराया न भेजें।';

  @override
  String get viewsLabel => 'दृश्य';

  @override
  String get interestedLabel => 'इच्छुक';

  @override
  String get likesLabel => 'पसंद';

  @override
  String get openChatCta => 'चैट खोलें';

  @override
  String get visitRequestSent => 'विज़िट अनुरोध भेजा गया!';

  @override
  String get visitFromDetailPageNote =>
      'इस प्रॉपर्टी में रुचि — लिस्टिंग पेज से शेड्यूल किया गया।';

  @override
  String get readMoreCta => 'और पढ़ें';

  @override
  String get showLessCta => 'कम दिखाएं';

  @override
  String get viewProfileCta => 'प्रोफ़ाइल देखें';

  @override
  String visitScheduledBanner(String date) {
    return 'आपकी विज़िट $date को है';
  }

  @override
  String get thePlaceSectionTitle => 'जगह';

  @override
  String get peopleSectionTitle => 'लोग';

  @override
  String get estimatedTotalLabel => 'अनुमानित कुल';

  @override
  String get perMonthSuffix => '/महीना';

  @override
  String get viewOnMapLabel => 'नक्शे पर देखें';

  @override
  String andNMore(int count) {
    return '+$count और';
  }

  @override
  String trendingNeighborhoodsIn(String city) {
    return '$city में ट्रेंडिंग';
  }

  @override
  String get meetPotentialFlatmates => 'संभावित फ्लैटमेट्स से मिलें';

  @override
  String get lifestyleSectionTitle => 'जीवनशैली';

  @override
  String get dealBreakersSectionTitle => 'डील-ब्रेकर्स';

  @override
  String get dealBreakersSectionSubtitle => 'उनकी गैर-समझौता शर्तें';

  @override
  String get matchToneGreat => 'बेहतरीन मैच';

  @override
  String get matchToneWorkable => 'ठीक-ठाक';

  @override
  String get matchToneGaps => 'प्राथमिकता अंतर';

  @override
  String compatAlignedCount(int count) {
    return '$count मेल';
  }

  @override
  String compatWorkableCount(int count) {
    return '$count ठीक-ठाक';
  }

  @override
  String compatGapCount(int count) {
    return '$count अंतर';
  }

  @override
  String get lifestyleDimSleep => 'नींद';

  @override
  String get lifestyleDimCleanliness => 'साफ़-सफ़ाई';

  @override
  String get lifestyleDimFood => 'खाना';

  @override
  String get lifestyleDimSmoking => 'धूम्रपान / पेय';

  @override
  String get lifestyleDimGuests => 'मेहमान';

  @override
  String get lifestyleDimWork => 'काम';

  @override
  String get lifestyleDimParty => 'पार्टियाँ';

  @override
  String get societyVibesLabel => 'सोसाइटी वाइब्स';

  @override
  String dealBreakersCountBadge(int count) {
    return '$count डील-ब्रेकर्स';
  }

  @override
  String get likeListingTooltip => 'अपनी पसंद में जोड़ें';

  @override
  String get unlikeListingTooltip => 'अपनी पसंद से हटाएँ';

  @override
  String get togglePasswordVisibility => 'पासवर्ड दिखाएं या छिपाएं';

  @override
  String get authMethodGoogle => 'Google';

  @override
  String get authMethodApple => 'Apple';

  @override
  String get authMethodEmail => 'ईमेल';

  @override
  String get authMethodPhone => 'फ़ोन';

  @override
  String get visitRescheduled => 'नया समय सुझाया गया';

  @override
  String get visitTimeInPast => 'कृपया भविष्य का कोई समय चुनें।';

  @override
  String get visitStatusPast => 'बीते हुए';

  @override
  String get visitScheduleNoConversation =>
      'हम यह बातचीत लोड नहीं कर सके। कृपया चैट से दोबारा प्रयास करें।';

  @override
  String get swipeLikeAction => 'पसंद';

  @override
  String get swipeSkipAction => 'छोड़ें';

  @override
  String get swipeUndoAction => 'पूर्ववत करें';

  @override
  String get matchPeerFallbackName => 'फ्लैटमेट';

  @override
  String get matchSelfFallbackName => 'आप';

  @override
  String get onboardingProgressTitle => 'प्रोफ़ाइल सेटअप';

  @override
  String get onboardingBudgetRangeError =>
      'न्यूनतम बजट अधिकतम से कम होना चाहिए';

  @override
  String get onboardingSubmitError =>
      'ऑनबोर्डिंग पूरी नहीं हो सकी। कृपया पुनः प्रयास करें।';

  @override
  String get deleteAccountInProgress => 'हटाया जा रहा है…';

  @override
  String get deleteAccountDialogBody =>
      'इससे आपका खाता और उससे जुड़ा सारा डेटा स्थायी रूप से हट जाएगा। इस क्रिया को पूर्ववत नहीं किया जा सकता।';

  @override
  String get notifAllEnabled => 'सभी सूचनाएं सक्षम कर दी गईं';

  @override
  String get notifAllDisabled => 'सभी सूचनाएं अक्षम कर दी गईं';

  @override
  String get listingUpdatedToast => 'लिस्टिंग सफलतापूर्वक अपडेट हो गई।';

  @override
  String get discardListingTitle => 'बदलाव छोड़ें?';

  @override
  String get discardListingMessage =>
      'आपके पास असहेजे गए बदलाव हैं। यदि आप अभी बाहर निकलते हैं, तो वे खो जाएंगे।';

  @override
  String get keepEditingCta => 'संपादन जारी रखें';

  @override
  String get discardCta => 'छोड़ें';

  @override
  String get couldNotLoadReviewStatus => 'समीक्षा स्थिति लोड नहीं हो सकी';

  @override
  String get removeVideoTourTooltip => 'वीडियो टूर हटाएं';

  @override
  String bedsCount(int count) {
    return '$count बेड';
  }

  @override
  String bathsCount(int count) {
    return '$count बाथ';
  }

  @override
  String sqftLabel(int count) {
    return '$count वर्ग फुट';
  }

  @override
  String shareListingText(String title, String rent, String location) {
    return '360 फ्लैटमेट्स पर इस फ्लैट को देखें: $title ₹$rent/माह $location में';
  }

  @override
  String get couldNotLoadProfile => 'प्रोफ़ाइल लोड नहीं हो सकी';

  @override
  String get profilePhotoUploadFailed =>
      'फ़ोटो अपलोड नहीं हो सकी। कृपया पुनः प्रयास करें।';

  @override
  String get profileSaving => 'सहेजा जा रहा है...';

  @override
  String profilePhotoSemantic(String name) {
    return '$name की प्रोफ़ाइल फ़ोटो';
  }

  @override
  String get profileChangePhotoSemantic => 'प्रोफ़ाइल फ़ोटो बदलें';

  @override
  String get profilePhotoUploading => 'प्रोफ़ाइल फ़ोटो अपलोड हो रही है';

  @override
  String get unsavedChangesTitle => 'बदलाव रद्द करें?';

  @override
  String get unsavedChangesMessage =>
      'आपके पास सहेजे न गए बदलाव हैं। यदि आप अभी छोड़ते हैं, तो वे खो जाएँगे।';

  @override
  String get keepEditing => 'संपादन जारी रखें';

  @override
  String get discardChanges => 'रद्द करें';

  @override
  String availableFromDate(String date) {
    return '$date से';
  }

  @override
  String moveInCostLabel(String amount) {
    return 'शिफ्टिंग $amount';
  }

  @override
  String distanceAway(String km) {
    return '$km किमी दूर';
  }

  @override
  String listedByLabel(String name) {
    return '$name द्वारा सूचीबद्ध';
  }

  @override
  String get ownerModeCoHunter => 'साथी ढूंढने वाला';

  @override
  String get ownerModeRoomPoster => 'कमरा देने वाला';

  @override
  String get ownerModeOpenToBoth => 'दोनों खुला';

  @override
  String perfViewsLabel(String count) {
    return '$count व्यूज़';
  }

  @override
  String perfInterestLabel(String count) {
    return '$count रुचि';
  }

  @override
  String get loadMoreCta => 'और देखें';

  @override
  String get loadOlderCta => 'पुराने देखें';

  @override
  String get startOfConversation => 'आप इस बातचीत की शुरुआत पर पहुँच गए हैं';

  @override
  String get noMoreListingsLabel => 'आपने सभी मैच देख लिए हैं।';

  @override
  String get noMoreVisitsLabel => 'दिखाने के लिए और विज़िट नहीं हैं।';

  @override
  String get noMoreNotificationsLabel => 'आप पूरी तरह अपडेट हैं।';

  @override
  String get noMoreBlockedUsersLabel =>
      'और कोई ब्लॉक किए गए उपयोगकर्ता नहीं हैं।';

  @override
  String get unverifiedAccountHint =>
      'आपका खाता अभी सत्यापित नहीं हुआ है। नीचे सत्यापन पूरा करें या कोड दोबारा भेजें।';

  @override
  String get profileCompletionTitle => 'अपनी प्रोफ़ाइल सेट करें';

  @override
  String get profileCompletionSubtitle =>
      'शुरू करने के लिए हमें कुछ जानकारी चाहिए।';

  @override
  String get profileCompletionContinue => 'जारी रखें';

  @override
  String get profileCompletionSaving => 'सहेजा जा रहा है…';

  @override
  String get profileCompletionError =>
      'प्रोफ़ाइल सहेजी नहीं जा सकी। कृपया दोबारा कोशिश करें।';

  @override
  String get dateOfBirthLabel => 'जन्म तिथि';

  @override
  String get dateOfBirthHelper => 'आपकी आयु 18 वर्ष या अधिक होनी चाहिए';

  @override
  String get dateOfBirthPickerTitle => 'अपनी जन्म तिथि चुनें';

  @override
  String get onboardingBannerTitle =>
      'मैचिंग शुरू करने के लिए अपनी प्रोफ़ाइल पूरी करें';

  @override
  String get onboardingBannerCta => 'सेटअप जारी रखें';

  @override
  String onboardingStepsRemaining(int count) {
    return '$count चरण शेष';
  }

  @override
  String onboardingStepOf(int current, int total) {
    return 'चरण $current / $total';
  }

  @override
  String get onboardingStepMode => 'आपकी भूमिका';

  @override
  String get onboardingStepLocation => 'स्थान';

  @override
  String get onboardingStepBasicInfo => 'बुनियादी जानकारी';

  @override
  String get onboardingStepPhoto => 'प्रोफ़ाइल फ़ोटो';

  @override
  String get onboardingStepLifestyle => 'जीवनशैली';

  @override
  String get onboardingStepBudget => 'बजट और समयरेखा';

  @override
  String get onboardingStepPreferences => 'प्राथमिकताएँ';

  @override
  String get onboardingStepNonNegotiables => 'अनिवार्य शर्तें';

  @override
  String get onboardingWelcomeBack =>
      'वापसी पर स्वागत है! जहाँ से छोड़ा था वहीं से शुरू करें।';

  @override
  String get onboardingActionBlockedTitle => 'पहले अपनी प्रोफ़ाइल पूरी करें';

  @override
  String get onboardingActionBlockedMessage =>
      'फ्लैटमेट्स के साथ मैचिंग शुरू करने के लिए अपनी प्रोफ़ाइल सेटअप पूरा करें।';

  @override
  String get onboardingActionBlockedCta => 'सेटअप जारी रखें';
}
