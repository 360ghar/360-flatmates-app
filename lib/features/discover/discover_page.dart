import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_failure.dart';
import '../../core/errors/l10n_bridge.dart';
import '../../core/location/location_data.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/debouncer.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../location/application/location_controller.dart';
import '../location/presentation/location_picker_modal.dart';
import '../shared/presentation/components.dart';
import 'discover_repository.dart';
import 'application/discover_feed_controller.dart';
import 'presentation/widgets/discover_header.dart';
import 'presentation/widgets/discover_listing_card.dart';
import 'presentation/widgets/discover_support_sections.dart';
import 'presentation/widgets/filter_sheet.dart';
import 'presentation/widgets/home_section_widgets.dart';
import 'presentation/widgets/staggered_card_appear.dart';

String _timeBasedGreeting(AppLocalizations locale, String name) {
  final hour = DateTime.now().hour;
  if (hour < 12) return locale.homeGreetingMorning(name);
  if (hour < 17) return locale.homeGreetingAfternoon(name);
  return locale.homeGreetingEvening(name);
}

class DiscoverPage extends ConsumerStatefulWidget {
  const DiscoverPage({super.key});

  @override
  ConsumerState<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends ConsumerState<DiscoverPage> {
  static const double _loadMoreThreshold = 500;
  static const double _kBottomNavOffset = 120.0;

  final _scrollController = ScrollController();
  final _likeDebouncer = ActionDebouncer();
  final _locationRadiusDebouncer = ActionDebouncer();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoDetectLocation();
    });
  }

  Future<void> _autoDetectLocation() async {
    final locState = ref.read(locationControllerProvider);
    if (locState.selectedLocation != null) {
      _applyLocationToFeed(locState.selectedLocation!);
      return;
    }
    await ref.read(locationControllerProvider.notifier).getCurrentLocation();
    final updated = ref.read(locationControllerProvider);
    if (updated.selectedLocation != null) {
      _applyLocationToFeed(updated.selectedLocation!);
      return;
    }
    final pos = updated.currentPosition;
    final address = updated.currentAddress;
    if (pos != null && address != null && address.isNotEmpty) {
      final location = LocationData(
        name: address,
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
      ref.read(locationControllerProvider.notifier).selectLocation(location);
      _applyLocationToFeed(location);
    }
  }

  void _applyLocationToFeed(LocationData location, {double? radiusKm}) {
    if (!location.latitude.isFinite ||
        !location.longitude.isFinite ||
        (location.latitude == 0 && location.longitude == 0)) {
      return;
    }

    final feedState = ref.read(discoverFeedControllerProvider);
    final effectiveRadiusKm =
        radiusKm ??
        feedState.filters.radiusKm ??
        DiscoverFeedController.defaultLocationRadiusKm;
    if (feedState.filters.latitude == location.latitude &&
        feedState.filters.longitude == location.longitude &&
        feedState.filters.radiusKm == effectiveRadiusKm) {
      return;
    }

    ref
        .read(discoverFeedControllerProvider.notifier)
        .updateLocationFilter(
          latitude: location.latitude,
          longitude: location.longitude,
          radiusKm: effectiveRadiusKm,
        );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - _loadMoreThreshold) {
      ref.read(discoverFeedControllerProvider.notifier).loadMore();
    }
  }

  /// Toggles the like for [item].
  ///
  /// The optimistic UI update, network call, and `conversationsProvider`
  /// invalidation are handled by [DiscoverFeedController.toggleLike]. This
  /// method only shows the success or error toast: it displays the
  /// "contact request sent" toast for a new like (with conversation id if
  /// one was created) and the "like removed" toast for an unlike.
  Future<void> _handleLike(PropertyListing item) async {
    final locale = AppLocalizations.of(context);
    final wasLiked = item.liked ?? false;
    try {
      final conversationId = await ref
          .read(discoverFeedControllerProvider.notifier)
          .toggleLike(item.id);
      if (!mounted) return;
      if (wasLiked) {
        FlatmatesToast.success(context, locale.likeRemovedToast);
      } else {
        FlatmatesToast.success(
          context,
          conversationId == null
              ? locale.contactRequestSent
              : locale.contactRequestWithConversation(conversationId),
        );
      }
    } catch (e) {
      debugPrint('DiscoverPage._handleLike failed: $e');
      if (!mounted) return;
      final msg = e is AppFailure
          ? e.userMessage(locale.toUserMessageL10n())
          : locale.actionFailedRetry;
      FlatmatesToast.error(context, msg);
    }
  }

  @override
  void dispose() {
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

          _applyLocationToFeed(activeLocation, radiusKm: radiusKm);
        });
      },
      onLocationSelected: (location) {
        didSelectLocation = true;
        unawaited(
          ref
              .read(locationControllerProvider.notifier)
              .selectAndPersistLocation(location),
        );
        final feedController = ref.read(
          discoverFeedControllerProvider.notifier,
        );
        if (location.latitude.isFinite &&
            location.longitude.isFinite &&
            !(location.latitude == 0 && location.longitude == 0)) {
          feedController.updateLocationFilter(
            latitude: location.latitude,
            longitude: location.longitude,
            radiusKm: selectedRadiusKm,
          );
        } else {
          // Non-finite or sentinel (0,0) coords mean the picked place lacks
          // usable geometry (e.g. a catalog city with no lat/lng meta) — fall
          // back to a text filter rather than writing an invalid geo filter.
          feedController.updateTextLocationFilter(location: location.name);
        }
        ref.invalidate(discoverListingsProvider);
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
    final filtered = ref.watch(filteredListingsProvider);
    final selectedLocation = ref.watch(
      locationControllerProvider.select((state) => state.selectedLocation),
    );

    final locality = profile?.locality?.trim();
    final city = profile?.city?.trim();
    final profileLocation = [
      if (locality != null && locality.isNotEmpty) locality,
      if (city != null && city.isNotEmpty) city,
    ].join(', ');
    final selectedDisplayText = selectedLocation?.displayText ?? '';
    final currentLocation = selectedDisplayText.isNotEmpty
        ? selectedDisplayText
        : profileLocation;
    final displayName = _firstName(
      profile?.fullName,
      fallback: locale.homeGuestName,
    );
    final currentRadiusKm =
        feedState.filters.radiusKm ??
        DiscoverFeedController.defaultLocationRadiusKm;
    final mode = profile?.mode ?? 'co_hunter';
    final isSeeker = mode != 'room_poster';

    return FlatmatesScreen(
      body: feedState.isLoading && filtered.isEmpty
          ? const FlatmatesSkeleton.discoverFeed()
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(discoverFeedControllerProvider.notifier).refresh(),
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.sm,
                  AppSpacing.xl,
                  _kBottomNavOffset,
                ),
                children: [
                  DiscoverHeader(
                    greeting: _timeBasedGreeting(locale, displayName),
                    location: currentLocation,
                    avatarUrl: profile?.profileImageUrl,
                    userName: profile?.fullName,
                    onAvatarTap: () => context.push('/profile'),
                    onLocationTap: () => _showLocationPicker(
                      context,
                      currentLocation: currentLocation,
                      currentRadiusKm: currentRadiusKm,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  HomeSearchBar(onTap: () => showFiltersSheet(context)),
                  const SizedBox(height: AppSpacing.sm),
                  if (filtered.length < 5 && city != null) ...[
                    WaitlistNudgeCard(
                      city: city,
                      listingCount: filtered.length,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  /*
                  if (isSeeker && city != null) ...[
                    HomeSectionHeader(title: locale.homeNewInCity(city)),
                    const SizedBox(height: AppSpacing.sm),
                    NewInCitySection(
                      items: filtered,
                      onExplore: () => context.go('/tab2'),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ] else */
                  if (!isSeeker) ...[
                    PostYourSpaceCard(onTap: () => context.push('/post/new')),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  if (city != null) ...[
                    TrendingNeighborhoodsSection(city: city),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  const MeetFlatmatesSection(),
                  const SizedBox(height: AppSpacing.sm),
                  MovingSoonSection(items: filtered),
                  const SizedBox(height: AppSpacing.sm),
                  HomeSectionHeader(
                    title: locale.homePickedForYou,
                    actionLabel: filtered.length > 2 ? locale.seeAllCta : null,
                    actionKey: const Key('home_picked_for_you_see_all'),
                    onActionTap: () =>
                        context.push('/discover/browse-listings'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (filtered.isEmpty && !feedState.isLoading)
                    FlatmatesEmptyState(
                      title: locale.homeNoResults,
                      subtitle: locale.homeNoResultsSubtitle,
                      icon: Icons.search_off_rounded,
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final badgeLabel = switch (index) {
                          0 => locale.badgeNew,
                          1 => locale.badgePopular,
                          _ => null,
                        };
                        return StaggeredCardAppear(
                          index: index,
                          child: DiscoverListingCard(
                            cardKey: index == 0
                                ? const Key('discover_feed_card_0')
                                : null,
                            item: item,
                            badgeLabel: badgeLabel,
                            onTap: () =>
                                context.push('/flat-details/${item.id}'),
                            onLike: () =>
                                _likeDebouncer.run(() => _handleLike(item)),
                          ),
                        );
                      },
                    ),
                  // The moved sections used to be here
                ],
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
