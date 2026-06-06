import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../core/location/location_data.dart';
import '../../core/map/map_controller.dart';
import '../../core/theme/app_motion.dart';
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
import 'application/map_listings_controller.dart';
import 'discover_repository.dart';
import 'presentation/widgets/discover_map.dart';
import 'presentation/widgets/map_filter_bar.dart';
import 'presentation/widgets/map_listing_sheets.dart';
import 'presentation/widgets/map_listings_bottom_sheet.dart';

class MapViewPage extends ConsumerStatefulWidget {
  const MapViewPage({super.key});

  @override
  ConsumerState<MapViewPage> createState() => _MapViewPageState();
}

class _MapViewPageState extends ConsumerState<MapViewPage> {
  final _locationRadiusDebouncer = ActionDebouncer();
  final ScrollController _cardScrollController = ScrollController();

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

    final selectedLocation = ref.read(locationControllerProvider).selectedLocation;
    if (selectedLocation != null) {
      ref.read(mapListingsProvider.notifier).updateLocationFilter(
        latitude: selectedLocation.latitude,
        longitude: selectedLocation.longitude,
        radiusKm: MapListingsController.defaultLocationRadiusKm,
      );
      return;
    }

    ref.read(locationControllerProvider.notifier).getCurrentLocation().then((_) {
      if (!mounted) return;
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
          ref.read(mapListingsProvider.notifier).updateLocationFilter(
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
    _cardScrollController.dispose();
    _locationRadiusDebouncer.dispose();
    super.dispose();
  }

  void _showLocationPicker(BuildContext context) {
    final mapState = ref.read(mapListingsProvider);
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
        mapState.filters.radiusKm ??
        MapListingsController.defaultLocationRadiusKm;

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
              .read(mapListingsProvider.notifier)
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
            .read(mapListingsProvider.notifier)
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

    final searchRadiusKm =
        mapState.filters.radiusKm ??
        MapListingsController.defaultLocationRadiusKm;
    final selectedDisplayText = selectedLocation?.displayText ?? '';

    final filtered = mapState.listings;
    _currentFiltered = filtered;

    final frostOverlayColor = isDark
        ? AppSemanticColors.frostOverlayDark
        : AppSemanticColors.frostOverlayLight;

    if (mapState.isLoading && mapState.listings.isEmpty) {
      return const Scaffold(body: SafeArea(child: FlatmatesSkeleton.card()));
    }

    if (mapState.hasError) {
      return Scaffold(
        body: SafeArea(
          child: FlatmatesErrorState(
            message: locale.couldNotLoadListing,
            onRetry: () =>
                ref.read(mapListingsProvider.notifier).load(),
            retryLabel: locale.commonRetry,
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Full-screen map
          Positioned.fill(child: _buildMap(filtered, searchRadiusKm, locale, isDark)),

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

  void _likeListing(PropertyListing item) async {
    final locale = AppLocalizations.of(context);
    try {
      final conversationId = await ref
          .read(discoverRepositoryProvider)
          .likeListing(item.id);
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
    } catch (e) {
      debugPrint('MapViewPage._handleContact failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(locale.actionFailedRetry)));
    }
  }

  Widget _buildMap(
    List<PropertyListing> filtered,
    double searchRadiusKm,
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
          searchRadiusKm: searchRadiusKm,
          initialCenter: _resolveCenter(filtered),
          selectedPropertyId: selectedPropertyId?.toString(),
          onMapReady: (controller) => _mapController = controller,
          onListingTap: _handleListingTap,
          onClusterTap: _handleClusterTap,
        ),
        Positioned(
          right: AppSpacing.md,
          top: AppSpacing.md,
          child: MapControlButtons(
            onRecenter: _recenterToUserLocation,
            onFitBounds: _fitBoundsToMarkers,
            onZoomIn: () => _mapController?.zoomIn(),
            onZoomOut: () => _mapController?.zoomOut(),
          ),
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
    context.push('/search-filters');
  }

  void _handleListingTap(PropertyListing item) {
    ref.read(selectedPropertyProvider.notifier).state = item;

    if (item.latitude != null && item.longitude != null) {
      _mapController?.move(LatLng(item.latitude!, item.longitude!), 15.0);
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
      _mapController?.move(
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
        _mapController?.move(
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
