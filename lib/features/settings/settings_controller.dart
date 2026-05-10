import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/storage/app_preferences.dart';
import '../../core/theme/app_palette.dart';
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
    final paletteRaw = _prefs.getString(PrefKeys.palette);
    final languageCode = _prefs.getString(PrefKeys.localeLanguageCode);
    final countryCode = _prefs.getString(PrefKeys.localeCountryCode);

    state = state.copyWith(
      themeMode: switch (themeRaw) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        'system' => ThemeMode.system,
        _ => ThemeMode.light,
      },
      palette: AppPaletteX.fromStorage(paletteRaw),
      locale: languageCode == null
          ? const Locale('en')
          : Locale(languageCode, countryCode),
      hideLastName: _prefs.getBool(PrefKeys.hideLastName),
      hideExactLocation: _prefs.getBool(PrefKeys.hideExactLocation),
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

  Future<void> updatePalette(AppPalette palette) async {
    await _prefs.setString(PrefKeys.palette, palette.storageValue);
    state = state.copyWith(palette: palette);
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
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, SettingsState>(SettingsController.new);
