import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/flatmates_bottom_sheet.dart';
import '../../../shared/presentation/flatmates_chip.dart';
import '../../../shared/presentation/flatmates_listing_mini_card.dart';
import '../../../shared/presentation/flatmates_network_image.dart';
import '../../../shared/presentation/flatmates_price_text.dart';
import '../../../shared/presentation/flatmates_ui.dart';
import '../../discover_repository.dart';

void showClusterSheet(
  BuildContext context, {
  required List<PropertyListing> clusterItems,
  required void Function(PropertyListing) onListingTap,
}) {
  final theme = Theme.of(context);
  final locale = AppLocalizations.of(context);
  const thumbSize = 88.0;

  FlatmatesBottomSheet.show(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.lg,
              AppSpacing.screen,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    clusterItems.first.locality ?? locale.clusterListingsTitle,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                FlatmatesChip(
                  label: locale.clusterListingsCount(clusterItems.length),
                  variant: FlatmatesChipVariant.info,
                  icon: Icons.apartment_rounded,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              controller: scrollController,
              padding: AppSpacing.edgeScreen,
              itemCount: clusterItems.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (_, index) {
                final item = clusterItems[index];
                final subtitleParts = <String>[
                  if (item.bedrooms != null) '${item.bedrooms} BHK',
                  if (item.sharingType != null)
                    localizedFlatmatesSharingTypeLabel(
                      locale,
                      item.sharingType!,
                    ),
                ];
                final genderDot = switch (item.genderPreference) {
                  'male' => Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  'female' => Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.pink,
                      shape: BoxShape.circle,
                    ),
                  ),
                  _ => null,
                };
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FlatmatesListingMiniCard(
                      title: item.title,
                      rent: item.monthlyRent.toInt(),
                      imageUrl: item.effectiveMainImageUrl,
                      locality: item.locality,
                      subtitle: subtitleParts.isNotEmpty
                          ? subtitleParts.join(' · ')
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (genderDot != null) ...[
                            genderDot,
                            const SizedBox(width: AppSpacing.sm),
                          ],
                          FlatmatesPriceText.card(
                            amount: item.monthlyRent.toInt(),
                            period: 'mo',
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        onListingTap(item);
                      },
                    ),
                    if (item.owner?.fullName != null)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: thumbSize + AppSpacing.md,
                          top: 2,
                        ),
                        child: Text(
                          locale.byOwnerLabel(item.owner!.fullName),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppSemanticColors.textSecondaryFor(
                              theme.brightness,
                            ),
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

void showListingSheet(
  BuildContext context, {
  required PropertyListing item,
  required VoidCallback onLike,
}) {
  final theme = Theme.of(context);
  final locale = AppLocalizations.of(context);
  final now = DateTime.now();

  FlatmatesBottomSheet.show(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.3,
      maxChildSize: 0.7,
      expand: false,
      builder: (_, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.all(AppSpacing.screen),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FlatmatesListingMiniCard(
              title: item.title,
              rent: item.monthlyRent.toInt(),
              imageUrl: item.effectiveMainImageUrl,
              locality: item.locality,
              trailing: FlatmatesPriceText.card(
                amount: item.monthlyRent.toInt(),
                period: 'mo',
              ),
            ),
            if (item.owner != null) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  if (item.owner!.profileImageUrl != null)
                    FlatmatesNetworkImage(
                      imageUrl: item.owner!.profileImageUrl!,
                      width: 28,
                      height: 28,
                      borderRadius: BorderRadius.circular(14),
                    )
                  else
                    CircleAvatar(
                      radius: 14,
                      child: Text(
                        item.owner!.fullName.isNotEmpty
                            ? item.owner!.fullName[0].toUpperCase()
                            : '?',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    locale.byOwnerLabel(item.owner!.fullName),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppSemanticColors.textSecondaryFor(
                        theme.brightness,
                      ),
                    ),
                  ),
                  if (item.owner!.mode != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    FlatmatesChip(
                      label: item.owner!.mode!,
                      variant: FlatmatesChipVariant.info,
                    ),
                  ],
                ],
              ),
            ],
            if (item.availableFrom != null) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: !item.availableFrom!.isAfter(now)
                          ? Colors.green.shade600
                          : Colors.orange.shade700,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    !item.availableFrom!.isAfter(now)
                        ? locale.availableNowLabel
                        : locale.availableFromFull(
                            DateFormat.yMMMd().format(item.availableFrom!),
                          ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppSemanticColors.textSecondaryFor(
                        theme.brightness,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                if (item.bedrooms != null)
                  FlatmatesChip(
                    icon: Icons.bed_outlined,
                    label: locale.homeBedsValue(item.bedrooms!),
                    variant: FlatmatesChipVariant.info,
                  ),
                if (item.bathrooms != null)
                  FlatmatesChip(
                    icon: Icons.bathtub_outlined,
                    label: locale.homeBathsValue(item.bathrooms!),
                    variant: FlatmatesChipVariant.info,
                  ),
                if (item.genderPreference != null)
                  FlatmatesChip(
                    icon: Icons.group_outlined,
                    label: localizedFlatmatesGenderLabel(
                      locale,
                      item.genderPreference!,
                    ),
                    variant: FlatmatesChipVariant.info,
                  ),
                if (item.sharingType != null)
                  FlatmatesChip(
                    icon: Icons.meeting_room_outlined,
                    label: localizedFlatmatesSharingTypeLabel(
                      locale,
                      item.sharingType!,
                    ),
                    variant: FlatmatesChipVariant.info,
                  ),
                if (item.isFurnished)
                  FlatmatesChip(
                    icon: Icons.chair_outlined,
                    label: locale.featureFurnished,
                    variant: FlatmatesChipVariant.info,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            FlatmatesButton(
              label: locale.likeListingCta,
              onPressed: () {
                Navigator.pop(ctx);
                onLike();
              },
              icon: Icons.favorite_border_rounded,
            ),
          ],
        ),
      ),
    ),
  );
}
