import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';

import '../storage/app_preferences.dart';

/// Asks for a store rating after a success moment (a match or a visit request).
///
/// The native sheet is rate-limited by the OS. This class adds its own limits:
/// it waits for [minSuccesses] success moments, so a brand-new user is never
/// asked, and it asks again only after [cooldown].
final class ReviewPrompter {
  ReviewPrompter(
    this._prefs, {
    InAppReview? review,
    DateTime Function()? clock,
    this.minSuccesses = 2,
    this.cooldown = const Duration(days: 120),
  }) : _review = review ?? InAppReview.instance,
       _clock = clock ?? DateTime.now;

  final AppPreferences _prefs;
  final InAppReview _review;
  final DateTime Function() _clock;
  final int minSuccesses;
  final Duration cooldown;

  /// Whether a prompt is due for [successes] success moments.
  @visibleForTesting
  bool isDue(int successes, DateTime? lastPromptAt, DateTime now) =>
      successes >= minSuccesses &&
      (lastPromptAt == null || now.difference(lastPromptAt) >= cooldown);

  /// Counts one success moment. When [prompt] is true and a prompt is due,
  /// shows the native review sheet. Never throws.
  Future<void> onSuccess({bool prompt = true}) async {
    try {
      final successes =
          (int.tryParse(_prefs.getString(PrefKeys.reviewSuccessCount) ?? '') ??
              0) +
          1;
      await _prefs.setString(PrefKeys.reviewSuccessCount, '$successes');
      if (!prompt) return;
      final last = int.tryParse(
        _prefs.getString(PrefKeys.reviewLastPromptAt) ?? '',
      );
      final now = _clock();
      final lastAt = last == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(last);
      if (!isDue(successes, lastAt, now)) return;
      if (!await _review.isAvailable()) return;
      await _prefs.setString(
        PrefKeys.reviewLastPromptAt,
        '${now.millisecondsSinceEpoch}',
      );
      await _review.requestReview();
    } catch (e) {
      debugPrint('ReviewPrompter.onSuccess: $e');
    }
  }
}
