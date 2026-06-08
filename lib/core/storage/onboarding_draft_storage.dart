import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'app_preferences.dart';

class OnboardingDraftStorage {
  OnboardingDraftStorage(this._prefs);

  static const String _prefsKey = 'onboarding_state';

  final AppPreferences _prefs;

  Map<String, dynamic>? load() {
    try {
      final savedJson = _prefs.getString(_prefsKey);
      if (savedJson == null) return null;
      return Map<String, dynamic>.from(jsonDecode(savedJson) as Map);
    } catch (e) {
      debugPrint('[OnboardingDraftStorage] load error: $e');
      return null;
    }
  }

  Future<void> save(Map<String, dynamic> data) async {
    try {
      await _prefs.setString(_prefsKey, jsonEncode(data));
    } catch (e) {
      debugPrint('[OnboardingDraftStorage] save error: $e');
    }
  }

  Future<void> clear() async {
    try {
      await _prefs.remove(_prefsKey);
    } catch (e) {
      debugPrint('[OnboardingDraftStorage] clear error: $e');
    }
  }
}
