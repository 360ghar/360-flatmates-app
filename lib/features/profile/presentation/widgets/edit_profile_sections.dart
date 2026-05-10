import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';

import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/flatmates_card.dart';
import '../../../shared/presentation/flatmates_chip.dart';
import '../../../shared/presentation/flatmates_network_image.dart';

class EditProfilePhotoSection extends StatelessWidget {
  const EditProfilePhotoSection({
    required this.locale,
    required this.photoUrls,
    required this.photoUploading,
    required this.onPickAndUploadPhoto,
    super.key,
  });

  final AppLocalizations locale;
  final List<String> photoUrls;
  final bool photoUploading;
  final VoidCallback onPickAndUploadPhoto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FlatmatesCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(locale.profilePhotoTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: GestureDetector(
              onTap: photoUploading ? null : onPickAndUploadPhoto,
              child: Stack(
                children: [
                  AnimatedScale(
                    scale: photoUploading ? 0.95 : 1.0,
                    duration: AppMotion.fast,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppSemanticColors.accent,
                            AppSemanticColors.orangeMid,
                          ],
                        ),
                      ),
                      child: photoUrls.isNotEmpty
                          ? ClipOval(
                              child: FlatmatesNetworkImage(
                                imageUrl: photoUrls.first,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Icon(Icons.person, size: 48, color: Colors.white),
                    ),
                  ),
                  if (photoUploading)
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black26,
                        ),
                        alignment: Alignment.center,
                        child: const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppSemanticColors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EditProfileBasicInfoSection extends StatelessWidget {
  const EditProfileBasicInfoSection({
    required this.locale,
    required this.nameController,
    required this.ageController,
    required this.professionController,
    required this.cityController,
    required this.localityController,
    super.key,
  });

  final AppLocalizations locale;
  final TextEditingController nameController;
  final TextEditingController ageController;
  final TextEditingController professionController;
  final TextEditingController cityController;
  final TextEditingController localityController;

  @override
  Widget build(BuildContext context) {
    return FlatmatesCard(
      child: Column(
        children: [
          TextField(
            controller: nameController,
            decoration: InputDecoration(labelText: locale.fullNameLabel),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: ageController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: locale.ageLabel),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: professionController,
                  decoration: InputDecoration(
                    labelText: locale.professionLabel,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            key: const Key('profile_city_input'),
            controller: cityController,
            decoration: InputDecoration(labelText: locale.cityLabel),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            key: const Key('profile_locality_input'),
            controller: localityController,
            decoration: InputDecoration(labelText: locale.localityLabel),
          ),
        ],
      ),
    );
  }
}

class EditProfileModeSection extends StatelessWidget {
  const EditProfileModeSection({
    required this.locale,
    required this.mode,
    required this.items,
    required this.onChanged,
    super.key,
  });

  final AppLocalizations locale;
  final String mode;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return FlatmatesCard(
      child: DropdownButtonFormField<String>(
        initialValue: mode,
        decoration: InputDecoration(labelText: locale.modeTitle),
        items: items,
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      ),
    );
  }
}

class EditProfileBudgetTimelineSection extends StatelessWidget {
  const EditProfileBudgetTimelineSection({
    required this.locale,
    required this.budgetMinController,
    required this.budgetMaxController,
    required this.moveInTimeline,
    required this.workStyle,
    required this.timelineItems,
    required this.workStyleItems,
    required this.onMoveInTimelineChanged,
    required this.onWorkStyleChanged,
    super.key,
  });

  final AppLocalizations locale;
  final TextEditingController budgetMinController;
  final TextEditingController budgetMaxController;
  final String moveInTimeline;
  final String workStyle;
  final List<DropdownMenuItem<String>> timelineItems;
  final List<DropdownMenuItem<String>> workStyleItems;
  final ValueChanged<String> onMoveInTimelineChanged;
  final ValueChanged<String> onWorkStyleChanged;

  @override
  Widget build(BuildContext context) {
    return FlatmatesCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            locale.budgetTimelineTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('profile_budget_min_input'),
                  controller: budgetMinController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: locale.budgetMinLabel),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: TextField(
                  key: const Key('profile_budget_max_input'),
                  controller: budgetMaxController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: locale.budgetMaxLabel),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          DropdownButtonFormField<String>(
            initialValue: moveInTimeline,
            decoration: InputDecoration(labelText: locale.moveInTimelineLabel),
            items: timelineItems,
            onChanged: (value) {
              if (value != null) onMoveInTimelineChanged(value);
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          DropdownButtonFormField<String>(
            initialValue: workStyle,
            decoration: InputDecoration(labelText: locale.workStyleTitle),
            items: workStyleItems,
            onChanged: (value) {
              if (value != null) onWorkStyleChanged(value);
            },
          ),
        ],
      ),
    );
  }
}

