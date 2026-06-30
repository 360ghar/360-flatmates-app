import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../core/errors/app_failure.dart';
import '../../core/errors/l10n_bridge.dart';
import '../../core/location/location_data.dart';
import '../../core/map/map_controller.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_semantic_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/debouncer.dart';
import '../shared/presentation/components.dart';
import '../../l10n/gen/app_localizations.dart';
import '../location/application/location_controller.dart';
import '../location/presentation/map_widgets.dart';
import 'application/map_listings_controller.dart';
import 'discover_repository.dart';
import 'presentation/widgets/discover_map.dart';
import 'presentation/widgets/filter_sheet.dart';
import 'presentation/widgets/map_filter_bar.dart';
import 'presentation/widgets/map_listing_sheets.dart';
import 'presentation/widgets/map_listings_bottom_sheet.dart';
import 'presentation/widgets/map_location_picker.dart';

class MapViewPage extends ConsumerStatefulWidget {
  const MapViewPage({super.key});

  @override
  ConsumerState<MapViewPage> createState() => _MapViewPageState();
}

class _MapViewPageState extends ConsumerState<MapViewPage> {
  final _locationRadiusDebouncer = ActionDebouncer();
  final ScrollController _cardScrollController = ScrollController();
  int _scrollAnimGen = 0;
  bool _autoLocationRunning = false;

  // Bound once the DiscoverMap hands back its controller via onMapReady.
  FlatmatesMapController? _mapController;

