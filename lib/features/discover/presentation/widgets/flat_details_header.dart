import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/compatibility/compatibility_ring.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/components.dart';
import '../../discover_repository.dart';
import 'flat_details_carousel.dart';

class FlatDetailsHeader extends StatelessWidget {
  const FlatDetailsHeader({
    required this.listing,
    required this.currentIndex,
    required this.onPageChanged,
    required this.onBack,
    required this.onShare,
    required this.onFavorite,
    this.isFavorite = false,
    this.onOwnerTap,
    this.onImageTap,
    this.matchPercentage,
    super.key,
  });

  final PropertyListing listing;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onBack;
  final VoidCallback onShare;
  final VoidCallback onFavorite;
  final bool isFavorite;
  final VoidCallback? onOwnerTap;
  final VoidCallback? onImageTap;
  final double? matchPercentage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    final l = listing;
    final images = l.imageUrls;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FlatDetailsCarousel(
          images: images,
          currentIndex: currentIndex,
          onPageChanged: onPageChanged,
          title: l.title,
          onBack: onBack,
          onShare: onShare,
          onFavorite: onFavorite,
          isFavorite: isFavorite,
          onImageTap: onImageTap,
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.xl,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    locale.listingLabel.toUpperCase(),
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamilyMono,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.6,
                      color: AppSemanticColors.textTertiaryFor(
                        isDark ? Brightness.dark : Brightness.light,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  if (l.isLive)
                    _LivePill(isDark: isDark, locale: locale),
                  const Spacer(),
                  if (l.createdAt != null)
                    Text(
                      DateFormat.yMMMd(locale.localeName).format(l.createdAt!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppSemanticColors.textTertiaryFor(
                          isDark ? Brightness.dark : Brightness.light,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              Text(
                l.title,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamilyDisplay,
                  fontSize: AppTypography.h2Size,
                  fontWeight: AppTypography.h2Weight,
                  height: AppTypography.h2Height,
                  letterSpacing: AppTypography.h2LetterSpacing,
                  color: AppSemanticColors.textPrimaryFor(
                    isDark ? Brightness.dark : Brightness.light,
                  ),
                  fontVariations: const [
                    FontVariation('opsz', 96),
                    FontVariation('SOFT', 30),
                    FontVariation('WONK', 0),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              FlatmatesPriceText.hero(
                amount: l.monthlyRent.round(),
                period: 'month',
                color: AppSemanticColors.ink,
              ),
              const SizedBox(height: AppSpacing.sm),

              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: AppSemanticColors.textSecondaryFor(
                      isDark ? Brightness.dark : Brightness.light,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      [l.locality, l.city].whereType<String>().join(', '),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppSemanticColors.textSecondaryFor(
                          isDark ? Brightness.dark : Brightness.light,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              _OwnerCard(
                ownerName: l.ownerName,
                ownerImageUrl: l.owner?.profileImageUrl,
                ownerMode: l.owner?.mode,
                onTap: onOwnerTap,
                matchPercentage: matchPercentage,
              ),
              const SizedBox(height: AppSpacing.lg),

              _QuickFactsStrip(listing: l, isDark: isDark, theme: theme),
              const SizedBox(height: AppSpacing.md),

              _FeatureChips(
                listing: l,
                isDark: isDark,
                theme: theme,
                locale: locale,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LivePill extends StatelessWidget {
  const _LivePill({required this.isDark, required this.locale});
  final bool isDark;
  final AppLocalizations locale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppSemanticColors.success.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        locale.liveBadge,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppSemanticColors.success,
        ),
      ),
    );
  }
}

class _OwnerCard extends StatelessWidget {
  const _OwnerCard({
    required this.ownerName,
    this.ownerImageUrl,
    this.ownerMode,
    this.onTap,
    this.matchPercentage,
  });

  final String? ownerName;
  final String? ownerImageUrl;
  final String? ownerMode;
  final VoidCallback? onTap;
  final double? matchPercentage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = ownerName ?? 'Owner';

    return FlatmatesCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: onTap,
      child: Row(
        children: [
          FlatmatesAvatar(
            name: name,
            imageUrl: ownerImageUrl,
            size: matchPercentage != null ? 36 : 44,
          ),
          if (matchPercentage != null) ...[
            const SizedBox(width: AppSpacing.sm),
            CompatibilityRing(
              percentage: matchPercentage!,
              size: 40,
              strokeWidth: 4,
            ),
            const SizedBox(width: AppSpacing.sm),
          ] else
            const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Listed by $name',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (ownerMode != null)
                  Text(
                    _localizedMode(ownerMode!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppSemanticColors.textSecondaryFor(
                        theme.brightness,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: AppSemanticColors.textTertiaryFor(theme.brightness),
          ),
        ],
      ),
    );
  }

  String _localizedMode(String mode) {
    switch (mode) {
      case 'co_hunter':
        return 'Co-Hunter';
      case 'room_poster':
        return 'Room Poster';
      case 'open_to_both':
        return 'Open to Both';
      default:
        return mode;
    }
  }
}

class _QuickFactsStrip extends StatelessWidget {
  const _QuickFactsStrip({
    required this.listing,
    required this.isDark,
    required this.theme,
  });

  final PropertyListing listing;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final facts = <Widget>[];
    final l = listing;

    if (l.bedrooms != null) {
      facts.add(_FactPill(
        icon: Icons.bed_outlined,
        label: '${l.bedrooms} bed',
        isDark: isDark,
      ));
    }
    if (l.bathrooms != null) {
      facts.add(_FactPill(
        icon: Icons.shower_outlined,
        label: '${l.bathrooms} bath',
        isDark: isDark,
      ));
    }
    if (l.areaSqft != null) {
      facts.add(_FactPill(
        icon: Icons.square_foot_outlined,
        label: '${l.areaSqft!.round()} sqft',
        isDark: isDark,
      ));
    }
    if (l.floorNumber != null && l.totalFloors != null) {
      facts.add(_FactPill(
        icon: Icons.layers_outlined,
        label: 'Floor ${l.floorNumber}/${l.totalFloors}',
        isDark: isDark,
      ));
    } else if (l.floorNumber != null) {
      facts.add(_FactPill(
        icon: Icons.layers_outlined,
        label: 'Floor ${l.floorNumber}',
        isDark: isDark,
      ));
    }

    if (facts.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: facts
            .map((f) => Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: f,
                ))
            .toList(),
      ),
    );
  }
}

class _FactPill extends StatelessWidget {
  const _FactPill({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppSemanticColors.secondarySurfaceFor(
          isDark ? Brightness.dark : Brightness.light,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppSemanticColors.textSecondaryFor(
            isDark ? Brightness.dark : Brightness.light,
          )),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppSemanticColors.textPrimaryFor(
                isDark ? Brightness.dark : Brightness.light,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureChips extends StatelessWidget {
  const _FeatureChips({
    required this.listing,
    required this.isDark,
    required this.theme,
    required this.locale,
  });

  final PropertyListing listing;
  final bool isDark;
  final ThemeData theme;
  final AppLocalizations locale;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    final shownLabels = <String>{};
    final l = listing;

    void addChip(String key, Widget chip) {
      if (shownLabels.add(key)) chips.add(chip);
    }

    if (l.bedrooms != null) {
      addChip('beds', FlatmatesChip(
        variant: FlatmatesChipVariant.info,
        label: '${l.bedrooms} Beds',
        icon: Icons.bed_outlined,
      ));
    }
    if (l.isFurnished) {
      addChip('furnished', FlatmatesChip(
        variant: FlatmatesChipVariant.info,
        label: locale.featureFurnished,
        icon: Icons.chair_outlined,
      ));
    }
    if (l.features.any((f) =>
        f.toLowerCase().contains('wifi') || f.toLowerCase().contains('wi_fi'))) {
      addChip('wifi', FlatmatesChip(
        variant: FlatmatesChipVariant.info,
        label: locale.wifiChipLabel,
        icon: Icons.wifi_outlined,
      ));
    }
    if (l.features.any((f) => f.toLowerCase().contains('parking'))) {
      addChip('parking', FlatmatesChip(
        variant: FlatmatesChipVariant.info,
        label: locale.parkingChipLabel,
        icon: Icons.local_parking_outlined,
      ));
    }
    if (l.features.any((f) =>
        f.toLowerCase().contains('lift') || f.toLowerCase().contains('elevator'))) {
      addChip('lift', FlatmatesChip(
        variant: FlatmatesChipVariant.info,
        label: locale.liftChipLabel,
        icon: Icons.elevator_outlined,
      ));
    }
    if (l.features.any((f) => f.toLowerCase().contains('security'))) {
      addChip('security', FlatmatesChip(
        variant: FlatmatesChipVariant.info,
        label: locale.securityChipLabel,
        icon: Icons.security_outlined,
      ));
    }

    for (final amenity in l.amenities) {
      addChip(amenity.title.toLowerCase(), FlatmatesChip(
        variant: FlatmatesChipVariant.info,
        label: amenity.title,
      ));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: chips,
    );
  }
}
