import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_semantic_colors.dart';
import '../../core/utils/debouncer.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../chats/chats_repository.dart';
import '../location/application/location_controller.dart';
import '../location/presentation/location_picker_modal.dart';
import '../shared/presentation/flatmates_empty_state.dart';
import '../shared/presentation/flatmates_card.dart';
import '../shared/presentation/flatmates_search_bar.dart';
import '../shared/presentation/flatmates_skeleton.dart';
import 'discover_repository.dart';
import 'application/discover_feed_controller.dart';
import 'presentation/widgets/discover_filter_chips.dart';
import 'presentation/widgets/discover_header.dart';
import 'presentation/widgets/discover_listing_card.dart';
import 'presentation/widgets/discover_support_sections.dart';
import 'presentation/widgets/staggered_card_appear.dart';

class DiscoverPage extends ConsumerStatefulWidget {
  const DiscoverPage({super.key});

  @override
  ConsumerState<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends ConsumerState<DiscoverPage> {
  static const double _loadMoreThreshold = 500;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _likeDebouncer = ActionDebouncer(
    duration: const Duration(milliseconds: 500),
  );
  final _locationRadiusDebouncer = ActionDebouncer();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - _loadMoreThreshold) {
      ref.read(discoverFeedControllerProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _likeDebouncer.dispose();
    _locationRadiusDebouncer.dispose();
    super.dispose();
  }

  void _showLocationPicker(
    BuildContext context, {
    required String currentLocation,
    required double currentRadiusKm,
  }) {
    var selectedRadiusKm = currentRadiusKm;
    var didSelectLocation = false;

    showLocationPickerModal(
      context,
      currentLocationName: currentLocation,
      currentRadius: currentRadiusKm,
      onRadiusChanged: (radiusKm) {
        selectedRadiusKm = radiusKm;
        _locationRadiusDebouncer.run(() {
          if (!mounted || didSelectLocation) return;

          final activeLocation = ref
              .read(locationControllerProvider)
              .selectedLocation;
          if (activeLocation == null) return;

          ref
              .read(discoverFeedControllerProvider.notifier)
              .updateLocationFilter(
                latitude: activeLocation.latitude,
                longitude: activeLocation.longitude,
                radiusKm: radiusKm,
              );
        });
      },
      onLocationSelected: (location) {
        didSelectLocation = true;
        ref.read(locationControllerProvider.notifier).selectLocation(location);
        ref
            .read(discoverFeedControllerProvider.notifier)
            .updateLocationFilter(
              latitude: location.latitude,
              longitude: location.longitude,
              radiusKm: selectedRadiusKm,
            );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(
      bootstrapControllerProvider.select((s) => s.valueOrNull?.profile),
    );
    final locale = AppLocalizations.of(context);
    final feedState = ref.watch(discoverFeedControllerProvider);
    final filtered = ref.watch(filteredListingsProvider(locale));
    final bedroomOptions = ref.watch(bedroomOptionsProvider);
    final featureOptions = ref.watch(featureOptionsProvider(locale));
    final selectedLocation = ref.watch(
      locationControllerProvider.select((state) => state.selectedLocation),
    );

    final locality = profile?.locality?.trim();
    final city = profile?.city?.trim();
    final profileLocation = [
      if (locality != null && locality.isNotEmpty) locality,
      if (city != null && city.isNotEmpty) city,
    ].join(', ');
    final currentLocation = selectedLocation?.displayText ?? profileLocation;
    final counterLocation = selectedLocation?.displayText ?? city;
    final subtitleCity = (city != null && city.isNotEmpty)
        ? city
        : currentLocation.isNotEmpty
        ? currentLocation
        : 'Gurugram';
    final displayName = _firstName(
      profile?.fullName,
      fallback: locale.homeGuestName,
    );
    final currentRadiusKm =
        feedState.filters.radiusKm ??
        DiscoverFeedController.defaultLocationRadiusKm;

    return Scaffold(
      body: SafeArea(
        child: feedState.isLoading && filtered.isEmpty
            ? const Center(child: FlatmatesSkeleton.feed())
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(discoverFeedControllerProvider.notifier).refresh(),
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.lg,
                    AppSpacing.xl,
                    120,
                  ),
                  children: [
                    DiscoverHeader(
                      greeting: locale.homeGreeting(displayName),
                      subtitle: locale.homeSubtitle(subtitleCity),
                      location: currentLocation,
                      avatarUrl: profile?.profileImageUrl,
                      userName: profile?.fullName,
                      cityCounterLabel:
                          counterLocation == null || counterLocation.isEmpty
                          ? null
                          : locale.cityCounter(
                              filtered.length,
                              counterLocation,
                            ),
                      onLocationTap: () => _showLocationPicker(
                        context,
                        currentLocation: currentLocation,
                        currentRadiusKm: currentRadiusKm,
                      ),
                      onNotificationTap: () => context.push('/notifications'),
                      onAvatarTap: () => context.push('/profile'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: FlatmatesSearchBar(
                            controller: _searchController,
                            hint: locale.homeSearchHint,
                            onChanged: (v) {
                              ref
                                  .read(discoverFeedControllerProvider.notifier)
                                  .updateSearchQuery(v);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton.filledTonal(
                          key: const Key('discover_filter_tune'),
                          onPressed: () => context.push('/search-filters'),
                          icon: const Icon(Icons.tune_rounded),
                        ),
                      ],
                    ),
                    if (filtered.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _MarketInsightCard(
                        count: filtered.length,
                        onTap: () => context.go('/swipe'),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    DiscoverFilterChips(
                      bedroomOptions: bedroomOptions,
                      featureOptions: featureOptions,
                      selectedBedrooms: feedState.filters.bedrooms,
                      selectedFeature: feedState.filters.features.firstOrNull,
                      selectedVibe: feedState.filters.vibe,
                      selectedMoveIn: feedState.filters.moveInTimeline,
                      onBedroomsChanged: (value) {
                        ref
                            .read(discoverFeedControllerProvider.notifier)
                            .updateBedrooms(value);
                      },
                      onFeatureChanged: (value) {
                        ref
                            .read(discoverFeedControllerProvider.notifier)
                            .updateFeature(value);
                      },
                      onVibeChanged: (value) {
                        ref
                            .read(discoverFeedControllerProvider.notifier)
                            .updateVibe(value);
                      },
                      onMoveInChanged: (value) {
                        ref
                            .read(discoverFeedControllerProvider.notifier)
                            .updateMoveInTimeline(value);
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (filtered.length < 5 && city != null) ...[
                      WaitlistNudgeCard(
                        city: city,
                        listingCount: filtered.length,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                    _HomeSectionHeader(
                      title: locale.homePickedForYou,
                      actionLabel: filtered.length > 2
                          ? locale.seeAllCta
                          : null,
                      onActionTap: () => context.push('/search-filters'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (filtered.isEmpty && !feedState.isLoading)
                      FlatmatesEmptyState(
                        title: locale.homeNoResults,
                        subtitle: locale.homeNoResultsSubtitle,
                        icon: Icons.search_off_rounded,
                      )
                    else
                      SizedBox(
                        height: 160,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount:
                              filtered.length +
                              (feedState.isLoadingMore ? 1 : 0),
                          separatorBuilder: (_, _) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            if (index >= filtered.length) {
                              return const SizedBox(
                                width: 200,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            final item = filtered[index];
                            final badgeLabel = switch (index) {
                              0 => locale.badgeNew,
                              1 => locale.badgePopular,
                              _ =>
                                item.interestCount > 1
                                    ? locale.badgeTrending
                                    : null,
                            };
                            final cardWidth =
                                MediaQuery.of(context).size.width -
                                AppSpacing.xl * 2;
                            return StaggeredCardAppear(
                              index: index,
                              child: SizedBox(
                                width: cardWidth,
                                child: DiscoverListingCard(
                                  item: item,
                                  badgeLabel: badgeLabel,
                                  onLike: () {
                                    _likeDebouncer.run(() {
                                      ref
                                          .read(discoverRepositoryProvider)
                                          .likeListing(item.id)
                                          .then((conversationId) {
                                            ref
                                                .read(
                                                  discoverFeedControllerProvider
                                                      .notifier,
                                                )
                                                .refresh();
                                            ref.invalidate(
                                              conversationsProvider,
                                            );
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  conversationId == null
                                                      ? locale
                                                            .contactRequestSent
                                                      : locale
                                                            .contactRequestWithConversation(
                                                              conversationId,
                                                            ),
                                                ),
                                              ),
                                            );
                                          })
                                          .catchError((_) {
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  locale.actionFailedRetry,
                                                ),
                                              ),
                                            );
                                          });
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    if (city != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      _HomeSectionHeader(title: locale.homeNewInCity(city)),
                      const SizedBox(height: AppSpacing.sm),
                      NewInCitySection(
                        items: filtered,
                        onExplore: () => context.go('/map'),
                      ),
                    ],
                    MovingSoonSection(items: filtered),
                  ],
                ),
              ),
      ),
    );
  }
}

String _firstName(String? fullName, {required String fallback}) {
  final trimmed = fullName?.trim();
  if (trimmed == null || trimmed.isEmpty) return fallback;
  return trimmed.split(RegExp(r'\s+')).first;
}

class _MarketInsightCard extends StatelessWidget {
  const _MarketInsightCard({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);

    return FlatmatesCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      borderColor: AppSemanticColors.accent.withValues(alpha: 0.16),
      backgroundColor: AppSemanticColors.accent.withValues(alpha: 0.08),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppSemanticColors.accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.verified_user_outlined,
              color: AppSemanticColors.accent,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  locale.homeMarketInsight(count),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppSemanticColors.textPrimaryFor(theme.brightness),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  locale.homeMarketInsightCta,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppSemanticColors.accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Icon(
            Icons.chevron_right_rounded,
            color: AppSemanticColors.accent,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _HomeSectionHeader extends StatelessWidget {
  const _HomeSectionHeader({
    required this.title,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppSemanticColors.textPrimaryFor(theme.brightness),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (actionLabel != null) ...[
          const SizedBox(width: AppSpacing.sm),
          TextButton(
            onPressed: onActionTap,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            ),
            child: Text(
              actionLabel!,
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppSemanticColors.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
