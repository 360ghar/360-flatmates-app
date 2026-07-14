import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/storage/app_preferences.dart';
import 'data/settings_repository.dart';
import 'domain/settings_state.dart';
export 'domain/settings_state.dart';

class SettingsController extends Notifier<SettingsState> {
  /// Last known remote notification payload so PUTs do not wipe unknown keys.
  Map<String, dynamic> _lastNotifPayload = {};

  /// Last known remote privacy payload so PUTs do not wipe unknown keys.
  Map<String, dynamic> _lastPrivacyPayload = {};

  @override
  SettingsState build() {
    Future.microtask(() => load());
    return const SettingsState();
  }

  AppPreferences get _prefs => ref.read(appPreferencesProvider);

  SettingsRepository get _repo => ref.read(settingsRepositoryProvider);

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

    // Best-effort remote merge — local prefs already applied above.
    await _mergeRemoteNotificationSettings();
    await _mergeRemotePrivacySettings();
  }

  Future<void> _mergeRemoteNotificationSettings() async {
    try {
      final remote = await _repo.fetchNotificationSettings();
      _lastNotifPayload = remote.toJson();

      final categories = remote.categories;
      final notifNewMessages = remote.pushNotifications;
      final notifVisitReminders = remote.visitReminders;
      final notifListingUpdates = remote.propertyUpdates;
      final notifPromotions = remote.promotionalEmails;
      final notifNewMatches = categories['new_matches'] ?? true;

      await Future.wait([
        _prefs.setBool(PrefKeys.notifNewMessages, notifNewMessages),
        _prefs.setBool(PrefKeys.notifVisitReminders, notifVisitReminders),
        _prefs.setBool(PrefKeys.notifListingUpdates, notifListingUpdates),
        _prefs.setBool(PrefKeys.notifPromotions, notifPromotions),
        _prefs.setBool(PrefKeys.notifNewMatches, notifNewMatches),
      ]);

      state = state.copyWith(
        notifNewMessages: notifNewMessages,
        notifVisitReminders: notifVisitReminders,
        notifListingUpdates: notifListingUpdates,
        notifPromotions: notifPromotions,
        notifNewMatches: notifNewMatches,
      );
    } catch (e) {
      debugPrint('SettingsController._mergeRemoteNotificationSettings: $e');
    }
  }

  Future<void> _mergeRemotePrivacySettings() async {
    try {
      final remote = await _repo.fetchPrivacySettings();
      _lastPrivacyPayload = remote.toJson();

      final hideExactLocation = !remote.locationSharing;
      // hide_last_name is not on the typed PrivacySettings schema (stripped on
      // GET); keep local prefs as source of truth, but honor raw if present.
      final hideLastNameRaw = remote.raw['hide_last_name'];
      final hideLastName = hideLastNameRaw is bool
          ? hideLastNameRaw
          : state.hideLastName;

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
    _pushPrivacyRemote();
  }

  Future<void> updateHideExactLocation(bool value) async {
    await _prefs.setBool(PrefKeys.hideExactLocation, value);
    state = state.copyWith(hideExactLocation: value);
    _pushPrivacyRemote();
  }

  Future<void> updateNotifNewMessages(bool value) async {
    await _prefs.setBool(PrefKeys.notifNewMessages, value);
    state = state.copyWith(notifNewMessages: value);
    _pushNotificationRemote();
  }

  Future<void> updateNotifVisitReminders(bool value) async {
    await _prefs.setBool(PrefKeys.notifVisitReminders, value);
    state = state.copyWith(notifVisitReminders: value);
    _pushNotificationRemote();
  }

  Future<void> updateNotifNewMatches(bool value) async {
    await _prefs.setBool(PrefKeys.notifNewMatches, value);
    state = state.copyWith(notifNewMatches: value);
    _pushNotificationRemote();
  }

  Future<void> updateNotifListingUpdates(bool value) async {
    await _prefs.setBool(PrefKeys.notifListingUpdates, value);
    state = state.copyWith(notifListingUpdates: value);
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
    _pushNotificationRemote();
  }

  /// Builds the remote notification payload from current local state.
  Map<String, dynamic> _buildNotificationPayload() {
    final s = state;
    final categories = <String, dynamic>{
      ...?(_lastNotifPayload['categories'] is Map
          ? Map<String, dynamic>.from(_lastNotifPayload['categories'] as Map)
          : null),
      'visit_reminders': s.notifVisitReminders,
      'property_updates': s.notifListingUpdates,
      'promotions': s.notifPromotions,
      'new_matches': s.notifNewMatches,
    };

    // push_notifications tracks messages; keep it true when messages are on
    // regardless of match toggle (matches live under categories.new_matches).
    final payload = Map<String, dynamic>.from(_lastNotifPayload)
      ..addAll({
        'push_notifications': s.notifNewMessages,
        'visit_reminders': s.notifVisitReminders,
        'property_updates': s.notifListingUpdates,
        'promotional_emails': s.notifPromotions,
        'categories': categories,
      });
    return payload;
  }

  /// Builds privacy payload including `hide_last_name` for the compat endpoint.
  Map<String, dynamic> _buildPrivacyPayload() {
    final s = state;
    return Map<String, dynamic>.from(_lastPrivacyPayload)..addAll({
      'profile_visibility':
          _lastPrivacyPayload['profile_visibility'] ?? 'public',
      'location_sharing': !s.hideExactLocation,
      'contact_sharing': _lastPrivacyPayload['contact_sharing'] ?? true,
      'search_history_tracking':
          _lastPrivacyPayload['search_history_tracking'] ?? true,
      'hide_last_name': s.hideLastName,
    });
  }

  void _pushNotificationRemote() {
    final payload = _buildNotificationPayload();
    _lastNotifPayload = payload;
    unawaited(_syncNotificationRemote(payload));
  }

  void _pushPrivacyRemote() {
    final payload = _buildPrivacyPayload();
    _lastPrivacyPayload = payload;
    // Use compat PUT so hide_last_name is accepted (typed schema strips it).
    unawaited(_syncPrivacyRemote(payload));
  }

  Future<void> _syncNotificationRemote(Map<String, dynamic> payload) async {
    try {
      await _repo.updateNotificationSettings(payload);
    } catch (e) {
      debugPrint('SettingsController._pushNotificationRemote: $e');
    }
  }

  Future<void> _syncPrivacyRemote(Map<String, dynamic> payload) async {
    try {
      await _repo.updatePrivacySettingsCompat(payload);
    } catch (e) {
      debugPrint('SettingsController._pushPrivacyRemote: $e');
    }
  }
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, SettingsState>(SettingsController.new);
