import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/image_upload_service.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../bootstrap/catalog_helpers.dart';
import '../shared/presentation/flatmates_ui.dart';
import 'presentation/widgets/edit_profile_sections.dart';
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

  String _mode = 'open_to_both';
  String _workStyle = 'hybrid';
  String _moveInTimeline = 'flexible';
  String? _sleepSchedule;
  String? _cleanliness;
  String? _foodHabits;
  String? _smokingDrinking;
  String? _guestsPolicy;
  List<String> _nonNegotiables = [];
  List<String> _photoUrls = [];
  bool _initialized = false;
  bool _saving = false;
  bool _photoUploading = false;

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
      _mode = profile.mode ?? _mode;
      _workStyle = profile.workStyle ?? _workStyle;
      _moveInTimeline = profile.moveInTimeline ?? _moveInTimeline;
      _sleepSchedule = profile.sleepSchedule;
      _cleanliness = profile.cleanliness;
      _foodHabits = profile.foodHabits;
      _smokingDrinking = profile.smokingDrinking;
      _guestsPolicy = profile.guestsPolicy;
      if (profile.profileImageUrl != null) {
        _photoUrls = [profile.profileImageUrl!];
      }
      final prefs = profile.preferences;
      if (prefs['non_negotiables'] is List) {
        _nonNegotiables = List<String>.from(prefs['non_negotiables']);
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _professionController.dispose();
    _cityController.dispose();
    _localityController.dispose();
    _budgetMinController.dispose();
    _budgetMaxController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  List<DropdownMenuItem<String>> _buildDropdownItems(
    String catalogKey,
    List<DropdownMenuItem<String>> fallback,
  ) {
    final bootstrap = ref.read(bootstrapControllerProvider).valueOrNull;
    final catalogOpts = bootstrap?.catalogOptions(catalogKey);
    if (catalogOpts != null && catalogOpts.isNotEmpty) {
      return catalogOpts
          .map((opt) => DropdownMenuItem(value: opt.id, child: Text(opt.label)))
          .toList();
    }
    return fallback;
  }

  List<DropdownMenuItem<String>> _buildModeItems() {
    final locale = AppLocalizations.of(context);
    return _buildDropdownItems('flatmates_modes', [
      DropdownMenuItem(
        value: 'room_poster',
        child: Text(locale.modeRoomPoster),
      ),
      DropdownMenuItem(value: 'seeker', child: Text(locale.modeSeeker)),
      DropdownMenuItem(value: 'co_hunter', child: Text(locale.modeCoHunter)),
      DropdownMenuItem(
        value: 'open_to_both',
        child: Text(locale.modeOpenToBoth),
      ),
    ]);
  }

  List<DropdownMenuItem<String>> _buildWorkStyleItems() {
    final locale = AppLocalizations.of(context);
    return _buildDropdownItems('flatmates_work_styles', [
      DropdownMenuItem(value: 'office', child: Text(locale.workStyleOffice)),
      DropdownMenuItem(value: 'hybrid', child: Text(locale.workStyleHybrid)),
      DropdownMenuItem(value: 'wfh', child: Text(locale.workStyleWfh)),
    ]);
  }

  List<DropdownMenuItem<String>> _buildTimelineItems() {
    final locale = AppLocalizations.of(context);
    return _buildDropdownItems('flatmates_move_in_timelines', [
      DropdownMenuItem(value: 'immediate', child: Text(locale.moveInImmediate)),
      DropdownMenuItem(
        value: 'this_month',
        child: Text(locale.moveInThisMonth),
      ),
      DropdownMenuItem(
        value: 'next_month',
        child: Text(locale.moveInNextMonth),
      ),
      DropdownMenuItem(value: 'flexible', child: Text(locale.moveInAnytime)),
    ]);
  }

  List<DropdownMenuItem<String>> _buildSleepItems() {
    final locale = AppLocalizations.of(context);
    return _buildDropdownItems('flatmates_lifestyle_sleep', [
      DropdownMenuItem(value: 'early_bird', child: Text(locale.quizEarlyBird)),
      DropdownMenuItem(value: 'flexible', child: Text(locale.quizFlexible)),
      DropdownMenuItem(value: 'night_owl', child: Text(locale.quizNightOwl)),
    ]);
  }

  List<DropdownMenuItem<String>> _buildCleanlinessItems() {
    final locale = AppLocalizations.of(context);
    return _buildDropdownItems('flatmates_lifestyle_cleanliness', [
      DropdownMenuItem(value: 'minimal', child: Text(locale.quizCleanMinimal)),
      DropdownMenuItem(value: 'tidy', child: Text(locale.quizCleanTidy)),
      DropdownMenuItem(
        value: 'spotless',
        child: Text(locale.quizCleanSpotless),
      ),
    ]);
  }

  List<DropdownMenuItem<String>> _buildFoodItems() {
    final locale = AppLocalizations.of(context);
    return _buildDropdownItems('flatmates_lifestyle_food', [
      DropdownMenuItem(value: 'vegetarian', child: Text(locale.quizVegetarian)),
      DropdownMenuItem(value: 'vegan', child: Text(locale.quizVegan)),
      DropdownMenuItem(
        value: 'non_vegetarian',
        child: Text(locale.quizNonVegetarian),
      ),
      DropdownMenuItem(
        value: 'no_preference',
        child: Text(locale.quizNoFoodPref),
      ),
    ]);
  }

  List<DropdownMenuItem<String>> _buildSmokingItems() {
    final locale = AppLocalizations.of(context);
    return _buildDropdownItems('flatmates_lifestyle_smoking', [
      DropdownMenuItem(value: 'neither', child: Text(locale.quizNeither)),
      DropdownMenuItem(
        value: 'smoke_outside',
        child: Text(locale.quizSmokeOutside),
      ),
      DropdownMenuItem(
        value: 'drink_occasionally',
        child: Text(locale.quizDrinkOccasionally),
      ),
      DropdownMenuItem(value: 'both_fine', child: Text(locale.quizBothFine)),
    ]);
  }

  List<DropdownMenuItem<String>> _buildGuestsItems() {
    final locale = AppLocalizations.of(context);
    return _buildDropdownItems('flatmates_lifestyle_guests', [
      DropdownMenuItem(
        value: 'no_overnight_guests',
        child: Text(locale.quizNoGuests),
      ),
      DropdownMenuItem(
        value: 'occasional_ok',
        child: Text(locale.quizOccasionalGuests),
      ),
      DropdownMenuItem(value: 'open_house', child: Text(locale.quizOpenHouse)),
    ]);
  }

  List<NonNegotiableOption> _buildNonNegotiableOptions() {
    final locale = AppLocalizations.of(context);
    return [
      NonNegotiableOption(
        'food_veg_only',
        locale.nonNegVegOnly,
        Icons.restaurant,
      ),
      NonNegotiableOption('food_vegan_only', locale.nonNegVeganOnly, Icons.eco),
      NonNegotiableOption(
        'no_smoking',
        locale.nonNegNoSmoking,
        Icons.smoke_free,
      ),
      NonNegotiableOption(
        'no_drinking',
        locale.nonNegNoDrinking,
        Icons.no_drinks,
      ),
      NonNegotiableOption(
        'no_overnight_guests',
        locale.nonNegNoGuests,
        Icons.nightlight,
      ),
      NonNegotiableOption('no_pets', locale.nonNegNoPets, Icons.pets),
      NonNegotiableOption(
        'gender_female_only',
        locale.nonNegFemaleOnly,
        Icons.female,
      ),
      NonNegotiableOption(
        'gender_male_only',
        locale.nonNegMaleOnly,
        Icons.male,
      ),
      NonNegotiableOption(
        'no_parties',
        locale.nonNegNoParties,
        Icons.do_not_disturb,
      ),
      NonNegotiableOption(
        'min_tidy',
        locale.nonNegMinTidy,
        Icons.cleaning_services,
      ),
    ];
  }

  Future<void> _pickAndUploadPhoto() async {
    if (_photoUploading) return;
    setState(() => _photoUploading = true);
    try {
      final uploadService = ref.read(imageUploadServiceProvider);
      final files = await uploadService.pickImages(limit: 1);
      if (files.isEmpty) return;
      final result = await uploadService.uploadProfilePhoto(files.first);
      if (result is UploadSuccess) {
        setState(() {
          if (_photoUrls.isEmpty) {
            _photoUrls = [result.url];
          } else {
            _photoUrls[0] = result.url;
          }
        });
      }
    } finally {
      if (mounted) setState(() => _photoUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    String? nullableText(TextEditingController controller) {
      final value = controller.text.trim();
      return value.isEmpty ? null : value;
    }

    return Scaffold(
      appBar: AppBar(title: Text(locale.editProfileCta)),
      body: SafeArea(
        minimum: const EdgeInsets.all(AppSpacing.lg),
        child: ListView(
          children: [
            EditProfilePhotoSection(
              locale: locale,
              photoUrls: _photoUrls,
              photoUploading: _photoUploading,
              onPickAndUploadPhoto: _pickAndUploadPhoto,
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
              mode: _mode,
              items: _buildModeItems(),
              onChanged: (value) => setState(() => _mode = value),
            ),
            const SizedBox(height: AppSpacing.section),
            EditProfileBudgetTimelineSection(
              locale: locale,
              budgetMinController: _budgetMinController,
              budgetMaxController: _budgetMaxController,
              moveInTimeline: _moveInTimeline,
              workStyle: _workStyle,
              timelineItems: _buildTimelineItems(),
              workStyleItems: _buildWorkStyleItems(),
              onMoveInTimelineChanged: (value) =>
                  setState(() => _moveInTimeline = value),
              onWorkStyleChanged: (value) => setState(() => _workStyle = value),
            ),
            const SizedBox(height: AppSpacing.section),
            EditProfileLifestyleSection(
              locale: locale,
              sleepSchedule: _sleepSchedule,
              cleanliness: _cleanliness,
              foodHabits: _foodHabits,
              smokingDrinking: _smokingDrinking,
              guestsPolicy: _guestsPolicy,
              sleepItems: _buildSleepItems(),
              cleanlinessItems: _buildCleanlinessItems(),
              foodItems: _buildFoodItems(),
              smokingItems: _buildSmokingItems(),
              guestsItems: _buildGuestsItems(),
              onSleepScheduleChanged: (value) =>
                  setState(() => _sleepSchedule = value),
              onCleanlinessChanged: (value) =>
                  setState(() => _cleanliness = value),
              onFoodHabitsChanged: (value) =>
                  setState(() => _foodHabits = value),
              onSmokingDrinkingChanged: (value) =>
                  setState(() => _smokingDrinking = value),
              onGuestsPolicyChanged: (value) =>
                  setState(() => _guestsPolicy = value),
            ),
            const SizedBox(height: AppSpacing.section),
            EditProfileNonNegotiablesSection(
              locale: locale,
              options: _buildNonNegotiableOptions(),
              selectedIds: _nonNegotiables,
              onSelectionChanged: (value) =>
                  setState(() => _nonNegotiables = value),
            ),
            const SizedBox(height: AppSpacing.section),
            EditProfileBioSection(
              locale: locale,
              bioController: _bioController,
            ),
            const SizedBox(height: AppSpacing.section),
            FlatmatesButton(
              key: const Key('profile_save_button'),
              label: locale.commonSave,
              fullWidth: true,
              onPressed: _saving ? null : () => _save(context, nullableText),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Future<void> _save(
    BuildContext context,
    String? Function(TextEditingController) nullableText,
  ) async {
    final locale = AppLocalizations.of(context);
    final budgetMin = double.tryParse(_budgetMinController.text.trim());
    final budgetMax = double.tryParse(_budgetMaxController.text.trim());
    if (budgetMin != null && budgetMax != null && budgetMin > budgetMax) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(locale.budgetMinMaxError)));
      return;
    }

    setState(() => _saving = true);
    try {
      final payload = <String, dynamic>{
        'full_name': nullableText(_nameController),
        'age': int.tryParse(_ageController.text.trim()),
        'profession': nullableText(_professionController),
        'mode': _mode,
        'city': nullableText(_cityController),
        'locality': nullableText(_localityController),
        'budget_min': budgetMin,
        'budget_max': budgetMax,
        'move_in_timeline': _moveInTimeline,
        'work_style': _workStyle,
        'bio': nullableText(_bioController),
        'sleep_schedule': _sleepSchedule,
        'cleanliness': _cleanliness,
        'food_habits': _foodHabits,
        'smoking_drinking': _smokingDrinking,
        'guests_policy': _guestsPolicy,
        'onboarding_completed': true,
      };
      if (_photoUrls.isNotEmpty) {
        payload['profile_image_url'] = _photoUrls.first;
      }
      if (_nonNegotiables.isNotEmpty) {
        payload['non_negotiables'] = _nonNegotiables;
      }

      await ref.read(profileRepositoryProvider).updateProfile(payload: payload);
      await ref.read(bootstrapControllerProvider.notifier).load();
      if (!context.mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(locale.errorUnknown)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
