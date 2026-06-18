import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_radius.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flatmates_app/core/theme/app_spacing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/gen/app_localizations.dart';
import '../shared/presentation/flatmates_card.dart';
import '../shared/presentation/flatmates_header.dart';
import '../shared/presentation/flatmates_toast.dart';
import '../shared/presentation/flatmates_ui.dart';
import 'settings_controller.dart';

class NotificationSettingsPage extends ConsumerWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (!settings.loaded) {
      return Scaffold(
        appBar: FlatmatesHeader.backTitle(
          title: locale.notificationSettingsTitle,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: FlatmatesHeader.backTitle(
        title: locale.notificationSettingsTitle,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          children: [
            const SizedBox(height: AppSpacing.lg),

            // Description
            Text(
              locale.notificationSettingsSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppSemanticColors.textSecondaryFor(theme.brightness),
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.section),

            // Notification toggles
            FlatmatesCard(
              padding: EdgeInsets.zero,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _NotifToggle(
                    icon: Icons.chat_bubble_outline,
                    iconColor: AppSemanticColors.accent,
                    title: locale.notifNewMessages,
                    subtitle: locale.notifNewMessagesDesc,
                    value: settings.notifNewMessages,
                    onChanged: (v) => ref
                        .read(settingsControllerProvider.notifier)
                        .updateNotifNewMessages(v),
                  ),
                  const Divider(height: 1, indent: 68, endIndent: 16),
                  _NotifToggle(
                    icon: Icons.calendar_today_outlined,
                    iconColor: AppSemanticColors.success,
                    title: locale.notifVisitReminders,
                    subtitle: locale.notifVisitRemindersDesc,
                    value: settings.notifVisitReminders,
                    onChanged: (v) => ref
                        .read(settingsControllerProvider.notifier)
                        .updateNotifVisitReminders(v),
                  ),
                  const Divider(height: 1, indent: 68, endIndent: 16),
                  _NotifToggle(
                    icon: Icons.favorite_border,
                    iconColor: AppSemanticColors.warning,
                    title: locale.notifNewMatches,
                    subtitle: locale.notifNewMatchesDesc,
                    value: settings.notifNewMatches,
                    onChanged: (v) => ref
                        .read(settingsControllerProvider.notifier)
                        .updateNotifNewMatches(v),
                  ),
                  const Divider(height: 1, indent: 68, endIndent: 16),
                  _NotifToggle(
                    icon: Icons.home_outlined,
                    iconColor: AppSemanticColors.info,
                    title: locale.notifListingUpdates,
                    subtitle: locale.notifListingUpdatesDesc,
                    value: settings.notifListingUpdates,
                    onChanged: (v) => ref
                        .read(settingsControllerProvider.notifier)
                        .updateNotifListingUpdates(v),
                  ),
                  const Divider(height: 1, indent: 68, endIndent: 16),
                  _NotifToggle(
                    icon: Icons.local_offer_outlined,
                    iconColor: AppSemanticColors.textTertiaryFor(
                      theme.brightness,
                    ),
                    title: locale.notifPromotions,
                    subtitle: locale.notifPromotionsDesc,
                    value: settings.notifPromotions,
                    onChanged: (v) => ref
                        .read(settingsControllerProvider.notifier)
                        .updateNotifPromotions(v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.section),

            // Quick actions
            Row(
              children: [
                Expanded(
                  child: FlatmatesButton.tertiary(
                    key: const Key('notif_enable_all'),
                    label: locale.notifEnableAll,
                    onPressed: () => _setAll(context, ref, true),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FlatmatesButton.tertiary(
                    key: const Key('notif_disable_all'),
                    label: locale.notifDisableAll,
                    onPressed: () => _setAll(context, ref, false),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.screen),
          ],
        ),
      ),
    );
  }

  /// Bulk-applies [value] to every notification preference and surfaces a
  /// confirmation toast so the user gets feedback for the action.
  Future<void> _setAll(BuildContext context, WidgetRef ref, bool value) async {
    final locale = AppLocalizations.of(context);
    final notifier = ref.read(settingsControllerProvider.notifier);
    await notifier.updateNotifNewMessages(value);
    await notifier.updateNotifVisitReminders(value);
    await notifier.updateNotifNewMatches(value);
    await notifier.updateNotifListingUpdates(value);
    await notifier.updateNotifPromotions(value);
    if (!context.mounted) return;
    FlatmatesToast.success(
      context,
      value ? locale.notifAllEnabled : locale.notifAllDisabled,
    );
  }
}

class _NotifToggle extends StatelessWidget {
  const _NotifToggle({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SwitchListTile(
      secondary: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: AppRadius.mdBorder,
          color: iconColor.withValues(alpha: 0.12),
        ),
        child: Icon(icon, size: 20, color: iconColor),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppSemanticColors.textPrimaryFor(theme.brightness),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: AppSemanticColors.textTertiaryFor(theme.brightness),
          height: 1.4,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppSemanticColors.accent,
    );
  }
}
