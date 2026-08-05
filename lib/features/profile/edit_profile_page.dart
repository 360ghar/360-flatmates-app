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
import '../discover/application/discover_feed_controller.dart';
import '../shared/presentation/components.dart';
import '../swipe/application/swipe_deck_controller.dart';
import 'presentation/widgets/edit_profile_form_state.dart';
import 'presentation/widgets/edit_profile_options.dart';
import 'presentation/widgets/edit_profile_tabs.dart';
import 'profile_repository.dart';

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
  final _nativePlaceController = TextEditingController();
  final _linkedInController = TextEditingController();

  bool _initialized = false;
  bool _hasEmail = false;
  bool _hasPhone = false;

  /// Suppresses dirty writes while seeding controllers (listener fires on .text=).
  bool _seeding = false;

  void _markDirty() {
    if (_seeding) return;
    if (!ref.read(editProfileDirtyProvider)) {
      ref.read(editProfileDirtyProvider.notifier).state = true;
    }
  }

  void _handleTextChanged(TextEditingController controller) {
    if (_seeding) return;
    if (controller == _linkedInController) {
      ref.read(editProfileLinkedInErrorProvider.notifier).state = null;
    }
    if (controller == _nativePlaceController) {
      ref.read(editProfileNativePlaceErrorProvider.notifier).state = null;
    }
    _markDirty();
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
    _nativePlaceController,
    _linkedInController,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(editProfileSavingProvider.notifier).state = false;
      ref.read(editProfilePhotoUploadingProvider.notifier).state = false;
      ref.read(editProfileDirtyProvider.notifier).state = false;
    });
    for (final controller in _textControllers) {
      controller.addListener(() => _handleTextChanged(controller));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final profile = ref.read(bootstrapControllerProvider).valueOrNull?.profile;
    if (profile == null) return;
    _initializeFromProfile(profile);
  }

  /// Seeds controllers + option providers once: from [didChangeDependencies]
  /// normally, and post-frame from [build] after an error-state retry.
  void _initializeFromProfile(FlatmatesProfileModel profile) {
    if (_initialized) return;
    _initialized = true;
    _seedControllers(profile);
    _hasEmail = profile.email?.isNotEmpty == true;
    _hasPhone = profile.phone?.isNotEmpty == true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      editProfileSeedProviders(profile);
    });
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
      _nativePlaceController.text = profile.nativePlace ?? '';
      _linkedInController.text = profile.linkedInUrl ?? '';
    } finally {
      _seeding = false;
    }
  }

  void editProfileSeedProviders(FlatmatesProfileModel profile) {
    final seed = EditProfileOptions(
      locale: AppLocalizations.of(context),
      bootstrap: ref.read(bootstrapControllerProvider).valueOrNull,
    ).seedFromProfile(profile);
    // Always seed nullable providers from catalog match (null = unmapped / unset).
    ref.read(editProfileModeProvider.notifier).state = seed.mode;
    ref.read(editProfileWorkStyleProvider.notifier).state = seed.workStyle;
    ref.read(editProfileMoveInTimelineProvider.notifier).state =
        seed.moveInTimeline;
    ref.read(editProfileSleepScheduleProvider.notifier).state =
        seed.sleepSchedule;
    ref.read(editProfileCleanlinessProvider.notifier).state = seed.cleanliness;
    ref.read(editProfileFoodHabitsProvider.notifier).state = seed.foodHabits;
    ref.read(editProfileSmokingProvider.notifier).state = seed.smoking;
    ref.read(editProfileDrinkingProvider.notifier).state = seed.drinking;
    ref.read(editProfileGuestsPolicyProvider.notifier).state =
        seed.guestsPolicy;
    ref.read(editProfileNonNegotiablesProvider.notifier).state =
        seed.nonNegotiables;
    ref.read(editProfilePhotoUrlsProvider.notifier).state = seed.photoUrls;
    ref.read(editProfileDirtyProvider.notifier).state = false;
  }

  /// Validates a LinkedIn URL: empty/whitespace is allowed (field optional);
  /// otherwise must parse as an http(s) URL with a host.
  static bool isValidLinkedInUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return true;
    final uri = Uri.tryParse(trimmed);
    if (uri == null) return false;
    return (uri.isScheme('http') || uri.isScheme('https')) &&
        uri.host.isNotEmpty;
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
    if (ref.read(editProfilePhotoUploadingProvider)) return;
    final locale = AppLocalizations.of(context);
    ref.read(editProfilePhotoUploadingProvider.notifier).state = true;
    try {
      final uploadService = ref.read(imageUploadServiceProvider);
      final files = await uploadService.pickImages(limit: 1);
      if (files.isEmpty) return;
      final result = await uploadService.uploadProfilePhoto(files.first);
      if (!mounted) return;
      switch (result) {
        case UploadSuccess(:final url):
          final current = List<String>.of(
            ref.read(editProfilePhotoUrlsProvider),
          );
          if (current.isEmpty) {
            ref.read(editProfilePhotoUrlsProvider.notifier).state = [url];
          } else {
            current[0] = url;
            ref.read(editProfilePhotoUrlsProvider.notifier).state = current;
          }
          ref.read(editProfileDirtyProvider.notifier).state = true;
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
      if (mounted) {
        ref.read(editProfilePhotoUploadingProvider.notifier).state = false;
      }
    }
  }

  Future<bool> _confirmDiscard() async {
    if (!ref.read(editProfileDirtyProvider)) return true;
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
    ref.read(editProfileDirtyProvider.notifier).state = false;
    _leaveEditPage();
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final bootstrap = ref.watch(bootstrapControllerProvider);
    final profile = bootstrap.valueOrNull?.profile;

    // Never render the form without real prefills: a bootstrap failure would
    // leave Save armed to overwrite name/bio/preferences with blanks.
    if (profile == null) {
      return Scaffold(
        appBar: FlatmatesHeader.backTitle(title: locale.editProfileCta),
        body: bootstrap.hasError
            ? FlatmatesErrorState(
                message: locale.couldNotLoadProfile,
                onRetry: () =>
                    ref.read(bootstrapControllerProvider.notifier).refresh(),
              )
            : const Center(child: FlatmatesSkeleton.profile()),
      );
    }

    if (!_initialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _initializeFromProfile(profile);
      });
    }

    final saving = ref.watch(editProfileSavingProvider);
    final photoUploading = ref.watch(editProfilePhotoUploadingProvider);
    final dirty = ref.watch(editProfileDirtyProvider);
    final tab = ref.watch(editProfileTabProvider);
    final options = EditProfileOptions(
      locale: locale,
      bootstrap: bootstrap.valueOrNull,
    );
    String? nullableText(TextEditingController controller) {
      final value = controller.text.trim();
      return value.isEmpty ? null : value;
    }

    final values = EditProfileTabValues(
      photoUrls: ref.watch(editProfilePhotoUrlsProvider),
      photoUploading: photoUploading,
      mode: ref.watch(editProfileModeProvider),
      moveInTimeline: ref.watch(editProfileMoveInTimelineProvider),
      workStyle: ref.watch(editProfileWorkStyleProvider),
      sleepSchedule: ref.watch(editProfileSleepScheduleProvider),
      cleanliness: ref.watch(editProfileCleanlinessProvider),
      foodHabits: ref.watch(editProfileFoodHabitsProvider),
      smoking: ref.watch(editProfileSmokingProvider),
      drinking: ref.watch(editProfileDrinkingProvider),
      guestsPolicy: ref.watch(editProfileGuestsPolicyProvider),
      nonNegotiables: ref.watch(editProfileNonNegotiablesProvider),
    );

    final handlers = buildEditProfileTabHandlers(ref, _markDirty);

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
          minimum: const EdgeInsets.only(
            top: AppSpacing.lg,
            left: AppSpacing.screen,
            right: AppSpacing.screen,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: FlatmatesSegmentedControl<EditProfileTab>(
                  segments: editProfileTabSegments(locale),
                  selected: tab,
                  onChanged: (value) =>
                      ref.read(editProfileTabProvider.notifier).state = value,
                  segmentKeys: const [
                    Key('profile_tab_identity'),
                    Key('profile_tab_preferences'),
                    Key('profile_tab_lifestyle'),
                    Key('profile_tab_about'),
                  ],
                ),
              ),
              Expanded(
                child: buildEditProfileTabBody(
                  tab: tab,
                  locale: locale,
                  options: options,
                  values: values,
                  handlers: handlers,
                  emailController: _emailController,
                  phoneController: _phoneController,
                  nameController: _nameController,
                  ageController: _ageController,
                  professionController: _professionController,
                  cityController: _cityController,
                  localityController: _localityController,
                  budgetMinController: _budgetMinController,
                  budgetMaxController: _budgetMaxController,
                  bioController: _bioController,
                  nativePlaceController: _nativePlaceController,
                  linkedInController: _linkedInController,
                  nativePlaceError: ref.watch(
                    editProfileNativePlaceErrorProvider,
                  ),
                  linkedInError: ref.watch(editProfileLinkedInErrorProvider),
                  hasEmail: _hasEmail,
                  hasPhone: _hasPhone,
                  onPickAndUploadPhoto: _pickAndUploadPhoto,
                ),
              ),
              FlatmatesBottomActionBar(
                label: saving ? locale.profileSaving : locale.commonSave,
                icon: saving ? null : Icons.check,
                primaryButtonKey: const Key('profile_save_button'),
                onPressed: (saving || photoUploading || !dirty)
                    ? null
                    : () => _save(nullableText),
              ),
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

    final nativePlace = nullableText(_nativePlaceController);
    if (nativePlace != null && nativePlace.length > 120) {
      ref.read(editProfileNativePlaceErrorProvider.notifier).state =
          locale.nativePlaceTooLongError;
      return;
    }
    final linkedIn = nullableText(_linkedInController);
    if (linkedIn != null && !isValidLinkedInUrl(linkedIn)) {
      ref.read(editProfileLinkedInErrorProvider.notifier).state =
          locale.linkedinInvalidError;
      return;
    }

    ref.read(editProfileSavingProvider.notifier).state = true;
    try {
      final payload = buildEditProfileSavePayload(
        ref: ref,
        nullableText: nullableText,
        budgetMin: budgetMin,
        budgetMax: budgetMax,
        nameController: _nameController,
        ageController: _ageController,
        professionController: _professionController,
        cityController: _cityController,
        localityController: _localityController,
        bioController: _bioController,
        emailController: _emailController,
        phoneController: _phoneController,
        nativePlaceController: _nativePlaceController,
        linkedInController: _linkedInController,
        existingPreferences:
            ref
                .read(bootstrapControllerProvider)
                .valueOrNull
                ?.profile
                .preferences ??
            const {},
        hasEmail: _hasEmail,
        hasPhone: _hasPhone,
      );
      await ref.read(profileRepositoryProvider).updateProfile(payload: payload);
      await ref.read(bootstrapControllerProvider.notifier).refresh();
      // Feed/deck read the profile via ref.read — invalidate to drop stale results.
      ref.invalidate(discoverFeedControllerProvider);
      ref.invalidate(swipeDeckControllerProvider);
      if (!mounted) return;
      ref.read(editProfileDirtyProvider.notifier).state = false;
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
      if (mounted) ref.read(editProfileSavingProvider.notifier).state = false;
    }
  }
}
