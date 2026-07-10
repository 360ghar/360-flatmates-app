import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../bootstrap/catalog_helpers.dart';
import '../shared/presentation/components.dart';
import 'onboarding_controller.dart';

class NonNegotiablesPage extends ConsumerStatefulWidget {
  const NonNegotiablesPage({required this.onComplete, super.key});

  final void Function(List<String> nonNegotiables) onComplete;

  @override
  ConsumerState<NonNegotiablesPage> createState() => _NonNegotiablesPageState();
}

class _NonNegotiablesPageState extends ConsumerState<NonNegotiablesPage> {
  final _selected = <String>{};

  @override
  void initState() {
    super.initState();
    // Restore previously-chosen non-negotiables on back/forward or resume,
    // capping at the same 3-item limit enforced by the UI.
    _selected.addAll(
      ref.read(onboardingControllerProvider).nonNegotiables.take(3),
    );
  }

  /// Hardcoded fallback options used when the backend catalog is unavailable.
  static const _fallbackOptions = [
    _NonNegOption(key: 'food_veg_only', icon: Icons.restaurant_outlined),
    _NonNegOption(key: 'food_vegan_only', icon: Icons.eco_outlined),
    _NonNegOption(key: 'no_smoking', icon: Icons.smoke_free_outlined),
    _NonNegOption(key: 'no_drinking', icon: Icons.no_drinks_outlined),
    _NonNegOption(key: 'no_overnight_guests', icon: Icons.bed_outlined),
    _NonNegOption(key: 'no_pets', icon: Icons.pets_outlined),
    _NonNegOption(key: 'gender_female_only', icon: Icons.female_outlined),
    _NonNegOption(key: 'gender_male_only', icon: Icons.male_outlined),
    _NonNegOption(key: 'no_parties', icon: Icons.music_off_outlined),
    _NonNegOption(key: 'min_tidy', icon: Icons.cleaning_services_outlined),
  ];

  /// Resolve options: try backend catalog first, fall back to hardcoded.
  List<_NonNegOption> get _options {
    final bootstrap = ref.watch(bootstrapControllerProvider).valueOrNull;
    final catalogOptions = bootstrap?.catalogOptions(
      'flatmates_non_negotiables',
    );
    if (catalogOptions != null && catalogOptions.isNotEmpty) {
      return catalogOptions.map((opt) {
        final iconName = opt.meta['icon']?.toString() ?? '';
        return _NonNegOption(key: opt.id, icon: _iconFromName(iconName));
      }).toList();
    }
    return _fallbackOptions;
  }

  IconData _iconFromName(String name) {
    return switch (name) {
      'restaurant_outlined' => Icons.restaurant_outlined,
      'eco_outlined' => Icons.eco_outlined,
      'smoke_free_outlined' => Icons.smoke_free_outlined,
      'no_drinks_outlined' => Icons.no_drinks_outlined,
      'bed_outlined' => Icons.bed_outlined,
      'pets_outlined' => Icons.pets_outlined,
      'female_outlined' => Icons.female_outlined,
      'male_outlined' => Icons.male_outlined,
      'music_off_outlined' => Icons.music_off_outlined,
      'cleaning_services_outlined' => Icons.cleaning_services_outlined,
      _ => Icons.block_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final controllerState = ref.watch(onboardingControllerProvider);
    final completionPct = controllerState.completionPercentage;

    return Scaffold(
      body: SafeArea(
        minimum: AppSpacing.horizontalScreen,
        child: ListView(
          children: [
            const SizedBox(height: AppSpacing.sm),
            FlatmatesStepProgress.segments(
              currentStep: completionPct.round(),
              totalSteps: 100,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              locale.nonNegotiablesTitle,
              style: theme.textTheme.headlineLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              locale.nonNegotiablesSubtitle,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppSemanticColors.textSecondaryFor(theme.brightness),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                InfoPill(
                  icon: Icons.info_outline,
                  label: locale.nonNegotiablesLimit,
                  highlighted: true,
                ),
                const Spacer(),
                Text(
                  '${_selected.length}/3',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: _selected.length >= 3
                        ? AppSemanticColors.accent
                        : AppSemanticColors.textSecondaryFor(theme.brightness),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.screen),
            FlatmatesCard(
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _options.map((opt) {
                  final isSelected = _selected.contains(opt.key);
                  return FlatmatesChip(
                    key: Key('non_neg_${opt.key}'),
                    icon: opt.icon,
                    label: _label(locale, opt.key),
                    variant: FlatmatesChipVariant.choice,
                    selected: isSelected,
                    onSelected: isSelected
                        ? (_) => setState(() => _selected.remove(opt.key))
                        : _selected.length < 3
                        ? (_) => setState(() => _selected.add(opt.key))
                        : null,
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.screen + AppSpacing.lg),
            FlatmatesButton(
              key: const Key('onboarding_non_neg_done'),
              label: locale.onboardingComplete,
              fullWidth: true,
              onPressed: () => widget.onComplete(_selected.toList()),
              icon: Icons.check_rounded,
            ),
          ],
        ),
      ),
    );
  }

  String _label(AppLocalizations locale, String key) {
    // Try to find the label from the catalog first
    final bootstrap = ref.watch(bootstrapControllerProvider).valueOrNull;
    final catalogOptions = bootstrap?.catalogOptions(
      'flatmates_non_negotiables',
    );
    if (catalogOptions != null) {
      for (final opt in catalogOptions) {
        if (opt.id == key) return opt.label;
      }
    }
    // Fall back to localized hardcoded labels
    switch (key) {
      case 'food_veg_only':
        return locale.nonNegVegOnly;
      case 'food_vegan_only':
        return locale.nonNegVeganOnly;
      case 'no_smoking':
        return locale.nonNegNoSmoking;
      case 'no_drinking':
        return locale.nonNegNoDrinking;
      case 'no_overnight_guests':
        return locale.nonNegNoGuests;
      case 'no_pets':
        return locale.nonNegNoPets;
      case 'gender_female_only':
        return locale.nonNegFemaleOnly;
      case 'gender_male_only':
        return locale.nonNegMaleOnly;
      case 'no_parties':
        return locale.nonNegNoParties;
      case 'min_tidy':
        return locale.nonNegMinTidy;
      default:
        return key;
    }
  }
}

class _NonNegOption {
  const _NonNegOption({required this.key, required this.icon});

  final String key;
  final IconData icon;
}
