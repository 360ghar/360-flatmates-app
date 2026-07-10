import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/flatmates_card.dart';
import '../../../shared/presentation/flatmates_network_image.dart';
import '../../../shared/presentation/flatmates_ui.dart';
import '../../discover_repository.dart';
import '../../../swipe/application/swipe_deck_controller.dart';
import 'flatmate_profile_sheet.dart';

class NewInCitySection extends StatelessWidget {
  const NewInCitySection({
    required this.items,
    required this.onExplore,
    super.key,
  });

  final List<PropertyListing> items;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);

    return FlatmatesCard(
      onTap: onExplore,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppSemanticColors.accentSoft,
              borderRadius: AppRadius.smBorder,
            ),
            child: const Icon(
              Icons.location_city_rounded,
              size: 18,
              color: AppSemanticColors.accent,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              locale.homeNewInCity(items.first.city ?? ''),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: onExplore,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  locale.navExplore,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppSemanticColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: AppSemanticColors.accent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MovingSoonSection extends StatelessWidget {
  const MovingSoonSection({required this.items, super.key});

  final List<PropertyListing> items;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final sevenDaysFromNow = now.add(const Duration(days: 7));
    final movingSoon = items.where((item) {
      final date = item.availableFrom;
      if (date == null) return false;
      return date.isAfter(now) && date.isBefore(sevenDaysFromNow);
    }).toList();

    if (movingSoon.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          locale.homeMovingSoon,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppSemanticColors.textPrimaryFor(theme.brightness),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: movingSoon.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = movingSoon[index];
              final daysLeft = item.availableFrom!.difference(now).inDays;
              final badgeText = daysLeft == 0
                  ? locale.moveInToday
                  : locale.moveInCountdownBadge(daysLeft);
              return SizedBox(
                width: 120,
                child: FlatmatesCard(
                  onTap: () => context.push('/flat-details/${item.id}'),
                  padding: EdgeInsets.zero,
                  child: Stack(
                    children: [
                      if (item.effectiveMainImageUrl != null)
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: FlatmatesNetworkImage(
                              imageUrl: item.effectiveMainImageUrl!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.7),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: AppSpacing.sm,
                        bottom: AppSpacing.sm,
                        right: AppSpacing.sm,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              badgeText,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppSemanticColors.coralSoftFor(
                                  theme.brightness,
                                ),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.title,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class TrendingNeighborhoodsSection extends StatelessWidget {
  const TrendingNeighborhoodsSection({required this.city, super.key});
  final String city;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);

    if (city.isEmpty) return const SizedBox.shrink();

    final cityLower = city.toLowerCase();
    List<String> locations;
    if (cityLower.contains('gurgaon') || cityLower.contains('gurugram')) {
      locations = ['DLF Phase 3', 'Sector 43', 'Sector 55', 'Sector 14'];
    } else if (cityLower.contains('bangalore') ||
        cityLower.contains('bengaluru')) {
      locations = ['Koramangala', 'Indiranagar', 'HSR Layout', 'Whitefield'];
    } else if (cityLower.contains('delhi')) {
      locations = ['Vasant Kunj', 'Lajpat Nagar', 'South Ex', 'Hauz Khas'];
    } else if (cityLower.contains('mumbai')) {
      locations = ['Bandra', 'Andheri', 'Powai', 'Juhu'];
    } else {
      locations = [
        'City Center',
        'North District',
        'South District',
        'East Side',
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          locale.trendingNeighborhoodsIn(city),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppSemanticColors.textPrimaryFor(theme.brightness),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: locations.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                decoration: BoxDecoration(
                  borderRadius: AppRadius.pillBorder,
                  color: AppSemanticColors.accent.withValues(alpha: 0.08),
                  border: Border.all(
                    color: AppSemanticColors.accent.withValues(alpha: 0.15),
                  ),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.near_me_rounded,
                      size: 14,
                      color: AppSemanticColors.accent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      locations[index],
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppSemanticColors.textPrimaryFor(
                          theme.brightness,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class MeetFlatmatesSection extends ConsumerWidget {
  const MeetFlatmatesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final deckState = ref.watch(swipeDeckControllerProvider);
    final profiles = deckState.profiles;

    if (profiles.isEmpty) return const SizedBox.shrink();

    // Show up to 10 profiles on the home feed
    final displayProfiles = profiles.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).meetPotentialFlatmates,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppSemanticColors.textPrimaryFor(theme.brightness),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: displayProfiles.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
            itemBuilder: (context, index) {
              final profile = displayProfiles[index];
              final name = profile.fullName?.split(' ').first ?? 'Flatmate';
              final imageUrl =
                  profile.profileImageUrl ??
                  (profile.imageUrls.isNotEmpty
                      ? profile.imageUrls.first
                      : null);

              return SizedBox(
                width: 68,
                child: FlatmatesCard(
                  onTap: () => FlatmateProfileSheet.show(
                    context: context,
                    userId: profile.id,
                    nameFallback: profile.fullName,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2.0,
                    vertical: 4.0,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FlatmatesAvatar(
                        name: profile.fullName ?? name,
                        imageUrl: imageUrl,
                        size: 54,
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10.0,
                          fontWeight: FontWeight.w700,
                          color: AppSemanticColors.textPrimaryFor(
                            theme.brightness,
                          ),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
