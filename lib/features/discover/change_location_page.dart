import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../core/location/location_data.dart';
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
import 'discover_repository.dart';

final _selectedCityProvider = StateProvider<CatalogOption?>((ref) => null);
final _locatingProvider = StateProvider<bool>((ref) => false);
final _savingProvider = StateProvider<bool>((ref) => false);
final _selectingPlaceProvider = StateProvider<bool>((ref) => false);
final _searchVersionProvider = StateProvider<int>((ref) => 0);

class ChangeLocationPage extends ConsumerStatefulWidget {
  const ChangeLocationPage({super.key});

  @override
  ConsumerState<ChangeLocationPage> createState() => _ChangeLocationPageState();
}

class _ChangeLocationPageState extends ConsumerState<ChangeLocationPage> {
  final _searchController = TextEditingController();

  String get _typedCity => _searchController.text.trim();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final selectedCity = ref.read(_selectedCityProvider);
      if (selectedCity != null && _typedCity != selectedCity.label) {
        ref.read(_selectedCityProvider.notifier).state = null;
      }
      ref
          .read(locationSearchProvider.notifier)
          .onSearchChanged(_searchController.text);
      // Bump version so the visible-cities filter recomputes reactively.
      ref.read(_searchVersionProvider.notifier).state++;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    ref.read(_locatingProvider.notifier).state = true;
    try {
      final bootstrap = ref.read(bootstrapControllerProvider).valueOrNull;
      final catalogCities =
          bootstrap?.catalogOptions('flatmates_popular_cities') ?? const [];
      final detection = await detectCurrentLocation(
        catalogCities: catalogCities,
      );

      if (!mounted) return;

      switch (detection.result) {
        case LocationDetectResult.success:
          ref.read(_selectedCityProvider.notifier).state = detection.city;
          final city = detection.city;
          if (city != null) _searchController.text = city.label;
        case LocationDetectResult.serviceDisabled:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).locationServicesDisabled,
              ),
              action: SnackBarAction(
                label: AppLocalizations.of(
                  context,
                ).locationServicesDisabledAction,
                onPressed: () => Geolocator.openLocationSettings(),
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        case LocationDetectResult.permissionDenied:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).locationPermissionRequired,
              ),
            ),
          );
        case LocationDetectResult.permissionDeniedForever:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).locationPermissionDeniedForever,
              ),
              action: SnackBarAction(
                label: AppLocalizations.of(context).locationOpenAppSettings,
                onPressed: () => Geolocator.openAppSettings(),
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        case LocationDetectResult.noMatch:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).locationNoMatchFound),
            ),
          );
        case LocationDetectResult.error:
          debugPrint('LocationDetection error: ${detection.errorDetail}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).locationDetectionFailed,
              ),
            ),
          );
      }
    } catch (e) {
      debugPrint('LocationDetection unhandled: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).locationDetectionFailed),
          ),
        );
      }
    } finally {
      if (mounted) ref.read(_locatingProvider.notifier).state = false;
    }
  }

  Future<void> _save() async {
    final selectedCity = ref.read(_selectedCityProvider);
    final city = selectedCity?.label ?? _typedCity;
    if (city.isEmpty || ref.read(_savingProvider)) return;
    ref.read(_savingProvider.notifier).state = true;

    final locale = AppLocalizations.of(context);
    try {
      final resolvedLocation = await _resolveCityLocation(city, selectedCity);
      if (!mounted) return;
      // A typed (non-catalog) city that fails to geocode must not be persisted
      // or applied as a filter — mirror LocationPickerModal's
      // _selectTypedLocation, which blocks and surfaces locationDetailsFailed.
      if (resolvedLocation == null && selectedCity == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(locale.locationDetailsFailed)));
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(locale.locationUpdated),
          duration: const Duration(seconds: 2),
        ),
      );
      if (mounted) context.pop();
    } catch (e) {
      debugPrint('ChangeLocationPage._save failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(locale.actionFailedRetry)));
      }
    } finally {
      if (mounted) ref.read(_savingProvider.notifier).state = false;
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

    ref.invalidate(discoverListingsProvider);
  }

  Future<void> _selectPlace(PlaceSuggestion suggestion) async {
    ref.read(_selectingPlaceProvider.notifier).state = true;
    try {
      final details = await ref
          .read(locationSearchProvider.notifier)
          .resolveSuggestion(suggestion);
      if (details == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).locationDetectionFailed,
              ),
            ),
          );
        }
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
        ref.read(_selectedCityProvider.notifier).state = match;
        _searchController.text = match.label;
        ref.read(locationSearchProvider.notifier).clear();
      } else {
        final fallbackOption = CatalogOption(
          id: suggestion.placeId,
          label: details.name,
          meta: {'latitude': details.latitude, 'longitude': details.longitude},
        );
        ref.read(_selectedCityProvider.notifier).state = fallbackOption;
        _searchController.text = details.name;
        ref.read(locationSearchProvider.notifier).clear();
      }
    } catch (e) {
      debugPrint('selectPlace error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).locationDetectionFailed),
          ),
        );
      }
    } finally {
      if (mounted) ref.read(_selectingPlaceProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    // Watch version so the visible-cities filter recomputes when search text
    // changes.
    ref.watch(_searchVersionProvider);
    final searchState = ref.watch(locationSearchProvider);
    final hasPlacesResults = searchState.suggestions.isNotEmpty;
    final selectingPlace = ref.watch(_selectingPlaceProvider);
    final isPlacesLoading = searchState.isLoading || selectingPlace;
    final locating = ref.watch(_locatingProvider);
    final saving = ref.watch(_savingProvider);
    final selectedCity = ref.watch(_selectedCityProvider);
    final canSave = (selectedCity?.label ?? _typedCity).isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.md,
                AppSpacing.screen,
                0,
              ),
              child: Row(
                children: [
                  FlatmatesChromeIconButton(
                    onPressed: () => context.pop(),
                    icon: Icons.arrow_back_rounded,
                    tooltip: locale.backCta,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      locale.locationSelectionTitle,
                      style: theme.textTheme.headlineMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
              ),
              child: FlatmatesSearchBar(
                controller: _searchController,
                hint: locale.searchCityOrAreaHint,
                // No-op onChanged; the _searchVersionProvider bump in the
                // listener triggers rebuild.
                onChanged: (_) {},
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
              ),
              child: LocationActionRow(
                icon: Icons.my_location_outlined,
                title: locating
                    ? locale.detectingLocation
                    : locale.useCurrentLocation,
                onTap: locating ? null : _useCurrentLocation,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
              ),
              child: Divider(
                color: AppSemanticColors.hairlineFor(
                  Theme.of(context).brightness,
                ),
              ),
            ),
            if (isPlacesLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            if (hasPlacesResults) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screen,
                ),
                child: Text(
                  locale.suggestionsLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppSemanticColors.textSecondaryFor(theme.brightness),
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...searchState.suggestions.map(
                (suggestion) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screen,
                    vertical: 4,
                  ),
                  child: LocationSuggestionRow(
                    suggestion: suggestion,
                    onTap: selectingPlace
                        ? null
                        : () => _selectPlace(suggestion),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            const Expanded(child: SizedBox.shrink()),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.sm,
                AppSpacing.screen,
                AppSpacing.xl,
              ),
              child: FlatmatesButton(
                label: locale.modeContinue,
                fullWidth: true,
                onPressed: !canSave || saving ? null : _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
