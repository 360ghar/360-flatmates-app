import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_failure.dart' hide UploadFailure;
import '../../core/errors/l10n_bridge.dart';
import '../../core/storage/image_upload_service.dart'
    show UploadFailure, UploadSuccess;
import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bootstrap/bootstrap_controller.dart';
import 'application/edit_profile_actions_controller.dart';
import '../shared/presentation/components.dart';
import 'presentation/widgets/edit_profile_form_state.dart';
import 'presentation/widgets/edit_profile_options.dart';
import 'presentation/widgets/edit_profile_tabs.dart';

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

  // Ephemeral page state (setState; never read outside this page).
  bool _saving = false;
  bool _photoUploading = false;
  bool _dirty = false;
  EditProfileTab _tab = EditProfileTab.identity;
  String? _nativePlaceError;
  String? _linkedInError;

  /// Suppresses dirty writes while seeding controllers (listener fires on .text=).
  bool _seeding = false;

  void _markDirty() {
    if (_seeding || _dirty || !mounted) return;
    setState(() => _dirty = true);
  }

  void _handleTextChanged(TextEditingController controller) {
    if (_seeding) return;
    if (controller == _linkedInController && _linkedInError != null) {
      setState(() => _linkedInError = null);
    }
    if (controller == _nativePlaceController && _nativePlaceError != null) {
      setState(() => _nativePlaceError = null);
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
    setState(() => _dirty = false);
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
    if (_photoUploading) return;
    final locale = AppLocalizations.of(context);
    setState(() => _photoUploading = true);
    try {
      final result = await ref
          .read(editProfileActionsControllerProvider)
          .pickAndUploadPhoto();
      if (!mounted || result == null) return;
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
          setState(() => _dirty = true);
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
      if (mounted) setState(() => _photoUploading = false);
    }
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    final locale = AppLocalizations.of(context);
    return FlatmatesDialog.confirm(
      context,
      title: locale.unsavedChangesTitle,
      message: locale.unsavedChangesMessage,
      cancelLabel: locale.keepEditing,
      confirmLabel: locale.discardChanges,
      destructive: true,
    );
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
    setState(() => _dirty = false);
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
      return FlatmatesScreen(
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

    final saving = _saving;
    final photoUploading = _photoUploading;
    final dirty = _dirty;
    final tab = _tab;
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
      child: FlatmatesScreen(
        // Header back bypasses PopScope; route through the unsaved-changes guard.
        appBar: FlatmatesHeader.backTitle(
          title: locale.editProfileCta,
          onBack: _handlePop,
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.lg,
          AppSpacing.screen,
          0,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: FlatmatesSegmentedControl<EditProfileTab>(
                segments: editProfileTabSegments(locale),
                selected: tab,
                onChanged: (value) => setState(() => _tab = value),
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
                nativePlaceError: _nativePlaceError,
                linkedInError: _linkedInError,
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
    );
  }

  Future<void> _save(
    String? Function(TextEditingController) nullableText,
  ) async {
    final locale = AppLocalizations.of(context);
    final budgetMin = double.tryParse(_budgetMinController.text.trim());
    final budgetMax = double.tryParse(_budgetMaxController.text.trim());
    // A failed field can sit on another tab: switch to it so the error shows.
    if (budgetMin != null && budgetMax != null && budgetMin > budgetMax) {
      setState(() => _tab = EditProfileTab.preferences);
      FlatmatesToast.error(context, locale.budgetMinMaxError);
      return;
    }

    final nativePlace = nullableText(_nativePlaceController);
    if (nativePlace != null && nativePlace.length > 120) {
      setState(() {
        _tab = EditProfileTab.identity;
        _nativePlaceError = locale.nativePlaceTooLongError;
      });
      return;
    }
    final linkedIn = nullableText(_linkedInController);
    if (linkedIn != null && !isValidLinkedInUrl(linkedIn)) {
      setState(() {
        _tab = EditProfileTab.identity;
        _linkedInError = locale.linkedinInvalidError;
      });
      return;
    }

    setState(() => _saving = true);
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
      await ref.read(editProfileActionsControllerProvider).save(payload);
      if (!mounted) return;
      setState(() => _dirty = false);
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
      if (mounted) setState(() => _saving = false);
    }
  }
}
