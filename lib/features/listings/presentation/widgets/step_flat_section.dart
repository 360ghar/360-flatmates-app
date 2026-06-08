import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../bootstrap/catalog_helpers.dart';
import '../../../shared/presentation/components.dart';

/// Step 4 — Flat configuration, floor, total floors, flat amenities.
class StepFlatSection extends StatelessWidget {
  const StepFlatSection({
    required this.flatConfig,
    required this.floorController,
    required this.totalFloorsController,
    required this.flatAmenities,
    required this.catalog,
    required this.iconForOption,
    required this.onFlatConfigChanged,
    required this.onAmenityToggled,
    super.key,
  });

  final String flatConfig;
  final TextEditingController floorController;
  final TextEditingController totalFloorsController;
  final Set<String> flatAmenities;
  final List<CatalogOption> Function(String key) catalog;
  final IconData Function(String id) iconForOption;
  final ValueChanged<String> onFlatConfigChanged;
  final void Function(String key, bool selected) onAmenityToggled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    final configs = catalog('flatmates_flat_configs');
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
          const SizedBox(height: AppSpacing.section - AppSpacing.md),
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
