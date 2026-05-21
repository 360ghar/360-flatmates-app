import 'package:flutter/material.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import 'search_filter_widgets.dart';

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

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return FilterSectionCard(
      title: locale.budgetFilterLabel,
      subtitle: locale.budgetRangeLabel(
        formatBudget(budgetValues.start),
        formatBudget(budgetValues.end),
      ),
      icon: Icons.account_balance_wallet_outlined,
      iconColor: AppSemanticColors.greenMid,
      iconBgColor: AppSemanticColors.successSoft,
      initiallyExpanded: false,
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
                rangeThumbShape: const RoundRangeSliderThumbShape(
                  enabledThumbRadius: 10,
                  elevation: 2,
                ),
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
                    color: AppSemanticColors.ink3,
                    fontSize: 11,
                  ),
                ),
                Text(
                  formatBudget(budgetMax),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppSemanticColors.ink3,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
