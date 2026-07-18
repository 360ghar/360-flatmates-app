import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/components.dart';

/// Step 5 — Costs (rent, deposit, maintenance, electricity, cook, maid, setup)
/// with total monthly outflow display.
class StepCostsSection extends StatelessWidget {
  const StepCostsSection({
    required this.rentController,
    required this.depositController,
    required this.maintenanceController,
    required this.electricityIncluded,
    required this.electricityEstController,
    required this.cookCostController,
    required this.maidCostController,
    required this.setupCostController,
    required this.showRentValidation,
    this.showDepositValidation = false,
    this.showMaintenanceValidation = false,
    this.showCostValidation = false,
    this.showElectricityValidation = false,
    required this.totalMonthlyOutflow,
    required this.flatConfig,
    required this.onElectricityChanged,
    required this.onChanged,
    super.key,
  });

  final TextEditingController rentController;
  final TextEditingController depositController;
  final TextEditingController maintenanceController;
  final String electricityIncluded;
  final TextEditingController electricityEstController;
  final TextEditingController cookCostController;
  final TextEditingController maidCostController;
  final TextEditingController setupCostController;
  final bool showRentValidation;
  final bool showDepositValidation;
  final bool showMaintenanceValidation;
  final bool showCostValidation;
  final bool showElectricityValidation;
  final double totalMonthlyOutflow;
  final String flatConfig;
  final ValueChanged<String> onElectricityChanged;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);

    // Estimate total flatmates from flat config: number of bedrooms
    final bedrooms = flatConfig.contains('1')
        ? 1
        : flatConfig.contains('3')
        ? 3
        : flatConfig.contains('4')
        ? 4
        : 2;
    final totalFlatmates = bedrooms;

    return FlatmatesCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      key: const Key('listing_rent_input'),
                      controller: rentController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: locale.monthlyRentInputLabel,
                        hintText: locale.monthlyRentHint,
                        prefixIcon: const Icon(Icons.currency_rupee_rounded),
                        errorText:
                            showRentValidation &&
                                rentController.text.trim().isEmpty
                            ? locale.listingRentRequired
                            : null,
                      ),
                      onChanged: (_) {
                        onChanged();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: TextFormField(
                  controller: depositController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: locale.securityDepositLabel,
                    hintText: locale.securityDepositHint,
                    prefixIcon: const Icon(Icons.currency_rupee_rounded),
                    errorText: showDepositValidation
                        ? locale.listingDepositInvalid
                        : null,
                  ),
                  onChanged: (_) => onChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: maintenanceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: locale.maintenanceLabel,
                    hintText: locale.maintenanceHint,
                    prefixIcon: const Icon(Icons.currency_rupee_rounded),
                    errorText: showMaintenanceValidation
                        ? locale.listingMaintenanceInvalid
                        : null,
                  ),
                  onChanged: (_) => onChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                locale.electricityLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppSemanticColors.textSecondaryFor(theme.brightness),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              FlatmatesSegmentedControl<String>(
                segments: [
                  ('included', locale.includedLabel, Icons.bolt_rounded),
                  (
                    'separate',
                    locale.separateLabel,
                    Icons.receipt_long_rounded,
                  ),
                ],
                selected: electricityIncluded,
                onChanged: onElectricityChanged,
              ),
            ],
          ),
          if (electricityIncluded == 'separate') ...[
            const SizedBox(height: AppSpacing.xl),
            TextFormField(
              controller: electricityEstController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: locale.electricityEstLabel,
                hintText: locale.electricityEstHint,
                prefixIcon: const Icon(Icons.currency_rupee_rounded),
                errorText: showElectricityValidation
                    ? locale.listingCostInvalid
                    : null,
              ),
              onChanged: (_) => onChanged(),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: cookCostController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: locale.cookCostLabel,
                    hintText: locale.cookCostHint,
                    prefixIcon: const Icon(Icons.currency_rupee_rounded),
                    errorText: showCostValidation
                        ? locale.listingCostInvalid
                        : null,
                  ),
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: TextFormField(
                  controller: maidCostController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: locale.maidCostLabel,
                    hintText: locale.maidCostHint,
                    prefixIcon: const Icon(Icons.currency_rupee_rounded),
                    errorText: showCostValidation
                        ? locale.listingCostInvalid
                        : null,
                  ),
                  onChanged: (_) => onChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          TextFormField(
            controller: setupCostController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: locale.setupCostLabel,
              hintText: locale.setupCostHint,
              prefixIcon: const Icon(Icons.currency_rupee_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (totalMonthlyOutflow > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppSemanticColors.accent.withValues(alpha: 0.08),
                borderRadius: AppRadius.mdBorder,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    locale.totalMonthlyOutflow(
                      '₹${totalMonthlyOutflow.toStringAsFixed(0)}',
                    ),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppSemanticColors.accent,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  if (totalFlatmates > 1) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '${locale.perPersonCostLabel} ₹${(totalMonthlyOutflow / totalFlatmates).toStringAsFixed(0)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppSemanticColors.accent.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
