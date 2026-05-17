import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/location/location_data.dart';
import '../../../core/location/location_helpers.dart';
import '../../../core/location/place_suggestion.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../bootstrap/bootstrap_controller.dart';
import '../../bootstrap/catalog_helpers.dart';
import '../../shared/presentation/flatmates_search_bar.dart';
import '../application/location_search_provider.dart';

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
          widget.onLocationSelected(
            LocationData(
              name: locale.currentLocationLabel,
              latitude: position.latitude,
              longitude: position.longitude,
            ),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(locale.locationDetectionFailed)));
      }
    } finally {
      if (mounted) setState(() => _isDetectingLocation = false);
    }
  }

  void _selectCatalogCity(CatalogOption city) {
    final meta = city.meta;
    final lat = (meta['latitude'] as num?)?.toDouble() ?? 0.0;
    final lng = (meta['longitude'] as num?)?.toDouble() ?? 0.0;
    widget.onLocationSelected(
      LocationData(name: city.label, latitude: lat, longitude: lng),
    );
    Navigator.of(context).pop();
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
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(locale.errorUnknown)));
      }
    } finally {
      if (mounted) setState(() => _isResolvingPlace = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final locale = AppLocalizations.of(context);
    final searchState = ref.watch(locationSearchProvider);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    final catalogCities = _getCatalogCities();
    final query = _searchController.text.trim().toLowerCase();
    final filteredCities = query.isEmpty
        ? catalogCities
        : catalogCities
              .where((c) => cityMatchesQuery(c, query))
              .toList(growable: false);
    final hasPlacesResults = searchState.suggestions.isNotEmpty;
    final isLoading = searchState.isLoading || _isResolvingPlace;

    return ClipRRect(
      borderRadius: AppRadius.sheetTopBorder,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppSemanticColors.frostBlur,
          sigmaY: AppSemanticColors.frostBlur,
        ),
        child: Container(
          decoration: BoxDecoration(
            color:
                (isDark
                        ? AppSemanticColors.darkSurface
                        : AppSemanticColors.card)
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppSemanticColors.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  locale.locationPickerTitle,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.lg),
                FlatmatesSearchBar(
                  controller: _searchController,
                  hint: locale.locationPickerSearchHint,
                  leadingIcon: Icons.search_rounded,
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
                  autofocus: true,
                ),
                const SizedBox(height: AppSpacing.md),
                _UseCurrentLocationButton(
                  isLoading: _isDetectingLocation,
                  onTap: _useCurrentLocation,
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
                          Divider(color: AppSemanticColors.line),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                        Text(
                          query.isEmpty
                              ? locale.popularCitiesLabel
                              : locale.matchingCitiesLabel,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppSemanticColors.textSecondaryFor(
                              theme.brightness,
                            ),
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        if (filteredCities.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.lg,
                            ),
                            child: Center(
                              child: Text(
                                locale.noCitiesFound,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppSemanticColors.ink3,
                                ),
                              ),
                            ),
                          )
                        else
                          ...filteredCities.map(
                            (city) => _CityTile(
                              city: city,
                              onTap: () => _selectCatalogCity(city),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
    return ListTile(
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
    );
  }
}

class _CityTile extends StatelessWidget {
  final CatalogOption city;
  final VoidCallback onTap;

  const _CityTile({required this.city, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = (city.meta['state'] as String?) ?? '';
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      leading: const Icon(
        Icons.location_city_rounded,
        size: 20,
        color: AppSemanticColors.ink3,
      ),
      title: Text(
        city.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: state.isNotEmpty
          ? Text(
              state,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppSemanticColors.ink3,
              ),
            )
          : null,
      trailing: const Icon(
        Icons.chevron_right,
        size: 18,
        color: AppSemanticColors.line,
      ),
      onTap: onTap,
    );
  }
}

class _UseCurrentLocationButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _UseCurrentLocationButton({
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: AppRadius.smBorder,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppSemanticColors.accentSoft,
          borderRadius: AppRadius.smBorder,
        ),
        child: Row(
          children: [
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Icon(
                Icons.gps_fixed_rounded,
                size: 20,
                color: AppSemanticColors.accent,
              ),
            const SizedBox(width: AppSpacing.md),
            Text(
              isLoading ? locale.detectingLocation : locale.useCurrentLocation,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppSemanticColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) => LocationPickerModal(
        currentLocationName: currentLocationName,
        currentRadius: currentRadius,
        onLocationSelected: onLocationSelected,
        onRadiusChanged: onRadiusChanged,
      ),
    ),
  );
}
