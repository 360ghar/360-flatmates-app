import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import 'search_filter_widgets.dart';

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
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm + AppSpacing.xs),
      decoration: BoxDecoration(
        color: isDark ? AppSemanticColors.darkSurface : AppSemanticColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppSemanticColors.line.withValues(alpha: 0.5),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x061F1A14),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppSemanticColors.tealSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    size: 16,
                    color: AppSemanticColors.tealMid,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
                Text(
                  locale.moreFiltersLabel,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(
            height: 1,
            indent: AppSpacing.lg,
            endIndent: AppSpacing.lg,
            color: AppSemanticColors.line,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.pets_outlined,
                      size: 16,
                      color: AppSemanticColors.orangeMid,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      locale.petsLabel,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
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
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    const Icon(
                      Icons.smoke_free_outlined,
                      size: 16,
                      color: AppSemanticColors.purpleMid,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      locale.smokingLabel,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
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
          ),
        ],
      ),
    );
  }
}
