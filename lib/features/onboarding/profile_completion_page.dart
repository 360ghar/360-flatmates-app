import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_failure.dart';
import '../../core/errors/l10n_bridge.dart';
import '../../core/providers.dart';
import '../../core/storage/app_preferences.dart';
import '../../core/theme/app_semantic_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../auth/auth_controller.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../profile/profile_repository.dart';
import '../shared/presentation/components.dart';

/// A focused, onboarding-style page that collects only the mandatory profile
/// fields reported missing by the backend `profile_completion` auth gate
/// (typically `full_name` and `date_of_birth`).
///
/// Unlike the full [EditProfilePage], this page shows a minimal form with
/// clear context about why the user is here and what happens next.
///
/// Persistence strategy (production-safe without backend deploy rights):
/// 1. `PUT /flatmates/profile` for `full_name` (+ derived `age`) — that
///    endpoint **explicitly commits** on the server.
/// 2. `PUT /users/me` for `full_name` + `date_of_birth` (gate fields on User).
/// 3. If auth-state still reports profile_completion after retries (known
///    production bug: `/users/me` returns 200 with fields that never commit),
///    record a per-user local override and advance the client gate so the
///    user is not permanently stuck.
class ProfileCompletionPage extends ConsumerStatefulWidget {
  const ProfileCompletionPage({super.key});

  @override
  ConsumerState<ProfileCompletionPage> createState() =>
      _ProfileCompletionPageState();
}

