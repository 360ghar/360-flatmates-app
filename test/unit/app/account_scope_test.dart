import 'package:flatmates_app/app/account_scope.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/core/storage/app_preferences.dart';
import 'package:flatmates_app/features/chats/application/cursor_list_controller.dart';
import 'package:flatmates_app/features/notifications/notifications_list_controller.dart';
import 'package:flatmates_app/features/settings/data/blocked_users_list_controller.dart';
import 'package:flatmates_app/features/settings/settings_controller.dart';
import 'package:flatmates_app/features/visits/application/visits_list_controller.dart';
import 'package:flatmates_app/features/visits/visits_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/recording_api.dart';

void main() {
  test(
    'sign-out drops the account data and keeps the device settings',
    () async {
      SharedPreferences.setMockInitialValues({
        // Device settings: stay.
        PrefKeys.themeMode: 'dark',
        PrefKeys.localeLanguageCode: 'hi',
        PrefKeys.lastAuthMethod: 'google',
        // Account data: go.
        PrefKeys.hideLastName: true,
        PrefKeys.hideExactLocation: true,
        PrefKeys.notifNewMessages: false,
        PrefKeys.notifPromotions: true,
        PrefKeys.onboardingDraft: '{"v":1,"account":"user-a","data":{}}',
        PrefKeys.flatmatesOnboardingCompletedUserId: '7',
        PrefKeys.profileCompletionLocalUserId: '7',
        PrefKeys.qnaNudgeDismissed(42): true,
        '${PrefKeys.legacyListingsCachePrefix}_v1': '[]',
      });
      final prefs = await AppPreferences.create();
      final api = RecordingApi(
        (options) => ok({
          'items': <dynamic>[],
          'next_cursor': null,
          'has_more': false,
          'limit': 20,
          'total': null,
        }),
        overrides: [appPreferencesProvider.overrideWithValue(prefs)],
      );
      final container = api.container;

      // The signed-in account reads its lists.
      final lists = <ProviderListenable<AsyncValue<Object?>>>[
        conversationsListControllerProvider,
        incomingLikesListControllerProvider,
        outgoingLikesListControllerProvider,
        notificationsListControllerProvider,
        visitsListControllerProvider,
        blockedUsersListControllerProvider,
        visitsProvider,
      ];
      for (final provider in lists) {
        container.read(provider);
      }
      await pumpEventQueue();
      for (final provider in lists) {
        expect(
          container.read(provider).hasValue,
          isTrue,
          reason: '$provider has loaded the account rows',
        );
      }

      await clearAccountScopedState(container);

      // An invalidated provider starts over on its next read: no rows of the
      // account that signed out, so the next account reads its own.
      for (final provider in lists) {
        expect(
          container.read(provider).isLoading,
          isTrue,
          reason: '$provider dropped the rows of the account that signed out',
        );
      }
      for (final key in [
        PrefKeys.hideLastName,
        PrefKeys.hideExactLocation,
        PrefKeys.notifNewMessages,
        PrefKeys.notifPromotions,
        PrefKeys.onboardingDraft,
        PrefKeys.flatmatesOnboardingCompletedUserId,
        PrefKeys.profileCompletionLocalUserId,
        PrefKeys.qnaNudgeDismissed(42),
        '${PrefKeys.legacyListingsCachePrefix}_v1',
      ]) {
        expect(prefs.containsKey(key), isFalse, reason: '$key is account data');
      }
      expect(prefs.getString(PrefKeys.themeMode), 'dark');
      expect(prefs.getString(PrefKeys.localeLanguageCode), 'hi');
      expect(prefs.getString(PrefKeys.lastAuthMethod), 'google');

      final settings = container.read(settingsControllerProvider);
      expect(settings.hideLastName, isFalse);
      expect(settings.hideExactLocation, isFalse);
      expect(settings.notifNewMessages, isTrue);
      expect(settings.notifPromotions, isFalse);
    },
  );
}
