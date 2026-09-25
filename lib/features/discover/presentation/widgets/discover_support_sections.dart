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
import '../../../swipe/swipe_repository.dart';
import 'flatmate_profile_sheet.dart';

/// Lightweight home-rail profiles. Intentionally separate from
/// [swipeDeckControllerProvider] so opening Discover does not prime the full
/// swipe deck (and its 20-profile page load).
final homeMeetProfilesProvider = FutureProvider.autoDispose<List<SwipeProfile>>(
  (ref) async {
    final filters = ref.watch(discoverFiltersProvider);
    final page = await ref
        .read(swipeRepositoryProvider)
        .fetchSwipeProfilesPage(filters: filters, limit: 10);
    return page.items;
  },
);

/// Profiles whose available-from date falls within the next 7 days.
List<PropertyListing> movingSoonItems(List<PropertyListing> items) {
  final now = DateTime.now();
  final sevenDaysFromNow = now.add(const Duration(days: 7));
  return items.where((item) {
    final date = item.availableFrom;
    if (date == null) return false;
    return date.isAfter(now) && date.isBefore(sevenDaysFromNow);
  }).toList();
}

class MovingSoonSection extends StatelessWidget {
  const MovingSoonSection({required this.items, super.key});

  final List<PropertyListing> items;

  @override
  Widget build(BuildContext context) {
    final movingSoon = movingSoonItems(items);

    if (movingSoon.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          locale.homeMovingSoon,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppSemanticColors.textPrimaryFor(theme.brightness),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: AppSpacing.scaled(context, 140),
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
                  bordered: false,
                  child: Stack(
                    children: [
                      if (item.effectiveMainImageUrl != null)
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: FlatmatesNetworkImage(
                              imageUrl: item.effectiveMainImageUrl!,
                              width: 120,
                              height: 140,
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
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppSemanticColors.onScrim,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.title,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppSemanticColors.onScrim,
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

class MeetFlatmatesSection extends ConsumerWidget {
  const MeetFlatmatesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profilesAsync = ref.watch(homeMeetProfilesProvider);
    final displayProfiles = profilesAsync.valueOrNull ?? const <SwipeProfile>[];

    // A failed load shows an inline retry instead of silently hiding the
    // section. Loading and a genuinely empty list stay hidden.
    if (displayProfiles.isEmpty && profilesAsync.hasError) {
      final locale = AppLocalizations.of(context);
      return Row(
        children: [
          Expanded(
            child: Text(
              locale.couldNotLoadContent,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          FlatmatesButton.tertiary(
            label: locale.commonRetry,
            onPressed: () => ref.invalidate(homeMeetProfilesProvider),
          ),
        ],
      );
    }
    if (displayProfiles.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).meetPotentialFlatmates,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppSemanticColors.textPrimaryFor(theme.brightness),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: AppSpacing.scaled(context, 112),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: displayProfiles.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
            itemBuilder: (context, index) {
              final profile = displayProfiles[index];
              final name =
                  profile.fullName?.split(' ').first ??
                  AppLocalizations.of(context).matchPeerFallbackName;
              final imageUrl =
                  profile.profileImageUrl ??
                  (profile.imageUrls.isNotEmpty
                      ? profile.imageUrls.first
                      : null);

              return SizedBox(
                width: 80,
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
                  bordered: false,
                  elevation: 0,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FlatmatesAvatar(
                        name: profile.fullName ?? name,
                        imageUrl: imageUrl,
                        size: 68,
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontSize: 13.0,
                          fontWeight: FontWeight.w500,
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
