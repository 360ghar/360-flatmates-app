import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

import '../providers.dart';

/// The one Shorebird updater handle for the whole process.
///
/// Constructing a [ShorebirdUpdater] synchronously probes the Shorebird engine
/// over FFI — the package's own source carries a FIXME warning that this can
/// block on the native config lock if another thread is in the updater at the
/// same time, which is plausible at launch while Shorebird checks for patches in
/// the background. Both call sites (this service and `AnalyticsService`, which
/// needs the patch number before `runApp`) share this lazily-created instance so
/// the probe happens exactly once per process instead of once per call site.
final ShorebirdUpdater sharedShorebirdUpdater = ShorebirdUpdater();

/// Read-only view of Shorebird's over-the-air patch state.
///
/// Patch downloads are handled by Shorebird itself (`auto_update: true` in
/// `shorebird.yaml`) — this service never downloads or applies anything. It
/// exists so a patched build is *observable*: the patch number is attached to
/// Crashlytics reports, surfaced in the About dialog, and used to tell the user
/// once when a downloaded patch is waiting on a restart.
///
/// Every method degrades to null/false when the updater is absent — debug
/// builds, `flutter run`, and any binary not produced by `shorebird release`.
/// See [ShorebirdUpdater.isAvailable].
class PatchService {
  PatchService({required this.ref, ShorebirdUpdater? updater})
    : _updater = updater ?? sharedShorebirdUpdater;

  final Ref ref;
  final ShorebirdUpdater _updater;

  static const _nudgedPatchKey = 'shorebird_patch_nudged';

  /// The patch currently running, or null when running the base release.
  Future<int?> currentPatchNumber() async {
    try {
      final patch = await _updater.readCurrentPatch();
      return patch?.number;
    } on ReadPatchException catch (e) {
      debugPrint('PatchService.currentPatchNumber: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('PatchService.currentPatchNumber: $e');
      return null;
    }
  }

  /// A downloaded patch that is not yet running, or null when there is none.
  ///
  /// `readNextPatch()` returns the *current* patch when nothing new has been
  /// downloaded, so the two are compared to isolate a genuinely pending patch.
  Future<int?> pendingPatchNumber() async {
    try {
      final next = await _updater.readNextPatch();
      if (next == null) return null;
      final current = await _updater.readCurrentPatch();
      return next.number == current?.number ? null : next.number;
    } on ReadPatchException catch (e) {
      debugPrint('PatchService.pendingPatchNumber: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('PatchService.pendingPatchNumber: $e');
      return null;
    }
  }

  /// True when the user has not yet been told about [patchNumber].
  ///
  /// Mirrors the per-version dismissal used for optional store updates so a
  /// pending patch is announced exactly once, not on every resume.
  bool shouldNudgeForPatch(int patchNumber) {
    try {
      final prefs = ref.read(appPreferencesProvider);
      return prefs.getString(_nudgedPatchKey) != '$patchNumber';
    } catch (e) {
      debugPrint('PatchService.shouldNudgeForPatch: $e');
      return false;
    }
  }

  Future<void> markPatchNudged(int patchNumber) async {
    try {
      final prefs = ref.read(appPreferencesProvider);
      await prefs.setString(_nudgedPatchKey, '$patchNumber');
    } catch (e) {
      debugPrint('PatchService.markPatchNudged: $e');
    }
  }
}

final patchServiceProvider = Provider<PatchService>(
  (ref) => PatchService(ref: ref),
);
