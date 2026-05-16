import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../core/map/map_controller.dart';
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
import '../shared/presentation/flatmates_search_bar.dart';
import '../shared/presentation/flatmates_skeleton.dart';
import 'application/discover_feed_controller.dart';
import 'application/move_in_filter.dart';
import 'discover_repository.dart';
import 'presentation/widgets/map_filter_bar.dart';
import 'presentation/widgets/map_listing_sheets.dart';
import 'presentation/widgets/map_marker_builder.dart';

class MapViewPage extends ConsumerStatefulWidget {
  const MapViewPage({super.key});

  @override
  ConsumerState<MapViewPage> createState() => _MapViewPageState();
}

class _MapViewPageState extends ConsumerState<MapViewPage> {
  double _budgetMin = 5000;
  double _budgetMax = 100000;
  String _roomType = 'all';
  String _moveInFilter = 'all';
  String _genderPref = 'any';
  bool _verifiedOnly = false;
  final _searchController = TextEditingController();
  final _locationRadiusDebouncer = ActionDebouncer();

  final FlatmatesMapController _flatmatesMapController =
      FlatmatesMapController();
  List<PropertyListing>? _previousListings;

  @override
  void dispose() {
    _searchController.dispose();
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

    final searchRadiusKm =
        feedState.filters.radiusKm ??
        DiscoverFeedController.defaultLocationRadiusKm;
    final selectedDisplayText = selectedLocation?.displayText ?? '';

    return Scaffold(
      body: SafeArea(
        child: Column(
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
                  _MapLocationChip(
                    locationName: selectedDisplayText.isNotEmpty
                        ? selectedDisplayText
                        : null,
                    onTap: () => _showLocationPicker(context),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FlatmatesSearchBar(
                      controller: _searchController,
                      hint: locale.searchMapHint,
                      readOnly: true,
                      onTap: () => _showFilterSheet(context),
                      trailingIcon: Icons.tune_rounded,
                      onTrailingTap: () => _showFilterSheet(context),
                    ),
                  ),
                ],
              ),
            ),
            MapFilterBar(
              budgetMin: _budgetMin,
              budgetMax: _budgetMax,
              roomType: _roomType,
              moveInFilter: _moveInFilter,
              genderPref: _genderPref,
              verifiedOnly: _verifiedOnly,
              onBudgetChanged: (min, max) => setState(() {
                _budgetMin = min;
                _budgetMax = max;
              }),
              onRoomTypeChanged: (v) => setState(() => _roomType = v),
              onMoveInChanged: (v) => setState(() => _moveInFilter = v),
              onGenderChanged: (v) => setState(() => _genderPref = v),
              onVerifiedChanged: (v) => setState(() => _verifiedOnly = v),
            ),
            Expanded(
              child: feedState.isLoading && feedState.listings.isEmpty
                  ? const FlatmatesSkeleton.card()
                  : feedState.hasError
                  ? FlatmatesErrorState(
                      message: locale.couldNotLoadListing,
                      onRetry: () => ref
                          .read(discoverFeedControllerProvider.notifier)
                          .load(),
                      retryLabel: locale.commonRetry,
                    )
                  : _buildMap(
                      feedState.listings,
                      searchRadiusKm,
                      theme,
                      locale,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap(
    List<PropertyListing> listings,
    double searchRadiusKm,
    ThemeData theme,
    AppLocalizations locale,
  ) {
    if (!identical(listings, _previousListings)) {
      _previousListings = listings;
    }
    final filtered = _applyFilters(listings);
    final markers = buildClusteredMarkers(
      items: filtered,
      theme: theme,
      onListingTap: _handleListingTap,
      onClusterTap: _handleClusterTap,
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
    showListingSheet(
      context,
      item: item,
      onLike: () async {
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
                    ? AppLocalizations.of(context).contactRequestSent
                    : AppLocalizations.of(
                        context,
                      ).contactRequestWithConversation(conversationId),
              ),
            ),
          );
        } catch (_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).actionFailedRetry),
            ),
          );
        }
      },
    );
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
    final filtered = _applyFilters(_previousListings!);
    final points = filtered
        .where((item) => item.latitude != null && item.longitude != null)
        .map((item) => LatLng(item.latitude!, item.longitude!))
        .toList();
    _flatmatesMapController.fitBounds(points);
  }

  List<PropertyListing> _applyFilters(List<PropertyListing> items) {
    return items.where((item) {
      if (item.monthlyRent < _budgetMin || item.monthlyRent > _budgetMax) {
        return false;
      }
      if (_roomType != 'all') {
        if (item.sharingType != _roomType) return false;
      }
      if (_genderPref != 'any') {
        if (item.genderPreference != null &&
            item.genderPreference != 'any' &&
            item.genderPreference != _genderPref) {
          return false;
        }
      }
      if (!listingMatchesMoveInFilter(item.availableFrom, _moveInFilter)) {
        return false;
      }
      if (_verifiedOnly) {
        final isVerified =
            item.features.contains('verified') ||
            item.features.contains('is_verified');
        if (!isVerified) return false;
      }
      return true;
    }).toList();
  }
}

class _MapLocationChip extends StatelessWidget {
  const _MapLocationChip({this.locationName, this.onTap});

  final String? locationName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on_rounded,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 100),
              child: Text(
                locationName ?? locale.selectLocationLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
