import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/location/location_data.dart';
import '../../core/location/location_detection.dart';
import '../../core/location/location_helpers.dart';
import '../../core/location/place_suggestion.dart';
import '../../core/theme/app_semantic_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../location/application/location_controller.dart';
import '../location/application/location_search_provider.dart';
import '../location/presentation/location_picker_rows.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../bootstrap/catalog_helpers.dart';
import '../shared/presentation/components.dart';
import '../profile/profile_repository.dart';
import 'application/discover_feed_controller.dart';
import 'application/map_listings_controller.dart';

class ChangeLocationPage extends ConsumerStatefulWidget {
  const ChangeLocationPage({super.key});

  @override
  ConsumerState<ChangeLocationPage> createState() => _ChangeLocationPageState();
}

class _ChangeLocationPageState extends ConsumerState<ChangeLocationPage> {
  final _searchController = TextEditingController();

  // Ephemeral page state (setState).
  CatalogOption? _selectedCity;
  bool _locating = false;
  bool _saving = false;
  bool _selectingPlace = false;

  String get _typedCity => _searchController.text.trim();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final selectedCity = _selectedCity;
      if (selectedCity != null && _typedCity != selectedCity.label) {
        setState(() => _selectedCity = null);
      }
      ref
          .read(locationSearchProvider.notifier)
          .onSearchChanged(_searchController.text);
      // Rebuild so the visible-cities filter recomputes.
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      final bootstrap = ref.read(bootstrapControllerProvider).valueOrNull;
      final catalogCities =
          bootstrap?.catalogOptions('flatmates_popular_cities') ?? const [];
      final detection = await detectAndReportLocation(
        context,
        catalogCities: catalogCities,
      );

      if (!mounted) return;

