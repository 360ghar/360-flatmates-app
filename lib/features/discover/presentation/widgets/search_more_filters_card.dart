import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';

import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import 'search_filter_widgets.dart';

/// Pets + smoking preferences under a collapsible "Lifestyle" header so
/// primary filters stay above the fold.
class MoreFiltersCard extends StatefulWidget {
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
  State<MoreFiltersCard> createState() => _MoreFiltersCardState();
}

class _MoreFiltersCardState extends State<MoreFiltersCard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    // Auto-expand when a lifestyle filter is already active.
    _expanded = widget.selectedPets != null || widget.selectedSmoking != null;
  }

  String _petsSubtitle(AppLocalizations locale) {
    return switch (widget.selectedPets) {
      'yes' => locale.petsYes,
      'no' => locale.petsNo,
      _ => locale.petsNoPreference,
    };
  }

  String _smokingSubtitle(AppLocalizations locale) {
    return switch (widget.selectedSmoking) {
      'yes' => locale.smokingYes,
      'no' => locale.smokingNo,
      _ => locale.smokingNoPreference,
    };
  }

  String _collapsedSummary(AppLocalizations locale) {
    final hasPets = widget.selectedPets != null;
    final hasSmoking = widget.selectedSmoking != null;
    if (!hasPets && !hasSmoking) {
      return locale.lifestyleFiltersSummaryAny;
    }
    final parts = <String>[
      if (hasPets) '${locale.petsLabel}: ${_petsSubtitle(locale)}',
      if (hasSmoking) '${locale.smokingLabel}: ${_smokingSubtitle(locale)}',
    ];
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    const accentColor = AppSemanticColors.purpleMid;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              key: const Key('lifestyle_filters_toggle'),
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: AppRadius.mdBorder,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppSemanticColors.purpleSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.favorite_outline,
                        size: 16,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            locale.lifestyleFiltersLabel,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          if (!_expanded)
                            Text(
                              _collapsedSummary(locale),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppSemanticColors.textSecondaryFor(
                                  brightness,
                                ),
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: AppMotion.chipSelect,
                      curve: AppMotion.easeOutCubic,
                      child: Icon(
                        Icons.expand_more,
                        color: AppSemanticColors.textSecondaryFor(brightness),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Prefer AnimatedSize over CrossFade: firstChild with
          // width: infinity + zero-height second path caused layout jank
          // inside the filter sheet ListView.
          AnimatedSize(
            duration: AppMotion.chipSelect,
            curve: AppMotion.easeOutCubic,
            alignment: Alignment.topCenter,
            child: !_expanded
                ? const SizedBox(width: double.infinity)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.xs),
                      CompactFilterSection(
                        title: locale.petsLabel,
                        icon: Icons.pets_outlined,
                        iconColor: AppSemanticColors.orangeMid,
                        iconBgColor: AppSemanticColors.orangeSoft,
                        child: CatalogFilterChips(
                          options: widget.catalogOrFallback(
                            'flatmates_pets_options',
                            ['no_preference', 'yes', 'no'],
                          ),
                          selectedId: widget.selectedPets ?? 'no_preference',
                          anyKey: 'no_preference',
                          iconForId: petsFilterOptionIcon,
                          onSelected: (id) => widget.onPetsChanged(
                            id == 'no_preference' ? null : id,
                          ),
                        ),
                      ),
                      CompactFilterSection(
                        title: locale.smokingLabel,
                        icon: Icons.smoke_free_outlined,
                        iconColor: AppSemanticColors.purpleMid,
                        iconBgColor: AppSemanticColors.purpleSoft,
                        child: CatalogFilterChips(
                          options: widget.catalogOrFallback(
                            'flatmates_smoking_options',
                            ['no_preference', 'no', 'yes'],
                          ),
                          selectedId: widget.selectedSmoking ?? 'no_preference',
                          anyKey: 'no_preference',
                          iconForId: smokingFilterOptionIcon,
                          onSelected: (id) => widget.onSmokingChanged(
                            id == 'no_preference' ? null : id,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
