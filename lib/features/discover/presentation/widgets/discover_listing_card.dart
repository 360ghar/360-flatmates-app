import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/flatmates_card.dart';
import '../../../shared/presentation/flatmates_listing_meta_chips.dart';
import '../../../shared/presentation/flatmates_network_image.dart';
import '../../../shared/presentation/flatmates_price_text.dart';
import '../../discover_repository.dart';

class DiscoverListingCard extends StatelessWidget {
  const DiscoverListingCard({
    required this.item,
    required this.onLike,
    super.key,
    this.cardKey,
    this.badgeLabel,
    this.onTap,
    this.isSelected = false,
    this.compact = false,
  });

  final PropertyListing item;
  final VoidCallback onLike;
  final Key? cardKey;
  final String? badgeLabel;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final titleLocation = [
      if (item.locality != null && item.locality!.trim().isNotEmpty)
        item.locality!.trim(),
      if (item.subLocality != null && item.subLocality!.trim().isNotEmpty)
        item.subLocality!.trim(),
    ].join(', ');

    final genderSuffix = switch (item.genderPreference) {
      'male' => locale.genderSuffixMaleOnly,
      'female' => locale.genderSuffixFemaleOnly,
      _ => locale.genderSuffixAny,
    };

    // Reusable, a11y-safe (11sp minimum) meta facts row.
    final metaItems = <ListingMetaItem>[
      if (item.bedrooms != null)
        ListingMetaItem(
          icon: Icons.bed_outlined,
          label: locale.homeBedsValue(item.bedrooms!),
        ),
      if (item.bathrooms != null)
        ListingMetaItem(
          icon: Icons.bathtub_outlined,
          label: locale.homeBathsValue(item.bathrooms!),
        ),
      if (item.areaSqft != null)
        ListingMetaItem(
          icon: Icons.square_foot_outlined,
          label: locale.sqftLabel(item.areaSqft!.round()),
        ),
      ListingMetaItem(icon: Icons.people_outline_rounded, label: genderSuffix),
      if (item.isFurnished)
        ListingMetaItem(
          icon: Icons.chair_outlined,
          label: locale.featureFurnished,
          emphasis: true,
        ),
    ];

    // Move-in cost (first month + deposit) — surfaces hidden costs up front.
    final moveInTotal =
        item.monthlyRent.round() + (item.securityDeposit?.round() ?? 0);

    final hasImage =
        item.effectiveMainImageUrl != null &&
        item.effectiveMainImageUrl!.trim().isNotEmpty;
    final isLiked = item.liked ?? false;

    return FlatmatesCard(
      key: cardKey ?? Key('discover_feed_card_${item.id}'),
      padding: EdgeInsets.zero,
      onTap: onTap,
      elevation: isSelected ? 8 : null,
      child: Container(
        decoration: isSelected
            ? BoxDecoration(
                border: Border.all(color: AppSemanticColors.accent, width: 2),
                borderRadius: const BorderRadius.all(
                  Radius.circular(AppRadius.card),
                ),
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: compact ? 16 / 9 : 16 / 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.card),
                    ),
                    child: hasImage
                        ? FlatmatesNetworkImage(
                            imageUrl: item.effectiveMainImageUrl!,
                            fit: BoxFit.cover,
                          )
                        : _CardImageFallback(
                            title: item.title,
                            compact: compact,
                          ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.35),
                          ],
                          stops: const [0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                  if (badgeLabel != null)
                    Positioned(
                      top: AppSpacing.sm,
                      left: AppSpacing.sm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs - 1,
                        ),
                        decoration: const BoxDecoration(
                          color: AppSemanticColors.accent,
                          borderRadius: AppRadius.pillBorder,
                        ),
                        child: Text(
                          badgeLabel!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  if (item.sharingType != null &&
                      (item.sharingType == 'private_room' ||
                          item.sharingType == 'shared_room'))
                    Positioned(
                      top: AppSpacing.sm,
                      right: AppSpacing.sm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm - 2,
                          vertical: AppSpacing.xs - 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.sm - 2,
                          ),
                        ),
                        child: Text(
                          item.sharingType == 'private_room'
                              ? locale.roomTypePrivate
                              : locale.roomTypeShared,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: SizedBox(
                      width: AppSpacing.section,
                      height: AppSpacing.section,
                      child: IconButton(
                        key: Key('discover_like_${item.id}'),
                        onPressed: onLike,
                        icon: Icon(
                          isLiked
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 14,
                          color: isLiked
                              ? AppSemanticColors.accent
                              : Colors.white,
                        ),
                        padding: EdgeInsets.zero,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black38,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                        tooltip: isLiked
                            ? locale.unlikeListingTooltip
                            : locale.likeListingTooltip,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? AppSpacing.xs : AppSpacing.sm,
                compact ? AppSpacing.xs : AppSpacing.sm,
                compact ? AppSpacing.xs : AppSpacing.sm,
                AppSpacing.xs,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Rent + move-in cost row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: Text(
                          _formatRent(item.monthlyRent.round()),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppSemanticColors.textPrimaryFor(
                              theme.brightness,
                            ),
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!compact &&
                          item.securityDeposit != null &&
                          item.securityDeposit! > 0) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            locale.moveInCostLabel(
                              FlatmatesPriceText.formatRupee(moveInTotal),
                            ),
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 11,
                              color: AppSemanticColors.textTertiaryFor(
                                theme.brightness,
                              ),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs - 1),
                  Text(
                    item.title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppSemanticColors.textPrimaryFor(theme.brightness),
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (titleLocation.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs - 2),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: AppSemanticColors.textSecondaryFor(
                            theme.brightness,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            titleLocation,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 11,
                              color: AppSemanticColors.textSecondaryFor(
                                theme.brightness,
                              ),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (!compact && metaItems.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    FlatmatesListingMetaChips(items: metaItems),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatRent(int amount) {
    if (amount >= 100000) {
      final lakhs = amount / 100000;
      final value = lakhs.toStringAsFixed(lakhs >= 10 ? 1 : 2);
      final compact = value.replaceAll(RegExp(r'\.?0+$'), '');
      return '\u20b9${compact}L';
    }
    return FlatmatesPriceText.formatRupee(amount);
  }
}

class _CardImageFallback extends StatelessWidget {
  const _CardImageFallback({required this.title, required this.compact});

  final String title;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppSemanticColors.accent.withValues(alpha: 0.9),
            AppSemanticColors.accent.withValues(alpha: 0.35),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        compact ? AppSpacing.sm : AppSpacing.md,
        compact ? AppSpacing.xs : AppSpacing.sm,
        compact ? AppSpacing.sm : AppSpacing.md,
        compact ? AppSpacing.sm : AppSpacing.md,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.apartment_rounded,
            color: Colors.white,
            size: compact ? 16 : 18,
          ),
          SizedBox(height: compact ? 2 : AppSpacing.xs),
          Text(
            title,
            maxLines: compact ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
