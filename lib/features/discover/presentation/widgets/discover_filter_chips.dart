import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/flatmates_chip.dart';
import '../../../shared/presentation/flatmates_ui.dart';

/// Horizontal scrollable filter chips for the discover page.
class DiscoverFilterChips extends StatelessWidget {
  const DiscoverFilterChips({
    required this.bedroomOptions,
    required this.featureOptions,
    required this.selectedBedrooms,
    required this.selectedFeature,
    required this.selectedMoveIn,
    required this.onBedroomsChanged,
    required this.onFeatureChanged,
    required this.onMoveInChanged,
    super.key,
  });

  final List<int> bedroomOptions;
  final List<String> featureOptions;
  final int? selectedBedrooms;
  final String? selectedFeature;
  final String? selectedMoveIn;

  final ValueChanged<int?> onBedroomsChanged;
  final ValueChanged<String?> onFeatureChanged;
  final ValueChanged<String?> onMoveInChanged;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
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
              ),
            );
          }),
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
              ),
            );
          }),
          ...featureOptions.take(4).map((feature) {
            final selected = selectedFeature == feature;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: FlatmatesChip(
                label: localizedFlatmatesFeatureLabel(locale, feature),
                selected: selected,
                onSelected: (_) {
                  onFeatureChanged(selected ? null : feature);
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
