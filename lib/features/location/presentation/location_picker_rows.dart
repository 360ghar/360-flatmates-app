import 'package:flutter/material.dart';

import '../../../core/location/place_suggestion.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../bootstrap/catalog_helpers.dart';
import '../../shared/presentation/components.dart';
import '../../../core/theme/app_radius.dart';

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
      borderRadius: AppRadius.mdBorder,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: vertical),
        child: Row(
          children: [
            Icon(icon, color: AppSemanticColors.clayFor(theme.brightness)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppSemanticColors.clayFor(theme.brightness),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppSemanticColors.hairlineFor(theme.brightness),
            ),
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
    final hairline = AppSemanticColors.hairlineFor(theme.brightness);
    return FlatmatesCard(
      onTap: onTap,
      borderColor: hairline.withValues(alpha: 0.35),
      child: Row(
        children: [
          Icon(
            Icons.location_on_outlined,
            color: AppSemanticColors.clayFor(theme.brightness),
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
          Icon(Icons.chevron_right, color: hairline),
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
    final brightness = theme.brightness;
    final hairline = AppSemanticColors.hairlineFor(brightness);
    if (city.comingSoon) {
      return Opacity(
        opacity: 0.6,
        child: FlatmatesCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md + AppSpacing.xs,
          ),
          borderColor: hairline.withValues(alpha: 0.35),
          child: Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: AppSemanticColors.textTertiaryFor(brightness),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  city.label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppSemanticColors.textTertiaryFor(brightness),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppSemanticColors.secondarySurfaceFor(brightness),
                  borderRadius: AppRadius.pillBorder,
                ),
                child: Text(
                  locale.comingSoon,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppSemanticColors.textTertiaryFor(brightness),
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
          ? AppSemanticColors.clayFor(
              Theme.of(context).brightness,
            ).withValues(alpha: 0.08)
          : null,
      borderColor: selected
          ? AppSemanticColors.clayFor(Theme.of(context).brightness)
          : hairline.withValues(alpha: 0.35),
      child: Row(
        children: [
          Icon(
            Icons.location_on_outlined,
            color: AppSemanticColors.clayFor(Theme.of(context).brightness),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(city.label, style: theme.textTheme.bodyLarge)),
          if (selected)
            Icon(
              Icons.check_circle_rounded,
              color: AppSemanticColors.clayFor(Theme.of(context).brightness),
            )
          else
            Icon(Icons.chevron_right, color: hairline),
        ],
      ),
    );
  }
}
