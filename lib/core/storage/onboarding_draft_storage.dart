import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'app_preferences.dart';

/// The onboarding draft: the answers a user typed before the profile exists.
///
/// The draft is account data, so the store follows three rules:
/// - it carries a schema version ([schemaVersion]); a draft of another version
///   is dropped, never read;
/// - it carries the id of the account that wrote it; another account (or no
///   account) never reads it;
/// - sign-out removes it (`AppPreferences.clearAccountData`).
class OnboardingDraftStorage {
  OnboardingDraftStorage(this._prefs, {String? Function()? accountId})
    : _accountId = accountId ?? (() => null);

  /// Bump when the shape of the draft map changes. An older draft is dropped.
  static const int schemaVersion = 1;

  final AppPreferences _prefs;
  final String? Function() _accountId;

  Map<String, dynamic>? load() {
    try {
      final savedJson = _prefs.getString(PrefKeys.onboardingDraft);
      if (savedJson == null) return null;
      final stored = Map<String, dynamic>.from(jsonDecode(savedJson) as Map);
      if (stored['v'] != schemaVersion) {
        debugPrint(
          '[OnboardingDraftStorage] dropped a draft of version ${stored['v']}',
        );
        return null;
      }
      // A draft saved with no account (or read with none) is never restored.
      final account = _accountId();
      if (account == null || stored['account'] != account) {
        debugPrint(
          '[OnboardingDraftStorage] dropped a draft of another account',
        );
        return null;
      }
      final data = stored['data'];
      return data is Map ? Map<String, dynamic>.from(data) : null;
    } catch (e) {
      debugPrint('[OnboardingDraftStorage] load error: $e');
      return null;
    }
  }

  Future<void> save(Map<String, dynamic> data) async {
    try {
      await _prefs.setString(
        PrefKeys.onboardingDraft,
        jsonEncode({'v': schemaVersion, 'account': _accountId(), 'data': data}),
      );
    } catch (e) {
      debugPrint('[OnboardingDraftStorage] save error: $e');
    }
  }

  Future<void> clear() async {
    try {
      await _prefs.remove(PrefKeys.onboardingDraft);
    } catch (e) {
      debugPrint('[OnboardingDraftStorage] clear error: $e');
    }
  }
}
