import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/storage/app_preferences.dart';
import 'data/settings_repository.dart';
import 'domain/settings_state.dart';
export 'domain/settings_state.dart';

class SettingsController extends Notifier<SettingsState> {
  /// Last known remote notification settings. The PUT sends all four contract
  /// keys, so the two with no switch here (email, sms) keep their value.
  RemoteNotificationSettings _lastNotif = const RemoteNotificationSettings();

  /// Whether [_lastNotif] came from the server for this account. Until it
  /// does, its email and sms values are defaults, and a PUT built from them
  /// would overwrite the account's real ones.
  bool _lastNotifKnown = false;

  /// Bumped by [resetAccountSettings]. A [load] that started under an earlier
  /// value belongs to the account that signed out, so it must not write.
  int _accountGeneration = 0;

  @override
  SettingsState build() {
    Future.microtask(() => load());
    return const SettingsState();
  }

  AppPreferences get _prefs => ref.read(appPreferencesProvider);

  SettingsRepository get _repo => ref.read(settingsRepositoryProvider);

  Future<void> load() async {
    final generation = _accountGeneration;
    try {
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
        notifPromotions: _prefs.getBoolOrDefault(
          PrefKeys.notifPromotions,
          false,
        ),
        loaded: true,
        loadFailed: false,
      );

      // Best-effort remote merge — local prefs already applied above.
      await _mergeRemoteNotificationSettings(generation);
      await _mergeRemotePrivacySettings(generation);
    } catch (e) {
      debugPrint('SettingsController.load: $e');
      state = state.copyWith(loadFailed: true);
    }
  }

  /// Forgets the account-level values (the privacy and notification switches)
  /// when the user signs out, so the next account does not see them. Theme and
  /// language belong to the device and stay. [load] reads the next account's
  /// values from the server after sign-in.
  void resetAccountSettings() {
    _accountGeneration++;
    _lastNotifKnown = false;
    _lastNotif = const RemoteNotificationSettings();
    state = state.copyWith(
      hideLastName: false,
      hideExactLocation: false,
      notifNewMessages: true,
      notifPromotions: false,
    );
  }

  Future<void> _mergeRemoteNotificationSettings(int generation) async {
    try {
      final remote = await _repo.fetchNotificationSettings();
      if (generation != _accountGeneration) return;
      _lastNotif = remote;
      _lastNotifKnown = true;

      await Future.wait([
        _prefs.setBool(PrefKeys.notifNewMessages, remote.pushNotifications),
        _prefs.setBool(PrefKeys.notifPromotions, remote.promotionalEmails),
      ]);

      state = state.copyWith(
        notifNewMessages: remote.pushNotifications,
        notifPromotions: remote.promotionalEmails,
      );
    } catch (e) {
      debugPrint('SettingsController._mergeRemoteNotificationSettings: $e');
    }
  }

  Future<void> _mergeRemotePrivacySettings(int generation) async {
    try {
      final remote = await _repo.fetchPrivacySettings();
      if (generation != _accountGeneration) return;

      final hideExactLocation = !remote.locationSharing;
      // hide_last_name is a typed PrivacySettings key: the server value wins.
      final hideLastName = remote.hideLastName;

      await Future.wait([
        _prefs.setBool(PrefKeys.hideExactLocation, hideExactLocation),
        _prefs.setBool(PrefKeys.hideLastName, hideLastName),
      ]);

      state = state.copyWith(
        hideExactLocation: hideExactLocation,
        hideLastName: hideLastName,
      );
    } catch (e) {
      debugPrint('SettingsController._mergeRemotePrivacySettings: $e');
    }
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
    _pushPrivacyRemote({'hide_last_name': value});
  }

  Future<void> updateHideExactLocation(bool value) async {
    await _prefs.setBool(PrefKeys.hideExactLocation, value);
    state = state.copyWith(hideExactLocation: value);
    _pushPrivacyRemote({'location_sharing': !value});
  }

  Future<void> updateNotifNewMessages(bool value) async {
    await _prefs.setBool(PrefKeys.notifNewMessages, value);
    state = state.copyWith(notifNewMessages: value);
    _pushNotificationRemote();
  }

  Future<void> updateNotifPromotions(bool value) async {
    await _prefs.setBool(PrefKeys.notifPromotions, value);
    state = state.copyWith(notifPromotions: value);
    _pushNotificationRemote();
  }

  Future<void> updateAllNotificationSettings(bool value) async {
    await Future.wait([
      _prefs.setBool(PrefKeys.notifNewMessages, value),
      _prefs.setBool(PrefKeys.notifPromotions, value),
    ]);
    state = state.copyWith(notifNewMessages: value, notifPromotions: value);
    _pushNotificationRemote();
  }

  void _pushNotificationRemote() => unawaited(_syncNotificationRemote());

  Future<void> _syncNotificationRemote() async {
    final generation = _accountGeneration;
    try {
      // push_notifications is the messages switch, promotional_emails the
      // promotions switch; email and sms keep the last value the server sent.
      if (!_lastNotifKnown) {
        final remote = await _repo.fetchNotificationSettings();
        if (generation != _accountGeneration) return;
        _lastNotif = remote;
        _lastNotifKnown = true;
      }
      final settings = RemoteNotificationSettings(
        pushNotifications: state.notifNewMessages,
        promotionalEmails: state.notifPromotions,
        emailNotifications: _lastNotif.emailNotifications,
        smsNotifications: _lastNotif.smsNotifications,
      );
      _lastNotif = settings;
      await _repo.updateNotificationSettings(settings);
    } catch (e) {
      debugPrint('SettingsController._pushNotificationRemote: $e');
    }
  }

  /// Writes only the privacy keys that changed.
  void _pushPrivacyRemote(Map<String, bool> patch) {
    unawaited(_syncPrivacyRemote(patch));
  }

  Future<void> _syncPrivacyRemote(Map<String, bool> patch) async {
    try {
      await _repo.updatePrivacySettings(patch);
    } catch (e) {
      debugPrint('SettingsController._pushPrivacyRemote: $e');
    }
  }
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, SettingsState>(SettingsController.new);