      if (detection.result == LocationDetectResult.success) {
        setState(() => _selectedCity = detection.city);
        final city = detection.city;
        if (city != null) _searchController.text = city.label;
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _save() async {
    final selectedCity = _selectedCity;
    final city = selectedCity?.label ?? _typedCity;
    if (city.isEmpty || _saving) return;
    setState(() => _saving = true);

    final locale = AppLocalizations.of(context);
    try {
      final resolvedLocation = await _resolveCityLocation(city, selectedCity);
      if (!mounted) return;
      // A typed (non-catalog) city that fails to geocode must not be persisted
      // or applied as a filter — mirror LocationPickerModal's
      // _selectTypedLocation, which blocks and surfaces locationDetailsFailed.
      if (resolvedLocation == null && selectedCity == null) {
        FlatmatesToast.error(context, locale.locationDetailsFailed);
        return;
      }
      await ref
          .read(profileRepositoryProvider)
          .updateProfile(payload: {'city': city});
      if (!mounted) return;
      _refreshDiscoveryLocation(city: city, location: resolvedLocation);
      // Always refresh after profile PUT. BootstrapController.refresh()
      // awaits any in-flight fetch before starting a new one, so this
      // still picks up the updated city even when a load is active.
      await ref.read(bootstrapControllerProvider.notifier).refresh();
      if (!mounted) return;

      FlatmatesToast.success(context, locale.locationUpdated);
      if (mounted) context.pop();
    } catch (e) {
      debugPrint('ChangeLocationPage._save failed: $e');
      if (mounted) {
        FlatmatesToast.error(context, locale.actionFailedRetry);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<LocationData?> _resolveCityLocation(
    String city,
    CatalogOption? selectedCity,
  ) async {
    final meta = selectedCity?.meta;
    final latitude = (meta?['latitude'] as num?)?.toDouble();
    final longitude = (meta?['longitude'] as num?)?.toDouble();
    if (latitude != null &&
        longitude != null &&
        latitude.isFinite &&
        longitude.isFinite) {
      return LocationData(name: city, latitude: latitude, longitude: longitude);
    }

    return ref
        .read(locationControllerProvider.notifier)
        .resolveLocationName(city);
  }

  void _refreshDiscoveryLocation({
    required String city,
    required LocationData? location,
  }) {
    final locationController = ref.read(locationControllerProvider.notifier);
    final feedController = ref.read(discoverFeedControllerProvider.notifier);
    final mapController = ref.read(mapListingsProvider.notifier);

    if (location != null &&
        location.latitude.isFinite &&
        location.longitude.isFinite) {
      locationController.selectLocation(location);
      feedController.updateLocationFilter(
        latitude: location.latitude,
        longitude: location.longitude,
        radiusKm: DiscoverFeedController.defaultLocationRadiusKm,
      );
      mapController.updateLocationFilter(
        latitude: location.latitude,
        longitude: location.longitude,
        radiusKm: MapListingsController.defaultLocationRadiusKm,
      );
    } else {
      locationController.clearSelectedLocation();
      feedController.updateTextLocationFilter(location: city);
      mapController.updateTextLocationFilter(location: city);
    }
  }

  Future<void> _selectPlace(PlaceSuggestion suggestion) async {
    setState(() => _selectingPlace = true);
    try {
      final details = await ref
          .read(locationSearchProvider.notifier)
          .resolveSuggestion(suggestion);
      // The page can be popped while the geocode request is in flight.
      if (!mounted) return;
      if (details == null) {
        FlatmatesToast.error(
          context,
          AppLocalizations.of(context).locationDetectionFailed,
        );
        return;
      }

      final bootstrap = ref.read(bootstrapControllerProvider).valueOrNull;
      final catalogCities =
          bootstrap?.catalogOptions('flatmates_popular_cities') ?? const [];
      final cities = resolveCities(
        catalogCities,
      ).where((c) => !c.comingSoon).toList();

      CatalogOption? match;
      double minDist = double.infinity;
      for (final city in cities) {
        final lat = (city.meta['latitude'] as num?)?.toDouble();
        final lng = (city.meta['longitude'] as num?)?.toDouble();
        if (lat == null || lng == null) continue;
        final d = haversineKm(details.latitude, details.longitude, lat, lng);
        if (d < minDist) {
          minDist = d;
          match = city;
        }
      }

      if (match != null && minDist <= kMaxMatchDistanceKm) {
        setState(() => _selectedCity = match);
        _searchController.text = match.label;
        ref.read(locationSearchProvider.notifier).clear();
      } else {
        final fallbackOption = CatalogOption(
          id: suggestion.placeId,
          label: details.name,
          meta: {'latitude': details.latitude, 'longitude': details.longitude},
        );
        setState(() => _selectedCity = fallbackOption);
        _searchController.text = details.name;
        ref.read(locationSearchProvider.notifier).clear();
      }
    } catch (e) {
      debugPrint('selectPlace error: $e');
      if (mounted) {
        FlatmatesToast.error(
          context,
          AppLocalizations.of(context).locationDetectionFailed,
        );
      }
    } finally {
      if (mounted) setState(() => _selectingPlace = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    final searchState = ref.watch(locationSearchProvider);
    final hasPlacesResults = searchState.suggestions.isNotEmpty;
    final selectingPlace = _selectingPlace;
    final isPlacesLoading = searchState.isLoading || selectingPlace;
    final locating = _locating;
    final saving = _saving;
    final selectedCity = _selectedCity;
    final canSave = (selectedCity?.label ?? _typedCity).isNotEmpty;

    return FlatmatesScreen(
      appBar: FlatmatesHeader.backTitle(
        title: locale.locationSelectionTitle,
        onBack: () => context.pop(),
      ),
      padding: AppSpacing.horizontalScreen,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.base),
          FlatmatesSearchBar(
            controller: _searchController,
            hint: locale.searchCityOrAreaHint,
          ),
          const SizedBox(height: AppSpacing.sm),
          LocationActionRow(
            icon: Icons.my_location_outlined,
            title: locating
                ? locale.detectingLocation
                : locale.useCurrentLocation,
            onTap: locating ? null : _useCurrentLocation,
          ),
          const SizedBox(height: AppSpacing.sm),
          // Suggestions scroll in the space left above the CTA, so the
          // keyboard never pushes them off the screen.
          Expanded(
            child: ListView(
              children: [
                if (isPlacesLoading)
                  const FlatmatesSkeleton.settingsList(itemCount: 3),
                if (hasPlacesResults) ...[
                  Text(
                    locale.suggestionsLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppSemanticColors.textSecondaryFor(
                        theme.brightness,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (final suggestion in searchState.suggestions)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs,
                      ),
                      child: LocationSuggestionRow(
                        suggestion: suggestion,
                        onTap: selectingPlace
                            ? null
                            : () => _selectPlace(suggestion),
                      ),
                    ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.sm,
              bottom: AppSpacing.base,
            ),
            child: FlatmatesButton(
              label: locale.modeContinue,
              fullWidth: true,
              onPressed: !canSave || saving ? null : _save,
            ),
          ),
        ],
      ),
    );
  }
}
