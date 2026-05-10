import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/flatmates_bottom_sheet.dart';
import '../../../shared/presentation/flatmates_chip.dart';
import '../../../shared/presentation/flatmates_listing_mini_card.dart';
import '../../../shared/presentation/flatmates_price_text.dart';
import '../../../shared/presentation/flatmates_ui.dart';
import '../../discover_repository.dart';

/// Shows a bottom sheet with all listings in a cluster.
void showClusterSheet(
  BuildContext context, {
  required List<PropertyListing> clusterItems,
  required void Function(PropertyListing) onListingTap,
}) {
  final theme = Theme.of(context);
  final locale = AppLocalizations.of(context);

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
                return FlatmatesListingMiniCard(
                  title: item.title,
                  rent: item.monthlyRent.toInt(),
                  imageUrl: item.mainImageUrl,
                  locality: item.locality,
                  subtitle: item.bedrooms != null
                      ? locale.homeBedsValue(item.bedrooms!)
                      : null,
                  trailing: FlatmatesPriceText.card(
                    amount: item.monthlyRent.toInt(),
                    period: 'mo',
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    onListingTap(item);
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

/// Shows a bottom sheet for a single listing with details and a like action.
void showListingSheet(
  BuildContext context, {
  required PropertyListing item,
  required VoidCallback onLike,
}) {
  final locale = AppLocalizations.of(context);

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
              imageUrl: item.mainImageUrl,
              locality: item.locality,
              trailing: FlatmatesPriceText.card(
                amount: item.monthlyRent.toInt(),
                period: 'mo',
              ),
            ),
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
