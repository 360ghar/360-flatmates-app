import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/storage/app_preferences.dart';
import 'domain/settings_state.dart';
export 'domain/settings_state.dart';

class SettingsController extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    Future.microtask(() => load());
    return const SettingsState();
  }

  AppPreferences get _prefs => ref.read(appPreferencesProvider);

  Future<void> load() async {
    final themeRaw = _prefs.getString(PrefKeys.themeMode);
    final languageCode = _prefs.getString(PrefKeys.localeLanguageCode);
    final countryCode = _prefs.getString(PrefKeys.localeCountryCode);

    state = state.copyWith(
      themeMode: switch (themeRaw) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        'system' => ThemeMode.system,
        _ => ThemeMode.light,
      },
      locale: languageCode == null
          ? const Locale('en')
          : Locale(languageCode, countryCode),
      hideLastName: _prefs.getBool(PrefKeys.hideLastName),
      hideExactLocation: _prefs.getBool(PrefKeys.hideExactLocation),
      notifNewMessages: _prefs.getBoolOrDefault(
        PrefKeys.notifNewMessages,
        true,
      ),
      notifVisitReminders: _prefs.getBoolOrDefault(
        PrefKeys.notifVisitReminders,
        true,
      ),
      notifNewMatches: _prefs.getBoolOrDefault(PrefKeys.notifNewMatches, true),
      notifListingUpdates: _prefs.getBoolOrDefault(
        PrefKeys.notifListingUpdates,
        true,
      ),
      notifPromotions: _prefs.getBoolOrDefault(PrefKeys.notifPromotions, false),
      loaded: true,
    );
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    final raw = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _prefs.setString(PrefKeys.themeMode, raw);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> updateLocale(Locale? locale) async {
    final effectiveLocale = locale ?? const Locale('en');
    if (locale == null) {
      await _prefs.remove(PrefKeys.localeLanguageCode);
      await _prefs.remove(PrefKeys.localeCountryCode);
    } else {
      await _prefs.setString(PrefKeys.localeLanguageCode, locale.languageCode);
      if (locale.countryCode != null) {
        await _prefs.setString(PrefKeys.localeCountryCode, locale.countryCode!);
      } else {
        await _prefs.remove(PrefKeys.localeCountryCode);
      }
    }
    state = state.copyWith(locale: effectiveLocale);
  }

  Future<void> updateHideLastName(bool value) async {
    await _prefs.setBool(PrefKeys.hideLastName, value);
    state = state.copyWith(hideLastName: value);
  }

  Future<void> updateHideExactLocation(bool value) async {
    await _prefs.setBool(PrefKeys.hideExactLocation, value);
    state = state.copyWith(hideExactLocation: value);
  }

  Future<void> updateNotifNewMessages(bool value) async {
    await _prefs.setBool(PrefKeys.notifNewMessages, value);
    state = state.copyWith(notifNewMessages: value);
  }

  Future<void> updateNotifVisitReminders(bool value) async {
    await _prefs.setBool(PrefKeys.notifVisitReminders, value);
    state = state.copyWith(notifVisitReminders: value);
  }

  Future<void> updateNotifNewMatches(bool value) async {
    await _prefs.setBool(PrefKeys.notifNewMatches, value);
    state = state.copyWith(notifNewMatches: value);
  }

  Future<void> updateNotifListingUpdates(bool value) async {
    await _prefs.setBool(PrefKeys.notifListingUpdates, value);
    state = state.copyWith(notifListingUpdates: value);
  }

  Future<void> updateNotifPromotions(bool value) async {
    await _prefs.setBool(PrefKeys.notifPromotions, value);
    state = state.copyWith(notifPromotions: value);
  }

  Future<void> updateAllNotificationSettings(bool value) async {
    await Future.wait([
      _prefs.setBool(PrefKeys.notifNewMessages, value),
      _prefs.setBool(PrefKeys.notifVisitReminders, value),
      _prefs.setBool(PrefKeys.notifNewMatches, value),
      _prefs.setBool(PrefKeys.notifListingUpdates, value),
      _prefs.setBool(PrefKeys.notifPromotions, value),
    ]);
    state = state.copyWith(
      notifNewMessages: value,
      notifVisitReminders: value,
      notifNewMatches: value,
      notifListingUpdates: value,
      notifPromotions: value,
    );
  }
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, SettingsState>(SettingsController.new);
