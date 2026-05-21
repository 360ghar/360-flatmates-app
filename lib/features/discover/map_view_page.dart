import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../core/map/map_controller.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_semantic_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/debouncer.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../chats/chats_repository.dart';
import '../location/application/location_controller.dart';
import '../location/presentation/location_picker_modal.dart';
import '../location/presentation/map_widgets.dart';
import '../shared/presentation/flatmates_empty_state.dart';
import '../shared/presentation/flatmates_error_state.dart';
import '../shared/presentation/flatmates_skeleton.dart';
import 'application/discover_feed_controller.dart';
import 'discover_repository.dart';
import 'presentation/widgets/discover_listing_card.dart';
import 'presentation/widgets/map_filter_bar.dart';
import 'presentation/widgets/map_listing_sheets.dart';
import 'presentation/widgets/map_marker_builder.dart';

class MapViewPage extends ConsumerStatefulWidget {
  const MapViewPage({super.key});

  @override
  ConsumerState<MapViewPage> createState() => _MapViewPageState();
}

class _MapViewPageState extends ConsumerState<MapViewPage> {
  final _locationRadiusDebouncer = ActionDebouncer();
  final ScrollController _cardScrollController = ScrollController();

  final FlatmatesMapController _flatmatesMapController =
      FlatmatesMapController();
  List<PropertyListing>? _previousListings;
  List<PropertyListing> _currentFiltered = [];

  @override
  void dispose() {
    _cardScrollController.dispose();
    _flatmatesMapController.dispose();
    _locationRadiusDebouncer.dispose();
    super.dispose();
  }

