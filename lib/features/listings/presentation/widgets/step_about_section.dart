import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../bootstrap/catalog_helpers.dart';
import '../../../shared/presentation/components.dart';

/// Calendar bounds for the "available from" date picker.
///
/// [showDatePicker] bounds *calendar dates*, so every value returned here is a
/// local date-only [DateTime]:
///
/// * `first` is today (local).
/// * `last` is 180 local calendar days later. `Duration(days: 180)` advances
///   180 x 24 h instead, which lands on 23:00 of the preceding day across a
///   DST fall-back and would drop the final selectable day.
/// * `initial` is the listing's stored date, normalized with
///   `DateUtils.dateOnly(availableFrom.toLocal())`: a listing saved via
///   `toUtc()` can represent today as the previous UTC date, and the picker
///   asserts that `initialDate` is inside `[first, last]`.
///
/// Pure and injectable so the date math is unit-testable.
({DateTime first, DateTime last, DateTime initial}) availableFromPickerBounds({
  required DateTime now,
  DateTime? availableFrom,
}) {
  final first = DateUtils.dateOnly(now);
  final last = DateTime(first.year, first.month, first.day + 180);
  final wanted = availableFrom == null
      ? DateTime(first.year, first.month, first.day + 1)
      : DateUtils.dateOnly(availableFrom.toLocal());
  // An older listing can carry a date outside the range.
  return (
    first: first,
    last: last,
    initial: wanted.isBefore(first)
        ? first
        : wanted.isAfter(last)
        ? last
        : wanted,
  );
}

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
          _buildNonNegotiableChips(nonNegCatalog),
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
                  final bounds = availableFromPickerBounds(
                    now: DateTime.now(),
                    availableFrom: availableFrom,
                  );
                  final date = await showDatePicker(
                    context: context,
                    firstDate: bounds.first,
                    lastDate: bounds.last,
                    initialDate: bounds.initial,
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

  Widget _buildNonNegotiableChips(List<CatalogOption> options) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: options.map((option) {
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
    );
  }
}
