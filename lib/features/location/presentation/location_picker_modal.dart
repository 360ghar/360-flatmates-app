import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/location/location_data.dart';
import '../../../core/location/location_helpers.dart';
import '../../../core/location/place_suggestion.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../shared/presentation/components.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../bootstrap/bootstrap_controller.dart';
import '../../bootstrap/catalog_helpers.dart';
import '../application/location_controller.dart';
import '../application/location_search_provider.dart';
import 'location_picker_rows.dart';

class LocationPickerModal extends ConsumerStatefulWidget {
  final String? currentLocationName;
  final double currentRadius;
  final ValueChanged<LocationData> onLocationSelected;
  final ValueChanged<double>? onRadiusChanged;

  const LocationPickerModal({
    super.key,
    this.currentLocationName,
    this.currentRadius = 10.0,
    required this.onLocationSelected,
    this.onRadiusChanged,
  });

  @override
  ConsumerState<LocationPickerModal> createState() =>
      _LocationPickerModalState();
}

class _LocationPickerModalState extends ConsumerState<LocationPickerModal> {
  final _searchController = TextEditingController();
  double _radius = 10.0;
  bool _isDetectingLocation = false;
  bool _isResolvingPlace = false;

  String get _typedLocation => _searchController.text.trim();

  @override
  void initState() {
    super.initState();
    _radius = widget.currentRadius;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CatalogOption> _getCatalogCities() {
    final bootstrap = ref.read(bootstrapControllerProvider).valueOrNull;
    final catalogCities =
        bootstrap?.catalogOptions('flatmates_popular_cities') ?? const [];
    return resolveCities(catalogCities);
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isDetectingLocation = true);
    final locale = AppLocalizations.of(context);
    try {
      final catalogCities = _getCatalogCities();
      final detection = await detectCurrentLocation(
        catalogCities: catalogCities,
      );
      if (!mounted) return;

      if (detection.result == LocationDetectResult.success &&
          detection.city != null) {
        final meta = detection.city!.meta;
        final lat = (meta['latitude'] as num?)?.toDouble() ?? 0.0;
        final lng = (meta['longitude'] as num?)?.toDouble() ?? 0.0;
        widget.onLocationSelected(
          LocationData(
            name: detection.city!.label,
            latitude: lat,
            longitude: lng,
          ),
        );
        Navigator.of(context).pop();
      } else {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!mounted) return;
        if (!serviceEnabled) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(locale.locationServicesDisabled),
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: locale.locationServicesDisabledAction,
                onPressed: Geolocator.openLocationSettings,
              ),
            ),
          );
          return;
        }
        var permission = await Geolocator.checkPermission();
        if (!mounted) return;
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (!mounted) return;
        }
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(locale.locationPermissionRequired)),
          );
          return;
        }
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
          ),
        );
        if (mounted) {
          String locationName = locale.currentLocationLabel;
          try {
            final placemarks = await placemarkFromCoordinates(
              position.latitude,
              position.longitude,
            );
            if (placemarks.isNotEmpty) {
              final place = placemarks.first;
              final parts = <String>[
                if (place.locality != null && place.locality!.isNotEmpty)
                  place.locality!,
                if (place.administrativeArea != null &&
                    place.administrativeArea!.isNotEmpty)
                  place.administrativeArea!,
              ];
              if (parts.isNotEmpty) {
                locationName = parts.join(', ');
              }
            }
          } catch (e) {
            debugPrint(
              'LocationPickerModal._useCurrentLocation: geocoding failed: $e',
            );
          }
          if (!mounted) return;
          widget.onLocationSelected(
            LocationData(
              name: locationName,
              latitude: position.latitude,
              longitude: position.longitude,
            ),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      debugPrint('LocationPickerModal._useCurrentLocation failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(locale.locationDetectionFailed)));
      }
    } finally {
      if (mounted) setState(() => _isDetectingLocation = false);
    }
  }

  Future<void> _selectTypedLocation() async {
    final location = _typedLocation;
    if (_isResolvingPlace || location.isEmpty) return;

    setState(() => _isResolvingPlace = true);
    final locale = AppLocalizations.of(context);
    try {
      final resolved = await ref
          .read(locationControllerProvider.notifier)
          .resolveLocationName(location);
      if (!mounted) return;
      if (resolved == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(locale.locationDetailsFailed)));
        return;
      }

      widget.onLocationSelected(resolved);
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('LocationPickerModal._selectTypedLocation failed: $e');
      if (mounted) {
        FlatmatesToast.error(context, locale.errorUnknown);
      }
    } finally {
      if (mounted) setState(() => _isResolvingPlace = false);
    }
  }

  Future<void> _onSuggestionTap(PlaceSuggestion suggestion) async {
    setState(() => _isResolvingPlace = true);
    final locale = AppLocalizations.of(context);
    try {
      final details = await ref
          .read(locationSearchProvider.notifier)
          .resolveSuggestion(suggestion);

      if (details != null && mounted) {
        final catalogCities = _getCatalogCities();
        CatalogOption? match;
        double minDist = double.infinity;
        for (final city in catalogCities) {
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
          final mLat = (match.meta['latitude'] as num?)?.toDouble() ?? 0.0;
          final mLng = (match.meta['longitude'] as num?)?.toDouble() ?? 0.0;
          widget.onLocationSelected(
            LocationData(name: match.label, latitude: mLat, longitude: mLng),
          );
        } else {
          widget.onLocationSelected(
            LocationData(
              name: details.name,
              latitude: details.latitude,
              longitude: details.longitude,
            ),
          );
        }
        Navigator.of(context).pop();
      } else if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(locale.locationDetailsFailed)));
      }
    } catch (e) {
      debugPrint('LocationPickerModal._onSuggestionTap failed: $e');
      if (mounted) {
        FlatmatesToast.error(context, locale.errorUnknown);
      }
    } finally {
      if (mounted) setState(() => _isResolvingPlace = false);
    }
  }

  void _onCityTap(CatalogOption city) {
    if (city.comingSoon) return;
    final lat = (city.meta['latitude'] as num?)?.toDouble() ?? 0.0;
    final lng = (city.meta['longitude'] as num?)?.toDouble() ?? 0.0;
    widget.onLocationSelected(
      LocationData(name: city.label, latitude: lat, longitude: lng),
    );
    Navigator.of(context).pop();
  }

  bool _isCurrentCity(CatalogOption city) {
    final current = widget.currentLocationName;
    if (current == null || current.isEmpty) return false;
    return current.toLowerCase() == city.label.toLowerCase();
  }

  Widget _citySection(String label, List<CatalogOption> cities) {
    if (cities.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: AppSemanticColors.textSecondaryFor(theme.brightness),
            letterSpacing: 1.1,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        ...cities.map(
          (city) => Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: LocationCityRow(
              key: Key('popular_city_${city.id}'),
              city: city,
              selected: _isCurrentCity(city),
              onTap: _isResolvingPlace ? null : () => _onCityTap(city),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final locale = AppLocalizations.of(context);
    final searchState = ref.watch(locationSearchProvider);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    final hasPlacesResults = searchState.suggestions.isNotEmpty;
    final isLoading = searchState.isLoading || _isResolvingPlace;
    final typedLocation = _typedLocation;
    final catalogCities = _getCatalogCities();
    final popularCities = catalogCities.where((c) => c.isPopular).toList();
    final moreCities = catalogCities
        .where((c) => !c.isPopular && !c.comingSoon)
        .toList();
    final matchingCities = typedLocation.isEmpty
        ? const <CatalogOption>[]
        : catalogCities
              .where((c) => cityMatchesQuery(c, typedLocation))
              .toList();

    return ClipRRect(
      borderRadius: AppRadius.sheetTopBorder,
      child: Container(
        decoration: BoxDecoration(
          color:
              (isDark ? AppSemanticColors.darkSurface : AppSemanticColors.card)
                  .withValues(alpha: 0.92),
          borderRadius: AppRadius.sheetTopBorder,
        ),
        child: AnimatedContainer(
          duration: AppMotion.bottomSheet,
          curve: AppMotion.easeOutQuart,
          padding: EdgeInsets.only(
            left: AppSpacing.screen,
            right: AppSpacing.screen,
            top: AppSpacing.md,
            bottom: bottomInset + AppSpacing.lg,
          ),
          child: Column(
            children: [
              Text(
                locale.locationPickerTitle,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: FlatmatesSearchBar(
                      controller: _searchController,
                      hint: locale.locationPickerSearchHint,
                      leadingIcon: AppIcons.search,
                      trailingIcon: _searchController.text.isNotEmpty
                          ? Icons.clear_rounded
                          : null,
                      onTrailingTap: () {
                        _searchController.clear();
                        ref.read(locationSearchProvider.notifier).clear();
                        setState(() {});
                      },
                      onChanged: (query) {
                        ref
                            .read(locationSearchProvider.notifier)
                            .onSearchChanged(query);
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _CurrentLocationIconButton(
                    isLoading: _isDetectingLocation,
                    onTap: _useCurrentLocation,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _RadiusSlider(
                radius: _radius,
                onChanged: (value) {
                  setState(() => _radius = value);
                  widget.onRadiusChanged?.call(value);
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              if (isLoading)
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
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (typedLocation.isEmpty) ...[
                        _citySection(locale.popularCitiesLabel, popularCities),
                        if (popularCities.isNotEmpty && moreCities.isNotEmpty)
                          const SizedBox(height: AppSpacing.md),
                        _citySection(locale.moreCitiesLabel, moreCities),
                      ] else if (matchingCities.isNotEmpty) ...[
                        _citySection(
                          locale.matchingCitiesLabel,
                          matchingCities,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                      if (hasPlacesResults) ...[
                        Text(
                          locale.suggestionsLabel,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppSemanticColors.textSecondaryFor(
                              theme.brightness,
                            ),
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        ...searchState.suggestions.map(
                          (s) => _PlaceSuggestionTile(
                            suggestion: s,
                            onTap: _isResolvingPlace
                                ? null
                                : () => _onSuggestionTap(s),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const Divider(color: AppSemanticColors.line),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                      if (_typedLocation.isNotEmpty)
                        _TypedLocationTile(
                          location: _typedLocation,
                          onTap: _selectTypedLocation,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceSuggestionTile extends StatelessWidget {
  final PlaceSuggestion suggestion;
  final VoidCallback? onTap;

  const _PlaceSuggestionTile({required this.suggestion, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        leading: const Icon(
          Icons.location_on_outlined,
          size: 20,
          color: AppSemanticColors.accent,
        ),
        title: Text(
          suggestion.mainText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: suggestion.secondaryText.isNotEmpty
            ? Text(
                suggestion.secondaryText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppSemanticColors.ink3,
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}

class _TypedLocationTile extends StatelessWidget {
  const _TypedLocationTile({required this.location, required this.onTap});

  final String location;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        leading: const Icon(
          Icons.location_city_rounded,
          size: 20,
          color: AppSemanticColors.accent,
        ),
        title: Text(
          location,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          size: 18,
          color: AppSemanticColors.line,
        ),
        onTap: onTap,
      ),
    );
  }
}

class _CurrentLocationIconButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _CurrentLocationIconButton({
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: AppRadius.smBorder,
      child: Container(
        height: 48,
        width: 48,
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? AppSemanticColors.darkSurface.withValues(alpha: 0.5)
              : AppSemanticColors.card,
          borderRadius: AppRadius.smBorder,
          border: Border.all(color: AppSemanticColors.line),
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(
                  Icons.gps_fixed_rounded,
                  size: 20,
                  color: AppSemanticColors.accent,
                ),
        ),
      ),
    );
  }
}

class _RadiusSlider extends StatelessWidget {
  final double radius;
  final ValueChanged<double> onChanged;

  const _RadiusSlider({required this.radius, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              locale.searchRadiusLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              locale.distanceKmLabel(radius.round()),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppSemanticColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Slider(
          value: radius,
          min: 5,
          max: 50,
          divisions: 9,
          activeColor: AppSemanticColors.accent,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

Future<void> showLocationPickerModal(
  BuildContext context, {
  String? currentLocationName,
  double currentRadius = 10.0,
  required ValueChanged<LocationData> onLocationSelected,
  ValueChanged<double>? onRadiusChanged,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: LocationPickerModal(
        currentLocationName: currentLocationName,
        currentRadius: currentRadius,
        onLocationSelected: onLocationSelected,
        onRadiusChanged: onRadiusChanged,
      ),
    ),
  );
}
