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
import '../bootstrap/bootstrap_controller.dart';
import '../bootstrap/catalog_helpers.dart';
import '../location/application/location_search_provider.dart';
import '../location/presentation/location_picker_rows.dart';
import '../shared/presentation/components.dart';
import '../shared/presentation/paper/paper_scene.dart';

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

  // Ephemeral page state (setState).
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
      final detection = await detectAndReportLocation(
        context,
        catalogCities: catalogCities,
      );

      if (!mounted) return;

      if (detection.result == LocationDetectResult.success) {
        final city = detection.city!;
        final lat = (city.meta['latitude'] as num?)?.toDouble() ?? 0.0;
        final lng = (city.meta['longitude'] as num?)?.toDouble() ?? 0.0;
        _returnResult(
          LocationData(name: city.label, latitude: lat, longitude: lng),
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
          FlatmatesToast.error(
            context,
            AppLocalizations.of(context).locationDetectionFailed,
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
        FlatmatesToast.error(
          context,
          AppLocalizations.of(context).locationDetectionFailed,
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
    final hasQuery = _searchController.text.trim().isNotEmpty;

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
            autofocus: true,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.sm),
          LocationActionRow(
            icon: Icons.my_location_outlined,
            title: _locating
                ? locale.detectingLocation
                : locale.useCurrentLocation,
            onTap: _locating ? null : _useCurrentLocation,
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: isPlacesLoading
                ? const SingleChildScrollView(
                    child: FlatmatesSkeleton.settingsList(itemCount: 3),
                  )
                : hasPlacesResults
                ? ListView(
                    children: [
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
                            onTap: _selectingPlace
                                ? null
                                : () => _selectPlace(suggestion),
                          ),
                        ),
                    ],
                  )
                // Only after the user has typed: an empty page on open is
                // not "no results".
                : hasQuery
                ? FlatmatesEmptyState(
                    title: locale.noLocationsAvailable,
                    prop: PaperProp.magnifier,
                    padHorizontally: false,
                    expand: true,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
