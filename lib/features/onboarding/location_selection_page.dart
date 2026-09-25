import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/location/location_detection.dart';
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
  const LocationSelectionPage({required this.onLocationSelected, super.key});

  final void Function(Map<String, String?> data) onLocationSelected;

  @override
  ConsumerState<LocationSelectionPage> createState() =>
      _LocationSelectionPageState();
}

class _LocationSelectionPageState extends ConsumerState<LocationSelectionPage> {
  final _searchController = TextEditingController();
  CatalogOption? _selectedCity;
  bool _selectingPlace = false;
  bool _locating = false;

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
      final detection = await detectAndReportLocation(
        context,
        catalogCities: catalogCities,
      );

      if (!mounted) return;

      if (detection.result == LocationDetectResult.success) {
        setState(() => _selectedCity = detection.city);
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
          FlatmatesToast.error(
            context,
            AppLocalizations.of(context).locationDetectionFailed,
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
        FlatmatesToast.error(
          context,
          AppLocalizations.of(context).locationDetectionFailed,
        );
      }
    } finally {
      if (mounted) setState(() => _selectingPlace = false);
    }
  }

  List<CatalogOption> _catalogCities() {
    final bootstrap = ref.watch(bootstrapControllerProvider).valueOrNull;
    final catalogCities =
        bootstrap?.catalogOptions('flatmates_popular_cities') ?? const [];
    return resolveCities(catalogCities);
  }

  void _onCityTap(CatalogOption city) {
    if (city.comingSoon) {
      context.push('/waitlist?city=${Uri.encodeComponent(city.label)}');
      return;
    }
    setState(() {
      _selectedCity = city;
      _searchController.text = city.label;
    });
    ref.read(locationSearchProvider.notifier).clear();
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
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...cities.map(
          (city) => Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: LocationCityRow(
              key: Key('popular_city_${city.id}'),
              city: city,
              selected: _selectedCity?.id == city.id,
              onTap: () => _onCityTap(city),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    final searchState = ref.watch(locationSearchProvider);
    final locating = _locating;
    final hasPlacesResults = searchState.suggestions.isNotEmpty;
    final isPlacesLoading = searchState.isLoading || _selectingPlace;
    final typedCity = _typedCity;
    final catalogCities = _catalogCities();
    final popularCities = catalogCities.where((c) => c.isPopular).toList();
    final moreCities = catalogCities
        .where((c) => !c.isPopular && !c.comingSoon)
        .toList();
    final matchingCities = typedCity.isEmpty
        ? const <CatalogOption>[]
        : catalogCities.where((c) => cityMatchesQuery(c, typedCity)).toList();

    return Material(
      // Steps sit inside the onboarding FlatmatesScreen, which owns the
      // scaffold and safe area; this only gives fields a Material ancestor.
      type: MaterialType.transparency,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.lg,
          AppSpacing.screen,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Everything above the CTA scrolls, so the list keeps room
            // when the keyboard is open.
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locale.locationSelectionTitle,
                      style: theme.textTheme.headlineLarge,
                    ),
                    const SizedBox(height: AppSpacing.lg),
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
                    const SizedBox(height: AppSpacing.base),
                    LocationActionRow(
                      icon: Icons.my_location_outlined,
                      title: locating
                          ? locale.detectingLocation
                          : locale.useCurrentLocation,
                      onTap: locating ? null : _useCurrentLocation,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (typedCity.isEmpty) ...[
                      _citySection(locale.popularCitiesLabel, popularCities),
                      if (popularCities.isNotEmpty && moreCities.isNotEmpty)
                        const SizedBox(height: AppSpacing.md),
                      _citySection(locale.moreCitiesLabel, moreCities),
                    ] else if (matchingCities.isNotEmpty) ...[
                      _citySection(locale.matchingCitiesLabel, matchingCities),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    if (isPlacesLoading)
                      const FlatmatesSkeleton.list(itemCount: 3),
                    if (hasPlacesResults) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        locale.suggestionsLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppSemanticColors.textSecondaryFor(
                            theme.brightness,
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ...searchState.suggestions.map(
                        (suggestion) => Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.xs,
                          ),
                          child: LocationSuggestionRow(
                            suggestion: suggestion,
                            onTap: _selectingPlace
                                ? null
                                : () => _selectPlace(suggestion),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                bottom: AppSpacing.xl,
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
