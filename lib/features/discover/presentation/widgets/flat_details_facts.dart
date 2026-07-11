import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/property_listing.dart';

/// Compact stat row (Beds | Baths | Sqft | Floor) shown under the owner
/// card on the flat details page. Columns with null data are hidden.
///
/// Each fact renders as a color-coded soft-background tile (inspired by the
/// swipe card's lifestyle grid) instead of a plain divider column — blue for
/// beds, teal for baths, purple for area, orange for floor.
class FlatDetailsFactsRow extends StatelessWidget {
  const FlatDetailsFactsRow({required this.listing, super.key});

  final PropertyListing listing;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final l = listing;

    final facts = <_Fact>[
      if (l.bedrooms != null)
        _Fact(
          icon: Icons.bed_outlined,
          value: '${l.bedrooms}',
          caption: locale.factBedsLabel,
          palette: _FactPalette.blue,
        ),
      if (l.bathrooms != null)
        _Fact(
          icon: Icons.shower_outlined,
          value: '${l.bathrooms}',
          caption: locale.factBathsLabel,
          palette: _FactPalette.teal,
        ),
      if (l.areaSqft != null)
        _Fact(
          icon: Icons.square_foot_outlined,
          value: '${l.areaSqft!.round()}',
          caption: locale.factAreaLabel,
          palette: _FactPalette.purple,
        ),
      if (l.floorNumber != null)
        _Fact(
          icon: Icons.layers_outlined,
          value: l.totalFloors != null
              ? '${l.floorNumber}/${l.totalFloors}'
              : '${l.floorNumber}',
          caption: locale.factFloorLabel,
          palette: _FactPalette.orange,
        ),
    ];

    if (facts.length < 2) return const SizedBox.shrink();

    return Row(
      children: [
        for (var i = 0; i < facts.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(child: _FactTile(fact: facts[i])),
        ],
      ],
    );
  }
}

class _Fact {
  const _Fact({
    required this.icon,
    required this.value,
    required this.caption,
    required this.palette,
  });

  final IconData icon;
  final String value;
  final String caption;
  final _FactPalette palette;
}

/// Soft-background + coloured-foreground pair for a fact tile.
class _FactPalette {
  const _FactPalette({required this.background, required this.foreground});

  final Color background;
  final Color foreground;

  static const blue = _FactPalette(
    background: AppSemanticColors.blueSoft,
    foreground: AppSemanticColors.blueInk,
  );
  static const teal = _FactPalette(
    background: AppSemanticColors.tealSoft,
    foreground: AppSemanticColors.tealInk,
  );
  static const purple = _FactPalette(
    background: AppSemanticColors.purpleSoft,
    foreground: AppSemanticColors.purpleInk,
  );
  static const orange = _FactPalette(
    background: AppSemanticColors.orangeSoft,
    foreground: AppSemanticColors.orangeInk,
  );
}

class _FactTile extends StatelessWidget {
  const _FactTile({required this.fact});

  final _Fact fact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Use dark-mode soft backgrounds when in dark theme.
    final bg = isDark ? _darkBackground(fact.palette) : fact.palette.background;
    final fg = isDark ? _darkForeground(fact.palette) : fact.palette.foreground;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.mdBorder),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: fg.withValues(alpha: 0.12),
              borderRadius: AppRadius.smBorder,
            ),
            child: Icon(fact.icon, size: 18, color: fg),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            fact.value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppSemanticColors.textPrimaryFor(theme.brightness),
            ),
          ),
          Text(
            fact.caption,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: AppSemanticColors.textTertiaryFor(theme.brightness),
            ),
          ),
        ],
      ),
    );
  }

  Color _darkBackground(_FactPalette p) {
    return switch (p) {
      _FactPalette.blue => AppSemanticColors.blueSoftDark,
      _FactPalette.teal => AppSemanticColors.tealSoftDark,
      _FactPalette.purple => AppSemanticColors.purpleSoftDark,
      _ => AppSemanticColors.orangeSoftDark,
    };
  }

  Color _darkForeground(_FactPalette p) {
    return switch (p) {
      _FactPalette.blue => AppSemanticColors.blueMid,
      _FactPalette.teal => AppSemanticColors.tealMid,
      _FactPalette.purple => AppSemanticColors.purpleMid,
      _ => AppSemanticColors.orangeMid,
    };
  }
}

