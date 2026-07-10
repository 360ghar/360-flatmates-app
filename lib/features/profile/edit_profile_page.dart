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
// Null until seeded from profile / user picks a catalog id — avoids overwriting
// an unmapped server value with a silent default on save.
final _moveInTimelineProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
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

  /// Suppresses dirty writes while seeding controllers (listener fires on .text=).
  bool _seeding = false;

  void _markDirty() {
    if (_seeding) return;
    if (!ref.read(_dirtyProvider)) {
      ref.read(_dirtyProvider.notifier).state = true;
    }
  }

  List<TextEditingController> get _textControllers => [
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
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(_savingProvider.notifier).state = false;
      ref.read(_photoUploadingProvider.notifier).state = false;
      ref.read(_dirtyProvider.notifier).state = false;
    });
    for (final controller in _textControllers) {
      controller.addListener(_markDirty);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final profile = ref.read(bootstrapControllerProvider).valueOrNull?.profile;
    if (profile == null) return;
    _seedControllers(profile);
    _hasEmail = profile.email?.isNotEmpty == true;
    _hasPhone = profile.phone?.isNotEmpty == true;
    final snapshot = profile;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _seedProviders(snapshot);
    });
    _initialized = true;
  }

  void _seedControllers(FlatmatesProfileModel profile) {
    _seeding = true;
    try {
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
    } finally {
      _seeding = false;
    }
  }

  void _seedProviders(FlatmatesProfileModel profile) {
    final seed = EditProfileOptions(
      locale: AppLocalizations.of(context),
      bootstrap: ref.read(bootstrapControllerProvider).valueOrNull,
    ).seedFromProfile(profile);
    if (seed.mode != null) ref.read(_modeProvider.notifier).state = seed.mode!;
    if (seed.workStyle != null) {
      ref.read(_workStyleProvider.notifier).state = seed.workStyle!;
    }
    if (seed.moveInTimeline != null) {
      ref.read(_moveInTimelineProvider.notifier).state = seed.moveInTimeline!;
    }
    ref.read(_sleepScheduleProvider.notifier).state = seed.sleepSchedule;
    ref.read(_cleanlinessProvider.notifier).state = seed.cleanliness;
    ref.read(_foodHabitsProvider.notifier).state = seed.foodHabits;
    ref.read(_smokingDrinkingProvider.notifier).state = seed.smokingDrinking;
    ref.read(_guestsPolicyProvider.notifier).state = seed.guestsPolicy;
    ref.read(_nonNegotiablesProvider.notifier).state = seed.nonNegotiables;
    ref.read(_photoUrlsProvider.notifier).state = seed.photoUrls;
    ref.read(_dirtyProvider.notifier).state = false;
  }

  @override
  void dispose() {
    for (final controller in _textControllers) {
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

  void _leaveEditPage() {
    if (!mounted) return;
    // profileCompletion redirect may leave no stack entry to pop.
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
        // Header back bypasses PopScope; route through the unsaved-changes guard.
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
              const SizedBox(height: AppSpacing.xl),
              EditProfileBasicInfoSection(
                locale: locale,
                nameController: _nameController,
                ageController: _ageController,
                professionController: _professionController,
                cityController: _cityController,
                localityController: _localityController,
              ),
              const SizedBox(height: AppSpacing.xl),
              EditProfileModeSection(
                locale: locale,
                mode: ref.watch(_modeProvider),
                items: options.modeItems(),
                onChanged: (value) {
                  ref.read(_modeProvider.notifier).state = value;
                  _markDirty();
                },
              ),
              const SizedBox(height: AppSpacing.xl),
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
              const SizedBox(height: AppSpacing.xl),
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
              const SizedBox(height: AppSpacing.xl),
              EditProfileNonNegotiablesSection(
                locale: locale,
                options: options.nonNegotiableOptions(),
                selectedIds: ref.watch(_nonNegotiablesProvider),
                onSelectionChanged: (value) {
                  ref.read(_nonNegotiablesProvider.notifier).state = value;
                  _markDirty();
                },
              ),
              const SizedBox(height: AppSpacing.xl),
              EditProfileBioSection(
                locale: locale,
                bioController: _bioController,
              ),
              const SizedBox(height: AppSpacing.xl),
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

  Map<String, dynamic> _buildSavePayload(
    String? Function(TextEditingController) nullableText,
    double? budgetMin,
    double? budgetMax,
  ) {
    final payload = <String, dynamic>{
      'full_name': nullableText(_nameController),
      'age': int.tryParse(_ageController.text.trim()),
      'profession': nullableText(_professionController),
      'mode': ref.read(_modeProvider),
      'city': nullableText(_cityController),
      'locality': nullableText(_localityController),
      'budget_min': budgetMin,
      'budget_max': budgetMax,
      if (ref.read(_moveInTimelineProvider) != null)
        'move_in_timeline': ref.read(_moveInTimelineProvider),
      'work_style': ref.read(_workStyleProvider),
      'bio': nullableText(_bioController),
      'sleep_schedule': ref.read(_sleepScheduleProvider),
      'cleanliness': ref.read(_cleanlinessProvider),
      'food_habits': ref.read(_foodHabitsProvider),
      'smoking_drinking': ref.read(_smokingDrinkingProvider),
      'guests_policy': ref.read(_guestsPolicyProvider),
      'preferences': {
        ...?ref
            .read(bootstrapControllerProvider)
            .valueOrNull
            ?.profile
            .preferences,
        'non_negotiables': ref.read(_nonNegotiablesProvider),
      },
    };
    final photoUrls = ref.read(_photoUrlsProvider);
    if (photoUrls.isNotEmpty) {
      payload['profile_image_url'] = photoUrls.first;
    }
    final newEmail = _emailController.text.trim();
    final newPhone = _phoneController.text.trim();
    if (!_hasEmail && newEmail.isNotEmpty) payload['email'] = newEmail;
    if (!_hasPhone && newPhone.isNotEmpty) payload['phone'] = newPhone;
    return payload;
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
      final payload = _buildSavePayload(nullableText, budgetMin, budgetMax);
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
