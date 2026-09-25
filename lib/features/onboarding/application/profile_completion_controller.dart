import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/storage/app_preferences.dart';
import '../../auth/auth_controller.dart';
import '../../bootstrap/bootstrap_controller.dart';
import '../../profile/profile_repository.dart';

/// Saves the mandatory fields asked for by the backend `profile_completion`
/// auth gate (`full_name`, `date_of_birth`) and advances the gate.
///
/// Persistence strategy (production-safe without backend deploy rights):
/// 1. `PUT /flatmates/profile` for `full_name` (+ derived `age`) — that
///    endpoint **explicitly commits** on the server.
/// 2. `PUT /users/me` for `full_name` + `date_of_birth` (gate fields on User).
/// 3. If auth-state still reports profile_completion after retries (known
///    production bug: `/users/me` returns 200 with fields that never commit),
///    record a per-user local override and advance the client gate so the
///    user is not permanently stuck.
class ProfileCompletionController {
  ProfileCompletionController(this._ref);

  final Ref _ref;

  static int ageFromDob(DateTime dob) {
    final today = DateTime.now();
    return today.year -
        dob.year -
        ((today.month < dob.month ||
                (today.month == dob.month && today.day < dob.day))
            ? 1
            : 0);
  }

  static String _isoDate(DateTime dob) =>
      '${dob.year}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}';

  /// Returns true when the gate advanced past `profile_completion`, false
  /// when it is still stuck. Throws on unexpected failures.
  Future<bool> submit({
    required String trimmedName,
    required DateTime? dob,
    required bool needsName,
    required bool needsDob,
  }) async {
    final repo = _ref.read(profileRepositoryProvider);

    // Only write fields the gate currently requires — do not resubmit
    // bootstrap-cached name on DOB-only completion (can overwrite newer data).
    // ── 1) Durable name write via flatmates profile (server commits) ──
    // Production `PUT /users/me` has been observed to roll back; the
    // flatmates profile endpoint calls `await db.commit()` itself.
    if (needsName && trimmedName.length >= 2) {
      final flatmatesPayload = <String, dynamic>{'full_name': trimmedName};
      if (needsDob && dob != null) {
        flatmatesPayload['age'] = ageFromDob(dob);
      }
      try {
        await repo.updateProfile(payload: flatmatesPayload);
        debugPrint(
          'ProfileCompletionController: flatmates profile saved name/age',
        );
      } catch (e) {
        debugPrint(
          'ProfileCompletionController: flatmates profile save failed: $e',
        );
        // Continue — still try /users/me below.
      }
    } else if (needsDob && dob != null) {
      // DOB-only: still push derived age on the durable profile path.
      try {
        await repo.updateProfile(payload: {'age': ageFromDob(dob)});
      } catch (e) {
        debugPrint(
          'ProfileCompletionController: flatmates age save failed: $e',
        );
      }
    }

    // ── 2) Gate fields on User via PUT /users/me ─────────────────────
    final userPayload = <String, dynamic>{};
    if (needsName && trimmedName.length >= 2) {
      userPayload['full_name'] = trimmedName;
    }
    if (needsDob && dob != null) {
      userPayload['date_of_birth'] = _isoDate(dob);
    }

    bool responseMatchesPayload(
      Map<String, dynamic> payload,
      Map<String, dynamic> response,
    ) {
      final nameOk =
          !payload.containsKey('full_name') ||
          ((response['full_name']?.toString().trim() ?? '').isNotEmpty);
      final dobOk =
          !payload.containsKey('date_of_birth') ||
          ((response['date_of_birth']?.toString().trim() ?? '').isNotEmpty);
      return nameOk && dobOk;
    }

    var putLooksOk = false;
    if (userPayload.isNotEmpty) {
      final updated = await repo.updateUser(payload: userPayload);
      debugPrint(
        'ProfileCompletionController._submit PUT /users/me '
        'responseDob=${updated['date_of_birth']} '
        'responseName=${updated['full_name']}',
      );
      putLooksOk = responseMatchesPayload(userPayload, updated);

      // Second attempt with ISO datetime if date-only body looked empty.
      if (!putLooksOk && needsDob && dob != null) {
        final retryPayload = Map<String, dynamic>.from(userPayload);
        retryPayload['date_of_birth'] = '${_isoDate(dob)}T00:00:00.000Z';
        final retried = await repo.updateUser(payload: retryPayload);
        debugPrint(
          'ProfileCompletionController._submit PUT retry datetime '
          'responseDob=${retried['date_of_birth']} '
          'responseName=${retried['full_name']}',
        );
        putLooksOk = responseMatchesPayload(retryPayload, retried);
      }
    }

    // ── 3) Re-read auth-state with retries ───────────────────────────
    var stage = AuthStage.profileCompletion;
    List<String> missing = const [];
    Object? lastAuthError;
    for (var attempt = 0; attempt < 4; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(Duration(milliseconds: 300 * attempt));
      }
      try {
        await _ref
            .read(bootstrapControllerProvider.notifier)
            .refreshAuthStage();
        lastAuthError = null;
      } catch (e) {
        lastAuthError = e;
        debugPrint(
          'ProfileCompletionController.refreshAuthStage attempt=$attempt failed: $e',
        );
        continue;
      }
      final auth = _ref.read(authControllerProvider);
      stage = auth.authStage;
      missing = auth.missingProfileFields;
      debugPrint(
        'ProfileCompletionController._submit auth attempt=$attempt '
        'stage=$stage missing=$missing',
      );
      if (stage != AuthStage.profileCompletion) break;
    }

