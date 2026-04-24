import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_palette.dart';
import '../../l10n/gen/app_localizations.dart';
import '../auth/auth_controller.dart';
import 'settings_controller.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(locale.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          _SettingsSection(
            title: locale.settingsProfileSection,
            children: [
              _SettingsTile(
                icon: Icons.person_outline,
                label: locale.editProfileCta,
                onTap: () => context.push('/profile/edit'),
              ),
              const Divider(height: 1),
              _SettingsTile(
                icon: Icons.notifications_outlined,
                label: locale.notificationsTitle,
                onTap: () => context.push('/notifications'),
              ),
              const Divider(height: 1),
              _SettingsTile(
                icon: Icons.help_outline,
                label: locale.helpSafetyTitle,
                onTap: () => context.push('/help-safety'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: locale.settingsAppearanceSection,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
                child: Text(
                  locale.themeModeTitle,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                child: SegmentedButton<ThemeMode>(
                  segments: [
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text(
                        locale.themeSystem,
                        key: const Key('theme_mode_system_option'),
                      ),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text(
                        locale.themeLight,
                        key: const Key('theme_mode_light_option'),
                      ),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text(
                        locale.themeDark,
                        key: const Key('theme_mode_dark_option'),
                      ),
                    ),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (selection) {
                    ref
                        .read(settingsControllerProvider.notifier)
                        .updateThemeMode(selection.first);
                  },
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                child: Text(
                  locale.paletteTitle,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppPalette.values.map((palette) {
                    final selected = settings.palette == palette;
                    return ChoiceChip(
                      key: Key('palette_${palette.storageValue}'),
                      label: Text(_paletteLabel(locale, palette)),
                      selected: selected,
                      onSelected: (_) {
                        ref
                            .read(settingsControllerProvider.notifier)
                            .updatePalette(palette);
                      },
                    );
                  }).toList(),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                child: Text(
                  locale.languageTitle,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                child: SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'en',
                      label: Text(
                        locale.languageEnglish,
                        key: const Key('language_english_option'),
                      ),
                    ),
                    ButtonSegment(
                      value: 'hi',
                      label: Text(
                        locale.languageHindi,
                        key: const Key('language_hindi_option'),
                      ),
                    ),
                  ],
                  selected: {settings.locale?.languageCode ?? 'en'},
                  onSelectionChanged: (selection) {
                    ref
                        .read(settingsControllerProvider.notifier)
                        .updateLocale(Locale(selection.first));
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: locale.privacyTitle,
            children: [
              SwitchListTile(
                key: const Key('setting_hide_last_name'),
                secondary: Icon(Icons.person_off_outlined, color: theme.colorScheme.primary),
                title: Text(locale.hideLastNameLabel),
                value: settings.hideLastName,
                onChanged: (v) {
                  ref.read(settingsControllerProvider.notifier).updateHideLastName(v);
                },
              ),
              const Divider(height: 1),
              SwitchListTile(
                key: const Key('setting_hide_location'),
                secondary: Icon(Icons.location_off_outlined, color: theme.colorScheme.primary),
                title: Text(locale.hideExactLocationLabel),
                value: settings.hideExactLocation,
                onChanged: (v) {
                  ref.read(settingsControllerProvider.notifier).updateHideExactLocation(v);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: locale.settingsSessionSection,
            children: [
              _SettingsTile(
                key: const Key('logout_button'),
                icon: Icons.logout_outlined,
                iconColor: theme.colorScheme.error,
                label: locale.logoutCta,
                labelColor: theme.colorScheme.error,
                onTap: () =>
                    ref.read(authControllerProvider.notifier).signOut(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _paletteLabel(AppLocalizations locale, AppPalette palette) {
    switch (palette) {
      case AppPalette.electricIndigo:
        return locale.paletteElectricIndigo;
      case AppPalette.emberCoral:
        return locale.paletteEmberCoral;
      case AppPalette.monsoonTeal:
        return locale.paletteMonsoonTeal;
    }
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 10),
          child: Text(title, style: theme.textTheme.titleLarge),
        ),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
    this.iconColor,
    this.labelColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      leading: Icon(icon, color: iconColor ?? theme.colorScheme.primary),
      title: Text(
        label,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: labelColor,
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}
