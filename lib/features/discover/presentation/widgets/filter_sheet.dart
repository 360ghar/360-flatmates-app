import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../bootstrap/bootstrap_controller.dart';
import '../../../bootstrap/catalog_helpers.dart';
import '../../../shared/presentation/components.dart';
import '../../application/discover_feed_controller.dart';
import '../../discover_repository.dart';
import 'search_active_filter_chips.dart';
import 'search_budget_filter_card.dart';
import 'search_filter_widgets.dart';
import 'search_more_filters_card.dart';

/// Shows the search filters as a compact, frosted bottom-sheet modal.
///
/// Used from every filter entry point (Discover home, Browse Listings,
/// Map, Swipe) in place of the old full-screen `/search-filters` page.
Future<void> showFiltersSheet(BuildContext context) {
  return FlatmatesBottomSheet.show<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const FilterSheet(),
  );
}

/// The filter form rendered inside [showFiltersSheet].
/// Primary filters stay expanded; lifestyle prefs collapse under a header.
class FilterSheet extends ConsumerStatefulWidget {
  const FilterSheet({super.key});

  @override
  ConsumerState<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<FilterSheet> {
  final _searchController = TextEditingController();
  bool _initialized = false;

  static const double _budgetMin = 5000;
  static const double _budgetMax = 100000;
  RangeValues _budgetValues = const RangeValues(5000, 50000);

  String? _selectedRoomType;
  String? _selectedFurnishing;
  String? _selectedGender;
  String? _selectedMoveIn;
  String? _selectedPets;
  String? _selectedSmoking;
  String? _selectedDrinking;
  final _selectedKitchenTypes = <String>{};
  final _selectedAmenities = <String>{};
  String? _selectedVentilation;
  bool? _hasLift;
  int? _windowsMin;
  RangeValues _ageValues = const RangeValues(_ageMin, _ageMax);
  static const double _ageMin = 18;
  static const double _ageMax = 60;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<({String id, String label})> _catalogOrFallback(
    String catalogKey,
    List<String> fallbackIds,
  ) {
    final bootstrap = ref.watch(bootstrapControllerProvider).valueOrNull;
    final catalogOptions = bootstrap?.catalogOptions(catalogKey);
    final locale = AppLocalizations.of(context);
    if (catalogOptions != null && catalogOptions.isNotEmpty) {
      return catalogOptions
          .map((opt) => (id: opt.id, label: opt.label))
          .toList();
    }
    return fallbackIds
        .map((id) => (id: id, label: _localizedLabel(locale, catalogKey, id)))
        .toList();
  }

  /// Ensures a leading "Any" option exists for single-select filter groups.
  ///
  /// Server catalogs often omit the synthetic any key; without it the
  /// segmented control's selected value (`any` when unset) matches nothing
  /// and no pill is highlighted.
  List<({String id, String label})> _catalogWithAny(
    String catalogKey,
    List<String> fallbackIds,
    String anyKey,
    String anyLabel,
  ) {
    final options = _catalogOrFallback(catalogKey, fallbackIds);
    if (options.any((o) => o.id == anyKey)) return options;
    return [(id: anyKey, label: anyLabel), ...options];
  }

  /// Map stored selection onto a catalog option id (handles private ↔ private_room).
  String _resolvedSelection(
    String? selected,
    List<({String id, String label})> options,
    String anyKey,
  ) {
    if (selected == null) return anyKey;
    if (options.any((o) => o.id == selected)) return selected;
    // Normalize room-type aliases when catalog uses backend ids.
    final aliases = switch (selected) {
      'private' => const ['private_room', 'master_bedroom', 'private'],
      'shared' => const ['shared_room', 'shared'],
      'private_room' ||
      'master_bedroom' => const ['private', 'private_room', 'master_bedroom'],
      'shared_room' => const ['shared', 'shared_room'],
      _ => <String>[selected],
    };
    for (final id in aliases) {
      if (options.any((o) => o.id == id)) return id;
    }
    return anyKey;
  }

  String _localizedLabel(
    AppLocalizations locale,
    String catalogKey,
    String id,
  ) {
    switch (catalogKey) {
      case 'flatmates_room_types':
        return switch (id) {
          'any' => locale.roomTypeAny,
          'private' => locale.roomTypePrivate,
          'shared' => locale.roomTypeShared,
          _ => humanizeFlatmatesToken(id),
        };
      case 'flatmates_furnishing':
        return switch (id) {
          'any' => locale.furnishingAny,
          'furnished' => locale.furnishingFurnished,
          'unfurnished' => locale.furnishingUnfurnished,
          _ => humanizeFlatmatesToken(id),
        };
      case 'flatmates_gender_options':
        return switch (id) {
          'any' => locale.genderFilterAny,
          'male' => locale.genderFilterMale,
          'female' => locale.genderFilterFemale,
          _ => humanizeFlatmatesToken(id),
        };
      case 'flatmates_move_in_timelines':
        return switch (id) {
          'any' => locale.moveInAnytime,
          'immediately' || 'immediate' => locale.timelineImmediately,
          'within_1_week' => locale.timelineWithin1Week,
          'within_2_weeks' => locale.timelineWithin2Weeks,
          'within_1_month' || 'this_month' => locale.timelineWithin1Month,
          'within_2_months' => locale.timelineWithin2Months,
          'within_3_months' => locale.timelineWithin3Months,
          'flexible' => locale.timelineFlexible,
          'next_month' => locale.moveInNextMonth,
          _ => humanizeFlatmatesToken(id),
        };
      case 'flatmates_pets_options':
        return switch (id) {
          'no_preference' => locale.petsNoPreference,
          'yes' => locale.petsYes,
          'no' => locale.petsNo,
          _ => humanizeFlatmatesToken(id),
        };
      case 'flatmates_smoking_options':
        return switch (id) {
          'no_preference' => locale.smokingNoPreference,
          'never' => locale.lifestyleValueNever,
          'occasionally' => locale.lifestyleValueOccasionally,
          'regularly' => locale.lifestyleValueRegularly,
          _ => humanizeFlatmatesToken(id),
        };
      case 'flatmates_drinking_options':
        return switch (id) {
          'no_preference' => locale.drinkingNoPreference,
          'never' => locale.lifestyleValueNever,
          'occasionally' => locale.lifestyleValueOccasionally,
          'regularly' => locale.lifestyleValueRegularly,
          _ => humanizeFlatmatesToken(id),
        };
      default:
        return humanizeFlatmatesToken(id);
    }
  }

  String _formatBudget(double value) {
    if (value >= 100000) {
      return '₹1,00,000+';
    }
    final intPart = value.round();
    final formatted = intPart.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{2})+(?=\d{3})($|\D))'),
      (m) => '${m[1]},',
    );
    return '₹$formatted';
  }

  String? _roomTypeSubtitle() {
    final locale = AppLocalizations.of(context);
    if (_selectedRoomType == null) return locale.roomTypeAny;
    if (_selectedRoomType == 'private') return locale.roomTypePrivate;
    if (_selectedRoomType == 'shared') return locale.roomTypeShared;
    return null;
  }

  String? _furnishingSubtitle() {
    final locale = AppLocalizations.of(context);
    if (_selectedFurnishing == null) return locale.furnishingAny;
    if (_selectedFurnishing == 'furnished') return locale.furnishingFurnished;
    if (_selectedFurnishing == 'unfurnished') {
      return locale.furnishingUnfurnished;
    }
    return null;
  }

  String? _genderSubtitle() {
    final locale = AppLocalizations.of(context);
    if (_selectedGender == null) return locale.genderFilterAny;
    if (_selectedGender == 'male') return locale.genderFilterMale;
    if (_selectedGender == 'female') return locale.genderFilterFemale;
    return null;
  }

  String? _moveInSubtitle() {
    final locale = AppLocalizations.of(context);
    if (_selectedMoveIn == null) return locale.moveInAnytime;
    return switch (_selectedMoveIn) {
      'immediately' || 'immediate' => locale.timelineImmediately,
      'within_1_week' => locale.timelineWithin1Week,
      'within_2_weeks' => locale.timelineWithin2Weeks,
      'within_1_month' || 'this_month' => locale.timelineWithin1Month,
      'within_2_months' => locale.timelineWithin2Months,
      'within_3_months' => locale.timelineWithin3Months,
      'flexible' => locale.timelineFlexible,
      'next_month' => locale.moveInNextMonth,
      _ => null,
    };
  }

  String? _petsSubtitle() {
    final locale = AppLocalizations.of(context);
    if (_selectedPets == null) return locale.petsNoPreference;
    if (_selectedPets == 'yes') return locale.petsYes;
    if (_selectedPets == 'no') return locale.petsNo;
    return null;
  }

  String? _smokingSubtitle() {
    final locale = AppLocalizations.of(context);
    if (_selectedSmoking == null) return locale.smokingNoPreference;
    return switch (_selectedSmoking) {
      'never' => locale.lifestyleValueNever,
      'occasionally' => locale.lifestyleValueOccasionally,
      'regularly' => locale.lifestyleValueRegularly,
      _ => null,
    };
  }

  String? _drinkingSubtitle() {
    final locale = AppLocalizations.of(context);
    if (_selectedDrinking == null) return locale.drinkingNoPreference;
    return switch (_selectedDrinking) {
      'never' => locale.lifestyleValueNever,
      'occasionally' => locale.lifestyleValueOccasionally,
      'regularly' => locale.lifestyleValueRegularly,
      _ => null,
    };
  }

  /// Resolves a catalog option id to its display label for active-filter chips.
  String _optionLabel(String catalogKey, String id) {
    final options = _catalogOrFallback(catalogKey, const []);
    return options
        .firstWhere((o) => o.id == id, orElse: () => (id: id, label: id))
        .label;
  }

  String? _normalizedSharingType() {
    return switch (_selectedRoomType) {
      'private' || 'private_room' || 'master_bedroom' => 'private_room',
      'shared' || 'shared_room' => 'shared_room',
      _ => null,
    };
  }

  String? _normalizedGenderPreference() {
    return switch (_selectedGender) {
      'male' || 'male_only' => 'male',
      'female' || 'female_only' => 'female',
      'any' || 'no_preference' => null,
      _ => null,
    };
  }

  List<(String, String, IconData?)> _segmentTuples(
    List<({String id, String label})> options,
  ) {
    return [
      for (final opt in options) (opt.id, opt.label, filterOptionIcon(opt.id)),
    ];
  }

  List<Key?> _segmentKeys(
    String prefix,
    List<({String id, String label})> options,
    String anyKey,
  ) {
    return [
      for (final opt in options)
        Key('${prefix}_${_segmentKeySuffix(opt.id, anyKey)}'),
    ];
  }

  String _segmentKeySuffix(String id, String anyKey) {
    if (id == anyKey) return 'any';
    return switch (id) {
      'private_room' || 'master_bedroom' => 'private',
      'shared_room' => 'shared',
      'no_preference' => 'any',
      _ => id,
    };
  }

  List<({String label, VoidCallback onRemove})> get _activeFilters {
    return [
      if (_budgetValues.start != _budgetMin || _budgetValues.end != _budgetMax)
        (
          label:
              '${_formatBudget(_budgetValues.start)} – ${_formatBudget(_budgetValues.end)}',
          onRemove: () => setState(
            () => _budgetValues = const RangeValues(_budgetMin, _budgetMax),
          ),
        ),
      if (_selectedRoomType != null)
        (
          label: _roomTypeSubtitle() ?? _selectedRoomType!,
          onRemove: () => setState(() => _selectedRoomType = null),
        ),
      if (_selectedFurnishing != null)
        (
          label: _furnishingSubtitle() ?? _selectedFurnishing!,
          onRemove: () => setState(() => _selectedFurnishing = null),
        ),
      if (_selectedGender != null)
        (
          label: _genderSubtitle() ?? _selectedGender!,
          onRemove: () => setState(() => _selectedGender = null),
        ),
      if (_selectedMoveIn != null)
        (
          label: _moveInSubtitle() ?? _selectedMoveIn!,
          onRemove: () => setState(() => _selectedMoveIn = null),
        ),
      if (_selectedPets != null)
        (
          label: _petsSubtitle() ?? _selectedPets!,
          onRemove: () => setState(() => _selectedPets = null),
        ),
      if (_selectedSmoking != null)
        (
          label: _smokingSubtitle() ?? _selectedSmoking!,
          onRemove: () => setState(() => _selectedSmoking = null),
        ),
      if (_selectedDrinking != null)
        (
          label: _drinkingSubtitle() ?? _selectedDrinking!,
          onRemove: () => setState(() => _selectedDrinking = null),
        ),
      if (_selectedKitchenTypes.isNotEmpty)
        (
          label: _selectedKitchenTypes
              .map((id) => _optionLabel('flatmates_kitchen_types', id))
              .join(', '),
          onRemove: () => setState(_selectedKitchenTypes.clear),
        ),
      if (_selectedVentilation != null)
        (
          label: _optionLabel(
            'flatmates_ventilation_options',
            _selectedVentilation!,
          ),
          onRemove: () => setState(() => _selectedVentilation = null),
        ),
      if (_selectedAmenities.isNotEmpty)
        (
          label: _selectedAmenities
              .map((id) => _optionLabel('flatmates_listing_amenities', id))
              .join(', '),
          onRemove: () => setState(_selectedAmenities.clear),
        ),
      if (_hasLift != null)
        (
          label: AppLocalizations.of(context).searchHasLiftLabel,
          onRemove: () => setState(() => _hasLift = null),
        ),
      if (_windowsMin != null)
        (
          label: _windowsMin! >= 10
              ? AppLocalizations.of(
                  context,
                ).searchWindowsMinOption(_windowsMin!)
              : '$_windowsMin+',
          onRemove: () => setState(() => _windowsMin = null),
        ),
      if (_ageValues.start != _ageMin || _ageValues.end != _ageMax)
        (
          label: '${_ageValues.start.round()} – ${_ageValues.end.round()} yrs',
          onRemove: () =>
              setState(() => _ageValues = const RangeValues(_ageMin, _ageMax)),
        ),
    ];
  }

  void _clearAllFilters() {
    setState(() {
      _searchController.clear();
      _budgetValues = const RangeValues(_budgetMin, _budgetMax);
      _selectedRoomType = null;
      _selectedFurnishing = null;
      _selectedGender = null;
      _selectedMoveIn = null;
      _selectedPets = null;
      _selectedSmoking = null;
      _selectedDrinking = null;
      _selectedKitchenTypes.clear();
      _selectedVentilation = null;
      _selectedAmenities.clear();
      _hasLift = null;
      _windowsMin = null;
      _ageValues = const RangeValues(_ageMin, _ageMax);
    });
  }

  void _applyFilters() {
    final filters = DiscoverFilters(
      query: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
      priceMin: _budgetValues.start == _budgetMin ? null : _budgetValues.start,
      priceMax: _budgetValues.end == _budgetMax ? null : _budgetValues.end,
      sharingType: _normalizedSharingType(),
      genderPreference: _normalizedGenderPreference(),
      features: [?_selectedFurnishing],
      furnishing: [?_selectedFurnishing],
      kitchenType: _selectedKitchenTypes.toList()..sort(),
      ventilationType: [?_selectedVentilation],
      amenities: _selectedAmenities.toList()..sort(),
      hasLift: _hasLift,
      windowsMin: _windowsMin,
      ageMin: _ageValues.start == _ageMin ? null : _ageValues.start.round(),
      ageMax: _ageValues.end == _ageMax ? null : _ageValues.end.round(),
      pets: _selectedPets,
      smoking: _selectedSmoking,
      drinking: _selectedDrinking,
      moveInTimeline: _selectedMoveIn,
    );
    ref.read(discoverFiltersProvider.notifier).set(filters);
    ref.read(discoverFeedControllerProvider.notifier).updateFilters(filters);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      _initialized = true;
      final existing = ref.read(discoverFiltersProvider);
      if (existing != null) {
        _budgetValues = RangeValues(
          existing.priceMin ?? _budgetMin,
          existing.priceMax ?? _budgetMax,
        );
        _selectedRoomType = switch (existing.sharingType) {
          'private_room' => 'private',
          'shared_room' => 'shared',
          _ => existing.sharingType,
        };
        _selectedFurnishing = existing.features.isNotEmpty
            ? existing.features.first
            : null;
        _selectedGender = existing.genderPreference;
        _selectedMoveIn = existing.moveInTimeline;
        _selectedPets = existing.pets;
        _selectedSmoking = existing.smoking;
        _selectedDrinking = existing.drinking;
        _selectedKitchenTypes
          ..clear()
          ..addAll(existing.kitchenType);
        _selectedVentilation = existing.ventilationType.isEmpty
            ? null
            : existing.ventilationType.first;
        _selectedAmenities
          ..clear()
          ..addAll(existing.amenities);
        _hasLift = existing.hasLift;
        _windowsMin = existing.windowsMin;
        _ageValues = RangeValues(
          (existing.ageMin ?? _ageMin).toDouble(),
          (existing.ageMax ?? _ageMax).toDouble(),
        );
        if (existing.query != null && existing.query!.isNotEmpty) {
          _searchController.text = existing.query!;
        }
      }
    }

    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final bootstrap = ref.watch(bootstrapControllerProvider);
    final showSkeleton = bootstrap.isLoading && bootstrap.valueOrNull == null;
    final showError = bootstrap.hasError && bootstrap.valueOrNull == null;
    final activeFilters = _activeFilters;

    // Bound sheet body height so the list scrolls instead of overflowing the
    // modal's maxHeight (Phase 2 content is taller: presets + segments).
    final sheetBodyHeight = MediaQuery.sizeOf(context).height * 0.78;

    final roomOptions = _catalogWithAny(
      'flatmates_room_types',
      const ['any', 'private', 'shared'],
      'any',
      locale.roomTypeAny,
    );
    final furnishingOptions = _catalogWithAny(
      'flatmates_furnishing',
      const ['any', 'furnished', 'unfurnished'],
      'any',
      locale.furnishingAny,
    );
    final genderOptions = _catalogWithAny(
      'flatmates_gender_options',
      const ['any', 'male', 'female'],
      'any',
      locale.genderFilterAny,
    );
    final moveInOptions = _catalogWithAny(
      'flatmates_move_in_timelines',
      const [
        'any',
        'immediately',
        'within_1_week',
        'within_2_weeks',
        'within_1_month',
        'within_2_months',
        'within_3_months',
        'flexible',
      ],
      'any',
      locale.moveInAnytime,
    );
    final ventilationOptions = _catalogWithAny(
      'flatmates_ventilation_options',
      const ['any', 'good', 'average', 'poor'],
      'any',
      humanizeFlatmatesToken('any'),
    );

    // Full width so the title can truly center in the sheet content area
    // (a shrink-wrapped Stack only centers within the text width).
    return SizedBox(
      width: double.infinity,
      height: sheetBodyHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  locale.searchFiltersTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                if (activeFilters.isNotEmpty)
                  Positioned(
                    right: 0,
                    child: FlatmatesButton.tertiary(
                      key: const Key('search_clear_filters'),
                      label: locale.clearAllFilters,
                      onPressed: _clearAllFilters,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (showSkeleton)
            const Expanded(child: FlatmatesSkeleton.searchFilters())
          else if (showError)
            Expanded(
              child: Center(
                child: FlatmatesErrorState(
                  message: locale.couldNotLoadListing,
                  onRetry: () =>
                      ref.read(bootstrapControllerProvider.notifier).refresh(),
                ),
              ),
            )
          else ...[
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: AppSpacing.base),
                children: [
                  FlatmatesSearchBar(
                    controller: _searchController,
                    hint: locale.homeSearchHint,
                    trailingIcon: AppIcons.search,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ActiveFilterChips(filters: activeFilters),
                  if (activeFilters.isNotEmpty)
                    const SizedBox(height: AppSpacing.sm),
                  BudgetFilterCard(
                    budgetValues: _budgetValues,
                    budgetMin: _budgetMin,
                    budgetMax: _budgetMax,
                    onChanged: (values) =>
                        setState(() => _budgetValues = values),
                    formatBudget: _formatBudget,
                  ),
                  const FilterSectionDivider(),
                  CompactFilterSection(
                    title: locale.roomTypeFilterLabel,
                    icon: Icons.bed_outlined,
                    iconColor: AppSemanticColors.blueMid,
                    iconBgColor: AppSemanticColors.blueSoft,
                    child: _filterChoice(
                      options: roomOptions,
                      selected: _resolvedSelection(
                        _selectedRoomType,
                        roomOptions,
                        'any',
                      ),
                      anyKey: 'any',
                      keyPrefix: 'search_room_type',
                      onSelected: (id) => setState(
                        () => _selectedRoomType = id == 'any' ? null : id,
                      ),
                    ),
                  ),
                  CompactFilterSection(
                    title: locale.furnishingFilterLabel,
                    icon: Icons.chair_outlined,
                    iconColor: AppSemanticColors.orangeMid,
                    iconBgColor: AppSemanticColors.orangeSoft,
                    child: _filterChoice(
                      options: furnishingOptions,
                      selected: _resolvedSelection(
                        _selectedFurnishing,
                        furnishingOptions,
                        'any',
                      ),
                      anyKey: 'any',
                      keyPrefix: 'search_furnishing',
                      onSelected: (id) => setState(
                        () => _selectedFurnishing = id == 'any' ? null : id,
                      ),
                    ),
                  ),
                  CompactFilterSection(
                    title: locale.genderFilterLabel,
                    icon: Icons.people_outlined,
                    iconColor: AppSemanticColors.purpleMid,
                    iconBgColor: AppSemanticColors.purpleSoft,
                    child: _filterChoice(
                      options: genderOptions,
                      selected: _resolvedSelection(
                        _selectedGender,
                        genderOptions,
                        'any',
                      ),
                      anyKey: 'any',
                      keyPrefix: 'search_gender',
                      onSelected: (id) => setState(
                        () => _selectedGender = id == 'any' ? null : id,
                      ),
                    ),
                  ),
                  CompactFilterSection(
                    title: locale.moveInFilterLabel,
                    icon: Icons.calendar_today_outlined,
                    iconColor: AppSemanticColors.tealMid,
                    iconBgColor: AppSemanticColors.tealSoft,
                    child: CatalogFilterChips(
                      options: moveInOptions,
                      selectedId: _resolvedSelection(
                        _selectedMoveIn,
                        moveInOptions,
                        'any',
                      ),
                      anyKey: 'any',
                      onSelected: (id) => setState(
                        () => _selectedMoveIn = id == 'any' ? null : id,
                      ),
                    ),
                  ),
                  CompactFilterSection(
                    title: locale.kitchenTypeLabel,
                    icon: Icons.restaurant_outlined,
                    iconColor: AppSemanticColors.greenMid,
                    iconBgColor: AppSemanticColors.greenSoft,
                    child: CatalogFilterChips(
                      options: _catalogOrFallback('flatmates_kitchen_types', [
                        'vegetarian',
                        'non_vegetarian',
                        'eggetarian',
                        'any',
                      ]),
                      selectedIds: _selectedKitchenTypes.toList(),
                      anyKey: 'any',
                      multiSelect: true,
                      onSelected: (id) => setState(() {
                        if (id == 'any') {
                          _selectedKitchenTypes.clear();
                        } else {
                          _selectedKitchenTypes.contains(id)
                              ? _selectedKitchenTypes.remove(id)
                              : _selectedKitchenTypes.add(id);
                        }
                      }),
                    ),
                  ),
                  CompactFilterSection(
                    title: locale.ventilationTypeLabel,
                    icon: Icons.air_outlined,
                    iconColor: AppSemanticColors.blueMid,
                    iconBgColor: AppSemanticColors.blueSoft,
                    child: CatalogFilterChips(
                      options: ventilationOptions,
                      selectedId: _resolvedSelection(
                        _selectedVentilation,
                        ventilationOptions,
                        'any',
                      ),
                      anyKey: 'any',
                      keyPrefix: 'search_ventilation',
                      onSelected: (id) => setState(
                        () => _selectedVentilation = id == 'any' ? null : id,
                      ),
                    ),
                  ),
                  CompactFilterSection(
                    title: locale.searchAmenitiesFilterLabel,
                    icon: Icons.checklist_outlined,
                    iconColor: AppSemanticColors.orangeMid,
                    iconBgColor: AppSemanticColors.orangeSoft,
                    child: CatalogFilterChips(
                      options: _catalogOrFallback(
                        'flatmates_listing_amenities',
                        const [],
                      ),
                      selectedIds: _selectedAmenities.toList(),
                      multiSelect: true,
                      anyKey: 'any',
                      keyPrefix: 'search_amenity',
                      onSelected: (id) => setState(() {
                        _selectedAmenities.contains(id)
                            ? _selectedAmenities.remove(id)
                            : _selectedAmenities.add(id);
                      }),
                    ),
                  ),
                  CompactFilterSection(
                    title: locale.searchWindowsMinLabel,
                    icon: Icons.window_outlined,
                    iconColor: AppSemanticColors.purpleMid,
                    iconBgColor: AppSemanticColors.purpleSoft,
                    child: Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [2, 5, 10].map((count) {
                        return FlatmatesChip(
                          variant: FlatmatesChipVariant.choice,
                          label: count >= 10
                              ? locale.searchWindowsMinOption(count)
                              : '$count+',
                          selected: _windowsMin == count,
                          onSelected: (_) => setState(
                            () => _windowsMin = _windowsMin == count
                                ? null
                                : count,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  CompactFilterSection(
                    title: locale.searchHasLiftLabel,
                    icon: Icons.elevator_outlined,
                    iconColor: AppSemanticColors.tealMid,
                    iconBgColor: AppSemanticColors.tealSoft,
                    child: FlatmatesSegmentedControl<bool?>(
                      segments: [
                        (true, locale.prefYes, Icons.check_rounded),
                        (false, locale.prefNo, Icons.close_rounded),
                        (null, locale.prefNoPreference, Icons.remove_rounded),
                      ],
                      selected: _hasLift,
                      onChanged: (v) => setState(() => _hasLift = v),
                    ),
                  ),
                  CompactFilterSection(
                    title: locale.ageRangeLabel,
                    icon: Icons.cake_outlined,
                    iconColor: AppSemanticColors.greenMid,
                    iconBgColor: AppSemanticColors.greenSoft,
                    child: RangeSlider(
                      values: _ageValues,
                      min: _ageMin,
                      max: _ageMax,
                      divisions: 21,
                      labels: RangeLabels(
                        '${_ageValues.start.round()}',
                        '${_ageValues.end.round()}',
                      ),
                      onChanged: (v) => setState(() => _ageValues = v),
                    ),
                  ),
                  const FilterSectionDivider(),
                  MoreFiltersCard(
                    selectedPets: _selectedPets,
                    selectedSmoking: _selectedSmoking,
                    selectedDrinking: _selectedDrinking,
                    onPetsChanged: (v) => setState(() => _selectedPets = v),
                    onSmokingChanged: (v) =>
                        setState(() => _selectedSmoking = v),
                    onDrinkingChanged: (v) =>
                        setState(() => _selectedDrinking = v),
                    catalogOrFallback: _catalogOrFallback,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FlatmatesButton(
              key: const Key('search_show_results_button'),
              label: activeFilters.isEmpty
                  ? locale.showResultsCta
                  : locale.showResultsWithFiltersCta(activeFilters.length),
              icon: AppIcons.filter,
              fullWidth: true,
              onPressed: _applyFilters,
            ),
          ],
        ],
      ),
    );
  }

  /// Prefer a compact segmented control for 2–3 options; fall back to chips
  /// when the catalog is larger so labels never overflow a fixed segment row.
  Widget _filterChoice({
    required List<({String id, String label})> options,
    required String selected,
    required String anyKey,
    required String keyPrefix,
    required ValueChanged<String> onSelected,
  }) {
    if (options.length <= 3) {
      return FlatmatesSegmentedControl<String>(
        segments: _segmentTuples(options),
        selected: selected,
        onChanged: onSelected,
        segmentKeys: _segmentKeys(keyPrefix, options, anyKey),
      );
    }
    return CatalogFilterChips(
      keyPrefix: keyPrefix,
      options: options,
      selectedId: selected,
      anyKey: anyKey,
      onSelected: onSelected,
    );
  }
}