class EditProfileLifestyleSection extends StatelessWidget {
  const EditProfileLifestyleSection({
    required this.locale,
    required this.sleepSchedule,
    required this.cleanliness,
    required this.foodHabits,
    required this.smokingDrinking,
    required this.guestsPolicy,
    required this.sleepItems,
    required this.cleanlinessItems,
    required this.foodItems,
    required this.smokingItems,
    required this.guestsItems,
    required this.onSleepScheduleChanged,
    required this.onCleanlinessChanged,
    required this.onFoodHabitsChanged,
    required this.onSmokingDrinkingChanged,
    required this.onGuestsPolicyChanged,
    super.key,
  });

  final AppLocalizations locale;
  final String? sleepSchedule;
  final String? cleanliness;
  final String? foodHabits;
  final String? smokingDrinking;
  final String? guestsPolicy;
  final List<DropdownMenuItem<String>> sleepItems;
  final List<DropdownMenuItem<String>> cleanlinessItems;
  final List<DropdownMenuItem<String>> foodItems;
  final List<DropdownMenuItem<String>> smokingItems;
  final List<DropdownMenuItem<String>> guestsItems;
  final ValueChanged<String?> onSleepScheduleChanged;
  final ValueChanged<String?> onCleanlinessChanged;
  final ValueChanged<String?> onFoodHabitsChanged;
  final ValueChanged<String?> onSmokingDrinkingChanged;
  final ValueChanged<String?> onGuestsPolicyChanged;

  @override
  Widget build(BuildContext context) {
    return FlatmatesCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            locale.lifestyleQuizTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          DropdownButtonFormField<String>(
            initialValue: sleepSchedule,
            decoration: InputDecoration(labelText: locale.quizSleepSchedule),
            items: sleepItems,
            onChanged: onSleepScheduleChanged,
          ),
          const SizedBox(height: AppSpacing.lg),
          DropdownButtonFormField<String>(
            initialValue: cleanliness,
            decoration: InputDecoration(labelText: locale.quizCleanliness),
            items: cleanlinessItems,
            onChanged: onCleanlinessChanged,
          ),
          const SizedBox(height: AppSpacing.lg),
          DropdownButtonFormField<String>(
            initialValue: foodHabits,
            decoration: InputDecoration(labelText: locale.quizFoodHabits),
            items: foodItems,
            onChanged: onFoodHabitsChanged,
          ),
          const SizedBox(height: AppSpacing.lg),
          DropdownButtonFormField<String>(
            initialValue: smokingDrinking,
            decoration: InputDecoration(labelText: locale.quizSmokingDrinking),
            items: smokingItems,
            onChanged: onSmokingDrinkingChanged,
          ),
          const SizedBox(height: AppSpacing.lg),
          DropdownButtonFormField<String>(
            initialValue: guestsPolicy,
            decoration: InputDecoration(labelText: locale.quizGuestsPolicy),
            items: guestsItems,
            onChanged: onGuestsPolicyChanged,
          ),
        ],
      ),
    );
  }
}

class EditProfileNonNegotiablesSection extends StatelessWidget {
  const EditProfileNonNegotiablesSection({
    required this.locale,
    required this.options,
    required this.selectedIds,
    required this.onSelectionChanged,
    super.key,
  });

  final AppLocalizations locale;
  final List<NonNegotiableOption> options;
  final List<String> selectedIds;
  final ValueChanged<List<String>> onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    return FlatmatesCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            locale.nonNegotiablesTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${locale.nonNegotiablesLimit} (${selectedIds.length}/3)',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: options.map((opt) {
              final selected = selectedIds.contains(opt.id);
              return FlatmatesChip(
                variant: FlatmatesChipVariant.choice,
                label: opt.label,
                icon: opt.icon,
                selected: selected,
                onSelected: (_) => _toggleOption(opt.id, selected),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _toggleOption(String id, bool selected) {
    final next = List<String>.of(selectedIds);
    if (selected) {
      next.remove(id);
    } else if (next.length < 3) {
      next.add(id);
    }
    onSelectionChanged(next);
  }
}

class EditProfileBioSection extends StatelessWidget {
  const EditProfileBioSection({
    required this.locale,
    required this.bioController,
    super.key,
  });

  final AppLocalizations locale;
  final TextEditingController bioController;

  @override
  Widget build(BuildContext context) {
    return FlatmatesCard(
      child: TextField(
        key: const Key('profile_bio_input'),
        controller: bioController,
        maxLines: 4,
        decoration: InputDecoration(labelText: locale.bioLabel),
      ),
    );
  }
}

class NonNegotiableOption {
  const NonNegotiableOption(this.id, this.label, this.icon);

  final String id;
  final String label;
  final IconData icon;
}
