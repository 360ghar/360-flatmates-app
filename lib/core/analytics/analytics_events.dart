/// Analytics event names aligned to the PRD metrics funnel.
abstract final class AnalyticsEvents {
  // App lifecycle
  static const appOpen = 'app_open';

  // Auth
  static const authStarted = 'auth_started';
  static const authCompleted = 'auth_completed';
  static const authFailed = 'auth_failed';

  // Onboarding
  static const onboardingStarted = 'onboarding_started';
  static const modeSelected = 'mode_selected';
  static const onboardingCompleted = 'onboarding_completed';

  // Discovery
  static const discoverCardViewed = 'discover_card_viewed';
  static const listingOpened = 'listing_opened';
  static const listingLiked = 'listing_liked';
  static const listingShortlisted = 'listing_shortlisted';

  // Swipe
  static const swipeLike = 'swipe_like';
  static const swipePass = 'swipe_pass';
  static const matchCreated = 'match_created';

  // Chat
  static const chatStarted = 'chat_started';
  static const messageSent = 'message_sent';
  static const photoSent = 'photo_sent';

  // Visits
  static const visitRequested = 'visit_requested';
  static const visitConfirmed = 'visit_confirmed';
  static const visitCancelled = 'visit_cancelled';
  static const visitCompleted = 'visit_completed';

  // Listings
  static const listingDraftStarted = 'listing_draft_started';
  static const listingSubmitted = 'listing_submitted';
  static const listingApproved = 'listing_approved_seen';
  static const listingPaused = 'listing_paused';
  static const listingRenewed = 'listing_renewed';

  // Share
  static const shareCardShared = 'share_card_shared';
  static const deepLinkOpened = 'deep_link_opened';

  // Profile
  static const profileEdited = 'profile_edited';
  static const avatarChanged = 'avatar_changed';

  // Settings
  static const themeChanged = 'theme_changed';
  static const localeChanged = 'locale_changed';
  static const userBlocked = 'user_blocked';
  static const userReported = 'user_reported';
  static const userSignedOut = 'user_signed_out';
}

/// Standard analytics property keys.
abstract final class AnalyticsProps {
  static const city = 'city';
  static const mode = 'mode';
  static const listingId = 'listing_id';
  static const conversationId = 'conversation_id';
  static const visitId = 'visit_id';
  static const source = 'source';
  static const matchPercentageBucket = 'match_percentage_bucket';
  static const networkStatus = 'network_status';
}