  List<PropertyListing> _currentFiltered = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureLocationData();
    });
  }

  void _ensureLocationData() {
    final mapState = ref.read(mapListingsProvider);
    if (mapState.filters.hasGeoLocation) return;

    final selectedLocation = ref
        .read(locationControllerProvider)
        .selectedLocation;
    if (selectedLocation != null) {
      ref
          .read(mapListingsProvider.notifier)
          .updateLocationFilter(
            latitude: selectedLocation.latitude,
            longitude: selectedLocation.longitude,
            radiusKm: MapListingsController.defaultLocationRadiusKm,
          );
      return;
    }

    if (_autoLocationRunning) return;
    _autoLocationRunning = true;

    ref.read(locationControllerProvider.notifier).getCurrentLocation().then((
      _,
    ) {
      _autoLocationRunning = false;
      if (!mounted) return;
      if (ref.read(locationControllerProvider).selectedLocation != null) return;

      final locState = ref.read(locationControllerProvider);
      final pos = locState.currentPosition;
      final address = locState.currentAddress;
      if (pos != null && address != null && address.isNotEmpty) {
        final location = LocationData(
          name: address,
          latitude: pos.latitude,
          longitude: pos.longitude,
        );
        ref.read(locationControllerProvider.notifier).selectLocation(location);
        if (!ref.read(mapListingsProvider).filters.hasGeoLocation) {
          ref
              .read(mapListingsProvider.notifier)
              .updateLocationFilter(
                latitude: location.latitude,
                longitude: location.longitude,
                radiusKm: MapListingsController.defaultLocationRadiusKm,
              );
        }
      }
    });
  }

  @override
  void dispose() {
    ref.read(mapProgrammaticScrollProvider.notifier).state = false;
    _cardScrollController.dispose();
    _locationRadiusDebouncer.dispose();
    super.dispose();
  }

  void _showLocationPicker(BuildContext context) {
    showMapLocationPicker(context, ref, debouncer: _locationRadiusDebouncer);
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapListingsProvider);
    final selectedLocation = ref.watch(
      locationControllerProvider.select((s) => s.selectedLocation),
    );

    // Re-center map when the user picks a new location.
    ref.listen<LocationState>(locationControllerProvider, (prev, next) {
      final prevLoc = prev?.selectedLocation;
      final nextLoc = next.selectedLocation;
      if (nextLoc != null &&
          (prevLoc?.latitude != nextLoc.latitude ||
              prevLoc?.longitude != nextLoc.longitude)) {
        _mapController?.animateTo(LatLng(nextLoc.latitude, nextLoc.longitude));
      }
    });

    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final currentPosition = ref.watch(
      locationControllerProvider.select((s) => s.currentPosition),
    );
    final userLocation = currentPosition != null
        ? LatLng(currentPosition.latitude, currentPosition.longitude)
        : null;
    final selectedDisplayText = selectedLocation?.displayText ?? '';

    final filtered = ref.watch(filteredMapListingsProvider);
    _currentFiltered = filtered;

    final frostOverlayColor = isDark
        ? AppSemanticColors.frostOverlayDark
        : AppSemanticColors.frostOverlayLight;

    if (mapState.isLoading && mapState.listings.isEmpty) {
      return const Scaffold(body: FlatmatesSkeleton.mapExplore());
    }

    if (mapState.hasError) {
      return Scaffold(
        body: SafeArea(
          child: FlatmatesErrorState(
            message: locale.couldNotLoadListing,
            onRetry: () => ref.read(mapListingsProvider.notifier).load(),
            retryLabel: locale.commonRetry,
          ),
        ),
      );
    }

    final safeAreaTop = MediaQuery.of(context).padding.top;
    // Top bar internal height: md (top) + 48 (icon button) + xs (bottom) ≈ 64
    const topBarContentHeight = AppSpacing.md + 48.0 + AppSpacing.xs;
    final controlsTopOffset = safeAreaTop + topBarContentHeight + AppSpacing.lg;

    return Scaffold(
      body: Stack(
        children: [
          // Full-screen map
          Positioned.fill(
            child: _buildMap(filtered, userLocation, locale, isDark),
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
                              Flexible(
                                child: MapLocationChip(
                                  locationName: selectedDisplayText.isNotEmpty
                                      ? selectedDisplayText
                                      : null,
                                  onTap: () => _showLocationPicker(context),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              // The map page has no standalone text-search
                              // surface — search lives inside the filter
                              // sheet (its top field) — so we expose a single
                              // filter affordance rather than two duplicate
                              // buttons. Kept on the right of the location chip.
                              IconButton(
                                onPressed: () => _showFilterSheet(context),
                                icon: const Icon(AppIcons.filter),
                                tooltip: locale.searchFiltersTitle,
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

          // Map controls — positioned in the safe zone below the top bar
          Positioned(
            right: AppSpacing.screen,
            top: controlsTopOffset,
            child: MapControlButtons(
              onRecenter: _recenterToUserLocation,
              onFitBounds: _fitBoundsToMarkers,
              onZoomIn: () => _mapController?.zoomIn(),
              onZoomOut: () => _mapController?.zoomOut(),
            ),
          ),

          // Bottom draggable sheet with listing cards
          MapListingsBottomSheet(
            listings: filtered,
            scrollController: _cardScrollController,
            onTap: (item) => context.push('/flat-details/${item.id}'),
            onLike: _likeListing,
          ),
        ],
      ),
    );
  }

  Future<void> _likeListing(PropertyListing item) async {
    final locale = AppLocalizations.of(context);
    try {
      final conversationId = await ref
          .read(mapListingsProvider.notifier)
          .setLiked(item.id, true);
      if (!mounted) return;
      FlatmatesToast.success(
        context,
        conversationId == null
            ? locale.contactRequestSent
            : locale.contactRequestWithConversation(conversationId),
      );
    } catch (e) {
      debugPrint('MapViewPage._handleContact failed: $e');
      if (!mounted) return;
      final msg = e is AppFailure
          ? e.userMessage(locale.toUserMessageL10n())
          : locale.actionFailedRetry;
      FlatmatesToast.error(context, msg);
    }
  }

  Widget _buildMap(
    List<PropertyListing> filtered,
    LatLng? userLocation,
    AppLocalizations locale,
    bool isDark,
  ) {
    final selectedPropertyId = ref.watch(
      selectedPropertyProvider.select((s) => s?.id),
    );
    final hasMarkers = filtered.any(
      (item) => item.latitude != null && item.longitude != null,
    );

    return Stack(
      children: [
        DiscoverMap(
          listings: filtered,
          initialCenter: _resolveCenter(filtered),
          userLocation: userLocation,
          selectedPropertyId: selectedPropertyId?.toString(),
          onMapReady: (controller) => _mapController = controller,
          onListingTap: _handleListingTap,
          onClusterTap: _handleClusterTap,
        ),
        if (!hasMarkers)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                color: isDark
                    ? AppSemanticColors.darkSurface.withValues(alpha: 0.7)
                    : Colors.white.withValues(alpha: 0.7),
                child: FlatmatesEmptyState(
                  title: filtered.isEmpty
                      ? locale.emptyListings
                      : locale.noListingsMatchFilters,
                  icon: Icons.map_outlined,
                ),
              ),
            ),
          ),
      ],
    );
  }

  LatLng _resolveCenter(List<PropertyListing> filtered) {
    final selectedLocation = ref
        .read(locationControllerProvider)
        .selectedLocation;
    final mapState = ref.read(mapListingsProvider);
    if (selectedLocation != null) {
      return LatLng(selectedLocation.latitude, selectedLocation.longitude);
    }
    if (mapState.filters.hasGeoLocation) {
      return LatLng(mapState.filters.latitude!, mapState.filters.longitude!);
    }
    for (final item in filtered) {
      if (item.latitude != null && item.longitude != null) {
        return LatLng(item.latitude!, item.longitude!);
      }
    }
    return const LatLng(28.4595, 77.0266);
  }

  void _showFilterSheet(BuildContext context) {
    showFiltersSheet(context);
  }

  void _handleListingTap(PropertyListing item) {
    ref.read(selectedPropertyProvider.notifier).state = item;

    if (item.latitude != null && item.longitude != null) {
      _mapController?.move(LatLng(item.latitude!, item.longitude!), 15.0);
    }

    final index = _currentFiltered.indexWhere((e) => e.id == item.id);
    if (index >= 0 && _cardScrollController.hasClients) {
      final viewportWidth = MediaQuery.sizeOf(context).width;
      const itemWidth = 130.0;
      const padding = AppSpacing.md;
      const spacing = AppSpacing.sm;
      const totalItemWidth = itemWidth + spacing;

      final targetCenterOffset =
          padding + index * totalItemWidth + itemWidth / 2;
      var targetOffset = targetCenterOffset - viewportWidth / 2;

      final maxScroll = _cardScrollController.position.maxScrollExtent;
      final minScroll = _cardScrollController.position.minScrollExtent;
      targetOffset = targetOffset.clamp(minScroll, maxScroll);

      final gen = ++_scrollAnimGen;
      ref.read(mapProgrammaticScrollProvider.notifier).state = true;
      _cardScrollController
          .animateTo(
            targetOffset,
            duration: AppMotion.standard,
            curve: AppMotion.easeOutCubic,
          )
          .whenComplete(() {
            if (mounted && _scrollAnimGen == gen) {
              ref.read(mapProgrammaticScrollProvider.notifier).state = false;
            }
          });
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
      await _mapController?.move(
        LatLng(pos.latitude, pos.longitude),
        kDefaultInitialZoom,
      );
      ref
          .read(mapListingsProvider.notifier)
          .updateLocationFilter(
            latitude: pos.latitude,
            longitude: pos.longitude,
            radiusKm:
                ref.read(mapListingsProvider).filters.radiusKm ??
                MapListingsController.defaultLocationRadiusKm,
          );
    } else {
      await ref.read(locationControllerProvider.notifier).getCurrentLocation();
      final newPos = ref.read(locationControllerProvider).currentPosition;
      if (newPos != null) {
        await _mapController?.move(
          LatLng(newPos.latitude, newPos.longitude),
          kDefaultInitialZoom,
        );
        ref
            .read(mapListingsProvider.notifier)
            .updateLocationFilter(
              latitude: newPos.latitude,
              longitude: newPos.longitude,
              radiusKm:
                  ref.read(mapListingsProvider).filters.radiusKm ??
                  MapListingsController.defaultLocationRadiusKm,
            );
      }
    }
  }

  void _fitBoundsToMarkers() {
    final points = _currentFiltered
        .where((item) => item.latitude != null && item.longitude != null)
        .map((item) => LatLng(item.latitude!, item.longitude!))
        .toList();
    _mapController?.fitBounds(points);
  }
}
