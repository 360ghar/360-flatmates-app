import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../bootstrap/catalog_helpers.dart';
import '../../../shared/presentation/components.dart';

/// Step 1 — Society type, amenities, vibe tags.
class StepSocietySection extends StatelessWidget {
  const StepSocietySection({
    required this.societyType,
    required this.societyAmenities,
    required this.societyVibeTags,
    required this.catalog,
    required this.iconForOption,
    required this.onSocietyTypeChanged,
    required this.onAmenityToggled,
    required this.onVibeToggled,
    super.key,
  });

  final String societyType;
  final Set<String> societyAmenities;
  final Set<String> societyVibeTags;
  final List<CatalogOption> Function(String key) catalog;
  final IconData Function(String id) iconForOption;
  final ValueChanged<String> onSocietyTypeChanged;
  final void Function(String key, bool selected) onAmenityToggled;
  final void Function(String key, bool selected) onVibeToggled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    final societyTypes = catalog('flatmates_society_types');
    final amenities = catalog('flatmates_listing_amenities');
    final vibes = catalog('flatmates_vibe_tags');

    return FlatmatesCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            locale.societyTypeLabel,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: societyTypes.map((type) {
              return FlatmatesChip(
                variant: FlatmatesChipVariant.choice,
                label: type.label,
                selected: societyType == type.id,
                onSelected: (_) => onSocietyTypeChanged(type.id),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.section - AppSpacing.md),
          Text(
            locale.societyAmenitiesLabel,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: amenities.map((opt) {
              final key = opt.id;
              final selected = societyAmenities.contains(key);
              return FlatmatesChip(
                icon: iconForOption(key),
                label: opt.label,
                selected: selected,
                onSelected: (v) => onAmenityToggled(key, v),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.section - AppSpacing.md),
          Text(
            locale.societyVibeLabel,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: vibes.map((opt) {
              final key = opt.id;
              final selected = societyVibeTags.contains(key);
              return FlatmatesChip(
                icon: iconForOption(key),
                label: opt.label,
                selected: selected,
                onSelected: (v) => onVibeToggled(key, v),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
