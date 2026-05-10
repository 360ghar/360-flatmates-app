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
import '../shared/presentation/flatmates_trust_badge.dart';
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
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.xl,
              ),
              children: [
                // --- Header row ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      locale.profilePageTitle,
                      style: theme.textTheme.headlineLarge,
                    ),
                    IconButton(
                      key: const Key('profile_settings_button'),
                      onPressed: () => context.push('/profile/settings'),
                      icon: const Icon(Icons.settings),
                      tooltip: 'Settings',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.section),
                // --- Compact header: avatar left, text right, whole group centered ---
                Center(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Avatar with animated ring + edit FAB
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
                      // Name, role badge, location
                      IntrinsicWidth(
                        child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            profile.fullName ?? locale.profileFallbackName,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (profile.mode != null) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.pill),
                                border: Border.all(
                                  color: AppSemanticColors.accent
                                      .withValues(alpha: 0.5),
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
                                  Text(
                                    localizedFlatmatesModeLabel(
                                        locale, profile.mode!),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppSemanticColors.accent,
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
                                Text(
                                  location,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppSemanticColors.textSecondaryFor(
                                      theme.brightness,
                                    ),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // --- Verified trust badge ---
                if (profile.profileStatus == 'verified' ||
                    profile.profileStatus == 'active')
                  Center(
                    child: FlatmatesTrustBadge(
                      label: locale.verifiedFilterLabel,
                      variant: FlatmatesTrustBadgeVariant.verified,
                    ),
                  ),
                if (profile.profileStatus == 'verified' ||
                    profile.profileStatus == 'active')
                  const SizedBox(height: AppSpacing.lg),
                // --- Menu items with staggered appear ---
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
