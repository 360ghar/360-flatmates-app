import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_semantic_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../bootstrap/catalog_helpers.dart';
import '../shared/presentation/flatmates_bottom_action_bar.dart';
import '../shared/presentation/flatmates_error_state.dart';
import '../shared/presentation/flatmates_header.dart';
import '../shared/presentation/flatmates_skeleton.dart';
import '../shared/presentation/flatmates_search_bar.dart';
import '../shared/presentation/flatmates_ui.dart';
import 'application/discover_feed_controller.dart';
import 'discover_repository.dart';
import 'presentation/widgets/search_active_filter_chips.dart';
import 'presentation/widgets/search_budget_filter_card.dart';
import 'presentation/widgets/search_filter_widgets.dart';
import 'presentation/widgets/search_more_filters_card.dart';

class SearchFiltersPage extends ConsumerStatefulWidget {
  const SearchFiltersPage({super.key});

  @override
  ConsumerState<SearchFiltersPage> createState() => _SearchFiltersPageState();
}

class _SearchFiltersPageState extends ConsumerState<SearchFiltersPage> {
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
          'immediate' => locale.moveInImmediate,
          'this_month' => locale.moveInThisMonth,
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
          'no' => locale.smokingNo,
          'yes' => locale.smokingYes,
          _ => humanizeFlatmatesToken(id),
        };
      default:
        return humanizeFlatmatesToken(id);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    if (_selectedMoveIn == 'immediate') return locale.moveInImmediate;
    if (_selectedMoveIn == 'this_month') return locale.moveInThisMonth;
    if (_selectedMoveIn == 'next_month') return locale.moveInNextMonth;
    return null;
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
    if (_selectedSmoking == 'yes') return locale.smokingYes;
    if (_selectedSmoking == 'no') return locale.smokingNo;
    return null;
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
    ];
  }

  void _clearAllFilters() {
    setState(() {
      _budgetValues = const RangeValues(_budgetMin, _budgetMax);
      _selectedRoomType = null;
      _selectedFurnishing = null;
      _selectedGender = null;
      _selectedMoveIn = null;
      _selectedPets = null;
      _selectedSmoking = null;
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
      pets: _selectedPets,
      smoking: _selectedSmoking,
      moveInTimeline: _selectedMoveIn,
    );
    ref.read(discoverFiltersProvider.notifier).state = filters;
    ref.read(discoverFeedControllerProvider.notifier).updateFilters(filters);
    context.go('/discover');
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
        _selectedFurnishing =
            existing.features.isNotEmpty ? existing.features.first : null;
        _selectedGender = existing.genderPreference;
        _selectedMoveIn = existing.moveInTimeline;
        _selectedPets = existing.pets;
        _selectedSmoking = existing.smoking;
        if (existing.query != null && existing.query!.isNotEmpty) {
          _searchController.text = existing.query!;
        }
      }
    }

    final locale = AppLocalizations.of(context);
    final listings = ref.watch(discoverListingsProvider);
    final activeFilters = _activeFilters;

    return Scaffold(
      appBar: FlatmatesHeader.backTitle(
        title: locale.searchFiltersTitle,
        actions: [
          if (activeFilters.isNotEmpty)
            FlatmatesButton.tertiary(
              key: const Key('search_clear_filters'),
              label: locale.clearAllFilters,
              onPressed: _clearAllFilters,
            ),
        ],
      ),
      body: SafeArea(
        child: listings.when(
          data: (items) {
            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.xl,
                    ),
                    children: [
                      FlatmatesSearchBar(
                        controller: _searchController,
                        hint: locale.homeSearchHint,
                        trailingIcon: Icons.search_rounded,
                      ),
                      ActiveFilterChips(filters: activeFilters),
                      const SizedBox(height: AppSpacing.lg),
                      BudgetFilterCard(
                        budgetValues: _budgetValues,
                        budgetMin: _budgetMin,
                        budgetMax: _budgetMax,
                        onChanged: (values) =>
                            setState(() => _budgetValues = values),
                        formatBudget: _formatBudget,
                      ),
                      FilterSectionCard(
                        title: locale.roomTypeFilterLabel,
                        subtitle: _roomTypeSubtitle(),
                        icon: Icons.bed_outlined,
                        iconColor: AppSemanticColors.blueMid,
                        iconBgColor: AppSemanticColors.blueSoft,
                        child: CatalogFilterChips(
                          options: _catalogOrFallback('flatmates_room_types', [
                            'any',
                            'private',
                            'shared',
                          ]),
                          selectedId: _selectedRoomType ?? 'any',
                          anyKey: 'any',
                          onSelected: (id) => setState(
                            () => _selectedRoomType = id == 'any' ? null : id,
                          ),
                        ),
                      ),
                      FilterSectionCard(
                        title: locale.furnishingFilterLabel,
                        subtitle: _furnishingSubtitle(),
                        icon: Icons.chair_outlined,
                        iconColor: AppSemanticColors.orangeMid,
                        iconBgColor: AppSemanticColors.orangeSoft,
                        child: CatalogFilterChips(
                          options:
                              _catalogOrFallback('flatmates_furnishing', [
                            'any',
                            'furnished',
                            'unfurnished',
                          ]),
                          selectedId: _selectedFurnishing ?? 'any',
                          anyKey: 'any',
                          onSelected: (id) => setState(
                            () =>
                                _selectedFurnishing = id == 'any' ? null : id,
                          ),
                        ),
                      ),
                      FilterSectionCard(
                        title: locale.genderFilterLabel,
                        subtitle: _genderSubtitle(),
                        icon: Icons.people_outlined,
                        iconColor: AppSemanticColors.purpleMid,
                        iconBgColor: AppSemanticColors.purpleSoft,
                        child: CatalogFilterChips(
                          options: _catalogOrFallback(
                            'flatmates_gender_options',
                            ['any', 'male', 'female'],
                          ),
                          selectedId: _selectedGender ?? 'any',
                          anyKey: 'any',
                          onSelected: (id) => setState(
                            () => _selectedGender = id == 'any' ? null : id,
                          ),
                        ),
                      ),
                      FilterSectionCard(
                        title: locale.moveInFilterLabel,
                        subtitle: _moveInSubtitle(),
                        icon: Icons.calendar_today_outlined,
                        iconColor: AppSemanticColors.tealMid,
                        iconBgColor: AppSemanticColors.tealSoft,
                        child: CatalogFilterChips(
                          options: _catalogOrFallback(
                            'flatmates_move_in_timelines',
                            ['any', 'immediate', 'this_month', 'next_month'],
                          ),
                          selectedId: _selectedMoveIn ?? 'any',
                          anyKey: 'any',
                          onSelected: (id) => setState(
                            () => _selectedMoveIn = id == 'any' ? null : id,
                          ),
                        ),
                      ),
                      MoreFiltersCard(
                        selectedPets: _selectedPets,
                        selectedSmoking: _selectedSmoking,
                        onPetsChanged: (v) =>
                            setState(() => _selectedPets = v),
                        onSmokingChanged: (v) =>
                            setState(() => _selectedSmoking = v),
                        catalogOrFallback: _catalogOrFallback,
                      ),
                    ],
                  ),
                ),
                FlatmatesBottomActionBar(
                  primaryButtonKey: const Key('search_show_results_button'),
                  label: locale.showResultsCta,
                  icon: Icons.filter_list_rounded,
                  onPressed: _applyFilters,
                ),
              ],
            );
          },
          loading: () => const FlatmatesSkeleton.list(),
          error: (error, _) =>
              const FlatmatesErrorState(message: 'Could not load filters'),
        ),
      ),
    );
  }
}
