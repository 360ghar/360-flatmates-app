import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../core/location/location_helpers.dart';
import '../../core/location/place_suggestion.dart';
import '../../core/theme/app_semantic_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../location/application/location_search_provider.dart';
import '../location/presentation/location_picker_rows.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../bootstrap/catalog_helpers.dart';
import '../shared/presentation/components.dart';
import '../profile/profile_repository.dart';

class ChangeLocationPage extends ConsumerStatefulWidget {
  const ChangeLocationPage({super.key});

  @override
  ConsumerState<ChangeLocationPage> createState() => _ChangeLocationPageState();
}

class _ChangeLocationPageState extends ConsumerState<ChangeLocationPage> {
  final _searchController = TextEditingController();
  CatalogOption? _selectedCity;
  bool _locating = false;
  bool _saving = false;
  bool _selectingPlace = false;

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

  Future<void> _save() async {
    if (_selectedCity == null || _saving) return;
    setState(() => _saving = true);

    final locale = AppLocalizations.of(context);
    try {
      await ref
          .read(profileRepositoryProvider)
          .updateProfile(payload: {'city': _selectedCity!.label});
      await ref.read(bootstrapControllerProvider.notifier).refresh();
      if (!mounted) return;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(locale.locationUpdated),
            duration: const Duration(seconds: 2),
          ),
        );
        if (mounted) context.pop();
      }
    } catch (e) {
      debugPrint('ChangeLocationPage._save failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(locale.actionFailedRetry)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
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
    final bootstrap = ref.watch(bootstrapControllerProvider).valueOrNull;
    final catalogCities =
        bootstrap?.catalogOptions('flatmates_popular_cities') ?? const [];
    final cities = resolveCities(catalogCities);
    final query = _searchController.text.trim().toLowerCase();
    final visibleCities = query.isEmpty
        ? cities
        : cities.where((c) => cityMatchesQuery(c, query)).toList();
    final searchState = ref.watch(locationSearchProvider);
    final hasPlacesResults = searchState.suggestions.isNotEmpty;
    final isPlacesLoading = searchState.isLoading || _selectingPlace;

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
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
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
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
              ),
              child: LocationActionRow(
                icon: Icons.my_location_outlined,
                title: _locating
                    ? locale.detectingLocation
                    : locale.useCurrentLocation,
                onTap: _locating ? null : _useCurrentLocation,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              child: Divider(color: AppSemanticColors.line),
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
                    onTap: _selectingPlace
                        ? null
                        : () => _selectPlace(suggestion),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
              ),
              child: Text(
                locale.popularCitiesLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppSemanticColors.textSecondaryFor(theme.brightness),
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: visibleCities.isEmpty
                  ? Center(
                      child: Text(
                        locale.noLocationsAvailable,
                        style: theme.textTheme.bodyMedium,
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screen,
                      ),
                      itemCount: visibleCities.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final city = visibleCities[index];
                        final selected = _selectedCity?.id == city.id;
                        return LocationCityRow(
                          city: city,
                          selected: selected,
                          onTap: city.comingSoon
                              ? null
                              : () => setState(() => _selectedCity = city),
                        );
                      },
                    ),
            ),
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
                onPressed: _selectedCity == null || _saving ? null : _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
