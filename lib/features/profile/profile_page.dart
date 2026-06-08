import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../auth/auth_controller.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../shared/presentation/components.dart';

const double _kAvatarOffset = 2.0;
const double _kVerticalSpacingCompact = 6.0;

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrap = ref.watch(bootstrapControllerProvider);
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return FlatmatesScreen(
      body: bootstrap.when(
        data: (data) {
          final profile = data?.profile;
          final city = profile?.city;
          final state = profile?.state;
          final location = [
            if (city != null && city.trim().isNotEmpty) city.trim(),
            if (state != null && state.trim().isNotEmpty) state.trim(),
          ].join(', ');
          if (profile == null) {
            return const FlatmatesSkeleton.card();
          }
          final profileStrength = _profileStrengthPercent(profile);
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            children: [
              // --- Compact header: avatar left, text right, whole group centered ---
              Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      FlatmatesAvatar(
                        name: profile.fullName,
                        imageUrl: profile.profileImageUrl,
                        size: 80,
                        showRing: true,
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
                                  color: Colors.white,
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
                          profile.fullName ?? locale.profileFallbackName,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        if (profile.email != null && profile.email!.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            profile.email!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppSemanticColors.textSecondaryFor(theme.brightness),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ] else if (profile.phone != null && profile.phone!.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            profile.phone!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppSemanticColors.textSecondaryFor(theme.brightness),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],

                        if (location.isNotEmpty) ...[
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
              const SizedBox(height: AppSpacing.screen),
              _ProfileStrengthCard(
                percent: profileStrength,
                onTap: () => context.push('/profile/edit'),
              ),
              const SizedBox(height: AppSpacing.section),
              // --- Menu items with staggered appear ---
              _MenuGroupLabel(label: locale.discoverySectionLabel),
              const SizedBox(height: AppSpacing.sm),
              _StaggeredMenuGroup(
                delayIndex: 0,
                child: FlatmatesCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FlatmatesMenuItem(
                        icon: Icons.add_home_outlined,
                        label: locale.profileMenuPostListing,
                        onTap: () => context.push('/manage-listings'),
                      ),
                      const Divider(
                        height: 1,
                        indent: AppSpacing.xl * 3 + AppSpacing.sm,
                        endIndent: AppSpacing.lg,
                      ),
                      FlatmatesMenuItem(
                        icon: Icons.calendar_month_outlined,
                        label: locale.profileMenuVisits,
                        onTap: () => context.push('/profile/visits'),
                      ),
                      const Divider(
                        height: 1,
                        indent: AppSpacing.xl * 3 + AppSpacing.sm,
                        endIndent: AppSpacing.lg,
                      ),
                      FlatmatesMenuItem(
                        icon: Icons.favorite_border,
                        label: locale.profileMenuShortlisted,
                        onTap: () => context.go('/chats'),
                      ),
                      const Divider(
                        height: 1,
                        indent: AppSpacing.xl * 3 + AppSpacing.sm,
                        endIndent: AppSpacing.lg,
                      ),
                      FlatmatesMenuItem(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: locale.profileMenuChats,
                        onTap: () => context.go('/chats'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.section),
              _MenuGroupLabel(label: locale.trustSectionLabel),
              const SizedBox(height: AppSpacing.sm),
              _StaggeredMenuGroup(
                delayIndex: 1,
                child: FlatmatesCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FlatmatesMenuItem(
                        icon: Icons.description_outlined,
                        label: locale.profileMenuDocuments,
                        onTap: () => context.push('/help-safety/bookings'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.section),
              _accountGroup(context, locale),
              const SizedBox(height: AppSpacing.section),
              // Group 4: Logout (standalone destructive tertiary button)
              FlatmatesButton.tertiary(
                key: const Key('logout_button'),
                label: locale.logoutCta,
                destructive: true,
                onPressed: () =>
                    ref.read(authControllerProvider.notifier).signOut(),
              ),
            ],
          );
        },
        loading: () => const FlatmatesSkeleton.profile(),
        error: (error, _) =>
            const FlatmatesErrorState(message: 'Could not load profile'),
      ),
    );
  }

  Widget _accountGroup(BuildContext context, AppLocalizations locale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _MenuGroupLabel(label: locale.accountSectionLabel),
        const SizedBox(height: AppSpacing.sm),
        _StaggeredMenuGroup(
          delayIndex: 2,
          child: FlatmatesCard(
            padding: EdgeInsets.zero,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FlatmatesMenuItem(
                  icon: Icons.settings_outlined,
                  label: locale.settingsTitle,
                  onTap: () => context.push('/profile/settings'),
                ),
                const Divider(
                  height: 1,
                  indent: AppSpacing.xl * 3 + AppSpacing.sm,
                  endIndent: AppSpacing.lg,
                ),
                FlatmatesMenuItem(
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

int _profileStrengthPercent(FlatmatesProfileModel profile) {
  final checks = <bool>[
    profile.fullName?.trim().isNotEmpty ?? false,
    profile.profileImageUrl?.trim().isNotEmpty ?? false,
    profile.city?.trim().isNotEmpty ?? false,
    profile.locality?.trim().isNotEmpty ?? false,
    profile.mode?.trim().isNotEmpty ?? false,
    profile.budgetMin != null && profile.budgetMax != null,
    profile.moveInTimeline?.trim().isNotEmpty ?? false,
    profile.bio?.trim().isNotEmpty ?? false,
    profile.cleanliness?.trim().isNotEmpty ?? false,
    profile.foodHabits?.trim().isNotEmpty ?? false,
  ];
  final completed = checks.where((value) => value).length;
  return ((completed / checks.length) * 100).round().clamp(0, 100);
}

class _ProfileStrengthCard extends StatelessWidget {
  const _ProfileStrengthCard({required this.percent, required this.onTap});

  final int percent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);

    return FlatmatesCard(
      onTap: onTap,
      borderColor: AppSemanticColors.accent.withValues(alpha: 0.16),
      backgroundColor: AppSemanticColors.accent.withValues(alpha: 0.06),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: percent / 100,
                  strokeWidth: 3.5,
                  backgroundColor: AppSemanticColors.line.withValues(
                    alpha: 0.25,
                  ),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppSemanticColors.accent,
                  ),
                ),
                Center(
                  child: Text(
                    '$percent',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppSemanticColors.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  locale.profileStrengthTitle(percent),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: _kAvatarOffset),
                Text(
                  locale.profileStrengthSubtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppSemanticColors.textSecondaryFor(theme.brightness),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: AppSemanticColors.accent,
          ),
        ],
      ),
    );
  }
}

class _MenuGroupLabel extends StatelessWidget {
  const _MenuGroupLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      label.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        color: AppSemanticColors.textTertiaryFor(theme.brightness),
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
      ),
    );
  }
}

/// Staggered fade-in for profile menu groups.
class _StaggeredMenuGroup extends StatefulWidget {
  const _StaggeredMenuGroup({required this.delayIndex, required this.child});

  final int delayIndex;
  final Widget child;

  @override
  State<_StaggeredMenuGroup> createState() => _StaggeredMenuGroupState();
}

class _StaggeredMenuGroupState extends State<_StaggeredMenuGroup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.slow);
    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.easeOutCubic,
    );
    _slideUp = Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: AppMotion.easeOutCubic),
    );

    final delay = Duration(
      milliseconds:
          300 + widget.delayIndex * AppMotion.staggerItem.inMilliseconds,
    );
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeIn,
      child: SlideTransition(position: _slideUp, child: widget.child),
    );
  }
}
