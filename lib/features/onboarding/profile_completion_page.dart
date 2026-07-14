import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
/// clear context about why the user is here and what happens next. On submit
/// it calls `PUT /users/me` (the general user update endpoint) which properly
/// sets `date_of_birth` on the User model — the flatmates profile endpoint
/// does not support this field.
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

  bool _isAtLeast18(DateTime dob) {
    final today = DateTime.now();
    final age =
        today.year -
        dob.year -
        ((today.month < dob.month ||
                (today.month == dob.month && today.day < dob.day))
            ? 1
            : 0);
    return age >= 18;
  }

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
    if (needsDob && _dob == null) return;

    setState(() {
      _saving = true;
      _hasError = false;
    });

    try {
      final payload = <String, dynamic>{};
      if (needsName) {
        payload['full_name'] = _name.trim();
      }
      if (needsDob && _dob != null) {
        final dob = _dob!;
        payload['date_of_birth'] =
            '${dob.year}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}';
      }
      if (payload.isEmpty) return;

      await ref.read(profileRepositoryProvider).updateUser(payload: payload);
      // Refresh bootstrap so auth-state re-evaluates and the router advances
      // past the profile_completion gate.
      await ref.read(bootstrapControllerProvider.notifier).refresh();
      // refresh() uses AsyncValue.guard and does not throw on failure.
      // Only leave when we are no longer hard-gated on profile_completion.
      // For app_onboarding/active the router also exits; for
      // identifier_verification (name just saved) we must navigate so the
      // fallback redirect chain can place the user (router exit intentionally
      // does not kick identifier_verification off this route).
      if (!context.mounted) return;
      final stage = ref.read(authControllerProvider).authStage;
      if (stage == AuthStage.profileCompletion) {
        // PUT returned OK but gate still incomplete — show error instead of
        // a silent no-op.
        setState(() => _hasError = true);
        FlatmatesToast.error(context, locale.profileCompletionError);
      } else {
        context.go('/splash');
      }
    } catch (e) {
      debugPrint('ProfileCompletionPage._submit error: $e');
      if (context.mounted) {
        setState(() => _hasError = true);
        FlatmatesToast.error(context, locale.profileCompletionError);
      }
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
