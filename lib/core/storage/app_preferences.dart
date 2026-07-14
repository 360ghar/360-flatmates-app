import 'package:shared_preferences/shared_preferences.dart';

abstract final class PrefKeys {
  static const themeMode = 'theme_mode';
  static const palette = 'theme_palette';
  static const localeLanguageCode = 'locale_language_code';
  static const localeCountryCode = 'locale_country_code';
  static const hideLastName = 'privacy_hide_last_name';
  static const hideExactLocation = 'privacy_hide_exact_location';
  static const notifNewMessages = 'notif_new_messages';
  static const notifVisitReminders = 'notif_visit_reminders';
  static const notifNewMatches = 'notif_new_matches';
  static const notifListingUpdates = 'notif_listing_updates';
  static const notifPromotions = 'notif_promotions';
  static const notifPermissionRequested = 'notif_permission_requested';

  /// Last auth method used (wire value: google|email_password|...), so the
  /// auth-entry screen can pre-select / highlight it on return.
  static const lastAuthMethod = 'last_auth_method';

  /// Masked last identifier (phone/email) used, for display hints.
  static const lastAuthIdentifier = 'last_auth_identifier';

  /// Local fallback for a successful FlatMates onboarding completion when the
  /// backend auth-state mirror is stale.
  static const flatmatesOnboardingCompletedUserId =
      'flatmates_onboarding_completed_user_id';

  /// Survives process death between OTP verify and set-password so the
  /// mandatory password gate is restored on cold start with a live session.
  static const pendingPasswordSetup = 'pending_password_setup';
}

final class AppPreferences {
  AppPreferences._(this._prefs);

  final SharedPreferences _prefs;

  static Future<AppPreferences> create() async {
    final prefs = await SharedPreferences.getInstance();
    return AppPreferences._(prefs);
  }

  String? getString(String key) => _prefs.getString(key);

  Future<bool> setString(String key, String value) =>
      _prefs.setString(key, value);

  Future<bool> remove(String key) => _prefs.remove(key);

  bool getBool(String key) => _prefs.getBool(key) ?? false;

  bool getBoolOrDefault(String key, bool defaultValue) =>
      _prefs.getBool(key) ?? defaultValue;

  bool containsKey(String key) => _prefs.containsKey(key);

  Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);
}
