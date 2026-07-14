import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import 'edit_profile_options.dart';
import 'edit_profile_sections.dart';

/// Tabs that organize the edit-profile form into scannable groups.
enum EditProfileTab { identity, preferences, lifestyle, about }

/// Segmented-control definition for the edit-profile tabs.
List<(EditProfileTab, String, IconData?)> editProfileTabSegments(
  AppLocalizations locale,
) => [
  (
    EditProfileTab.identity,
    locale.editProfileTabIdentity,
    Icons.person_outline,
  ),
  (EditProfileTab.preferences, locale.editProfileTabPreferences, Icons.tune),
  (
    EditProfileTab.lifestyle,
    locale.editProfileTabLifestyle,
    Icons.spa_outlined,
  ),
  (EditProfileTab.about, locale.editProfileTabAbout, Icons.info_outline),
];

/// Provider-derived values consumed by the tab bodies.
class EditProfileTabValues {
  const EditProfileTabValues({
    required this.photoUrls,
    required this.photoUploading,
    required this.mode,
    required this.moveInTimeline,
    required this.workStyle,
    required this.sleepSchedule,
    required this.cleanliness,
    required this.foodHabits,
    required this.smokingDrinking,
    required this.guestsPolicy,
    required this.nonNegotiables,
  });

  final List<String> photoUrls;
  final bool photoUploading;

  /// Null when unset or unmapped — omit from save payload.
  final String? mode;
  final String? moveInTimeline;

  /// Null when unset or unmapped — omit from save payload.
  final String? workStyle;
  final String? sleepSchedule;
  final String? cleanliness;
  final String? foodHabits;
  final String? smokingDrinking;
  final String? guestsPolicy;
  final List<String> nonNegotiables;
}

/// Change handlers for the tab bodies, wired back to page-level StateProviders.
class EditProfileTabHandlers {
  const EditProfileTabHandlers({
    required this.onModeChanged,
    required this.onMoveInTimelineChanged,
    required this.onWorkStyleChanged,
    required this.onSleepScheduleChanged,
    required this.onCleanlinessChanged,
    required this.onFoodHabitsChanged,
    required this.onSmokingDrinkingChanged,
    required this.onGuestsPolicyChanged,
    required this.onNonNegotiablesChanged,
  });

  final ValueChanged<String> onModeChanged;
  final ValueChanged<String> onMoveInTimelineChanged;
  final ValueChanged<String> onWorkStyleChanged;
  final ValueChanged<String?> onSleepScheduleChanged;
  final ValueChanged<String?> onCleanlinessChanged;
  final ValueChanged<String?> onFoodHabitsChanged;
  final ValueChanged<String?> onSmokingDrinkingChanged;
  final ValueChanged<String?> onGuestsPolicyChanged;
  final ValueChanged<List<String>> onNonNegotiablesChanged;
}

Widget buildEditProfileTabBody({
  required EditProfileTab tab,
  required AppLocalizations locale,
  required EditProfileOptions options,
  required EditProfileTabValues values,
  required EditProfileTabHandlers handlers,
  required TextEditingController emailController,
  required TextEditingController phoneController,
  required TextEditingController nameController,
  required TextEditingController ageController,
  required TextEditingController professionController,
  required TextEditingController cityController,
  required TextEditingController localityController,
  required TextEditingController budgetMinController,
  required TextEditingController budgetMaxController,
  required TextEditingController bioController,
  required bool hasEmail,
  required bool hasPhone,
  required VoidCallback onPickAndUploadPhoto,
}) {
  switch (tab) {
    case EditProfileTab.identity:
      return ListView(
        children: [
          EditProfilePhotoSection(
            locale: locale,
            photoUrls: values.photoUrls,
            photoUploading: values.photoUploading,
            onPickAndUploadPhoto: onPickAndUploadPhoto,
          ),
          const SizedBox(height: AppSpacing.lg),
          EditProfileContactInfoSection(
            locale: locale,
            emailController: emailController,
            phoneController: phoneController,
            hasEmail: hasEmail,
            hasPhone: hasPhone,
          ),
          const SizedBox(height: AppSpacing.xl),
          EditProfileBasicInfoSection(
            locale: locale,
            nameController: nameController,
            ageController: ageController,
            professionController: professionController,
            cityController: cityController,
            localityController: localityController,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      );
    case EditProfileTab.preferences:
      return ListView(
        children: [
          EditProfileModeSection(
            locale: locale,
            mode: values.mode,
            items: options.modeItems(),
            onChanged: handlers.onModeChanged,
          ),
          const SizedBox(height: AppSpacing.xl),
          EditProfileBudgetTimelineSection(
            locale: locale,
            budgetMinController: budgetMinController,
            budgetMaxController: budgetMaxController,
            moveInTimeline: values.moveInTimeline,
            workStyle: values.workStyle,
            timelineItems: options.timelineItems(),
            workStyleItems: options.workStyleItems(),
            onMoveInTimelineChanged: handlers.onMoveInTimelineChanged,
            onWorkStyleChanged: handlers.onWorkStyleChanged,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      );
    case EditProfileTab.lifestyle:
      return ListView(
        children: [
          EditProfileLifestyleSection(
            locale: locale,
            sleepSchedule: values.sleepSchedule,
            cleanliness: values.cleanliness,
            foodHabits: values.foodHabits,
            smokingDrinking: values.smokingDrinking,
            guestsPolicy: values.guestsPolicy,
            sleepItems: options.sleepItems(),
            cleanlinessItems: options.cleanlinessItems(),
            foodItems: options.foodItems(),
            smokingItems: options.smokingItems(),
            guestsItems: options.guestsItems(),
            onSleepScheduleChanged: handlers.onSleepScheduleChanged,
            onCleanlinessChanged: handlers.onCleanlinessChanged,
            onFoodHabitsChanged: handlers.onFoodHabitsChanged,
            onSmokingDrinkingChanged: handlers.onSmokingDrinkingChanged,
            onGuestsPolicyChanged: handlers.onGuestsPolicyChanged,
          ),
          const SizedBox(height: AppSpacing.xl),
          EditProfileNonNegotiablesSection(
            locale: locale,
            options: options.nonNegotiableOptions(),
            selectedIds: values.nonNegotiables,
            onSelectionChanged: handlers.onNonNegotiablesChanged,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      );
    case EditProfileTab.about:
      return ListView(
        children: [
          EditProfileBioSection(locale: locale, bioController: bioController),
          const SizedBox(height: AppSpacing.xl),
        ],
      );
  }
}
