import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/gen/app_localizations.dart';
import '../auth/auth_controller.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../shared/presentation/flatmates_ui.dart';

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
            final location = [
              if (profile?.city != null && profile!.city!.trim().isNotEmpty)
                profile.city!.trim(),
              if (profile?.state != null && profile!.state!.trim().isNotEmpty)
                profile.state!.trim(),
            ].join(', ');
            if (profile == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        locale.profilePageTitle,
                        style: theme.textTheme.headlineLarge,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      key: const Key('profile_notifications_button'),
                      onPressed: () => context.push('/notifications'),
                      icon: const Icon(Icons.notifications_outlined),
                    ),
                    IconButton(
                      key: const Key('profile_settings_button'),
                      onPressed: () => context.push('/profile/settings'),
                      icon: const Icon(Icons.settings_outlined),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(36),
                    gradient: RadialGradient(
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                      radius: 0.8,
                    ),
                  ),
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.18,
                                ),
                                width: 2,
                              ),
                            ),
                            child: FlatmatesAvatar(
                              name: profile.fullName,
                              imageUrl: profile.profileImageUrl,
                              size: 142,
                            ),
                          ),
                          Positioned(
                            right: -6,
                            bottom: 10,
                            child: Material(
                              color: theme.colorScheme.primary,
                              shape: const CircleBorder(),
                              child: IconButton(
                                key: const Key('profile_edit_button'),
                                onPressed: () => context.push('/profile/edit'),
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Text(
                        profile.fullName ?? locale.profileFallbackName,
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontSize: 32,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (profile.mode != null) ...[
                        const SizedBox(height: 10),
                        InfoPill(
                          icon: Icons.verified_user_outlined,
                          label: localizedFlatmatesModeLabel(
                            locale,
                            profile.mode!,
                          ),
                          highlighted: true,
                        ),
                      ],
                      if (location.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 18,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                location,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (profile.bio != null &&
                          profile.bio!.trim().isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            profile.bio!,
                            style: theme.textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // --- Age & Profession ---
                if (profile.age != null || profile.profession != null) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          if (profile.age != null) ...[
                            InfoPill(
                              icon: Icons.cake_outlined,
                              label: '${profile.age} yrs',
                            ),
                            if (profile.profession != null)
                              const SizedBox(width: 12),
                          ],
                          if (profile.profession != null)
                            InfoPill(
                              icon: Icons.work_outline,
                              label: profile.profession!,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // --- Lifestyle tags ---
                if (_lifestyleEntries(profile).isNotEmpty) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            locale.workStyleTitle,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _lifestyleEntries(profile).map((entry) {
                              return FilterChip(
                                label: Text(entry),
                                selected: true,
                                onSelected: null,
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // --- Non-negotiables ---
                if (_nonNegotiableLabels(profile, locale).isNotEmpty) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            locale.nonNegotiablesTitle,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _nonNegotiableLabels(profile, locale)
                                .map((label) {
                              return FilterChip(
                                label: Text(label),
                                selected: true,
                                onSelected: null,
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // --- Budget & Timeline ---
                if (profile.budgetMin != null ||
                    profile.budgetMax != null ||
                    profile.moveInTimeline != null) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            locale.budgetTimelineTitle,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (profile.budgetMin != null ||
                                  profile.budgetMax != null)
                                InfoPill(
                                  icon: Icons.currency_rupee,
                                  label: _budgetRange(profile),
                                ),
                              if (profile.moveInTimeline != null)
                                InfoPill(
                                  icon: Icons.event_outlined,
                                  label: _timelineLabel(
                                    locale,
                                    profile.moveInTimeline!,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: locale.profileStatListings,
                        value: '${data?.activeListingCount ?? 0}',
                        icon: Icons.home_work_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: locale.profileStatChats,
                        value: '${data?.conversationCount ?? 0}',
                        icon: Icons.chat_bubble_outline_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: locale.profileStatUnread,
                        value: '${data?.unreadMessageCount ?? 0}',
                        icon: Icons.mark_chat_unread_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      _ProfileMenuTile(
                        icon: Icons.calendar_month_outlined,
                        label: locale.profileMenuVisits,
                        onTap: () => context.go('/visits'),
                      ),
                      const Divider(height: 1),
                      _ProfileMenuTile(
                        icon: Icons.favorite_border_rounded,
                        label: locale.profileMenuLikesChat,
                        onTap: () => context.go('/chats'),
                      ),
                      const Divider(height: 1),
                      _ProfileMenuTile(
                        icon: Icons.add_home_work_outlined,
                        label: locale.profileMenuPostListing,
                        onTap: () => context.go('/post'),
                      ),
                      const Divider(height: 1),
                      _ProfileMenuTile(
                        icon: Icons.person_outline,
                        label: locale.editProfileCta,
                        onTap: () => context.push('/profile/edit'),
                      ),
                      const Divider(height: 1),
                      _ProfileMenuTile(
                        icon: Icons.settings_outlined,
                        label: locale.settingsTitle,
                        onTap: () => context.push('/profile/settings'),
                      ),
                      const Divider(height: 1),
                      _ProfileMenuTile(
                        icon: Icons.help_outline,
                        label: locale.helpSafetyTitle,
                        onTap: () => context.push('/help-safety'),
                      ),
                      const Divider(height: 1),
                      _ProfileMenuTile(
                        key: const Key('logout_button'),
                        icon: Icons.logout_outlined,
                        label: locale.logoutCta,
                        labelColor: theme.colorScheme.error,
                        iconColor: theme.colorScheme.error,
                        onTap: () =>
                            ref.read(authControllerProvider.notifier).signOut(),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text(error.toString())),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 10),
            Text(value, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 6),
            Text(
              label,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      leading: Icon(icon, color: iconColor ?? theme.colorScheme.primary),
      title: Text(
        label,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: labelColor,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}

List<String> _lifestyleEntries(FlatmatesProfileModel profile) {
  final entries = <String>[];
  if (profile.sleepSchedule != null && profile.sleepSchedule!.trim().isNotEmpty) {
    entries.add(humanizeFlatmatesToken(profile.sleepSchedule!));
  }
  if (profile.cleanliness != null && profile.cleanliness!.trim().isNotEmpty) {
    entries.add(humanizeFlatmatesToken(profile.cleanliness!));
  }
  if (profile.foodHabits != null && profile.foodHabits!.trim().isNotEmpty) {
    entries.add(humanizeFlatmatesToken(profile.foodHabits!));
  }
  if (profile.smokingDrinking != null && profile.smokingDrinking!.trim().isNotEmpty) {
    entries.add(humanizeFlatmatesToken(profile.smokingDrinking!));
  }
  if (profile.guestsPolicy != null && profile.guestsPolicy!.trim().isNotEmpty) {
    entries.add(humanizeFlatmatesToken(profile.guestsPolicy!));
  }
  if (profile.workStyle != null && profile.workStyle!.trim().isNotEmpty) {
    entries.add(humanizeFlatmatesToken(profile.workStyle!));
  }
  return entries;
}

List<String> _nonNegotiableLabels(
  FlatmatesProfileModel profile,
  AppLocalizations locale,
) {
  final raw = profile.preferences['non_negotiables'];
  if (raw is! List) return const [];
  return raw
      .whereType<String>()
      .map((key) => _nonNegLabel(locale, key))
      .toList();
}

String _nonNegLabel(AppLocalizations l, String k) => switch (k) {
  'food_veg_only' => l.nonNegVegOnly,
  'no_smoking' => l.nonNegNoSmoking,
  'no_drinking' => l.nonNegNoDrinking,
  'no_overnight_guests' => l.nonNegNoGuests,
  'no_pets' => l.nonNegNoPets,
  'no_parties' => l.nonNegNoParties,
  'min_tidy' => l.nonNegMinTidy,
  _ => humanizeFlatmatesToken(k),
};

String _budgetRange(FlatmatesProfileModel profile) {
  final min = profile.budgetMin;
  final max = profile.budgetMax;
  if (min != null && max != null) {
    return '${min.toStringAsFixed(0)} - ${max.toStringAsFixed(0)}';
  } else if (min != null) {
    return 'From ${min.toStringAsFixed(0)}';
  } else {
    return 'Up to ${max!.toStringAsFixed(0)}';
  }
}

String _timelineLabel(AppLocalizations locale, String key) {
  switch (key) {
    case 'immediate':
      return locale.timelineImmediate;
    case 'this_month':
      return locale.timelineThisMonth;
    case 'next_month':
      return locale.timelineNextMonth;
    default:
      return locale.timelineFlexible;
  }
}
