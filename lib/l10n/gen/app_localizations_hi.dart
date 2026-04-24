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
  String get splashTagline =>
      'सही फ्लैट ढूंढें, सही लोगों से मिलें, जल्दी शिफ्ट हों।';

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
      'पासवर्ड लॉगिन करें या OTP के साथ जारी रखें।';

  @override
  String get phoneNumberLabel => 'फोन नंबर';

  @override
  String get loginWithPassword => 'पासवर्ड से लॉगिन करें';

  @override
  String get continueWithOtp => 'OTP के साथ जारी रखें';

  @override
  String get createAccountCta => 'खाता बनाएं';

  @override
  String get loginTitle => 'लॉगिन';

  @override
  String get signupTitle => 'अपना खाता बनाएं';

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
  String homeGreeting(String name) {
    return 'हाय, $name';
  }

  @override
  String get homeLocationFallback =>
      'डिस्कवरी को बेहतर बनाने के लिए अपना शहर और लोकैलिटी सेट करें।';

  @override
  String get homeSearchHint => 'लोकेशन, एरिया या लैंडमार्क से खोजें';

  @override
  String get homePickedForYou => 'आपके लिए चुना गया';

  @override
  String get homePickedSubtitle => 'आपकी पसंद और वाइब से मेल खाने वाले फ्लैट्स';

  @override
  String get homeNoResults => 'इन फ़िल्टर्स से कोई लिस्टिंग नहीं मिली।';

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
  String contactRequestWithConversation(int conversationId) {
    return 'रुचि भेज दी गई है। बातचीत #$conversationId तैयार है।';
  }

  @override
  String get likeListingCta => 'लिस्टिंग पसंद करें';

  @override
  String get likesChatTitle => 'लाइक्स और चैट';

  @override
  String get likesTabLabel => 'लाइक्स';

  @override
  String get chatsTabLabel => 'चैट्स';

  @override
  String get likesIncomingLabel => 'यह कनेक्शन पहली बातचीत के लिए तैयार है।';

  @override
  String get emptyLikes => 'अभी कोई नया लाइक नहीं है।';

  @override
  String get chatsTitle => 'चैट्स';

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
  String get safetyFirstSubtitle =>
      'हम समुदाय को सुरक्षित रखने के लिए प्रोफ़ाइल सत्यापित करते हैं।';

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
  String get profilePageTitle => 'प्रोफ़ाइल';

  @override
  String get profileTitle => 'प्रोफ़ाइल और सेटिंग्स';

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
  String get profileMenuLikesChat => 'लाइक्स और चैट';

  @override
  String get profileMenuPostListing => 'लिस्टिंग पोस्ट करें';

  @override
  String get editProfileCta => 'प्रोफ़ाइल संपादित करें';

  @override
  String get themeModeTitle => 'थीम मोड';

  @override
  String get themeSystem => 'सिस्टम';

  @override
  String get themeLight => 'लाइट';

  @override
  String get themeDark => 'डार्क';

  @override
  String get paletteTitle => 'पैलेट';

  @override
  String get paletteElectricIndigo => 'इलेक्ट्रिक इंडिगो';

  @override
  String get paletteEmberCoral => 'एम्बर कोरल';

  @override
  String get paletteMonsoonTeal => 'मानसून टील';

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
  String get modeRoomPoster => 'रूम पोस्टर';

  @override
  String get modeSeeker => 'सीकर';

  @override
  String get modeCoHunter => 'को-हंटर';

  @override
  String get modeOpenToBoth => 'दोनों के लिए खुला';

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
  String get availableFromLabel => 'कब से उपलब्ध';

  @override
  String get availableFromUnset => 'मूव-इन उपलब्धता चुनें';

  @override
  String get selectDateCta => 'तारीख चुनें';

  @override
  String get postListingTitle => 'अपना स्पेस पोस्ट करें';

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
  String get navLikesChat => 'लाइक्स और चैट';

  @override
  String get navSchedule => 'शेड्यूल';

  @override
  String get navPost => 'पोस्ट';

  @override
  String get navProfile => 'प्रोफ़ाइल';

  @override
  String get onboardingGetStarted => 'शुरू करें';

  @override
  String get onboardingNext => 'आगे';

  @override
  String get onboardingComplete => 'पूरा करें';

  @override
  String get onboardingSubmitting => 'आपकी प्रोफ़ाइल सेट की जा रही है...';

  @override
  String get modeSelectionTitle => 'आप फ्लैटमेट कैसे ढूंढ रहे हैं?';

  @override
  String get modeSelectionSubtitle =>
      'आप इसे बाद में अपनी प्रोफ़ाइल से बदल सकते हैं।';

  @override
  String get modeRoomPosterDesc =>
      'मैं फ्लैट में रहता हूं और खाली कमरे के लिए फ्लैटमेट ढूंढ रहा हूं।';

  @override
  String get modeSeekerDesc =>
      'मैं साथ मिलकर फ्लैट ढूंढने के लिए फ्लैटमेट खोज रहा हूँ';

  @override
  String get modeCoHunterDesc => 'मैं किसी के साथ फ्लैट खोजना चाहता हूं।';

  @override
  String get modeOpenToBothDesc =>
      'मैं मौजूदा फ्लैट में जा सकता हूं या नया ढूंढ सकता हूं।';

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
  String get profilePhotoSubtitle => 'अच्छी फ़ोटो से ज़्यादा मैच मिलते हैं।';

  @override
  String get profilePhotoNudge =>
      '3+ फ़ोटो वाली प्रोफ़ाइल्स को 4 गुना ज़्यादा मैच मिलते हैं!';

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
  String get emptySwipeDeck =>
      'अभी दिखाने के लिए कोई प्रोफ़ाइल नहीं है। बाद में दोबारा देखें!';

  @override
  String swipeDeckRemaining(int count) {
    return '$count बचे हुए';
  }

  @override
  String get tapToSeeMore => 'और देखने के लिए टैप करें';

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
  String get vibeQuiet => 'शांत';

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
  String get roomFeaturesLabel => 'कमरे की विशेषताएँ';

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
  String get qnaNudgeTitle => 'पहले बर्फ तोड़ें?';

  @override
  String get qnaNudgeSubtitle =>
      'बातचीत शुरू करने के लिए 3 सवालों के जवाब दें।';

  @override
  String get qnaQuestion1 => 'आपकी आदर्श फ्लैटमेट स्थिति कैसी होनी चाहिए?';

  @override
  String get qnaQuestion1Hint =>
      'जैसे कोई शांत व्यक्ति जो निजी स्पेस का सम्मान करता हो...';

  @override
  String get qnaQuestion2 => 'एक आम वर्कडे पर आप घर पर कितने सोशल रहते हैं?';

  @override
  String get qnaQuestion3 => 'फ्लैटमेट में आपको कौन सी बात सबसे ज़रूरी है?';

  @override
  String get qnaQuestion3Hint => 'जैसे सफाई, पंक्चुअलिटी, ईमानदारी...';

  @override
  String get qnaAnswerCta => 'सवालों के जवाब दें';

  @override
  String get qnaSkipCta => 'अभी छोड़ें';

  @override
  String get waitlistConfirmed => 'आप सूची में हैं! हम आपको सूचित करेंगे।';

  @override
  String get privacyTitle => 'गोपनीयता';

  @override
  String get hideLastNameLabel => 'सार्वजनिक प्रोफ़ाइल पर उपनाम छिपाएं';

  @override
  String get hideExactLocationLabel => 'लिस्टिंग पर सटीक लोकेशन छिपाएं';

  @override
  String get visitConfirmTitle => 'इस विज़िट की पुष्टि करें?';

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
  String get videoTourHint => '15-30 सेकंड का वर्टिकल वीडियो, अधिकतम 50MB';

  @override
  String get addVideoCta => 'वीडियो टूर जोड़ें';

  @override
  String get videoTourAdded => 'वीडियो टूर जोड़ दिया गया';

  @override
  String get videoTooLarge => 'वीडियो 50MB से कम होना चाहिए';

  @override
  String get videoTooLong => 'वीडियो 30 सेकंड से कम होना चाहिए';

  @override
  String superLikeCapLabel(int count) {
    return 'आज $count सुपर लाइक बचे हैं';
  }

  @override
  String swipeCounterLabel(int count) {
    return 'आज $count स्वाइप बचे हैं';
  }

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
}
