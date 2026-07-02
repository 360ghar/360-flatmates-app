import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_failure.dart' hide UploadFailure;
import '../../core/errors/l10n_bridge.dart';
import '../../core/storage/image_upload_service.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../shared/presentation/components.dart';
import 'presentation/widgets/edit_profile_options.dart';
import 'presentation/widgets/edit_profile_sections.dart';
import 'profile_repository.dart';

// Local UI state via StateProviders (convention: no setState in ConsumerState).
// These are .autoDispose so each edit session starts with fresh defaults and
// seeded backend values never leak across visits.
final _modeProvider = StateProvider.autoDispose<String>(
  (ref) => 'open_to_both',
);
final _workStyleProvider = StateProvider.autoDispose<String>((ref) => 'hybrid');
final _moveInTimelineProvider = StateProvider.autoDispose<String>(
  (ref) => 'flexible',
);
final _sleepScheduleProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);
final _cleanlinessProvider = StateProvider.autoDispose<String?>((ref) => null);
final _foodHabitsProvider = StateProvider.autoDispose<String?>((ref) => null);
final _smokingDrinkingProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);
final _guestsPolicyProvider = StateProvider.autoDispose<String?>((ref) => null);
final _nonNegotiablesProvider = StateProvider.autoDispose<List<String>>(
  (ref) => const [],
);
final _photoUrlsProvider = StateProvider.autoDispose<List<String>>(
  (ref) => const [],
);
final _savingProvider = StateProvider.autoDispose<bool>((ref) => false);
final _photoUploadingProvider = StateProvider.autoDispose<bool>((ref) => false);
final _dirtyProvider = StateProvider.autoDispose<bool>((ref) => false);

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _professionController = TextEditingController();
  final _cityController = TextEditingController();
  final _localityController = TextEditingController();
  final _budgetMinController = TextEditingController();
  final _budgetMaxController = TextEditingController();
  final _bioController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _initialized = false;
  bool _hasEmail = false;
  bool _hasPhone = false;

  void _markDirty() {
    if (!ref.read(_dirtyProvider)) {
      ref.read(_dirtyProvider.notifier).state = true;
    }
  }

  @override
  void initState() {
    super.initState();
    // Reset transient local state for a fresh edit session. Done post-frame so
    // we never mutate providers during the initial build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(_savingProvider.notifier).state = false;
      ref.read(_photoUploadingProvider.notifier).state = false;
      ref.read(_dirtyProvider.notifier).state = false;
    });
    for (final controller in [
      _nameController,
      _ageController,
      _professionController,
      _cityController,
      _localityController,
      _budgetMinController,
      _budgetMaxController,
      _bioController,
      _emailController,
      _phoneController,
    ]) {
      controller.addListener(_markDirty);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final profile = ref.read(bootstrapControllerProvider).valueOrNull?.profile;
    if (profile != null) {
      _nameController.text = profile.fullName ?? '';
      _ageController.text = profile.age?.toString() ?? '';
      _professionController.text = profile.profession ?? '';
      _cityController.text = profile.city ?? '';
      _localityController.text = profile.locality ?? '';
      _budgetMinController.text = profile.budgetMin?.toStringAsFixed(0) ?? '';
      _budgetMaxController.text = profile.budgetMax?.toStringAsFixed(0) ?? '';
      _bioController.text = profile.bio ?? '';
      _emailController.text = profile.email ?? '';
      _phoneController.text = profile.phone ?? '';
      _hasEmail = profile.email?.isNotEmpty == true;
      _hasPhone = profile.phone?.isNotEmpty == true;
      // Seed providers post-frame to avoid mutating during build.
      final mode = profile.mode;
      final workStyle = profile.workStyle;
      final timeline = profile.moveInTimeline;
      final prefs = profile.preferences;
      final nonNeg = prefs['non_negotiables'] is List
          ? List<String>.from(prefs['non_negotiables'] as List)
          : const <String>[];
      final photos = profile.profileImageUrl != null
          ? [profile.profileImageUrl!]
          : const <String>[];
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (mode != null) ref.read(_modeProvider.notifier).state = mode;
        if (workStyle != null) {
          ref.read(_workStyleProvider.notifier).state = workStyle;
        }
        if (timeline != null) {
          ref.read(_moveInTimelineProvider.notifier).state = timeline;
        }
        ref.read(_sleepScheduleProvider.notifier).state = profile.sleepSchedule;
        ref.read(_cleanlinessProvider.notifier).state = profile.cleanliness;
        ref.read(_foodHabitsProvider.notifier).state = profile.foodHabits;
        ref.read(_smokingDrinkingProvider.notifier).state =
            profile.smokingDrinking;
        ref.read(_guestsPolicyProvider.notifier).state = profile.guestsPolicy;
        ref.read(_nonNegotiablesProvider.notifier).state = nonNeg;
        ref.read(_photoUrlsProvider.notifier).state = photos;
        // Seeding initial values should not mark the form dirty.
        ref.read(_dirtyProvider.notifier).state = false;
      });
      _initialized = true;
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _nameController,
      _ageController,
      _professionController,
      _cityController,
      _localityController,
      _budgetMinController,
      _budgetMaxController,
      _bioController,
      _emailController,
      _phoneController,
    ]) {
      controller.removeListener(_markDirty);
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto() async {
    if (ref.read(_photoUploadingProvider)) return;
    final locale = AppLocalizations.of(context);
    ref.read(_photoUploadingProvider.notifier).state = true;
    try {
      final uploadService = ref.read(imageUploadServiceProvider);
      final files = await uploadService.pickImages(limit: 1);
      if (files.isEmpty) return;
      final result = await uploadService.uploadProfilePhoto(files.first);
      if (!mounted) return;
      switch (result) {
        case UploadSuccess(:final url):
          final current = List<String>.of(ref.read(_photoUrlsProvider));
          if (current.isEmpty) {
            ref.read(_photoUrlsProvider.notifier).state = [url];
          } else {
            current[0] = url;
            ref.read(_photoUrlsProvider.notifier).state = current;
          }
          ref.read(_dirtyProvider.notifier).state = true;
        case UploadFailure(:final reason, :final underlyingError):
          debugPrint(
            'EditProfilePage._pickAndUploadPhoto failed: $reason '
            '($underlyingError)',
          );
          FlatmatesToast.error(context, locale.profilePhotoUploadFailed);
      }
    } catch (e) {
      debugPrint('EditProfilePage._pickAndUploadPhoto error: $e');
      if (!mounted) return;
      FlatmatesToast.error(context, locale.profilePhotoUploadFailed);
    } finally {
      if (mounted) ref.read(_photoUploadingProvider.notifier).state = false;
    }
  }

  Future<bool> _confirmDiscard() async {
    if (!ref.read(_dirtyProvider)) return true;
    final locale = AppLocalizations.of(context);
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(locale.unsavedChangesTitle),
        content: Text(locale.unsavedChangesMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(locale.keepEditing),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(locale.discardChanges),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  /// Navigate away from the edit page. The route may have been reached via the
  /// profileCompletion redirect (no page to pop), so fall back to /profile.
  void _leaveEditPage() {
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/profile');
    }
  }

  Future<void> _handlePop() async {
    final shouldPop = await _confirmDiscard();
    if (!mounted || !shouldPop) return;
    ref.read(_dirtyProvider.notifier).state = false;
    _leaveEditPage();
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final saving = ref.watch(_savingProvider);
    final photoUploading = ref.watch(_photoUploadingProvider);
    final dirty = ref.watch(_dirtyProvider);
    final options = EditProfileOptions(
      locale: locale,
      bootstrap: ref.watch(bootstrapControllerProvider).valueOrNull,
    );
    String? nullableText(TextEditingController controller) {
      final value = controller.text.trim();
      return value.isEmpty ? null : value;
    }

    return PopScope(
      canPop: !dirty,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        unawaited(_handlePop());
      },
      child: Scaffold(
        // Route the in-app back button through the unsaved-changes guard. The
        // shared header uses Navigator.pop(), which bypasses PopScope, so we
        // handle the confirmation explicitly here.
        appBar: FlatmatesHeader.backTitle(
          title: locale.editProfileCta,
          onBack: _handlePop,
        ),
        body: SafeArea(
          minimum: const EdgeInsets.all(AppSpacing.lg),
          child: ListView(
            children: [
              EditProfilePhotoSection(
                locale: locale,
                photoUrls: ref.watch(_photoUrlsProvider),
                photoUploading: photoUploading,
                onPickAndUploadPhoto: _pickAndUploadPhoto,
              ),
              const SizedBox(height: AppSpacing.lg),
              EditProfileContactInfoSection(
                locale: locale,
                emailController: _emailController,
                phoneController: _phoneController,
                hasEmail: _hasEmail,
                hasPhone: _hasPhone,
              ),
              const SizedBox(height: AppSpacing.section),
              EditProfileBasicInfoSection(
                locale: locale,
                nameController: _nameController,
                ageController: _ageController,
                professionController: _professionController,
                cityController: _cityController,
                localityController: _localityController,
              ),
              const SizedBox(height: AppSpacing.section),
              EditProfileModeSection(
                locale: locale,
                mode: ref.watch(_modeProvider),
                items: options.modeItems(),
                onChanged: (value) {
                  ref.read(_modeProvider.notifier).state = value;
                  _markDirty();
                },
              ),
              const SizedBox(height: AppSpacing.section),
              EditProfileBudgetTimelineSection(
                locale: locale,
                budgetMinController: _budgetMinController,
                budgetMaxController: _budgetMaxController,
                moveInTimeline: ref.watch(_moveInTimelineProvider),
                workStyle: ref.watch(_workStyleProvider),
                timelineItems: options.timelineItems(),
                workStyleItems: options.workStyleItems(),
                onMoveInTimelineChanged: (value) {
                  ref.read(_moveInTimelineProvider.notifier).state = value;
                  _markDirty();
                },
                onWorkStyleChanged: (value) {
                  ref.read(_workStyleProvider.notifier).state = value;
                  _markDirty();
                },
              ),
              const SizedBox(height: AppSpacing.section),
              EditProfileLifestyleSection(
                locale: locale,
                sleepSchedule: ref.watch(_sleepScheduleProvider),
                cleanliness: ref.watch(_cleanlinessProvider),
                foodHabits: ref.watch(_foodHabitsProvider),
                smokingDrinking: ref.watch(_smokingDrinkingProvider),
                guestsPolicy: ref.watch(_guestsPolicyProvider),
                sleepItems: options.sleepItems(),
                cleanlinessItems: options.cleanlinessItems(),
                foodItems: options.foodItems(),
                smokingItems: options.smokingItems(),
                guestsItems: options.guestsItems(),
                onSleepScheduleChanged: (value) {
                  ref.read(_sleepScheduleProvider.notifier).state = value;
                  _markDirty();
                },
                onCleanlinessChanged: (value) {
                  ref.read(_cleanlinessProvider.notifier).state = value;
                  _markDirty();
                },
                onFoodHabitsChanged: (value) {
                  ref.read(_foodHabitsProvider.notifier).state = value;
                  _markDirty();
                },
                onSmokingDrinkingChanged: (value) {
                  ref.read(_smokingDrinkingProvider.notifier).state = value;
                  _markDirty();
                },
                onGuestsPolicyChanged: (value) {
                  ref.read(_guestsPolicyProvider.notifier).state = value;
                  _markDirty();
                },
              ),
              const SizedBox(height: AppSpacing.section),
              EditProfileNonNegotiablesSection(
                locale: locale,
                options: options.nonNegotiableOptions(),
                selectedIds: ref.watch(_nonNegotiablesProvider),
                onSelectionChanged: (value) {
                  ref.read(_nonNegotiablesProvider.notifier).state = value;
                  _markDirty();
                },
              ),
              const SizedBox(height: AppSpacing.section),
              EditProfileBioSection(
                locale: locale,
                bioController: _bioController,
              ),
              const SizedBox(height: AppSpacing.section),
              FlatmatesButton(
                key: const Key('profile_save_button'),
                label: saving ? locale.profileSaving : locale.commonSave,
                icon: saving ? null : Icons.check,
                fullWidth: true,
                onPressed: (saving || photoUploading || !dirty)
                    ? null
                    : () => _save(nullableText),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save(
    String? Function(TextEditingController) nullableText,
  ) async {
    final locale = AppLocalizations.of(context);
    final budgetMin = double.tryParse(_budgetMinController.text.trim());
    final budgetMax = double.tryParse(_budgetMaxController.text.trim());
    if (budgetMin != null && budgetMax != null && budgetMin > budgetMax) {
      FlatmatesToast.error(context, locale.budgetMinMaxError);
      return;
    }

    ref.read(_savingProvider.notifier).state = true;
    try {
      final payload = <String, dynamic>{
        'full_name': nullableText(_nameController),
        'age': int.tryParse(_ageController.text.trim()),
        'profession': nullableText(_professionController),
        'mode': ref.read(_modeProvider),
        'city': nullableText(_cityController),
        'locality': nullableText(_localityController),
        'budget_min': budgetMin,
        'budget_max': budgetMax,
        'move_in_timeline': ref.read(_moveInTimelineProvider),
        'work_style': ref.read(_workStyleProvider),
        'bio': nullableText(_bioController),
        'sleep_schedule': ref.read(_sleepScheduleProvider),
        'cleanliness': ref.read(_cleanlinessProvider),
        'food_habits': ref.read(_foodHabitsProvider),
        'smoking_drinking': ref.read(_smokingDrinkingProvider),
        'guests_policy': ref.read(_guestsPolicyProvider),
      };
      final photoUrls = ref.read(_photoUrlsProvider);
      if (photoUrls.isNotEmpty) {
        payload['profile_image_url'] = photoUrls.first;
      }
      final nonNegotiables = ref.read(_nonNegotiablesProvider);
      final existingPreferences = ref
          .read(bootstrapControllerProvider)
          .valueOrNull
          ?.profile
          .preferences;
      payload['preferences'] = {
        ...?existingPreferences,
        'non_negotiables': nonNegotiables,
      };

      // Include email/phone if newly added.
      final newEmail = _emailController.text.trim();
      final newPhone = _phoneController.text.trim();
      if (!_hasEmail && newEmail.isNotEmpty) {
        payload['email'] = newEmail;
      }
      if (!_hasPhone && newPhone.isNotEmpty) {
        payload['phone'] = newPhone;
      }

      await ref.read(profileRepositoryProvider).updateProfile(payload: payload);
      await ref.read(bootstrapControllerProvider.notifier).refresh();
      if (!mounted) return;
      ref.read(_dirtyProvider.notifier).state = false;
      FlatmatesToast.success(context, locale.profileUpdated);
      _leaveEditPage();
    } catch (e) {
      debugPrint('EditProfilePage._save error: $e');
      if (!mounted) return;
      final message = e is AppFailure
          ? e.userMessage(locale.toUserMessageL10n())
          : locale.errorUnknown;
      FlatmatesToast.error(context, message);
    } finally {
      if (mounted) ref.read(_savingProvider.notifier).state = false;
    }
  }
}
