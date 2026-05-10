import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../bootstrap/catalog_helpers.dart';
import '../shared/presentation/components.dart';

class LocationSelectionPage extends ConsumerStatefulWidget {
  const LocationSelectionPage({required this.onLocationSelected, super.key});

  final void Function(Map<String, String?> data) onLocationSelected;

  @override
  ConsumerState<LocationSelectionPage> createState() =>
      _LocationSelectionPageState();
}

class _LocationSelectionPageState extends ConsumerState<LocationSelectionPage> {
  final _searchController = TextEditingController();
  CatalogOption? _selectedCity;
  bool _locating = false;

  static const _fallbackCities = [
    CatalogOption(
      id: 'bangalore',
      label: 'Bangalore',
      meta: {'state': 'Karnataka', 'latitude': 12.9716, 'longitude': 77.5946},
    ),
    CatalogOption(
      id: 'hyderabad',
      label: 'Hyderabad',
      meta: {'state': 'Telangana', 'latitude': 17.3850, 'longitude': 78.4867},
    ),
    CatalogOption(
      id: 'pune',
      label: 'Pune',
      meta: {'state': 'Maharashtra', 'latitude': 18.5204, 'longitude': 73.8567},
    ),
    CatalogOption(
      id: 'chennai',
      label: 'Chennai',
      meta: {'state': 'Tamil Nadu', 'latitude': 13.0827, 'longitude': 80.2707},
    ),
    CatalogOption(
      id: 'mumbai',
      label: 'Mumbai',
      meta: {'state': 'Maharashtra', 'latitude': 19.0760, 'longitude': 72.8777},
    ),
    CatalogOption(
      id: 'gurgaon',
      label: 'Gurgaon',
      meta: {'state': 'Haryana', 'latitude': 28.4595, 'longitude': 77.0266},
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      // Check & request permission
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permission is required to detect your city.',
              ),
            ),
          );
        }
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      ).timeout(const Duration(seconds: 10));

      // Find closest popular city by coordinates
      final bootstrap = ref.read(bootstrapControllerProvider).valueOrNull;
      final catalogCities =
          bootstrap?.catalogOptions('flatmates_popular_cities') ?? const [];
      final cities = catalogCities.isNotEmpty ? catalogCities : _fallbackCities;

      CatalogOption? closest;
      double minDist = double.infinity;
      for (final city in cities) {
        final lat = (city.meta['latitude'] as num?)?.toDouble();
        final lng = (city.meta['longitude'] as num?)?.toDouble();
        if (lat == null || lng == null) continue;
        final d = _haversine(position.latitude, position.longitude, lat, lng);
        if (d < minDist) {
          minDist = d;
          closest = city;
        }
      }

      // If no coordinates in catalog, try matching by reverse-geocoded locality
      if (closest == null) {
        try {
          final placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );
          if (placemarks.isNotEmpty) {
            final locality = placemarks.first.locality?.toLowerCase() ?? '';
            final adminArea =
                placemarks.first.administrativeArea?.toLowerCase() ?? '';
            for (final city in cities) {
              final label = city.label.toLowerCase();
              if (locality.contains(label) ||
                  label.contains(locality) ||
                  adminArea.contains(label) ||
                  label.contains(adminArea)) {
                closest = city;
                break;
              }
            }
          }
        } catch (_) {
          // Geocoding may fail on some platforms; fall through to manual
        }
      }

      if (closest != null && mounted) {
        setState(() => _selectedCity = closest);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not find a matching city. Please select manually.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not detect your location. Please select manually.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  /// Haversine distance in km.
  static double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0; // Earth radius in km
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * asin(sqrt(a));
  }

  static double _toRad(double deg) => deg * pi / 180;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    final bootstrap = ref.watch(bootstrapControllerProvider).valueOrNull;
    final catalogCities =
        bootstrap?.catalogOptions('flatmates_popular_cities') ?? const [];
    final cities = catalogCities.isNotEmpty ? catalogCities : _fallbackCities;
    final query = _searchController.text.trim().toLowerCase();
    final visibleCities = query.isEmpty
        ? cities
        : cities
              .where((city) => city.label.toLowerCase().contains(query))
              .toList(growable: false);

    return Scaffold(
      body: SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: locale.backCta,
            ),
            const SizedBox(height: 28),
            // Step progress
            FlatmatesStepProgress.dots(currentStep: 1, totalSteps: 4),
            const SizedBox(height: AppSpacing.section),
            Text(
              locale.locationSelectionTitle,
              style: theme.textTheme.headlineLarge,
            ),
            const SizedBox(height: 20),
            // Search bar
            FlatmatesSearchBar(
              controller: _searchController,
              hint: locale.searchLocationPlaceholder,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 18),
            _LocationActionRow(
              icon: Icons.my_location_outlined,
              title: _locating
                  ? locale.detectingLocation
                  : locale.useCurrentLocation,
              onTap: _locating ? () {} : _useCurrentLocation,
            ),
            const SizedBox(height: 18),
            Divider(color: AppSemanticColors.line),
            const SizedBox(height: 16),
            Text(
              locale.popularCitiesLabel,
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppSemanticColors.textSecondaryFor(theme.brightness),
                letterSpacing: 1.1,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: visibleCities.isEmpty
                  ? Center(
                      child: Text(
                        locale.noLocationsAvailable,
                        style: theme.textTheme.bodyMedium,
                      ),
                    )
                  : ListView.separated(
                      itemCount: visibleCities.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final city = visibleCities[index];
                        final selected = _selectedCity?.id == city.id;
                        return _CityRow(
                          city: city,
                          selected: selected,
                          onTap: () => setState(() => _selectedCity = city),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 28, top: 12),
              child: FlatmatesButton(
                label: locale.modeContinue,
                fullWidth: true,
                onPressed: _selectedCity == null
                    ? null
                    : () => widget.onLocationSelected({
                        'city': _selectedCity!.label,
                        'locality': null,
                      }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationActionRow extends StatelessWidget {
  const _LocationActionRow({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: AppSemanticColors.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppSemanticColors.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: AppSemanticColors.line),
          ],
        ),
      ),
    );
  }
}

class _CityRow extends StatelessWidget {
  const _CityRow({
    required this.city,
    required this.selected,
    required this.onTap,
  });

  final CatalogOption city;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FlatmatesCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md + AppSpacing.xs,
      ),
      backgroundColor: selected
          ? AppSemanticColors.accent.withValues(alpha: 0.08)
          : null,
      borderColor: selected
          ? AppSemanticColors.accent
          : AppSemanticColors.line.withValues(alpha: 0.35),
      child: Row(
        children: [
          Icon(Icons.location_on_outlined, color: AppSemanticColors.accent),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(city.label, style: theme.textTheme.bodyLarge)),
          if (selected)
            Icon(Icons.check_circle_rounded, color: AppSemanticColors.accent)
          else
            Icon(Icons.chevron_right, color: AppSemanticColors.line),
        ],
      ),
    );
  }
}