/// Feature/amenity chips (furnished, wifi, parking, lift, security, plus
/// catalog amenities) for the flat details page.
///
/// Key amenities use color-coded soft-background pills (green for furnished,
/// blue for wifi, teal for parking, purple for lift, orange for security)
/// instead of uniform gray info chips — making the amenity list scannable
/// and visually appealing, inspired by the swipe card's quick-stat pills.
class FlatDetailsFeatureChips extends StatelessWidget {
  const FlatDetailsFeatureChips({required this.listing, super.key});

  final PropertyListing listing;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final chips = <Widget>[];
    final shownLabels = <String>{};
    final l = listing;

    void addChip(
      String key,
      IconData icon,
      String label,
      _ChipPalette palette,
    ) {
      if (shownLabels.add(key)) {
        chips.add(
          _ColoredChip(
            icon: icon,
            label: label,
            palette: palette,
            isDark: isDark,
          ),
        );
      }
    }

    if (l.bedrooms != null) {
      addChip(
        'beds',
        Icons.bed_outlined,
        '${l.bedrooms} Beds',
        _ChipPalette.blue,
      );
    }
    if (l.isFurnished) {
      addChip(
        'furnished',
        Icons.chair_outlined,
        locale.featureFurnished,
        _ChipPalette.green,
      );
    }
    if (l.features.any(
      (f) =>
          f.toLowerCase().contains('wifi') || f.toLowerCase().contains('wi_fi'),
    )) {
      addChip(
        'wifi',
        Icons.wifi_outlined,
        locale.wifiChipLabel,
        _ChipPalette.blue,
      );
    }
    if (l.features.any((f) => f.toLowerCase().contains('parking'))) {
      addChip(
        'parking',
        Icons.local_parking_outlined,
        locale.parkingChipLabel,
        _ChipPalette.teal,
      );
    }
    if (l.features.any(
      (f) =>
          f.toLowerCase().contains('lift') ||
          f.toLowerCase().contains('elevator'),
    )) {
      addChip(
        'lift',
        Icons.elevator_outlined,
        locale.liftChipLabel,
        _ChipPalette.purple,
      );
    }
    if (l.features.any((f) => f.toLowerCase().contains('security'))) {
      addChip(
        'security',
        Icons.security_outlined,
        locale.securityChipLabel,
        _ChipPalette.orange,
      );
    }

    // Catalog amenities use the default neutral pill style.
    for (final amenity in l.amenities) {
      final key = amenity.title.toLowerCase();
      if (shownLabels.add(key)) {
        chips.add(
          _ColoredChip(
            icon: Icons.check_circle_outline_rounded,
            label: amenity.title,
            palette: _ChipPalette.neutral,
            isDark: isDark,
          ),
        );
      }
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: chips,
    );
  }
}

/// Palette for a feature chip — soft background + coloured icon.
enum _ChipPalette { blue, teal, purple, orange, green, neutral }

class _ColoredChip extends StatelessWidget {
  const _ColoredChip({
    required this.icon,
    required this.label,
    required this.palette,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final _ChipPalette palette;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (bg, fg) = _resolve(palette, isDark);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.pillBorder,
        border: Border.all(color: fg.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: palette == _ChipPalette.neutral
                  ? AppSemanticColors.textSecondaryFor(theme.brightness)
                  : fg,
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color) _resolve(_ChipPalette p, bool isDark) {
    final brightness = isDark ? Brightness.dark : Brightness.light;
    return switch (p) {
      _ChipPalette.blue => (
        AppSemanticColors.blueSoftFor(brightness),
        isDark ? AppSemanticColors.blueMid : AppSemanticColors.blueInk,
      ),
      _ChipPalette.teal => (
        AppSemanticColors.tealSoftFor(brightness),
        isDark ? AppSemanticColors.tealMid : AppSemanticColors.tealInk,
      ),
      _ChipPalette.purple => (
        AppSemanticColors.purpleSoftFor(brightness),
        isDark ? AppSemanticColors.purpleMid : AppSemanticColors.purpleInk,
      ),
      _ChipPalette.orange => (
        AppSemanticColors.orangeSoftFor(brightness),
        isDark ? AppSemanticColors.orangeMid : AppSemanticColors.orangeInk,
      ),
      _ChipPalette.green => (
        AppSemanticColors.greenSoftFor(brightness),
        AppSemanticColors.greenInkFor(brightness),
      ),
      _ChipPalette.neutral => (
        AppSemanticColors.secondarySurfaceFor(brightness),
        AppSemanticColors.textSecondaryFor(brightness),
      ),
    };
  }
}
