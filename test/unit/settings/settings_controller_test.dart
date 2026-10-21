import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/core/storage/app_preferences.dart';
import 'package:flatmates_app/features/settings/data/settings_repository.dart';
import 'package:flatmates_app/features/settings/settings_controller.dart';

class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository({this.remotePrivacy = const {}});

  final Map<String, dynamic> remotePrivacy;
  final notificationWrites = <Map<String, dynamic>>[];
  final privacyWrites = <Map<String, bool>>[];

  @override
  Future<RemoteNotificationSettings> fetchNotificationSettings() async {
    return RemoteNotificationSettings.fromJson(const {});
  }

  @override
  Future<void> updateNotificationSettings(
    RemoteNotificationSettings settings,
  ) async {
    notificationWrites.add(settings.toJson());
  }

  @override
  Future<RemotePrivacySettings> fetchPrivacySettings() async {
    return RemotePrivacySettings.fromJson(remotePrivacy);
  }

  @override
  Future<void> updatePrivacySettings(Map<String, bool> patch) async {
    privacyWrites.add(patch);
  }
}

ProviderContainer _container([_FakeSettingsRepository? repository]) {
  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(fakeAppConfig()),
      appPreferencesProvider.overrideWithValue(
        // The cached prefs from testAppPreferences is used.
        // This is set up in setUp via SharedPreferences.setMockInitialValues.
        _cachedPrefs!,
      ),
      settingsRepositoryProvider.overrideWithValue(
        repository ?? _FakeSettingsRepository(),
      ),
      settingsControllerProvider.overrideWith(() => SettingsController()),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

AppPreferences? _cachedPrefs;

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    resetTestAppPreferences();
    _cachedPrefs = await testAppPreferences;
  });

  group('SettingsController', () {
    test('default state is light theme, English locale', () async {
      final container = _container();
      final notifier = container.read(settingsControllerProvider.notifier);
      await notifier.load();

      final state = container.read(settingsControllerProvider);
      expect(state.themeMode, ThemeMode.light);
      expect(state.locale, const Locale('en'));
      expect(state.loaded, isTrue);
    });

    test('updateThemeMode updates state', () async {
      final container = _container();
      final notifier = container.read(settingsControllerProvider.notifier);
      await notifier.load();

      await notifier.updateThemeMode(ThemeMode.dark);

      final state = container.read(settingsControllerProvider);
      expect(state.themeMode, ThemeMode.dark);
    });

    test('updateLocale updates state', () async {
      final container = _container();
      final notifier = container.read(settingsControllerProvider.notifier);
      await notifier.load();

      await notifier.updateLocale(const Locale('hi'));

      final state = container.read(settingsControllerProvider);
      expect(state.locale, const Locale('hi'));
    });

    test('updateHideLastName updates state', () async {
      final container = _container();
      final notifier = container.read(settingsControllerProvider.notifier);
      await notifier.load();

      await notifier.updateHideLastName(true);

      final state = container.read(settingsControllerProvider);
      expect(state.hideLastName, isTrue);
    });

    test('updateHideExactLocation updates state', () async {
      final container = _container();
      final notifier = container.read(settingsControllerProvider.notifier);
      await notifier.load();

      await notifier.updateHideExactLocation(true);

      final state = container.read(settingsControllerProvider);
      expect(state.hideExactLocation, isTrue);
    });

    test(
      'updateAllNotificationSettings updates the notification switches',
      () async {
        final container = _container();
        final notifier = container.read(settingsControllerProvider.notifier);
        await notifier.load();

        await notifier.updateAllNotificationSettings(false);

        final state = container.read(settingsControllerProvider);
        expect(state.notifNewMessages, isFalse);
        expect(state.notifPromotions, isFalse);
      },
    );

    test('updateAllNotificationSettings(true) turns every switch on', () async {
      final container = _container();
      final notifier = container.read(settingsControllerProvider.notifier);
      await notifier.load();

      await notifier.updateAllNotificationSettings(false);
      await notifier.updateAllNotificationSettings(true);

      final state = container.read(settingsControllerProvider);
      expect(state.notifNewMessages, isTrue);
      expect(state.notifPromotions, isTrue);
    });

    test('a notification save sends the four contract keys only', () async {
      final repository = _FakeSettingsRepository();
      final container = _container(repository);
      final notifier = container.read(settingsControllerProvider.notifier);
      await notifier.load();

      await notifier.updateNotifPromotions(true);
      await Future<void>.delayed(Duration.zero);

      expect(repository.notificationWrites, isNotEmpty);
      for (final body in repository.notificationWrites) {
        // Any other key (visit_reminders, property_updates, onboarding,
        // digest, categories, ...) is a 422 for the whole request.
        expect(body.keys, {
          'push_notifications',
          'email_notifications',
          'sms_notifications',
          'promotional_emails',
        });
      }
      expect(repository.notificationWrites.last['promotional_emails'], isTrue);
    });

    test(
      'hide_last_name is written to and read from privacy-settings',
      () async {
        final repository = _FakeSettingsRepository(
          remotePrivacy: const {'hide_last_name': true},
        );
        final container = _container(repository);
        final notifier = container.read(settingsControllerProvider.notifier);
        await notifier.load();

        // The server value wins over the local default.
        expect(container.read(settingsControllerProvider).hideLastName, isTrue);

        await notifier.updateHideLastName(false);
        await Future<void>.delayed(Duration.zero);

        // A privacy write is a partial update: only the changed key.
        expect(repository.privacyWrites.last, {'hide_last_name': false});
      },
    );

    test('hide exact location writes location_sharing only', () async {
      final repository = _FakeSettingsRepository();
      final container = _container(repository);
      final notifier = container.read(settingsControllerProvider.notifier);
      await notifier.load();

      await notifier.updateHideExactLocation(true);
      await Future<void>.delayed(Duration.zero);

      expect(repository.privacyWrites.last, {'location_sharing': false});
    });
  });
}
