import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/notifications/notification_service.dart';
import '../core/providers.dart';
import '../features/chats/application/cursor_list_controller.dart';
import '../features/discover/application/map_listings_controller.dart';
import '../features/discover/application/property_listing_seed_store.dart';
import '../features/discover/application/discover_feed_controller.dart';
import '../features/discover/discover_repository.dart';
import '../features/listings/listings_repository.dart';
import '../features/listings/my_listings_controller.dart';
import '../features/notifications/notifications_list_controller.dart';
import '../features/notifications/notifications_repository.dart';
import '../features/onboarding/onboarding_controller.dart';
import '../features/settings/data/blocked_users_list_controller.dart';
import '../features/settings/settings_controller.dart';
import '../features/swipe/application/swipe_deck_controller.dart';
import '../features/visits/application/visits_list_controller.dart';
import '../features/visits/visits_repository.dart';

/// Drops everything the app holds for the account that just signed out, in
/// memory and on disk, so the next account on this device starts empty.
///
/// What a store holds for one account, it must not show to the next:
/// - disk: the account keys of [AppPreferences] (the onboarding draft, the
///   privacy and notification switches, the Q&A nudge flags, the onboarding
///   completion fallbacks); the device keys (theme, language, last sign-in
///   method) stay;
/// - memory: every list and detail provider that read the account's data. They
///   are invalidated, so the next account reads its own rows.
///
/// Call it when the session ends (sign-out, a deleted account, an expired
/// session), not while the user is signed in.
Future<void> clearAccountScopedState(ProviderContainer container) async {
  // First, so a settings load still in flight for the old account stops before
  // the preferences are cleared and cannot write them back afterwards.
  container.read(settingsControllerProvider.notifier).resetAccountSettings();
  // One retry: a failed remove usually clears on the second pass. A second
  // failure is logged, and the next sign-in's load overwrites these values.
  for (var attempt = 0; attempt < 2; attempt++) {
    try {
      await container.read(appPreferencesProvider).clearAccountData();
      break;
    } catch (e) {
      debugPrint(
        'clearAccountScopedState: preferences (try ${attempt + 1}): $e',
      );
    }
  }
  try {
    // The owner listings cache of the repository lives in memory only.
    await container.read(listingsRepositoryProvider).clearOwnerListingsCache();
  } catch (e) {
    debugPrint('clearAccountScopedState: owner listings cache: $e');
  }
  NotificationService.clearPendingRoute();
  resetAccountScopedProviders(container);
}

/// Invalidates the providers that hold the signed-in account's data. Kept
/// apart from [clearAccountScopedState] so a test can check the list alone.
@visibleForTesting
void resetAccountScopedProviders(ProviderContainer container) {
  // Chats, likes, matches.
  container
    ..invalidate(conversationsListControllerProvider)
    ..invalidate(incomingLikesListControllerProvider)
    ..invalidate(outgoingLikesListControllerProvider)
    // Notifications.
    ..invalidate(notificationsListControllerProvider)
    ..invalidate(notificationsUnreadCountProvider)
    // Visits.
    ..invalidate(visitsListControllerProvider)
    ..invalidate(visitsProvider)
    // Blocked users.
    ..invalidate(blockedUsersListControllerProvider)
    // The owner's own listings, and the listing details (the liked flag is
    // per account).
    ..invalidate(myListingsListControllerProvider)
    ..invalidate(myListingsProvider)
    ..invalidate(propertyListingProvider)
    ..invalidate(propertyListingSeedStoreProvider)
    // Feeds that were ranked and filtered for the account.
    ..invalidate(discoverFeedControllerProvider)
    ..invalidate(mapListingsProvider)
    ..invalidate(discoverFiltersProvider)
    ..invalidate(swipeDeckControllerProvider)
    // The onboarding flow and its in-memory completion gate.
    ..invalidate(onboardingControllerProvider)
    ..invalidate(flatmatesOnboardingCompletedOverrideProvider);
  container.read(settingsControllerProvider.notifier).resetAccountSettings();
}
