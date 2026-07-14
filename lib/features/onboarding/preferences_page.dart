import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../bootstrap/catalog_helpers.dart';
import '../shared/presentation/components.dart';
import 'onboarding_controller.dart';

class PreferencesPage extends ConsumerStatefulWidget {
  const PreferencesPage({required this.onComplete, super.key});

  final void Function(Map<String, dynamic> preferences) onComplete;

  @override
  ConsumerState<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends ConsumerState<PreferencesPage> {
  String _preferredGender = 'no_preference';
  String _allowedFlatmates = '1';
  String _foodHabits = 'no_preference';
  String _pets = 'no_preference';
  String _smoking = 'no';

  @override
  void initState() {
    super.initState();
    // Restore previously-selected preferences so going back/forward or
    // resuming a saved draft retains the user's choices.
    // Move-in timeline is owned by the budget step — not duplicated here.
    final saved = ref.read(onboardingControllerProvider).preferences;
    if (saved.isEmpty) return;
    _preferredGender =
        saved['gender_preference']?.toString() ?? _preferredGender;
    _allowedFlatmates =
        saved['allowed_flatmates']?.toString() ?? _allowedFlatmates;
    _foodHabits = saved['food_habits']?.toString() ?? _foodHabits;
    _pets = saved['pets']?.toString() ?? _pets;
    _smoking = saved['smoking']?.toString() ?? _smoking;
  }

  /// Resolve pill options from a catalog key, falling back to hardcoded values.
  List<_PillOption> _catalogPills(
    String catalogKey,
    List<_PillOption> fallback,
  ) {
    final bootstrap = ref.watch(bootstrapControllerProvider).valueOrNull;
    final catalogOptions = bootstrap?.catalogOptions(catalogKey);
    if (catalogOptions != null && catalogOptions.isNotEmpty) {
      return catalogOptions
          .map(
            (opt) => _PillOption(
              key: _normalizeCatalogValue(catalogKey, opt.id),
              label: opt.label,
            ),
          )
          .toList();
    }
    return fallback;
  }

  String _normalizeCatalogValue(String catalogKey, String value) {
    if (catalogKey == 'flatmates_food_habits') {
      return switch (value) {
        'veg' => 'vegetarian',
        'non_veg' => 'non_vegetarian',
        _ => value,
      };
    }
    return value;
  }

  // --- Hardcoded fallback option lists ---

  static const _fallbackGenderOptions = [
    _PillOption(key: 'no_preference', label: ''), // resolved via locale
    _PillOption(key: 'male_only', label: ''),
    _PillOption(key: 'female_only', label: ''),
    _PillOption(key: 'other', label: ''),
  ];

  static const _fallbackFoodOptions = [
    _PillOption(key: 'vegetarian', label: ''),
    _PillOption(key: 'non_vegetarian', label: ''),
    _PillOption(key: 'eggetarian', label: ''),
    _PillOption(key: 'no_preference', label: ''),
  ];

  static const _fallbackPetsOptions = [
    _PillOption(key: 'yes', label: ''),
    _PillOption(key: 'no', label: ''),
    _PillOption(key: 'no_preference', label: ''),
  ];

  static const _fallbackSmokingOptions = [
    _PillOption(key: 'no', label: ''),
    _PillOption(key: 'yes', label: ''),
    _PillOption(key: 'no_preference', label: ''),
  ];

  /// Get gender options: catalog first, then localized fallback.
  List<_PillOption> get _genderOptions {
    final catalog = _catalogPills(
      'flatmates_gender_options',
      _fallbackGenderOptions,
    );
    // If catalog returned items with real labels, use them directly
    if (catalog.isNotEmpty && catalog.first.label.isNotEmpty) return catalog;
    // Otherwise use localized fallback labels
    final locale = AppLocalizations.of(context);
    return [
      _PillOption(key: 'no_preference', label: locale.prefNoPreference),
      _PillOption(key: 'male_only', label: locale.prefMaleOnly),
      _PillOption(key: 'female_only', label: locale.prefFemaleOnly),
      _PillOption(key: 'other', label: locale.prefOther),
    ];
  }

  List<_PillOption> get _foodOptions {
    final catalog = _catalogPills(
      'flatmates_food_habits',
      _fallbackFoodOptions,
    );
    if (catalog.isNotEmpty && catalog.first.label.isNotEmpty) return catalog;
    final locale = AppLocalizations.of(context);
    return [
      _PillOption(key: 'vegetarian', label: locale.prefVeg),
      _PillOption(key: 'non_vegetarian', label: locale.prefNonVeg),
      _PillOption(key: 'eggetarian', label: locale.prefEggetarian),
      _PillOption(key: 'no_preference', label: locale.prefNoPreference),
    ];
  }

  List<_PillOption> get _petsOptions {
    final catalog = _catalogPills(
      'flatmates_pets_options',
      _fallbackPetsOptions,
    );
    if (catalog.isNotEmpty && catalog.first.label.isNotEmpty) return catalog;
    final locale = AppLocalizations.of(context);
    return [
      _PillOption(key: 'yes', label: locale.prefYes),
      _PillOption(key: 'no', label: locale.prefNo),
      _PillOption(key: 'no_preference', label: locale.prefNoPreference),
    ];
  }

  List<_PillOption> get _smokingOptions {
    final catalog = _catalogPills(
      'flatmates_smoking_options',
      _fallbackSmokingOptions,
    );
    if (catalog.isNotEmpty && catalog.first.label.isNotEmpty) return catalog;
    final locale = AppLocalizations.of(context);
    return [
      _PillOption(key: 'no', label: locale.prefNo),
      _PillOption(key: 'yes', label: locale.prefYes),
      _PillOption(key: 'no_preference', label: locale.prefNoPreference),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final controllerState = ref.watch(onboardingControllerProvider);
    final completionPct = controllerState.completionPercentage;

    return FlatmatesScreen(
      scrollable: true,
      padding: AppSpacing.horizontalScreen,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.sm),
          FlatmatesStepProgress.segments(
            currentStep: completionPct.round(),
            totalSteps: 100,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(locale.preferencesTitle, style: theme.textTheme.headlineLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            locale.preferencesSubtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppSemanticColors.textSecondaryFor(theme.brightness),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // 1. Preferred Gender
          _PreferenceSection(
            icon: Icons.wc_outlined,
            title: locale.prefGenderLabel,
            children: [
              _pillOptions(
                options: _genderOptions,
                selectedKey: _preferredGender,
                onSelected: (v) => setState(() => _preferredGender = v),
              ),
            ],
          ),

          // 2. Allowed Flatmates
          _PreferenceSection(
            icon: Icons.group_outlined,
            title: locale.prefFlatmatesLabel,
            children: [
              _pillOptions(
                options: [
                  const _PillOption(key: '1', label: '1'),
                  const _PillOption(key: '2', label: '2'),
                  const _PillOption(key: '3', label: '3'),
                  const _PillOption(key: '4+', label: '4+'),
                ],
                selectedKey: _allowedFlatmates,
                onSelected: (v) => setState(() => _allowedFlatmates = v),
              ),
            ],
          ),

          // 3. Food Habits
          _PreferenceSection(
            icon: Icons.restaurant_outlined,
            title: locale.prefFoodLabel,
            children: [
              _pillOptions(
                options: _foodOptions,
                selectedKey: _foodHabits,
                onSelected: (v) => setState(() => _foodHabits = v),
              ),
            ],
          ),

          // 4. Pets
          _PreferenceSection(
            icon: Icons.pets_outlined,
            title: locale.prefPetsLabel,
            children: [
              _pillOptions(
                options: _petsOptions,
                selectedKey: _pets,
                onSelected: (v) => setState(() => _pets = v),
              ),
            ],
          ),

          // 5. Smoking
          _PreferenceSection(
            icon: Icons.smoke_free_outlined,
            title: locale.prefSmokingLabel,
            children: [
              _pillOptions(
                options: _smokingOptions,
                selectedKey: _smoking,
                onSelected: (v) => setState(() => _smoking = v),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.screen + AppSpacing.lg),
          FlatmatesButton(
            key: const Key('onboarding_preferences_next'),
            label: locale.prefNext,
            fullWidth: true,
            onPressed: () => widget.onComplete({
              'gender_preference': _preferredGender,
              'allowed_flatmates': _allowedFlatmates,
              'food_habits': _foodHabits,
              'pets': _pets,
              'smoking': _smoking,
            }),
            icon: Icons.arrow_forward_rounded,
          ),
        ],
      ),
    );
  }

  Widget _pillOptions({
    required List<_PillOption> options,
    required String selectedKey,
    required ValueChanged<String> onSelected,
  }) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: options.map((opt) {
        final isSelected = selectedKey == opt.key;
        return FlatmatesChip(
          key: Key('pref_${opt.key}'),
          label: opt.label,
          variant: FlatmatesChipVariant.choice,
          selected: isSelected,
          onSelected: (_) => onSelected(opt.key),
        );
      }).toList(),
    );
  }
}

class _PreferenceSection extends StatelessWidget {
  const _PreferenceSection({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: FlatmatesCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppSemanticColors.accent, size: 22),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _PillOption {
  const _PillOption({required this.key, required this.label});

  final String key;
  final String label;
}
