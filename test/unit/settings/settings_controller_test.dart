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
  _FakeSettingsRepository();

  @override
  Future<RemoteNotificationSettings> fetchNotificationSettings() async {
    return RemoteNotificationSettings.fromJson(const {});
  }

  @override
  Future<void> updateNotificationSettings(Map<String, dynamic> payload) async {}

  @override
  Future<RemotePrivacySettings> fetchPrivacySettings() async {
    return RemotePrivacySettings.fromJson(const {});
  }

  @override
  Future<void> updatePrivacySettings(Map<String, dynamic> payload) async {}

  @override
  Future<void> updatePrivacySettingsCompat(
    Map<String, dynamic> payload,
  ) async {}
}

ProviderContainer _container() {
  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(fakeAppConfig()),
      appPreferencesProvider.overrideWithValue(
        // The cached prefs from testAppPreferences is used.
        // This is set up in setUp via SharedPreferences.setMockInitialValues.
        _cachedPrefs!,
      ),
      settingsRepositoryProvider.overrideWithValue(_FakeSettingsRepository()),
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
      'updateAllNotificationSettings updates all notification toggles',
      () async {
        final container = _container();
        final notifier = container.read(settingsControllerProvider.notifier);
        await notifier.load();

        await notifier.updateAllNotificationSettings(false);

        final state = container.read(settingsControllerProvider);
        expect(state.notifNewMessages, isFalse);
        expect(state.notifVisitReminders, isFalse);
        expect(state.notifNewMatches, isFalse);
        expect(state.notifListingUpdates, isFalse);
        expect(state.notifPromotions, isFalse);
      },
    );

    test('updateAllNotificationSettings(true) turns every toggle on', () async {
      final container = _container();
      final notifier = container.read(settingsControllerProvider.notifier);
      await notifier.load();

      // First turn everything off.
      await notifier.updateAllNotificationSettings(false);
      // Then turn everything on.
      await notifier.updateAllNotificationSettings(true);

      final state = container.read(settingsControllerProvider);
      expect(state.notifNewMessages, isTrue);
      expect(state.notifVisitReminders, isTrue);
      expect(state.notifNewMatches, isTrue);
      expect(state.notifListingUpdates, isTrue);
      expect(state.notifPromotions, isTrue);
    });
  });
}
