import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_semantic_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../shared/presentation/components.dart';
import 'settings_controller.dart';

/// Opens the Preferences bottom sheet (theme, language, privacy toggles).
void showPreferencesSheet(BuildContext context) {
  FlatmatesBottomSheet.show(
    context: context,
    isScrollControlled: true,
    builder: (_) => const PreferencesSheet(),
  );
}

/// Bottom sheet for Preferences — theme mode, language, and privacy toggles.
class PreferencesSheet extends StatelessWidget {
  const PreferencesSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final settings = ref.watch(settingsControllerProvider);
        final locale = AppLocalizations.of(context);
        final theme = Theme.of(context);
        final clay = AppSemanticColors.clayFor(theme.brightness);

        if (!settings.loaded) {
          return DraggableScrollableSheet(
            initialChildSize: 0.4,
            expand: false,
            builder: (context, scrollController) {
              return const FlatmatesSkeleton.settingsList(itemCount: 3);
            },
          );
        }

        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            // FlatmatesBottomSheet draws the drag handle.
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      locale.preferencesLabel,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    // The sheet shell already pads the sides.
                    padding: const EdgeInsets.only(
                      top: AppSpacing.sm,
                      bottom: AppSpacing.xl,
                    ),
                    children: [
                      Text(
                        locale.themeModeTitle,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      FlatmatesSegmentedControl<ThemeMode>(
                        segments: [
                          (
                            ThemeMode.system,
                            locale.themeSystem,
                            Icons.brightness_auto_outlined,
                          ),
                          (
                            ThemeMode.light,
                            locale.themeLight,
                            Icons.light_mode_outlined,
                          ),
                          (
                            ThemeMode.dark,
                            locale.themeDark,
                            Icons.dark_mode_outlined,
                          ),
                        ],
                        selected: settings.themeMode,
                        onChanged: (value) {
                          ref
                              .read(settingsControllerProvider.notifier)
                              .updateThemeMode(value);
                        },
                        segmentKeys: const [
                          Key('theme_mode_system_option'),
                          Key('theme_mode_light_option'),
                          Key('theme_mode_dark_option'),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        locale.languageTitle,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      FlatmatesSegmentedControl<String>(
                        segments: [
                          ('en', locale.languageEnglish, null),
                          ('hi', locale.languageHindi, null),
                        ],
                        selected: settings.locale?.languageCode ?? 'en',
                        onChanged: (value) {
                          ref
                              .read(settingsControllerProvider.notifier)
                              .updateLocale(Locale(value));
                        },
                        segmentKeys: const [
                          Key('language_english_option'),
                          Key('language_hindi_option'),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Material(
                        color: Colors.transparent,
                        child: SwitchListTile(
                          key: const Key('setting_hide_last_name'),
                          // Align the icon with the section labels.
                          contentPadding: EdgeInsets.zero,
                          secondary: Icon(
                            Icons.person_off_outlined,
                            color: clay,
                          ),
                          title: Text(locale.hideLastNameLabel),
                          value: settings.hideLastName,
                          onChanged: (v) {
                            ref
                                .read(settingsControllerProvider.notifier)
                                .updateHideLastName(v);
                          },
                        ),
                      ),
                      const Divider(),
                      Material(
                        color: Colors.transparent,
                        child: SwitchListTile(
                          key: const Key('setting_hide_location'),
                          // Align the icon with the section labels.
                          contentPadding: EdgeInsets.zero,
                          secondary: Icon(
                            Icons.location_off_outlined,
                            color: clay,
                          ),
                          title: Text(locale.hideExactLocationLabel),
                          value: settings.hideExactLocation,
                          onChanged: (v) {
                            ref
                                .read(settingsControllerProvider.notifier)
                                .updateHideExactLocation(v);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
