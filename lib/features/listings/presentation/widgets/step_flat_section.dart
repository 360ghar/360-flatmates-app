import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../bootstrap/catalog_helpers.dart';
import '../../../shared/presentation/components.dart';

/// Step 4 — Flat configuration, kitchen/ventilation, floor, windows,
/// ventilation shafts, flat amenities.
class StepFlatSection extends StatelessWidget {
  const StepFlatSection({
    required this.flatConfig,
    required this.floorController,
    required this.totalFloorsController,
    required this.flatAmenities,
    required this.kitchenType,
    required this.ventilationType,
    required this.windowsController,
    required this.ventilationShaftsController,
    required this.catalog,
    required this.iconForOption,
    required this.onFlatConfigChanged,
    required this.onKitchenTypeChanged,
    required this.onVentilationTypeChanged,
    required this.onAmenityToggled,
    required this.onChanged,
    super.key,
  });

  final String flatConfig;
  final TextEditingController floorController;
  final TextEditingController totalFloorsController;
  final Set<String> flatAmenities;
  final String? kitchenType;
  final String? ventilationType;
  final TextEditingController windowsController;
  final TextEditingController ventilationShaftsController;
  final List<CatalogOption> Function(String key) catalog;
  final IconData Function(String id) iconForOption;
  final ValueChanged<String> onFlatConfigChanged;
  final ValueChanged<String> onKitchenTypeChanged;
  final ValueChanged<String> onVentilationTypeChanged;
  final void Function(String key, bool selected) onAmenityToggled;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    final configs = catalog('flatmates_flat_configs');
    final kitchenTypes = catalog('flatmates_kitchen_types');
    final ventilationOptions = catalog('flatmates_ventilation_options');
    final amenities = catalog('flatmates_listing_amenities');

    return FlatmatesCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            locale.flatConfigLabel,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: configs.map((config) {
              return FlatmatesChip(
                variant: FlatmatesChipVariant.choice,
                label: config.label,
                selected: flatConfig == config.id,
                onSelected: (_) => onFlatConfigChanged(config.id),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: floorController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: locale.floorLabel),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: TextFormField(
                  controller: totalFloorsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: locale.totalFloorsLabel,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl - AppSpacing.md),
          Text(
            locale.kitchenTypeLabel,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: kitchenTypes.map((opt) {
              return FlatmatesChip(
                icon: iconForOption(opt.id),
                label: opt.label,
                selected: kitchenType == opt.id,
                onSelected: (_) => onKitchenTypeChanged(opt.id),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.xl - AppSpacing.md),
          Text(
            locale.ventilationTypeLabel,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: ventilationOptions.map((opt) {
              return FlatmatesChip(
                icon: iconForOption(opt.id),
                label: opt.label,
                selected: ventilationType == opt.id,
                onSelected: (_) => onVentilationTypeChanged(opt.id),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.xl - AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: windowsController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  decoration: InputDecoration(
                    labelText: locale.windowsCountLabel,
                    hintText: '0–100',
                  ),
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: TextFormField(
                  controller: ventilationShaftsController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                  decoration: InputDecoration(
                    labelText: locale.ventilationShaftsLabel,
                    hintText: '0–50',
                  ),
                  onChanged: (_) => onChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl - AppSpacing.md),
          Text(
            locale.flatAmenitiesLabel,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: amenities.map((opt) {
              final selected = flatAmenities.contains(opt.id);
              return FlatmatesChip(
                icon: iconForOption(opt.id),
                label: opt.label,
                selected: selected,
                onSelected: (v) => onAmenityToggled(opt.id, v),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
