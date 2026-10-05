import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/flatmates_listing_meta_chips.dart';
import '../../domain/property_listing.dart';

/// Compact stat tiles (Beds | Baths | Sqft | Floor) shown under the owner
/// card on the flat details page. Facts with null data are hidden.
///
/// Tiles share one height. On a narrow phone (or at large text) they wrap
/// into two columns instead of squeezing four tiles into one row.
class FlatDetailsFactsRow extends StatelessWidget {
  const FlatDetailsFactsRow({required this.listing, super.key});

  final PropertyListing listing;

  /// Narrowest tile that still fits "1,200" and its caption.
  static const double _minTileWidth = 80;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final l = listing;

    final facts = <_Fact>[
      if (l.bedrooms != null)
        _Fact(Icons.bed_outlined, '${l.bedrooms}', locale.factBedsLabel),
      if (l.bathrooms != null)
        _Fact(Icons.shower_outlined, '${l.bathrooms}', locale.factBathsLabel),
      if (l.areaSqft != null)
        _Fact(
          Icons.square_foot_outlined,
          '${l.areaSqft!.round()}',
          locale.factAreaLabel,
        ),
      if (l.floorNumber != null)
        _Fact(
          Icons.layers_outlined,
          l.totalFloors != null
              ? '${l.floorNumber}/${l.totalFloors}'
              : '${l.floorNumber}',
          locale.factFloorLabel,
        ),
    ];

    if (facts.length < 2) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.sm;
        final scale = MediaQuery.textScalerOf(context).scale(1);
        final fitsOneRow =
            constraints.maxWidth >=
            facts.length * _minTileWidth * scale + (facts.length - 1) * gap;
        final perRow = fitsOneRow ? facts.length : 2;

        final rows = <Widget>[];
        for (var start = 0; start < facts.length; start += perRow) {
          final slice = facts.skip(start).take(perRow).toList();
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < perRow; i++) ...[
                    if (i > 0) const SizedBox(width: gap),
                    Expanded(
                      child: i < slice.length
                          ? _FactTile(fact: slice[i])
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          );
        }
        return Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const SizedBox(height: gap),
              rows[i],
            ],
          ],
        );
      },
    );
  }
}

class _Fact {
  const _Fact(this.icon, this.value, this.caption);

  final IconData icon;
  final String value;
  final String caption;
}

class _FactTile extends StatelessWidget {
  const _FactTile({required this.fact});

  final _Fact fact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final b = theme.brightness;

    // A paper tile with a bare clay icon: no tinted well behind the icon.
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppSemanticColors.paper2For(b),
        borderRadius: AppRadius.cardBorder,
        boxShadow: AppShadows.e1(b),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(fact.icon, size: 22, color: AppSemanticColors.clayFor(b)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            fact.value,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppSemanticColors.textPrimaryFor(b),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            fact.caption,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppSemanticColors.textTertiaryFor(b),
            ),
          ),
        ],
      ),
    );
  }
}

/// Feature and amenity facts for the flat details page.
///
/// Key features (furnished, wifi, parking, lift, security) are pine-soft
/// pills; catalog amenities are plain icon + label, so the list stays
/// scannable without a pill on every noun. Beds are already a fact tile.
class FlatDetailsFeatureChips extends StatelessWidget {
  const FlatDetailsFeatureChips({required this.listing, super.key});

  final PropertyListing listing;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final l = listing;
    final items = <ListingMetaItem>[];
    final shown = <String>{};

    bool has(String needle) =>
        l.features.any((f) => f.toLowerCase().contains(needle));

    void addKey(String key, IconData icon, String label) {
      if (shown.add(key)) {
        items.add(
          ListingMetaItem(
            icon: icon,
            label: label,
            chipColor: MetaChipColor.green,
          ),
        );
      }
    }

    if (l.isFurnished) {
      addKey('furnished', Icons.chair_outlined, locale.featureFurnished);
    }
    if (has('wifi') || has('wi_fi')) {
      addKey('wifi', Icons.wifi_outlined, locale.wifiChipLabel);
    }
    if (has('parking')) {
      addKey('parking', Icons.local_parking_outlined, locale.parkingChipLabel);
    }
    if (has('lift') || has('elevator')) {
      addKey('lift', Icons.elevator_outlined, locale.liftChipLabel);
    }
    if (has('security')) {
      addKey('security', Icons.security_outlined, locale.securityChipLabel);
    }
    for (final amenity in l.amenities) {
      if (shown.add(amenity.title.toLowerCase())) {
        items.add(
          ListingMetaItem(
            icon: Icons.check_circle_outline_rounded,
            label: amenity.title,
          ),
        );
      }
    }

    if (items.isEmpty) return const SizedBox.shrink();
    return FlatmatesListingMetaChips(items: items);
  }
}