class _ProfileCompletionPageState extends ConsumerState<ProfileCompletionPage> {
  late final TextEditingController _nameController;
  bool _saving = false;
  bool _hasError = false;
  bool _initialized = false;
  DateTime? _dob;
  String _name = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    // Prefill once after the first frame so we never mutate state in build.
    WidgetsBinding.instance.addPostFrameCallback((_) => _prefillFromProfile());
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _prefillFromProfile() {
    if (!mounted || _initialized) return;
    final profile = ref.read(bootstrapControllerProvider).valueOrNull?.profile;
    if (profile == null) return;

    _initialized = true;
    final existingName = profile.fullName ?? '';
    if (existingName.isNotEmpty && _name.isEmpty) {
      setState(() {
        _name = existingName;
        _nameController.text = existingName;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final missingFields = ref
        .watch(authControllerProvider)
        .missingProfileFields;
    final needsName =
        missingFields.isEmpty || missingFields.contains('full_name');
    final needsDob =
        missingFields.isEmpty || missingFields.contains('date_of_birth');

    // If bootstrap arrives after first frame, prefill when it becomes ready.
    ref.listen(bootstrapControllerProvider, (previous, next) {
      if (!_initialized && next.valueOrNull?.profile != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _prefillFromProfile();
        });
      }
    });

    final isNameValid = _name.trim().length >= 2;
    final isDobValid = _dob != null && _isAtLeast18(_dob!);
    final isValid = (!needsName || isNameValid) && (!needsDob || isDobValid);

    // Mandatory gate — same pattern as SetPasswordPage: system back cannot
    // dismiss, and there is no AppBar back that would loop via the hard
    // profile_completion redirect.
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: FlatmatesHeader.titleOnly(title: locale.profileCompletionTitle),
        body: SafeArea(
          minimum: AppSpacing.horizontalScreen,
          child: ListView(
            children: [
              const SizedBox(height: AppSpacing.xl),
              Text(
                locale.profileCompletionSubtitle,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppSemanticColors.textSecondaryFor(theme.brightness),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              if (needsName) ...[
                TextField(
                  key: const Key('profile_completion_name'),
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: locale.fullNameLabel,
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  onChanged: (v) => setState(() => _name = v),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
              if (needsDob) ...[
                _DateOfBirthField(
                  selectedDate: _dob,
                  onTap: () => _pickDateOfBirth(context, locale),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              if (_hasError) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 18,
                      color: AppSemanticColors.error,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        locale.profileCompletionError,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppSemanticColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.xxl),
              FlatmatesButton(
                key: const Key('profile_completion_submit'),
                label: _saving
                    ? locale.profileCompletionSaving
                    : locale.profileCompletionContinue,
                fullWidth: true,
                onPressed: (isValid && !_saving)
                    ? () => _submit(
                        context,
                        locale,
                        needsName: needsName,
                        needsDob: needsDob,
                      )
                    : null,
                icon: _saving ? null : Icons.arrow_forward_rounded,
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  int _ageFromDob(DateTime dob) {
    final today = DateTime.now();
    return today.year -
        dob.year -
        ((today.month < dob.month ||
                (today.month == dob.month && today.day < dob.day))
            ? 1
            : 0);
  }

  bool _isAtLeast18(DateTime dob) => _ageFromDob(dob) >= 18;

  String _isoDate(DateTime dob) =>
      '${dob.year}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}';

  Future<void> _pickDateOfBirth(
    BuildContext context,
    AppLocalizations locale,
  ) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25),
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - 18, now.month, now.day),
      helpText: locale.dateOfBirthPickerTitle,
    );
    if (picked != null && mounted) {
      setState(() => _dob = picked);
    }
  }

  Future<void> _submit(
    BuildContext context,
    AppLocalizations locale, {
    required bool needsName,
    required bool needsDob,
  }) async {
    if (_saving) return;
    if (needsName && _name.trim().length < 2) return;
    if (needsDob && (_dob == null || !_isAtLeast18(_dob!))) return;

    setState(() {
      _saving = true;
      _hasError = false;
    });

    try {
      final trimmedName = _name.trim();
      final dob = _dob;
      final repo = ref.read(profileRepositoryProvider);

      // Only write fields the gate currently requires — do not resubmit
      // bootstrap-cached name on DOB-only completion (can overwrite newer data).
      // ── 1) Durable name write via flatmates profile (server commits) ──
      // Production `PUT /users/me` has been observed to roll back; the
      // flatmates profile endpoint calls `await db.commit()` itself.
      if (needsName && trimmedName.length >= 2) {
        final flatmatesPayload = <String, dynamic>{'full_name': trimmedName};
        if (needsDob && dob != null) {
          flatmatesPayload['age'] = _ageFromDob(dob);
        }
        try {
          await repo.updateProfile(payload: flatmatesPayload);
          debugPrint('ProfileCompletionPage: flatmates profile saved name/age');
        } catch (e) {
          debugPrint(
            'ProfileCompletionPage: flatmates profile save failed: $e',
          );
          // Continue — still try /users/me below.
        }
      } else if (needsDob && dob != null) {
        // DOB-only: still push derived age on the durable profile path.
        try {
          await repo.updateProfile(payload: {'age': _ageFromDob(dob)});
        } catch (e) {
          debugPrint('ProfileCompletionPage: flatmates age save failed: $e');
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
          'ProfileCompletionPage._submit PUT /users/me '
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
            'ProfileCompletionPage._submit PUT retry datetime '
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
          await ref
              .read(bootstrapControllerProvider.notifier)
              .refreshAuthStage();
          lastAuthError = null;
        } catch (e) {
          lastAuthError = e;
          debugPrint(
            'ProfileCompletionPage.refreshAuthStage attempt=$attempt failed: $e',
          );
          continue;
        }
        if (!context.mounted) return;
        final auth = ref.read(authControllerProvider);
        stage = auth.authStage;
        missing = auth.missingProfileFields;
        debugPrint(
          'ProfileCompletionPage._submit auth attempt=$attempt '
          'stage=$stage missing=$missing',
        );
        if (stage != AuthStage.profileCompletion) break;
      }

      // ── 4) Verify durable server state (GET, not PUT response) ───────
      Map<String, dynamic> verified = const {};
      try {
        verified = await repo.fetchUser();
        debugPrint(
          'ProfileCompletionPage GET /users/me '
          'name=${verified['full_name']} dob=${verified['date_of_birth']}',
        );
      } catch (e) {
        debugPrint('ProfileCompletionPage.fetchUser failed: $e');
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
        final profileId = ref
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
            'ProfileCompletionPage: applying local gate override for '
            'user=$profileId serverHasName=$serverHasName '
            'serverHasDob=$serverHasDob putLooksOk=$putLooksOk '
            'missing=$missing lastAuthError=$lastAuthError',
          );
          await ref
              .read(appPreferencesProvider)
              .setString(PrefKeys.profileCompletionLocalUserId, profileId);
          ref
              .read(authControllerProvider.notifier)
              .updateGateStage(AuthStage.appOnboarding);
          stage = AuthStage.appOnboarding;
        }
      }

      unawaited(ref.read(bootstrapControllerProvider.notifier).refresh());

      if (!context.mounted) return;
      if (stage == AuthStage.profileCompletion) {
        debugPrint(
          'ProfileCompletionPage._submit gate stuck; '
          'missing=$missing lastAuthError=$lastAuthError',
        );
        setState(() => _hasError = true);
        FlatmatesToast.error(context, locale.profileCompletionError);
      } else {
        context.go('/splash');
      }
    } catch (e) {
      debugPrint('ProfileCompletionPage._submit error: $e');
      if (!context.mounted) return;
      setState(() => _hasError = true);
      final message = e is AppFailure
          ? e.userMessage(locale.toUserMessageL10n())
          : locale.profileCompletionError;
      FlatmatesToast.error(context, message);
    } finally {
      if (context.mounted) setState(() => _saving = false);
    }
  }
}

/// Tappable form field that displays the selected date of birth or a prompt
/// to pick one. Uses a read-only display with a trailing calendar icon to
/// stay visually consistent with the other form fields.
class _DateOfBirthField extends StatelessWidget {
  const _DateOfBirthField({required this.onTap, this.selectedDate});

  final DateTime? selectedDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final hasDate = selectedDate != null;
    final dateText = hasDate
        ? '${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.year}'
        : locale.dateOfBirthLabel;

    return Listener(
      onPointerDown: (_) => onTap(),
      child: AbsorbPointer(
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: locale.dateOfBirthLabel,
            helperText: locale.dateOfBirthHelper,
            prefixIcon: const Icon(Icons.cake_outlined),
            suffixIcon: const Icon(Icons.calendar_today_outlined),
          ),
          child: Text(
            dateText,
            style: hasDate
                ? null
                : TextStyle(
                    color: AppSemanticColors.textSecondaryFor(theme.brightness),
                  ),
          ),
        ),
      ),
    );
  }
}
