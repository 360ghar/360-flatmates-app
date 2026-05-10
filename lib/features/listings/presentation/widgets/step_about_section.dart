import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../bootstrap/catalog_helpers.dart';
import '../../../shared/presentation/components.dart';

/// Step 6 — About (typical day, gender preference, age range,
/// non-negotiables, available from date).
class StepAboutSection extends StatelessWidget {
  const StepAboutSection({
    required this.typicalDayController,
    required this.genderPreference,
    required this.ageMin,
    required this.ageMax,
    required this.nonNegotiables,
    required this.availableFrom,
    required this.catalog,
    required this.onGenderChanged,
    required this.onAgeRangeChanged,
    required this.onNonNegotiableToggled,
    required this.onAvailableFromChanged,
    super.key,
  });

  final TextEditingController typicalDayController;
  final String genderPreference;
  final double ageMin;
  final double ageMax;
  final Set<String> nonNegotiables;
  final DateTime? availableFrom;
  final List<CatalogOption> Function(String key) catalog;
  final ValueChanged<String> onGenderChanged;
  final void Function(double min, double max) onAgeRangeChanged;
  final void Function(String key, bool selected) onNonNegotiableToggled;
  final void Function(DateTime? date) onAvailableFromChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    final nonNegCatalog = catalog('flatmates_non_negotiables');

    return FlatmatesCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            locale.typicalDayLabel,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: typicalDayController,
            minLines: 3,
            maxLines: 5,
            maxLength: 300,
            decoration: InputDecoration(hintText: locale.typicalDayHint),
          ),
          const SizedBox(height: 24),
          Text(
            locale.genderPreferenceLabel,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'any', label: Text(locale.genderAny)),
              ButtonSegment(value: 'male', label: Text(locale.genderMale)),
              ButtonSegment(value: 'female', label: Text(locale.genderFemale)),
            ],
            selected: {genderPreference},
            onSelectionChanged: (v) => onGenderChanged(v.first),
          ),
          const SizedBox(height: 20),
          Text(
            locale.ageRangeLabel,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          RangeSlider(
            values: RangeValues(ageMin, ageMax),
            min: 18,
            max: 50,
            divisions: 32,
            labels: RangeLabels('${ageMin.round()}', '${ageMax.round()}'),
            onChanged: (v) => onAgeRangeChanged(v.start, v.end),
          ),
          const SizedBox(height: 24),
          Text(
            locale.nonNegotiablesTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: nonNegCatalog.map((option) {
              final key = option.id;
              final selected = nonNegotiables.contains(key);
              return FlatmatesChip(
                variant: FlatmatesChipVariant.choice,
                label: option.label,
                selected: selected,
                onSelected: selected
                    ? (_) => onNonNegotiableToggled(key, false)
                    : nonNegotiables.length < 3
                    ? (_) => onNonNegotiableToggled(key, true)
                    : null,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locale.availableFromLabel,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      availableFrom == null
                          ? locale.availableFromUnset
                          : DateFormat(
                              'd MMM yyyy',
                              locale.localeName,
                            ).format(availableFrom!),
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              FlatmatesButton.secondary(
                label: locale.selectDateCta,
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 180)),
                    initialDate:
                        availableFrom ??
                        DateTime.now().add(const Duration(days: 1)),
                  );
                  if (date != null) onAvailableFromChanged(date);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
