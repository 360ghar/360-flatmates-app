import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../auth/auth_controller.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../shared/presentation/flatmates_card.dart';
import '../shared/presentation/flatmates_error_state.dart';
import '../shared/presentation/flatmates_ui.dart';
import '../shared/presentation/flatmates_skeleton.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrap = ref.watch(bootstrapControllerProvider);
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: bootstrap.when(
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
                Text(
                  locale.profilePageTitle,
                  style: theme.textTheme.headlineLarge,
                ),
                const SizedBox(height: AppSpacing.section),
                // --- Compact header: avatar left, text right, whole group centered ---
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                          right: -2,
                          bottom: 2,
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
                          if (profile.mode != null) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                                border: Border.all(
                                  color: AppSemanticColors.accent.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    size: 16,
                                    color: AppSemanticColors.accent,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      localizedFlatmatesModeLabel(
                                        locale,
                                        profile.mode!,
                                      ),
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: AppSemanticColors.accent,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (location.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 16,
                                  color: AppSemanticColors.textSecondaryFor(
                                    theme.brightness,
                                  ),
                                ),
                                const SizedBox(width: 6),
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
                const SizedBox(height: 32),
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
                          icon: Icons.calendar_month_outlined,
                          label: locale.profileMenuVisits,
                          onTap: () => context.push('/profile/visits'),
                        ),
                        const Divider(height: 1, indent: 68, endIndent: 16),
                        FlatmatesMenuItem(
                          icon: Icons.favorite_border,
                          label: locale.profileMenuShortlisted,
                          onTap: () => context.go('/chats'),
                        ),
                        const Divider(height: 1, indent: 68, endIndent: 16),
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
                          onTap: () {},
                        ),
                        const Divider(height: 1, indent: 68, endIndent: 16),
                        FlatmatesMenuItem(
                          icon: Icons.payment_outlined,
                          label: locale.profileMenuPaymentMethods,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.section),
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
                        const Divider(height: 1, indent: 68, endIndent: 16),
                        FlatmatesMenuItem(
                          icon: Icons.help_outline,
                          label: locale.helpSafetyTitle,
                          onTap: () => context.push('/help-safety'),
                        ),
                      ],
                    ),
                  ),
                ),
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
          loading: () => const FlatmatesSkeleton.list(),
          error: (error, _) =>
              const FlatmatesErrorState(message: 'Could not load profile'),
        ),
      ),
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
      backgroundColor: AppSemanticColors.accent.withValues(alpha: 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  locale.profileStrengthTitle(percent),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                locale.completeProfileCta,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppSemanticColors.accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: AppRadius.pillBorder,
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 8,
              backgroundColor: AppSemanticColors.line.withValues(alpha: 0.35),
              valueColor: AlwaysStoppedAnimation<Color>(
                AppSemanticColors.accent,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            locale.profileStrengthSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppSemanticColors.textSecondaryFor(theme.brightness),
            ),
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