  void _showLocationPicker(BuildContext context) {
    final feedState = ref.read(discoverFeedControllerProvider);
    final selectedLocation = ref
        .read(locationControllerProvider)
        .selectedLocation;
    final profile = ref.read(bootstrapControllerProvider).valueOrNull?.profile;

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
    final currentRadiusKm =
        feedState.filters.radiusKm ??
        DiscoverFeedController.defaultLocationRadiusKm;

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
    final feedState = ref.watch(discoverFeedControllerProvider);
    final selectedLocation = ref.watch(
      locationControllerProvider.select((s) => s.selectedLocation),
    );
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final searchRadiusKm =
        feedState.filters.radiusKm ??
        DiscoverFeedController.defaultLocationRadiusKm;
    final selectedDisplayText = selectedLocation?.displayText ?? '';

    final filtered = feedState.listings;
    _currentFiltered = filtered;

    // Frost surface colors
    final frostOverlayColor = isDark
        ? AppSemanticColors.frostOverlayDark
        : AppSemanticColors.frostOverlayLight;

    if (feedState.isLoading && feedState.listings.isEmpty) {
      return const Scaffold(body: SafeArea(child: FlatmatesSkeleton.card()));
    }

    if (feedState.hasError) {
      return Scaffold(
        body: SafeArea(
          child: FlatmatesErrorState(
            message: locale.couldNotLoadListing,
            onRetry: () =>
                ref.read(discoverFeedControllerProvider.notifier).load(),
            retryLabel: locale.commonRetry,
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Full-screen map
          Positioned.fill(
            child: _buildMap(filtered, searchRadiusKm, theme, locale),
          ),

          // Top bar overlay with frosted glass background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(
                  sigmaX: AppSemanticColors.frostBlur,
                  sigmaY: AppSemanticColors.frostBlur,
                ),
                child: Container(
                  color: frostOverlayColor,
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.screen,
                            AppSpacing.md,
                            AppSpacing.screen,
                            AppSpacing.xs,
                          ),
                          child: Row(
                            children: [
                              MapLocationChip(
                                locationName: selectedDisplayText.isNotEmpty
                                    ? selectedDisplayText
                                    : null,
                                onTap: () => _showLocationPicker(context),
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: () =>
                                    context.push('/search-filters'),
                                icon: const Icon(Icons.search_rounded),
                                style: IconButton.styleFrom(
                                  backgroundColor:
                                      theme.brightness == Brightness.dark
                                      ? AppSemanticColors.darkSurfaceElevated
                                      : AppSemanticColors.paper,
                                  foregroundColor:
                                      AppSemanticColors.textPrimaryFor(
                                        theme.brightness,
                                      ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              IconButton(
                                onPressed: () => _showFilterSheet(context),
                                icon: const Icon(Icons.tune_rounded),
                                style: IconButton.styleFrom(
                                  backgroundColor:
                                      theme.brightness == Brightness.dark
                                      ? AppSemanticColors.darkSurfaceElevated
                                      : AppSemanticColors.paper,
                                  foregroundColor:
                                      AppSemanticColors.textPrimaryFor(
                                        theme.brightness,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom draggable sheet with listing cards
          DraggableScrollableSheet(
            initialChildSize: 0.35,
            minChildSize: 0.08,
            maxChildSize: 0.45,
            snap: true,
            snapSizes: const [0.08, 0.35, 0.45],
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: frostOverlayColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.card),
                  ),
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom + 76,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Drag handle
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm,
                          ),
                          child: Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                        // Listing count
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            0,
                            AppSpacing.lg,
                            AppSpacing.sm,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: Text(
                              locale.clusterListingsCount(filtered.length),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppSemanticColors.textPrimaryFor(
                                  theme.brightness,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Horizontal card list — fixed height, own scroll
                        SizedBox(
                          height: 180,
                          child: filtered.isEmpty
                              ? FlatmatesEmptyState(
                                  title: locale.noListingsMatchFilters,
                                  icon: Icons.search_off_rounded,
                                )
                              : NotificationListener<ScrollNotification>(
                                  onNotification: (notification) {
                                    if (notification
                                            is ScrollUpdateNotification ||
                                        notification is ScrollEndNotification) {
                                      final offset =
                                          _cardScrollController.offset;
                                      final itemWidth = 130.0 + AppSpacing.sm;
                                      final index = (offset / itemWidth)
                                          .round()
                                          .clamp(0, filtered.length - 1);
                                      final visibleItem = filtered[index];
                                      final currentSelected = ref.read(
                                        selectedPropertyProvider,
                                      );
                                      if (currentSelected?.id !=
                                          visibleItem.id) {
                                        ref
                                                .read(
                                                  selectedPropertyProvider
                                                      .notifier,
                                                )
                                                .state =
                                            visibleItem;
                                      }
                                    }
                                    return false;
                                  },
                                  child: ListView.builder(
                                    controller: _cardScrollController,
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                    ),
                                    itemCount: filtered.length,
                                    itemBuilder: (context, index) {
                                      final item = filtered[index];
                                      final selectedProperty = ref.watch(
                                        selectedPropertyProvider,
                                      );
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          right: AppSpacing.sm,
                                        ),
                                        child: SizedBox(
                                          width: 130,
                                          child: DiscoverListingCard(
                                            item: item,
                                            isSelected:
                                                item.id == selectedProperty?.id,
                                            onTap: () => context.push(
                                              '/flat-details/${item.id}',
                                            ),
                                            onLike: () => _likeListing(item),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _likeListing(PropertyListing item) async {
    final locale = AppLocalizations.of(context);
    try {
      final conversationId = await ref
          .read(discoverRepositoryProvider)
          .likeListing(item.id);
      ref.invalidate(discoverListingsProvider);
      ref.invalidate(conversationsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            conversationId == null
                ? locale.contactRequestSent
                : locale.contactRequestWithConversation(conversationId),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(locale.actionFailedRetry)));
    }
  }

  Widget _buildMap(
    List<PropertyListing> filtered,
    double searchRadiusKm,
    ThemeData theme,
    AppLocalizations locale,
  ) {
    if (!identical(filtered, _previousListings)) {
      _previousListings = filtered;
    }
    final selectedPropertyId = ref.watch(
      selectedPropertyProvider.select((s) => s?.id),
    );
    final markers = buildClusteredMarkers(
      items: filtered,
      theme: theme,
      onListingTap: _handleListingTap,
      onClusterTap: _handleClusterTap,
      selectedPropertyId: selectedPropertyId?.toString(),
    );

    final selectedLocation = ref
        .read(locationControllerProvider)
        .selectedLocation;
    final feedState = ref.read(discoverFeedControllerProvider);
    LatLng mapCenter;
    if (selectedLocation != null) {
      mapCenter = LatLng(selectedLocation.latitude, selectedLocation.longitude);
    } else if (feedState.filters.hasGeoLocation) {
      mapCenter = LatLng(
        feedState.filters.latitude!,
        feedState.filters.longitude!,
      );
    } else if (markers.isNotEmpty) {
      mapCenter = markers.first.point;
    } else if (filtered.isNotEmpty &&
        filtered.first.latitude != null &&
        filtered.first.longitude != null) {
      mapCenter = LatLng(filtered.first.latitude!, filtered.first.longitude!);
    } else {
      mapCenter = const LatLng(28.4595, 77.0266);
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _flatmatesMapController.controller,
          options: MapOptions(
            initialCenter: mapCenter,
            initialZoom: kDefaultInitialZoom,
            minZoom: kDefaultMinZoom,
            maxZoom: kDefaultMaxZoom,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            createOsmTileLayer(),
            MapRadiusCircle(center: mapCenter, radiusKm: searchRadiusKm),
            MarkerLayer(markers: markers),
          ],
        ),
        Positioned(
          right: AppSpacing.md,
          top: AppSpacing.md,
          child: MapControlButtons(
            onRecenter: _recenterToUserLocation,
            onFitBounds: _fitBoundsToMarkers,
            onZoomIn: () => _flatmatesMapController.zoomIn(),
            onZoomOut: () => _flatmatesMapController.zoomOut(),
          ),
        ),
        if (markers.isEmpty)
          FlatmatesEmptyState(
            title: filtered.isEmpty
                ? locale.emptyListings
                : locale.noListingsMatchFilters,
            icon: Icons.map_outlined,
          ),
      ],
    );
  }

  void _showFilterSheet(BuildContext context) {
    context.push('/search-filters');
  }

  void _handleListingTap(PropertyListing item) {
    ref.read(selectedPropertyProvider.notifier).state = item;

    if (item.latitude != null && item.longitude != null) {
      _flatmatesMapController.move(
        LatLng(item.latitude!, item.longitude!),
        15.0,
      );
    }

    final index = _currentFiltered.indexWhere((e) => e.id == item.id);
    if (index >= 0 && _cardScrollController.hasClients) {
      final itemWidth = 130.0 + AppSpacing.sm;
      _cardScrollController.animateTo(
        index * itemWidth,
        duration: AppMotion.standard,
        curve: AppMotion.easeOutCubic,
      );
    }
  }

  void _handleClusterTap(List<PropertyListing> clusterItems) {
    showClusterSheet(
      context,
      clusterItems: clusterItems,
      onListingTap: _handleListingTap,
    );
  }

  void _recenterToUserLocation() async {
    final locState = ref.read(locationControllerProvider);
    if (locState.currentPosition != null) {
      final pos = locState.currentPosition!;
      final center = LatLng(pos.latitude, pos.longitude);
      _flatmatesMapController.move(center, kDefaultInitialZoom);
      ref
          .read(discoverFeedControllerProvider.notifier)
          .updateLocationFilter(
            latitude: pos.latitude,
            longitude: pos.longitude,
            radiusKm:
                ref.read(discoverFeedControllerProvider).filters.radiusKm ??
                DiscoverFeedController.defaultLocationRadiusKm,
          );
    } else {
      await ref.read(locationControllerProvider.notifier).getCurrentLocation();
      final newPos = ref.read(locationControllerProvider).currentPosition;
      if (newPos != null) {
        final center = LatLng(newPos.latitude, newPos.longitude);
        _flatmatesMapController.move(center, kDefaultInitialZoom);
        ref
            .read(discoverFeedControllerProvider.notifier)
            .updateLocationFilter(
              latitude: newPos.latitude,
              longitude: newPos.longitude,
              radiusKm:
                  ref.read(discoverFeedControllerProvider).filters.radiusKm ??
                  DiscoverFeedController.defaultLocationRadiusKm,
            );
      }
    }
  }

  void _fitBoundsToMarkers() {
    if (_previousListings == null || _previousListings!.isEmpty) return;
    final points = _previousListings!
        .where((item) => item.latitude != null && item.longitude != null)
        .map((item) => LatLng(item.latitude!, item.longitude!))
        .toList();
    _flatmatesMapController.fitBounds(points);
  }
}
