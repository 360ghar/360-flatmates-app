import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../core/theme/app_palette.dart';

part 'settings_state.freezed.dart';

@Freezed()
class SettingsState with _$SettingsState {
  const SettingsState._();

  const factory SettingsState({
    @Default(ThemeMode.light) ThemeMode themeMode,
    @Default(AppPalette.inkOnPaper) AppPalette palette,
    @Default(Locale('en')) Locale? locale,
    @Default(false) bool loaded,
    @Default(false) bool hideLastName,
    @Default(false) bool hideExactLocation,
  }) = _SettingsState;
}
