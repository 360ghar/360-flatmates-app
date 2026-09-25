import 'package:flutter/material.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/flatmates_bottom_sheet.dart';
import '../../../shared/presentation/flatmates_chip.dart';
import '../../../shared/presentation/flatmates_listing_mini_card.dart';
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
                  if (item.bedrooms != null)
                    locale.homeBedroomsChip(item.bedrooms!),
                  if (item.sharingType != null)
                    localizedFlatmatesSharingTypeLabel(
                      locale,
                      item.sharingType!,
                    ),
                  // Gender as text, not a colour-only dot.
                  if (item.genderPreference == 'male')
                    locale.genderSuffixMaleOnly,
                  if (item.genderPreference == 'female')
                    locale.genderSuffixFemaleOnly,
                ];
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
                      trailing: FlatmatesPriceText.card(
                        amount: item.monthlyRent.toInt(),
                        period: AppLocalizations.of(context).perMonthSuffix,
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
