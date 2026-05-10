import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/flatmates_card.dart';
import 'search_filter_widgets.dart';

/// The "More filters" card containing Pets and Smoking options.
class MoreFiltersCard extends StatelessWidget {
  const MoreFiltersCard({
    required this.selectedPets,
    required this.selectedSmoking,
    required this.onPetsChanged,
    required this.onSmokingChanged,
    required this.catalogOrFallback,
    super.key,
  });

  final String? selectedPets;
  final String? selectedSmoking;
  final void Function(String?) onPetsChanged;
  final void Function(String?) onSmokingChanged;
  final List<({String id, String label})> Function(String, List<String>)
  catalogOrFallback;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return FlatmatesCard(
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ExpansionTile(
        title: Row(
          children: [
            const Icon(Icons.more_horiz_rounded, size: 16),
            const SizedBox(width: AppSpacing.sm),
            Text(
              locale.moreFiltersLabel,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        subtitle:
            [
              _petsSubtitle(locale),
              _smokingSubtitle(locale),
            ].where((s) => s != null).isNotEmpty
            ? Text(
                [
                  _petsSubtitle(locale),
                  _smokingSubtitle(locale),
                ].where((s) => s != null).join(' · '),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                  color: AppSemanticColors.textSecondaryFor(theme.brightness),
                ),
              )
            : null,
        initiallyExpanded: false,
        shape: const RoundedRectangleBorder(),
        collapsedShape: const RoundedRectangleBorder(),
        childrenPadding: const EdgeInsets.only(bottom: 14),
        children: [
          // Pets
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(locale.petsLabel, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 8),
                CatalogFilterChips(
                  options: catalogOrFallback('flatmates_pets_options', [
                    'no_preference',
                    'yes',
                    'no',
                  ]),
                  selectedId: selectedPets ?? 'no_preference',
                  anyKey: 'no_preference',
                  onSelected: (id) =>
                      onPetsChanged(id == 'no_preference' ? null : id),
                ),
              ],
            ),
          ),
          // Smoking
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(locale.smokingLabel, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 8),
              CatalogFilterChips(
                options: catalogOrFallback('flatmates_smoking_options', [
                  'no_preference',
                  'no',
                  'yes',
                ]),
                selectedId: selectedSmoking ?? 'no_preference',
                anyKey: 'no_preference',
                onSelected: (id) =>
                    onSmokingChanged(id == 'no_preference' ? null : id),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String? _petsSubtitle(AppLocalizations locale) {
    if (selectedPets == null) return locale.petsNoPreference;
    if (selectedPets == 'yes') return locale.petsYes;
    if (selectedPets == 'no') return locale.petsNo;
    return null;
  }

  String? _smokingSubtitle(AppLocalizations locale) {
    if (selectedSmoking == null) return locale.smokingNoPreference;
    if (selectedSmoking == 'yes') return locale.smokingYes;
    if (selectedSmoking == 'no') return locale.smokingNo;
    return null;
  }
}
