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

  Future<void> _queue = Future<void>.value();

  // One at a time: two hooks must not both read the same "due" state.
  Future<void> _enqueue(Future<void> Function() job) {
    final run = _queue.then((_) => job());
    _queue = run;
    return run;
  }

  int get _successes =>
      int.tryParse(_prefs.getString(PrefKeys.reviewSuccessCount) ?? '') ?? 0;

  /// Counts one success moment without asking. Never throws.
  Future<void> recordSuccess() => _enqueue(() async {
    try {
      await _prefs.setString(PrefKeys.reviewSuccessCount, '${_successes + 1}');
    } catch (e) {
      debugPrint('ReviewPrompter.recordSuccess: $e');
    }
  });

  /// Shows the native review sheet when a prompt is due. Never throws.
  Future<void> maybePrompt() => _enqueue(() async {
    try {
      final last = int.tryParse(
        _prefs.getString(PrefKeys.reviewLastPromptAt) ?? '',
      );
      final now = _clock();
      final lastAt = last == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(last);
      if (!isDue(_successes, lastAt, now)) return;
      if (!await _review.isAvailable()) return;
      // Persist first: if the write fails, ask nothing, so a broken store
      // cannot cause a prompt on every success.
      final saved = await _prefs.setString(
        PrefKeys.reviewLastPromptAt,
        '${now.millisecondsSinceEpoch}',
      );
      if (!saved) return;
      await _review.requestReview();
    } catch (e) {
      debugPrint('ReviewPrompter.maybePrompt: $e');
    }
  });

  /// Counts one success moment, then asks when due.
  Future<void> onSuccess() async {
    await recordSuccess();
    await maybePrompt();
  }
}
