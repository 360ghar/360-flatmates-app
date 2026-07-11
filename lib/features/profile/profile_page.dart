import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../auth/auth_controller.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../settings/preferences_sheet.dart';
import '../settings/settings_controller.dart';
import '../shared/presentation/components.dart';
import 'presentation/widgets/identity_pills.dart';
import 'presentation/widgets/profile_strength_card.dart';

const double _kAvatarOffset = 2.0;
const double _kVerticalSpacingCompact = 6.0;

/// Dense menu: hPad(16) + iconWell(32) + gap(12).
const double _kDenseDividerIndent = 60;

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
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.base,
              AppSpacing.screen,
              AppSpacing.xxl,
            ),
            children: [
              // --- Compact header: avatar left, text right, whole group centered ---
              Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Semantics(
                        image: true,
                        label: locale.profilePhotoSemantic(displayName),
                        child: FlatmatesAvatar(
                          name: displayName,
                          imageUrl: profile.profileImageUrl,
                          size: 80,
                          showRing: true,
                        ),
                      ),
                      Positioned(
                        right: -_kAvatarOffset,
                        bottom: _kAvatarOffset,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.8, end: 1.0),
                          duration: AppMotion.durationOrZero(
                            context,
                            AppMotion.fabExpand,
                          ),
                          curve: AppMotion.easeOutBack,
                          builder: (context, scale, child) {
                            return Transform.scale(scale: scale, child: child);
                          },
                          child: Material(
                            color: AppSemanticColors.accent,
                            shape: const CircleBorder(),
                            elevation: 3,
                            child: Tooltip(
                              message: locale.editProfileCta,
                              child: Semantics(
                                button: true,
                                label: locale.editProfileCta,
                                child: InkWell(
                                  key: const Key('profile_edit_button'),
                                  onTap: () => context.push('/profile/edit'),
                                  customBorder: const CircleBorder(),
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.edit,
                                      size: 14,
                                      color: AppSemanticColors.onPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.xl),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          displayName,
                          key: const Key('profile_name_text'),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        if (profile.email != null &&
                            profile.email!.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            profile.email!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppSemanticColors.textSecondaryFor(
                                theme.brightness,
                              ),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ] else if (profile.phone != null &&
                            profile.phone!.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            profile.phone!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppSemanticColors.textSecondaryFor(
                                theme.brightness,
                              ),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],

                        if (location != null && location.isNotEmpty) ...[
                          const SizedBox(height: _kVerticalSpacingCompact),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: AppSemanticColors.textSecondaryFor(
                                  theme.brightness,
                                ),
                              ),
                              const SizedBox(width: _kVerticalSpacingCompact),
                              Expanded(
                                child: Text(
                                  location,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppSemanticColors.textSecondaryFor(
                                      theme.brightness,
                                    ),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
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
                      const Divider(
                        height: 1,
                        indent: _kDenseDividerIndent,
                        endIndent: AppSpacing.lg,
                      ),
                      FlatmatesMenuItem(
                        dense: true,
                        icon: Icons.calendar_month_outlined,
                        label: locale.profileMenuVisits,
                        onTap: () => context.push('/profile/visits'),
                      ),
                      const Divider(
                        height: 1,
                        indent: _kDenseDividerIndent,
                        endIndent: AppSpacing.lg,
                      ),
                      FlatmatesMenuItem(
                        dense: true,
                        icon: Icons.favorite_border,
                        label: locale.profileMenuShortlisted,
                        onTap: () => context.go('/chats?tab=likes'),
                      ),
                      const Divider(
                        height: 1,
                        indent: _kDenseDividerIndent,
                        endIndent: AppSpacing.lg,
                      ),
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
          );
        },
        loading: () => const FlatmatesSkeleton.profile(),
        error: (error, _) =>
            FlatmatesErrorState(message: locale.couldNotLoadProfile),
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
                const Divider(
                  height: 1,
                  indent: _kDenseDividerIndent,
                  endIndent: AppSpacing.lg,
                ),
                FlatmatesMenuItem(
                  key: const Key('profile_notification_settings_menu_item'),
                  dense: true,
                  icon: Icons.notifications_outlined,
                  label: locale.notificationSettingsLabel,
                  onTap: () => context.push('/notification-settings'),
                ),
                const Divider(
                  height: 1,
                  indent: _kDenseDividerIndent,
                  endIndent: AppSpacing.lg,
                ),
                FlatmatesMenuItem(
                  key: const Key('profile_settings_menu_item'),
                  dense: true,
                  icon: Icons.settings_outlined,
                  label: locale.settingsTitle,
                  onTap: () => context.push('/profile/settings'),
                ),
                const Divider(
                  height: 1,
                  indent: _kDenseDividerIndent,
                  endIndent: AppSpacing.lg,
                ),
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

Future<void> _confirmAndLogout(BuildContext context, WidgetRef ref) async {
  final locale = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(locale.logoutCta),
      actions: [
        TextButton(
          key: const Key('logout_dialog_cancel'),
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(locale.cancelCta),
        ),
        TextButton(
          key: const Key('logout_dialog_confirm'),
          onPressed: () => Navigator.of(ctx).pop(true),
          style: TextButton.styleFrom(foregroundColor: AppSemanticColors.error),
          child: Text(locale.logoutCta),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    await ref.read(authControllerProvider.notifier).signOut();
  }
}
