import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/errors/app_failure.dart';
import '../../core/errors/l10n_bridge.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_semantic_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../auth/auth_controller.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../shared/presentation/components.dart';
import 'application/profile_completion_controller.dart';
import 'domain/onboarding_state.dart';

/// A focused, onboarding-style page that collects only the mandatory profile
/// fields reported missing by the backend `profile_completion` auth gate
/// (typically `full_name` and `date_of_birth`).
///
/// Unlike the full [EditProfilePage], this page shows a minimal form with
/// clear context about why the user is here and what happens next.
///
/// Saving runs in [ProfileCompletionController].
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
  bool _handedOffToEditor = false;
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

    // The backend reported mandatory fields this form cannot collect (it only
    // knows full_name / date_of_birth). Rendering anyway showed an empty form
    // with an enabled Continue that silently no-oped, and PopScope + the
    // router gate left no way out. Hand off to the full editor instead, which
    // the profile-completion gate explicitly allows.
    if (!needsName && !needsDob) {
      _handOffToProfileEditor();
      return const FlatmatesScreen(body: FlatmatesSkeleton.form());
    }

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
      child: FlatmatesScreen(
        appBar: FlatmatesHeader.titleOnly(title: locale.profileCompletionTitle),
        padding: AppSpacing.horizontalScreen,
        body: ListView(
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
              FlatmatesInlineError(locale.profileCompletionError),
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
    );
  }

  /// Leaves this page for the full profile editor after the current frame —
  /// navigating during `build` is not allowed.
  void _handOffToProfileEditor() {
    if (_handedOffToEditor) return;
    _handedOffToEditor = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go('/profile/edit');
    });
  }

  bool _isAtLeast18(DateTime dob) =>
      ProfileCompletionController.ageFromDob(dob) >= 18;

  Future<void> _pickDateOfBirth(
    BuildContext context,
    AppLocalizations locale,
  ) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25),
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - kMinimumAge, now.month, now.day),
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
      final advanced = await ref
          .read(profileCompletionControllerProvider)
          .submit(
            trimmedName: _name.trim(),
            dob: _dob,
            needsName: needsName,
            needsDob: needsDob,
          );
      if (!context.mounted) return;
      if (advanced) {
        context.go('/splash');
      } else {
        setState(() => _hasError = true);
        FlatmatesToast.error(context, locale.profileCompletionError);
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
    final date = selectedDate;
    final hasDate = date != null;
    final dateText = hasDate
        ? DateFormat.yMd(locale.localeName).format(date)
        : '';

    // InkWell (not a pointer-down Listener) so starting a scroll over the
    // field does not open the picker.
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdBorder,
        // isEmpty keeps the label in place as the placeholder until a date
        // is picked.
        child: InputDecorator(
          isEmpty: !hasDate,
          decoration: InputDecoration(
            labelText: locale.dateOfBirthLabel,
            helperText: locale.dateOfBirthHelper,
            helperMaxLines: 2,
            prefixIcon: const Icon(Icons.cake_outlined),
            suffixIcon: const Icon(Icons.calendar_today_outlined),
          ),
          child: Text(hasDate ? dateText : ''),
        ),
      ),
    );
  }
}
