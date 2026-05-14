import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/utils/debouncer.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../chats/chats_repository.dart';
import '../location/application/location_controller.dart';
import '../location/presentation/location_picker_modal.dart';
import '../shared/presentation/flatmates_empty_state.dart';
import '../shared/presentation/flatmates_search_bar.dart';
import '../shared/presentation/flatmates_skeleton.dart';
import '../shared/presentation/flatmates_ui.dart';
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
                      greeting: locale.homeGreeting(
                        profile?.fullName ?? locale.profileFallbackName,
                      ),
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
                    const SizedBox(height: AppSpacing.lg),
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
                    const SizedBox(height: AppSpacing.section),
                    if (filtered.length < 5 && city != null) ...[
                      WaitlistNudgeCard(
                        city: city,
                        listingCount: filtered.length,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                    FlatmatesSectionHeader(
                      title: locale.homePickedForYou,
                      subtitle: locale.homePickedSubtitle,
                      actionLabel: filtered.length > 2
                          ? locale.seeAllCta
                          : null,
                      onActionTap: () => context.push('/search-filters'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (filtered.isEmpty && !feedState.isLoading)
                      FlatmatesEmptyState(
                        title: locale.homeNoResults,
                        subtitle: locale.homeNoResultsSubtitle,
                        icon: Icons.search_off_rounded,
                      )
                    else
                      SizedBox(
                        height: 170,
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
                      const SizedBox(height: AppSpacing.lg),
                      FlatmatesSectionHeader(title: locale.homeNewInCity(city)),
                      const SizedBox(height: AppSpacing.md),
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
