import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/flatmates_like_button.dart';
import '../../../shared/presentation/flatmates_listing_meta_chips.dart';
import '../../../shared/presentation/flatmates_network_image.dart';
import '../../../shared/presentation/flatmates_price_text.dart';
import '../../discover_repository.dart';

/// Photo-first property card aligned with Airbnb `property-card`.
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
    final brightness = theme.brightness;
    final ink = AppSemanticColors.textPrimaryFor(brightness);
    final body = AppSemanticColors.textSecondaryFor(brightness);
    final muted = AppSemanticColors.textTertiaryFor(brightness);

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

    final metaItems = <ListingMetaItem>[
      if (item.bedrooms != null)
        ListingMetaItem(
          icon: Icons.bed_outlined,
          label: locale.homeBedsValue(item.bedrooms!),
          chipColor: MetaChipColor.blue,
        ),
      if (item.bathrooms != null)
        ListingMetaItem(
          icon: Icons.bathtub_outlined,
          label: locale.homeBathsValue(item.bathrooms!),
          chipColor: MetaChipColor.teal,
        ),
      if (item.areaSqft != null)
        ListingMetaItem(
          icon: Icons.square_foot_outlined,
          label: locale.sqftLabel(item.areaSqft!.round()),
          chipColor: MetaChipColor.purple,
        ),
      ListingMetaItem(
        icon: Icons.people_outline_rounded,
        label: genderSuffix,
        chipColor: MetaChipColor.orange,
      ),
      if (item.isFurnished)
        ListingMetaItem(
          icon: Icons.chair_outlined,
          label: locale.featureFurnished,
          emphasis: true,
          chipColor: MetaChipColor.green,
        ),
    ];

    final moveInTotal =
        item.monthlyRent.round() + (item.securityDeposit?.round() ?? 0);

    final hasImage =
        item.effectiveMainImageUrl != null &&
        item.effectiveMainImageUrl!.trim().isNotEmpty;
    final isLiked = item.liked ?? false;

    return Material(
      key: cardKey ?? Key('discover_feed_card_${item.id}'),
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.cardBorder,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              // Feed: 1:1 photo-first. Compact map carousel: 16:10 balances
              // photo size with readable rent/locality text below.
              aspectRatio: compact ? 16 / 10 : 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.cardBorder,
                      boxShadow: isSelected
                          ? AppShadows.elevationFor(brightness)
                          : AppShadows.none,
                    ),
                    child: ClipRRect(
                      borderRadius: AppRadius.cardBorder,
                      // FlatmatesNetworkImage uses LayoutBuilder to size
                      // Cloudinary delivery + mem decode for this slot.
                      child: hasImage
                          ? FlatmatesNetworkImage(
                              imageUrl: item.effectiveMainImageUrl!,
                              fit: BoxFit.cover,
                              fallbackName: item.title,
                            )
                          : _CardImageFallback(
                              title: item.title,
                              compact: compact,
                            ),
                    ),
                  ),
                  if (badgeLabel != null)
                    Positioned(
                      top: AppSpacing.sm,
                      left: AppSpacing.sm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm + AppSpacing.xxs,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: const BoxDecoration(
                          color: AppSemanticColors.canvas,
                          borderRadius: AppRadius.pillBorder,
                          boxShadow: AppShadows.elevation,
                        ),
                        child: Text(
                          badgeLabel!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppSemanticColors.ink,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  if (item.sharingType != null &&
                      (item.sharingType == 'private_room' ||
                          item.sharingType == 'shared_room'))
                    Positioned(
                      top: AppSpacing.sm,
                      left: badgeLabel != null ? null : AppSpacing.sm,
                      // Clearance for the top-right like control (default size 32).
                      right: badgeLabel != null
                          ? AppSpacing.sm + AppSpacing.xl
                          : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: AppSemanticColors.canvas.withValues(
                            alpha: 0.92,
                          ),
                          borderRadius: AppRadius.pillBorder,
                        ),
                        child: Text(
                          item.sharingType == 'private_room'
                              ? locale.roomTypePrivate
                              : locale.roomTypeShared,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppSemanticColors.ink,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: FlatmatesLikeButton(
                      key: Key('discover_like_${item.id}'),
                      liked: isLiked,
                      onTap: onLike,
                      iconSize: 16,
                      tooltip: isLiked
                          ? locale.unlikeListingTooltip
                          : locale.likeListingTooltip,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                top: compact ? AppSpacing.sm : AppSpacing.sm + AppSpacing.xxs,
              ),
              child: compact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatRent(item.monthlyRent.round()),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: ink,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (titleLocation.isNotEmpty)
                          Text(
                            titleLocation,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: muted,
                              fontSize: 12,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: ink,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (titleLocation.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                size: 12,
                                color: AppSemanticColors.primary,
                              ),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  titleLocation,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: muted,
                                    height: 1.43,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (metaItems.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          FlatmatesListingMetaChips(items: metaItems),
                        ],
                        const SizedBox(height: AppSpacing.xs),
                        // Price block: rent + /month on the first line, with
                        // /month flowing to a new line if the card is narrow.
                        // Move-in cost goes on its own line below. The full
                        // price string must always render — never ellipsized.
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: _formatRent(item.monthlyRent.round()),
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          color: ink,
                                          fontWeight: FontWeight.w700,
                                          height: 1.25,
                                        ),
                                  ),
                                  const TextSpan(text: ' '),
                                  TextSpan(
                                    text: locale.perMonthSuffix,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: body,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (item.securityDeposit != null &&
                                item.securityDeposit! > 0) ...[
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                locale.moveInCostLabel(
                                  FlatmatesPriceText.formatRupee(moveInTotal),
                                ),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: muted,
                                ),
                              ),
                            ],
                          ],
                        ),
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
      color: AppSemanticColors.surfaceStrong,
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
            color: AppSemanticColors.muted,
            size: compact ? 16 : 22,
          ),
          SizedBox(height: compact ? 2 : AppSpacing.xs),
          Text(
            title,
            maxLines: compact ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppSemanticColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
