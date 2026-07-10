import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings_state.freezed.dart';

@Freezed()
class SettingsState with _$SettingsState {
  const SettingsState._();

  const factory SettingsState({
    @Default(ThemeMode.light) ThemeMode themeMode,
    @Default(Locale('en')) Locale? locale,
    @Default(false) bool loaded,
    @Default(false) bool hideLastName,
    @Default(false) bool hideExactLocation,
    @Default(true) bool notifNewMessages,
    @Default(true) bool notifVisitReminders,
    @Default(true) bool notifNewMatches,
    @Default(true) bool notifListingUpdates,
    @Default(false) bool notifPromotions,
  }) = _SettingsState;
}
