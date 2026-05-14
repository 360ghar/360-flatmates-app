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
import '../bootstrap/bootstrap_controller.dart';
import '../bootstrap/catalog_helpers.dart';
import '../location/application/location_search_provider.dart';
import '../shared/presentation/components.dart';

class LocationSearchPage extends ConsumerStatefulWidget {
  final ValueChanged<LocationData>? onLocationSelected;
  final bool showRadiusSlider;

  const LocationSearchPage({
    super.key,
    this.onLocationSelected,
    this.showRadiusSlider = false,
  });

  @override
  ConsumerState<LocationSearchPage> createState() => _LocationSearchPageState();
}

class _LocationSearchPageState extends ConsumerState<LocationSearchPage> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  bool _locating = false;
  bool _selectingPlace = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      ref
          .read(locationSearchProvider.notifier)
          .onSearchChanged(_searchController.text);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
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
          final city = detection.city!;
          final lat = (city.meta['latitude'] as num?)?.toDouble() ?? 0.0;
          final lng = (city.meta['longitude'] as num?)?.toDouble() ?? 0.0;
          final locationData = LocationData(
            name: city.label,
            latitude: lat,
            longitude: lng,
          );
          _returnResult(locationData);
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

      final locationData = LocationData(
        name: details.name,
        latitude: details.latitude,
        longitude: details.longitude,
      );
      _returnResult(locationData);
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

  void _returnResult(LocationData locationData) {
    if (widget.onLocationSelected != null) {
      widget.onLocationSelected!(locationData);
    } else {
      context.pop<LocationData>(locationData);
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
                autofocus: true,
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
              ),
              child: InkWell(
                onTap: _locating ? null : _useCurrentLocation,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Row(
                    children: [
                      Icon(
                        Icons.my_location_outlined,
                        color: AppSemanticColors.accent,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          _locating
                              ? locale.detectingLocation
                              : locale.useCurrentLocation,
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
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
              ),
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
              const SizedBox(height: AppSpacing.sm),
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
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screen,
                  ),
                  itemCount: searchState.suggestions.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final suggestion = searchState.suggestions[index];
                    return FlatmatesCard(
                      onTap: _selectingPlace
                          ? null
                          : () => _selectPlace(suggestion),
                      borderColor: AppSemanticColors.line.withValues(
                        alpha: 0.35,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            color: AppSemanticColors.accent,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  suggestion.mainText,
                                  style: theme.textTheme.bodyLarge,
                                ),
                                if (suggestion.secondaryText.isNotEmpty)
                                  Text(
                                    suggestion.secondaryText,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppSemanticColors.textSecondaryFor(
                                        theme.brightness,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: AppSemanticColors.line,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
            if (!hasPlacesResults && !isPlacesLoading)
              Expanded(
                child: Center(
                  child: Text(
                    locale.noLocationsAvailable,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
