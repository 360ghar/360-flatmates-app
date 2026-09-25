import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../auth/auth_controller.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../settings/preferences_sheet.dart';
import '../settings/settings_controller.dart';
import '../shared/presentation/components.dart';
import 'presentation/widgets/profile_header.dart';
import 'presentation/widgets/profile_menu_group.dart';
import 'presentation/widgets/profile_strength_card.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrap = ref.watch(bootstrapControllerProvider);
    final settings = ref.watch(settingsControllerProvider);
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final listHubBg = AppSemanticColors.secondarySurfaceFor(theme.brightness);

    return FlatmatesScreen(
      backgroundColor: listHubBg,
      body: bootstrap.when(
        data: (data) {
          final profile = data?.profile;
          if (profile == null) {
            return const FlatmatesSkeleton.profile();
          }
          final displayName = displayOwnName(
            profile.fullName,
            hideLastName: settings.hideLastName,
            fallback: locale.profileFallbackName,
          );
          final location = displayOwnLocation(
            city: profile.city,
            state: profile.state,
            locality: profile.locality,
            hideExactLocation: settings.hideExactLocation,
          );
          final profileStrength = profileStrengthPercent(profile);
          final email = profile.email?.trim();
          final phone = profile.phone?.trim();
          final contact = email != null && email.isNotEmpty
              ? email
              : phone != null && phone.isNotEmpty
              ? phone
              : null;
          return RefreshIndicator(
            color: AppSemanticColors.clayFor(theme.brightness),
            onRefresh: () =>
                ref.read(bootstrapControllerProvider.notifier).refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.base,
                AppSpacing.screen,
                AppSpacing.xxl,
              ),
              children: [
                ProfileHeader(
                  displayName: displayName,
                  imageUrl: profile.profileImageUrl,
                  contact: contact,
                  location: location != null && location.isNotEmpty
                      ? location
                      : null,
                ),
                const SizedBox(height: AppSpacing.base),
                ProfileStrengthCard(
                  percent: profileStrength,
                  onTap: () => context.push('/profile/edit'),
                ),
                const SizedBox(height: AppSpacing.base),
                // --- Menu items with staggered appear ---
                MenuGroupLabel(label: locale.discoverySectionLabel),
                const SizedBox(height: AppSpacing.sm),
                StaggeredMenuGroup(
                  delayIndex: 0,
                  child: FlatmatesCard(
                    padding: EdgeInsets.zero,
                    backgroundColor: AppSemanticColors.surfaceFor(
                      theme.brightness,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FlatmatesMenuItem(
                          dense: true,
                          icon: Icons.add_home_outlined,
                          label: locale.profileMenuPostListing,
                          onTap: () => context.push('/manage-listings'),
                        ),
                        const _MenuDivider(),
                        FlatmatesMenuItem(
                          dense: true,
                          icon: Icons.calendar_month_outlined,
                          label: locale.profileMenuVisits,
                          onTap: () => context.push('/profile/visits'),
                        ),
                        const _MenuDivider(),
                        FlatmatesMenuItem(
                          dense: true,
                          icon: Icons.favorite_border,
                          label: locale.profileMenuShortlisted,
                          onTap: () => context.go('/chats?tab=likes'),
                        ),
                        const _MenuDivider(),
                        FlatmatesMenuItem(
                          dense: true,
                          icon: Icons.chat_bubble_outline_rounded,
                          label: locale.profileMenuChats,
                          onTap: () => context.go('/chats'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.base),
                MenuGroupLabel(label: locale.trustSectionLabel),
                const SizedBox(height: AppSpacing.sm),
                StaggeredMenuGroup(
                  delayIndex: 1,
                  child: FlatmatesCard(
                    padding: EdgeInsets.zero,
                    backgroundColor: AppSemanticColors.surfaceFor(
                      theme.brightness,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FlatmatesMenuItem(
                          dense: true,
                          icon: Icons.description_outlined,
                          label: locale.profileMenuDocuments,
                          onTap: () => context.push('/help-safety/bookings'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.base),
                _accountGroup(context, locale),
                const SizedBox(height: AppSpacing.base),
                FlatmatesButton.tertiary(
                  key: const Key('logout_button'),
                  label: locale.logoutCta,
                  destructive: true,
                  onPressed: () => _confirmAndLogout(context, ref),
                ),
              ],
            ),
          );
        },
        loading: () => const FlatmatesSkeleton.profile(),
        error: (error, _) => FlatmatesErrorState(
          message: locale.couldNotLoadProfile,
          onRetry: () =>
              ref.read(bootstrapControllerProvider.notifier).refresh(),
        ),
      ),
    );
  }

  Widget _accountGroup(BuildContext context, AppLocalizations locale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        MenuGroupLabel(label: locale.accountSectionLabel),
        const SizedBox(height: AppSpacing.sm),
        StaggeredMenuGroup(
          delayIndex: 2,
          child: FlatmatesCard(
            padding: EdgeInsets.zero,
            backgroundColor: AppSemanticColors.surfaceFor(
              Theme.of(context).brightness,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FlatmatesMenuItem(
                  key: const Key('preferences_menu_item'),
                  dense: true,
                  icon: AppIcons.filter,
                  label: locale.preferencesLabel,
                  onTap: () => showPreferencesSheet(context),
                ),
                const _MenuDivider(),
                FlatmatesMenuItem(
                  key: const Key('profile_notification_settings_menu_item'),
                  dense: true,
                  icon: Icons.notifications_outlined,
                  label: locale.notificationSettingsLabel,
                  onTap: () => context.push('/notification-settings'),
                ),
                const _MenuDivider(),
                FlatmatesMenuItem(
                  key: const Key('profile_settings_menu_item'),
                  dense: true,
                  icon: Icons.settings_outlined,
                  label: locale.settingsTitle,
                  onTap: () => context.push('/profile/settings'),
                ),
                const _MenuDivider(),
                FlatmatesMenuItem(
                  key: const Key('profile_help_safety_menu_item'),
                  dense: true,
                  icon: Icons.help_outline,
                  label: locale.helpSafetyTitle,
                  onTap: () => context.push('/help-safety'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Divider between dense menu rows, aligned with the row labels.
class _MenuDivider extends StatelessWidget {
  const _MenuDivider();

  @override
  Widget build(BuildContext context) => Divider(
    height: 1,
    indent: FlatmatesMenuItem.labelInset(dense: true),
    endIndent: AppSpacing.base,
  );
}

Future<void> _confirmAndLogout(BuildContext context, WidgetRef ref) async {
  final locale = AppLocalizations.of(context);
  final confirmed = await FlatmatesDialog.confirm(
    context,
    title: locale.logoutCta,
    cancelLabel: locale.cancelCta,
    confirmLabel: locale.logoutCta,
    destructive: true,
    cancelKey: const Key('logout_dialog_cancel'),
    confirmKey: const Key('logout_dialog_confirm'),
  );
  if (confirmed == true && context.mounted) {
    await ref.read(authControllerProvider.notifier).signOut();
  }
}
