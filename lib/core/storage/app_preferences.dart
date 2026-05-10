import 'package:shared_preferences/shared_preferences.dart';

abstract final class PrefKeys {
  static const themeMode = 'theme_mode';
  static const palette = 'theme_palette';
  static const localeLanguageCode = 'locale_language_code';
  static const localeCountryCode = 'locale_country_code';
  static const hideLastName = 'privacy_hide_last_name';
  static const hideExactLocation = 'privacy_hide_exact_location';
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

  Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);
}
