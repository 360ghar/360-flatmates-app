import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'edit_profile_tabs.dart';

// Local UI state for the edit-profile page via autoDispose StateProviders
// (convention: no setState in the page). Kept here so the page stays under
// the 500-line limit; everything below is page-scoped form state.

/// Nullable until seeded/chosen so unmapped server values aren't blanked on
/// save.
final editProfileModeProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);
final editProfileWorkStyleProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);
final editProfileMoveInTimelineProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);
final editProfileSleepScheduleProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);
final editProfileCleanlinessProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);
final editProfileFoodHabitsProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);
final editProfileSmokingProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);
final editProfileDrinkingProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);
final editProfileGuestsPolicyProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);
final editProfileNonNegotiablesProvider =
    StateProvider.autoDispose<List<String>>((ref) => const []);
final editProfilePhotoUrlsProvider = StateProvider.autoDispose<List<String>>(
  (ref) => const [],
);
final editProfileSavingProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);
final editProfilePhotoUploadingProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);
final editProfileDirtyProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);
final editProfileNativePlaceErrorProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);
final editProfileLinkedInErrorProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);

/// Active edit-profile tab; defaults to Identity (the most-edited fields).
final editProfileTabProvider = StateProvider.autoDispose<EditProfileTab>(
  (ref) => EditProfileTab.identity,
);

/// Assembles the profile-update payload from form state. Values come from the
/// page-level providers above plus the text controllers owned by the page.
Map<String, dynamic> buildEditProfileSavePayload({
  required WidgetRef ref,
  required String? Function(TextEditingController) nullableText,
  required double? budgetMin,
  required double? budgetMax,
  required TextEditingController nameController,
  required TextEditingController ageController,
  required TextEditingController professionController,
  required TextEditingController cityController,
  required TextEditingController localityController,
  required TextEditingController bioController,
  required TextEditingController emailController,
  required TextEditingController phoneController,
  required TextEditingController nativePlaceController,
  required TextEditingController linkedInController,
  required Map<String, dynamic> existingPreferences,
  required bool hasEmail,
  required bool hasPhone,
}) {
  final payload = <String, dynamic>{
    'full_name': nullableText(nameController),
    'age': int.tryParse(ageController.text.trim()),
    'profession': nullableText(professionController),
    'mode': ?ref.read(editProfileModeProvider),
    'city': nullableText(cityController),
    'locality': nullableText(localityController),
    'budget_min': budgetMin,
    'budget_max': budgetMax,
    'move_in_timeline': ?ref.read(editProfileMoveInTimelineProvider),
    'work_style': ?ref.read(editProfileWorkStyleProvider),
    'bio': nullableText(bioController),
    'sleep_schedule': ref.read(editProfileSleepScheduleProvider),
    'cleanliness': ref.read(editProfileCleanlinessProvider),
    'food_habits': ref.read(editProfileFoodHabitsProvider),
    'smoking': ref.read(editProfileSmokingProvider),
    'drinking': ref.read(editProfileDrinkingProvider),
    'guests_policy': ref.read(editProfileGuestsPolicyProvider),
    'native_place': nullableText(nativePlaceController),
    'linkedin_url': nullableText(linkedInController),
    'preferences': {
      ...existingPreferences,
      'non_negotiables': ref.read(editProfileNonNegotiablesProvider),
    },
  };
  final photoUrls = ref.read(editProfilePhotoUrlsProvider);
  if (photoUrls.isNotEmpty) {
    payload['profile_image_url'] = photoUrls.first;
  }
  final newEmail = emailController.text.trim();
  final newPhone = phoneController.text.trim();
  if (!hasEmail && newEmail.isNotEmpty) payload['email'] = newEmail;
  if (!hasPhone && newPhone.isNotEmpty) payload['phone'] = newPhone;
  return payload;
}

/// Wires every edit-profile field to its provider, marking the form dirty on
/// each change.
///
/// Lives here rather than inline in the page for the same reason as the
/// providers above: it is ten identical write-then-mark blocks that only need
/// [ref] and [markDirty], and inlining them pushes the page past the 500-line
/// limit.
EditProfileTabHandlers buildEditProfileTabHandlers(
  WidgetRef ref,
  VoidCallback markDirty,
) {
  void set<T>(AutoDisposeStateProvider<T> provider, T value) {
    ref.read(provider.notifier).state = value;
    markDirty();
  }

  return EditProfileTabHandlers(
    onModeChanged: (value) => set(editProfileModeProvider, value),
    onMoveInTimelineChanged: (value) =>
        set(editProfileMoveInTimelineProvider, value),
    onWorkStyleChanged: (value) => set(editProfileWorkStyleProvider, value),
    onSleepScheduleChanged: (value) =>
        set(editProfileSleepScheduleProvider, value),
    onCleanlinessChanged: (value) => set(editProfileCleanlinessProvider, value),
    onFoodHabitsChanged: (value) => set(editProfileFoodHabitsProvider, value),
    onSmokingChanged: (value) => set(editProfileSmokingProvider, value),
    onDrinkingChanged: (value) => set(editProfileDrinkingProvider, value),
    onGuestsPolicyChanged: (value) =>
        set(editProfileGuestsPolicyProvider, value),
    onNonNegotiablesChanged: (value) =>
        set(editProfileNonNegotiablesProvider, value),
  );
}
