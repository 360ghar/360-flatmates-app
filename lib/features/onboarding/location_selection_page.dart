import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../core/location/location_helpers.dart';
import '../../core/location/place_suggestion.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../location/application/location_search_provider.dart';
import '../location/presentation/location_picker_rows.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../bootstrap/catalog_helpers.dart';
import '../shared/presentation/components.dart';

class LocationSelectionPage extends ConsumerStatefulWidget {
  const LocationSelectionPage({
    required this.onLocationSelected,
    super.key,
    this.onBack,
  });

  final void Function(Map<String, String?> data) onLocationSelected;

  /// Steps back to the previous onboarding step. Falls back to the system pop
  /// when null.
  final VoidCallback? onBack;

  @override
  ConsumerState<LocationSelectionPage> createState() =>
      _LocationSelectionPageState();
}

class _LocationSelectionPageState extends ConsumerState<LocationSelectionPage> {
  final _searchController = TextEditingController();
  CatalogOption? _selectedCity;
  bool _locating = false;
  bool _selectingPlace = false;

  String get _typedCity => _searchController.text.trim();

  bool get _canContinue => _selectedCity != null || _typedCity.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      ref
          .read(locationSearchProvider.notifier)
          .onSearchChanged(_searchController.text);
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
      final detection = await detectCurrentLocation(
        catalogCities: catalogCities,
      );

      if (!mounted) return;

      switch (detection.result) {
        case LocationDetectResult.success:
          setState(() => _selectedCity = detection.city);
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
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _selectPlace(PlaceSuggestion suggestion) async {
    setState(() => _selectingPlace = true);
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
        setState(() {
          _selectedCity = match;
          _searchController.text = match!.label;
        });
        ref.read(locationSearchProvider.notifier).clear();
      } else {
        final fallbackOption = CatalogOption(
          id: suggestion.placeId,
          label: details.name,
          meta: {'latitude': details.latitude, 'longitude': details.longitude},
        );
        setState(() {
          _selectedCity = fallbackOption;
          _searchController.text = details.name;
        });
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
      if (mounted) setState(() => _selectingPlace = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    final searchState = ref.watch(locationSearchProvider);
    final hasPlacesResults = searchState.suggestions.isNotEmpty;
    final isPlacesLoading = searchState.isLoading || _selectingPlace;

    return Scaffold(
      body: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.lg,
          AppSpacing.screen,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              onPressed: widget.onBack ?? () => context.pop(),
              icon: const Icon(Icons.arrow_back),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: locale.backCta,
            ),
            const SizedBox(height: 28),
            const FlatmatesStepProgress.dots(currentStep: 1, totalSteps: 4),
            const SizedBox(height: AppSpacing.section),
            Text(
              locale.locationSelectionTitle,
              style: theme.textTheme.headlineLarge,
            ),
            const SizedBox(height: 20),
            FlatmatesSearchBar(
              controller: _searchController,
              hint: locale.searchCityOrAreaHint,
              onChanged: (value) {
                final selectedCity = _selectedCity;
                if (selectedCity != null &&
                    value.trim() != selectedCity.label) {
                  _selectedCity = null;
                }
                setState(() {});
              },
            ),
            const SizedBox(height: 18),
            LocationActionRow(
              icon: Icons.my_location_outlined,
              title: _locating
                  ? locale.detectingLocation
                  : locale.useCurrentLocation,
              onTap: _locating ? null : _useCurrentLocation,
              vertical: 10,
            ),
            const SizedBox(height: 18),
            const Divider(color: AppSemanticColors.line),
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
              const SizedBox(height: 12),
              Text(
                locale.suggestionsLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppSemanticColors.textSecondaryFor(theme.brightness),
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              ...searchState.suggestions.map(
                (suggestion) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: LocationSuggestionRow(
                    suggestion: suggestion,
                    onTap: _selectingPlace
                        ? null
                        : () => _selectPlace(suggestion),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            const Expanded(child: SizedBox.shrink()),
            Padding(
              padding: const EdgeInsets.only(
                bottom: AppSpacing.section,
                top: AppSpacing.md,
              ),
              child: FlatmatesButton(
                label: locale.modeContinue,
                fullWidth: true,
                onPressed: !_canContinue
                    ? null
                    : () => widget.onLocationSelected({
                        'city': _selectedCity?.label ?? _typedCity,
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
