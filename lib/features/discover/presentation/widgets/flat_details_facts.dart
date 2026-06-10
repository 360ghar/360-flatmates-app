import 'package:flutter/material.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/components.dart';
import '../../domain/property_listing.dart';

/// Compact stat row (Beds | Baths | Sqft | Floor) shown under the owner
/// card on the flat details page. Columns with null data are hidden.
class FlatDetailsFactsRow extends StatelessWidget {
  const FlatDetailsFactsRow({required this.listing, super.key});

  final PropertyListing listing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    final l = listing;

    final facts = <_Fact>[
      if (l.bedrooms != null)
        _Fact(
          icon: Icons.bed_outlined,
          value: '${l.bedrooms}',
          caption: locale.factBedsLabel,
        ),
      if (l.bathrooms != null)
        _Fact(
          icon: Icons.shower_outlined,
          value: '${l.bathrooms}',
          caption: locale.factBathsLabel,
        ),
      if (l.areaSqft != null)
        _Fact(
          icon: Icons.square_foot_outlined,
          value: '${l.areaSqft!.round()}',
          caption: locale.factAreaLabel,
        ),
      if (l.floorNumber != null)
        _Fact(
          icon: Icons.layers_outlined,
          value: l.totalFloors != null
              ? '${l.floorNumber}/${l.totalFloors}'
              : '${l.floorNumber}',
          caption: locale.factFloorLabel,
        ),
    ];

    if (facts.length < 2) return const SizedBox.shrink();

    return FlatmatesCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          for (var i = 0; i < facts.length; i++) ...[
            if (i > 0)
              Container(width: 1, height: 36, color: theme.dividerColor),
            Expanded(
              child: _FactColumn(fact: facts[i], theme: theme),
            ),
          ],
        ],
      ),
    );
  }
}

class _Fact {
  const _Fact({required this.icon, required this.value, required this.caption});

  final IconData icon;
  final String value;
  final String caption;
}

class _FactColumn extends StatelessWidget {
  const _FactColumn({required this.fact, required this.theme});

  final _Fact fact;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final brightness = theme.brightness;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(fact.icon, size: 18, color: AppSemanticColors.accent),
        const SizedBox(height: AppSpacing.xs),
        Text(
          fact.value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppSemanticColors.textPrimaryFor(brightness),
          ),
        ),
        Text(
          fact.caption,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 11,
            color: AppSemanticColors.textTertiaryFor(brightness),
          ),
        ),
      ],
    );
  }
}

/// Feature/amenity chips (furnished, wifi, parking, lift, security, plus
/// catalog amenities) for the flat details page.
class FlatDetailsFeatureChips extends StatelessWidget {
  const FlatDetailsFeatureChips({required this.listing, super.key});

  final PropertyListing listing;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final chips = <Widget>[];
    final shownLabels = <String>{};
    final l = listing;

    void addChip(String key, Widget chip) {
      if (shownLabels.add(key)) chips.add(chip);
    }

    if (l.bedrooms != null) {
      addChip(
        'beds',
        FlatmatesChip(
          variant: FlatmatesChipVariant.info,
          label: '${l.bedrooms} Beds',
          icon: Icons.bed_outlined,
        ),
      );
    }
    if (l.isFurnished) {
      addChip(
        'furnished',
        FlatmatesChip(
          variant: FlatmatesChipVariant.info,
          label: locale.featureFurnished,
          icon: Icons.chair_outlined,
        ),
      );
    }
    if (l.features.any(
      (f) =>
          f.toLowerCase().contains('wifi') || f.toLowerCase().contains('wi_fi'),
    )) {
      addChip(
        'wifi',
        FlatmatesChip(
          variant: FlatmatesChipVariant.info,
          label: locale.wifiChipLabel,
          icon: Icons.wifi_outlined,
        ),
      );
    }
    if (l.features.any((f) => f.toLowerCase().contains('parking'))) {
      addChip(
        'parking',
        FlatmatesChip(
          variant: FlatmatesChipVariant.info,
          label: locale.parkingChipLabel,
          icon: Icons.local_parking_outlined,
        ),
      );
    }
    if (l.features.any(
      (f) =>
          f.toLowerCase().contains('lift') ||
          f.toLowerCase().contains('elevator'),
    )) {
      addChip(
        'lift',
        FlatmatesChip(
          variant: FlatmatesChipVariant.info,
          label: locale.liftChipLabel,
          icon: Icons.elevator_outlined,
        ),
      );
    }
    if (l.features.any((f) => f.toLowerCase().contains('security'))) {
      addChip(
        'security',
        FlatmatesChip(
          variant: FlatmatesChipVariant.info,
          label: locale.securityChipLabel,
          icon: Icons.security_outlined,
        ),
      );
    }

    for (final amenity in l.amenities) {
      addChip(
        amenity.title.toLowerCase(),
        FlatmatesChip(variant: FlatmatesChipVariant.info, label: amenity.title),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: chips,
    );
  }
}
