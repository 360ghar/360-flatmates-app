import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import 'search_filter_widgets.dart';

/// Budget range filter card with a RangeSlider.
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
      initiallyExpanded: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RangeSlider(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(formatBudget(budgetMin), style: theme.textTheme.bodySmall),
              Text(formatBudget(budgetMax), style: theme.textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}
