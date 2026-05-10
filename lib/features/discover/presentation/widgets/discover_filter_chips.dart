import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/flatmates_chip.dart';

/// Vibe preset filter data.
class VibePreset {
  const VibePreset({
    required this.key,
    required this.icon,
    required this.label,
  });

  final String key;
  final IconData icon;
  final String label;
}

/// Horizontal scrollable filter chips for the discover page.
class DiscoverFilterChips extends StatelessWidget {
  const DiscoverFilterChips({
    required this.bedroomOptions,
    required this.featureOptions,
    required this.currentLocation,
    required this.selectedBedrooms,
    required this.selectedFeature,
    required this.selectedVibe,
    required this.selectedMoveIn,
    required this.onBedroomsChanged,
    required this.onFeatureChanged,
    required this.onVibeChanged,
    required this.onMoveInChanged,
    super.key,
  });

  final List<int> bedroomOptions;
  final List<String> featureOptions;
  final String currentLocation;
  final int? selectedBedrooms;
  final String? selectedFeature;
  final String? selectedVibe;
  final String? selectedMoveIn;

  final ValueChanged<int?> onBedroomsChanged;
  final ValueChanged<String?> onFeatureChanged;
  final ValueChanged<String?> onVibeChanged;
  final ValueChanged<String?> onMoveInChanged;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);

    final vibePresets = [
      VibePreset(
        key: 'quiet',
        icon: Icons.bedtime_outlined,
        label: locale.vibeQuiet,
      ),
      VibePreset(
        key: 'social',
        icon: Icons.celebration_outlined,
        label: locale.vibeSocial,
      ),
      VibePreset(
        key: 'professional',
        icon: Icons.work_outlined,
        label: locale.vibeProfessional,
      ),
      VibePreset(
        key: 'student',
        icon: Icons.school_outlined,
        label: locale.vibeStudent,
      ),
      VibePreset(key: 'pet', icon: Icons.pets_outlined, label: locale.vibePet),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Vibe preset filter chips
          ...vibePresets.map((vibe) {
            final selected = selectedVibe == vibe.key;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: FlatmatesChip(
                label: vibe.label,
                icon: vibe.icon,
                selected: selected,
                onSelected: (_) {
                  onVibeChanged(selected ? null : vibe.key);
                },
                variant: FlatmatesChipVariant.filter,
              ),
            );
          }),
          ...[
            (key: 'immediate', label: locale.timelineImmediate),
            (key: 'this_month', label: locale.moveInThisMonth),
            (key: 'next_month', label: locale.moveInNextMonth),
            (key: 'flexible', label: locale.timelineFlexible),
          ].map((option) {
            final selected =
                selectedMoveIn == option.key ||
                (selectedMoveIn == null && option.key == 'flexible');
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: FlatmatesChip(
                label: option.label,
                icon: Icons.event_available_outlined,
                selected: selected,
                onSelected: (_) {
                  onMoveInChanged(
                    option.key == 'flexible' || selected ? null : option.key,
                  );
                },
                variant: FlatmatesChipVariant.filter,
              ),
            );
          }),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: FlatmatesChip(
              label: locale.nearbyChipLabel,
              icon: Icons.near_me_outlined,
              selected: false,
              onSelected: (_) {},
              variant: FlatmatesChipVariant.filter,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: FlatmatesChip(
              label: locale.budgetPlusChipLabel,
              icon: Icons.add_outlined,
              selected: false,
              onSelected: (_) {},
              variant: FlatmatesChipVariant.filter,
            ),
          ),
          if (currentLocation.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: FlatmatesChip(
                label: currentLocation,
                icon: Icons.near_me_outlined,
                selected: false,
                onSelected: (_) {},
                variant: FlatmatesChipVariant.filter,
              ),
            ),
          ...bedroomOptions.map((value) {
            final selected = selectedBedrooms == value;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: FlatmatesChip(
                label: locale.homeBedroomsChip(value),
                selected: selected,
                onSelected: (_) {
                  onBedroomsChanged(selected ? null : value);
                },
                variant: FlatmatesChipVariant.filter,
              ),
            );
          }),
          ...featureOptions.take(4).map((feature) {
            final selected = selectedFeature == feature;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: FlatmatesChip(
                label: feature,
                selected: selected,
                onSelected: (_) {
                  onFeatureChanged(selected ? null : feature);
                },
                variant: FlatmatesChipVariant.filter,
              ),
            );
          }),
        ],
      ),
    );
  }
}