    // ── 4) Verify durable server state (GET, not PUT response) ───────
    Map<String, dynamic> verified = const {};
    try {
      verified = await repo.fetchUser();
      debugPrint(
        'ProfileCompletionController GET /users/me '
        'name=${verified['full_name']} dob=${verified['date_of_birth']}',
      );
    } catch (e) {
      debugPrint('ProfileCompletionController.fetchUser failed: $e');
    }

    final verifiedName = verified['full_name']?.toString().trim() ?? '';
    final verifiedDob = verified['date_of_birth']?.toString().trim() ?? '';
    final serverHasName = verifiedName.isNotEmpty;
    final serverHasDob = verifiedDob.isNotEmpty;

    // ── 5) Local override when server gate is stuck after a good form ─
    // If GET still lacks DOB (production /users/me commit bug) but the
    // user filled a valid form and name was saved (or PUT looked ok),
    // advance the client gate so signup is not a dead end.
    if (stage == AuthStage.profileCompletion) {
      final profileId = _ref
          .read(bootstrapControllerProvider)
          .valueOrNull
          ?.profile
          .id
          .toString();
      final nameSatisfied =
          !needsName || trimmedName.length >= 2 || serverHasName;
      final dobSatisfied = !needsDob || dob != null || serverHasDob;
      final canOverride =
          profileId != null &&
          profileId.isNotEmpty &&
          nameSatisfied &&
          dobSatisfied &&
          (putLooksOk || serverHasName || serverHasDob || !needsName);

      if (canOverride) {
        debugPrint(
          'ProfileCompletionController: applying local gate override for '
          'user=$profileId serverHasName=$serverHasName '
          'serverHasDob=$serverHasDob putLooksOk=$putLooksOk '
          'missing=$missing lastAuthError=$lastAuthError',
        );
        await _ref
            .read(appPreferencesProvider)
            .setString(PrefKeys.profileCompletionLocalUserId, profileId);
        _ref
            .read(authControllerProvider.notifier)
            .updateGateStage(AuthStage.appOnboarding);
        stage = AuthStage.appOnboarding;
      }
    }

    unawaited(_ref.read(bootstrapControllerProvider.notifier).refresh());

    if (stage == AuthStage.profileCompletion) {
      debugPrint(
        'ProfileCompletionController.submit gate stuck; '
        'missing=$missing lastAuthError=$lastAuthError',
      );
      return false;
    }
    return true;
  }
}

final profileCompletionControllerProvider =
    Provider<ProfileCompletionController>(ProfileCompletionController.new);
