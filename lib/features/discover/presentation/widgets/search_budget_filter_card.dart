import 'package:flutter/material.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/flatmates_chip.dart';
import 'search_filter_widgets.dart';

/// Named rent bands used as quick budget presets (India market bands).
class BudgetPreset {
  const BudgetPreset({
    required this.id,
    required this.label,
    required this.range,
  });

  final String id;
  final String label;
  final RangeValues range;
}

class BudgetFilterCard extends StatelessWidget {
  const BudgetFilterCard({
    required this.budgetValues,
    required this.budgetMin,
    required this.budgetMax,
    required this.onChanged,
    required this.formatBudget,
    super.key,
  });

  final RangeValues budgetValues;
  final double budgetMin;
  final double budgetMax;
  final ValueChanged<RangeValues> onChanged;
  final String Function(double) formatBudget;

  List<BudgetPreset> _presets(AppLocalizations locale) {
    return [
      BudgetPreset(
        id: 'any',
        label: locale.budgetPresetAny,
        range: RangeValues(budgetMin, budgetMax),
      ),
      BudgetPreset(
        id: 'under_15k',
        label: locale.budgetPresetUnder15k,
        range: RangeValues(budgetMin, 15000),
      ),
      BudgetPreset(
        id: '15_25k',
        label: locale.budgetPreset15to25k,
        range: const RangeValues(15000, 25000),
      ),
      BudgetPreset(
        id: '25_40k',
        label: locale.budgetPreset25to40k,
        range: const RangeValues(25000, 40000),
      ),
      BudgetPreset(
        id: '40_60k',
        label: locale.budgetPreset40to60k,
        range: const RangeValues(40000, 60000),
      ),
      BudgetPreset(
        id: '60k_plus',
        label: locale.budgetPreset60kPlus,
        range: RangeValues(60000, budgetMax),
      ),
    ];
  }

  String? _matchingPresetId(List<BudgetPreset> presets) {
    for (final preset in presets) {
      if (budgetValues.start == preset.range.start &&
          budgetValues.end == preset.range.end) {
        return preset.id;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final presets = _presets(locale);
    final selectedPresetId = _matchingPresetId(presets);

    return CompactFilterSection(
      title: locale.budgetFilterLabel,
      subtitle: locale.budgetRangeLabel(
        formatBudget(budgetValues.start),
        formatBudget(budgetValues.end),
      ),
      icon: Icons.account_balance_wallet_outlined,
      iconColor: AppSemanticColors.greenMid,
      iconBgColor: AppSemanticColors.successSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Theme(
            data: theme.copyWith(
              sliderTheme: SliderThemeData(
                activeTrackColor: AppSemanticColors.accent,
                inactiveTrackColor: AppSemanticColors.accent.withValues(
                  alpha: 0.15,
                ),
                thumbColor: AppSemanticColors.accent,
                overlayColor: AppSemanticColors.accent.withValues(alpha: 0.08),
                rangeThumbShape: const RoundRangeSliderThumbShape(elevation: 2),
                trackHeight: 4,
              ),
            ),
            child: RangeSlider(
              values: budgetValues,
              min: budgetMin,
              max: budgetMax,
              divisions: 19,
              labels: RangeLabels(
                formatBudget(budgetValues.start),
                formatBudget(budgetValues.end),
              ),
              onChanged: onChanged,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatBudget(budgetMin),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppSemanticColors.textTertiaryFor(theme.brightness),
                    fontSize: 11,
                  ),
                ),
                Text(
                  formatBudget(budgetMax),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppSemanticColors.textTertiaryFor(theme.brightness),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final preset in presets)
                FlatmatesChip(
                  key: Key('budget_preset_${preset.id}'),
                  label: preset.label,
                  variant: FlatmatesChipVariant.choice,
                  selected: selectedPresetId == preset.id,
                  onSelected: (_) => onChanged(preset.range),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
