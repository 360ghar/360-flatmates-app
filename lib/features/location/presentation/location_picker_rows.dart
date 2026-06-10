import 'package:flutter/material.dart';

import '../../../core/location/place_suggestion.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../bootstrap/catalog_helpers.dart';
import '../../shared/presentation/components.dart';

/// Single tappable row used in the location-picker screens for primary
/// actions (e.g. "Use current location").
class LocationActionRow extends StatelessWidget {
  const LocationActionRow({
    required this.icon,
    required this.title,
    this.onTap,
    this.vertical = AppSpacing.md,
    super.key,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final double vertical;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: vertical),
        child: Row(
          children: [
            Icon(icon, color: AppSemanticColors.accent),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppSemanticColors.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppSemanticColors.line),
          ],
        ),
      ),
    );
  }
}

/// Row showing an address suggestion (Google Places / Nominatim).
class LocationSuggestionRow extends StatelessWidget {
  const LocationSuggestionRow({
    required this.suggestion,
    required this.onTap,
    super.key,
  });

  final PlaceSuggestion suggestion;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FlatmatesCard(
      onTap: onTap,
      borderColor: AppSemanticColors.line.withValues(alpha: 0.35),
      child: Row(
        children: [
          const Icon(
            Icons.location_on_outlined,
            color: AppSemanticColors.accent,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(suggestion.mainText, style: theme.textTheme.bodyLarge),
                if (suggestion.secondaryText.isNotEmpty)
                  Text(
                    suggestion.secondaryText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppSemanticColors.textSecondaryFor(
                        theme.brightness,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppSemanticColors.line),
        ],
      ),
    );
  }
}

/// Row representing a popular city in the location picker. Renders a
/// "Coming soon" badge for cities marked unavailable.
class LocationCityRow extends StatelessWidget {
  const LocationCityRow({
    required this.city,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final CatalogOption city;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    if (city.comingSoon) {
      return Opacity(
        opacity: 0.6,
        child: FlatmatesCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md + AppSpacing.xs,
          ),
          borderColor: AppSemanticColors.line.withValues(alpha: 0.35),
          child: Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: AppSemanticColors.textTertiaryFor(theme.brightness),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  city.label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppSemanticColors.textTertiaryFor(theme.brightness),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppSemanticColors.paper2,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  locale.comingSoon,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppSemanticColors.textTertiaryFor(theme.brightness),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return FlatmatesCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md + AppSpacing.xs,
      ),
      backgroundColor: selected
          ? AppSemanticColors.accent.withValues(alpha: 0.08)
          : null,
      borderColor: selected
          ? AppSemanticColors.accent
          : AppSemanticColors.line.withValues(alpha: 0.35),
      child: Row(
        children: [
          const Icon(
            Icons.location_on_outlined,
            color: AppSemanticColors.accent,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(city.label, style: theme.textTheme.bodyLarge)),
          if (selected)
            const Icon(
              Icons.check_circle_rounded,
              color: AppSemanticColors.accent,
            )
          else
            const Icon(Icons.chevron_right, color: AppSemanticColors.line),
        ],
      ),
    );
  }
}
