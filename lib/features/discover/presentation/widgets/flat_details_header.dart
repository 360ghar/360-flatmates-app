import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/compatibility/compatibility_engine.dart';
import '../../../../core/compatibility/compatibility_ring.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/components.dart';
import '../../discover_repository.dart';
import 'flat_details_carousel.dart';
import 'flat_details_facts.dart';

class FlatDetailsHeader extends StatelessWidget {
  const FlatDetailsHeader({
    required this.listing,
    required this.currentIndex,
    required this.onPageChanged,
    required this.onBack,
    required this.onShare,
    this.onFavorite,
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

  /// Null hides the heart (for example on the viewer's own listing).
  final VoidCallback? onFavorite;
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

    // Content sheet overlaps the carousel bottom by this much, giving the
    // "sheet over hero" look with rounded top corners.
    const sheetOverlap = 20.0;

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
          heroTagPrefix: 'flat-gallery-${l.id}',
          bottomInset: sheetOverlap,
        ),

        Transform.translate(
          offset: const Offset(0, -sheetOverlap),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.lg,
              AppSpacing.screen,
              0,
            ),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.card),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (l.isLive)
                      Text(
                        locale.liveBadge,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppSemanticColors.pineFor(theme.brightness),
                        ),
                      ),
                    const Spacer(),
                    if (l.createdAt != null)
                      Text(
                        DateFormat.yMMMd(
                          locale.localeName,
                        ).format(l.createdAt!),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppSemanticColors.textTertiaryFor(
                            theme.brightness,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // h2 display role (Gambarino), at most two lines.
                Text(
                  l.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.sm),

                FlatmatesPriceText.hero(
                  amount: l.monthlyRent.round(),
                  period: AppLocalizations.of(context).perMonthSuffix,
                  color: AppSemanticColors.textPrimaryFor(theme.brightness),
                ),
                const SizedBox(height: AppSpacing.sm),

                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: AppSemanticColors.textSecondaryFor(
                        theme.brightness,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        [l.locality, l.city].whereType<String>().join(', '),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppSemanticColors.textSecondaryFor(
                            theme.brightness,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Quick stat pills — scannable facts at-a-glance, inspired by
                // the swipe card's quick-stat overlay.
                _QuickStatPills(listing: l, locale: locale),
                const SizedBox(height: AppSpacing.lg),

                _OwnerCard(
                  ownerName: l.ownerName,
                  ownerImageUrl: l.owner?.profileImageUrl,
                  ownerMode: l.owner?.mode,
                  onTap: onOwnerTap,
                  matchPercentage: matchPercentage,
                ),
                const SizedBox(height: AppSpacing.lg),

                FlatDetailsFactsRow(listing: l),
                const SizedBox(height: AppSpacing.md),

                FlatDetailsFeatureChips(listing: l),
              ],
            ),
          ),
        ),
      ],
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
    final locale = AppLocalizations.of(context);
    final name = ownerName ?? locale.ownerFallbackLabel;

    return FlatmatesCard(
      padding: AppSpacing.edgeMd,
      onTap: onTap,
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (matchPercentage != null && matchPercentage! > 0)
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CompatibilityRing(
                      percentage: matchPercentage!,
                      size: 52,
                      strokeWidth: 3,
                    ),
                    FlatmatesAvatar(
                      name: name,
                      imageUrl: ownerImageUrl,
                      size: 40,
                    ),
                  ],
                )
              else
                FlatmatesAvatar(name: name, imageUrl: ownerImageUrl, size: 40),
              // Match pill sits under the ring, matching owner profile layout.
              if (matchPercentage != null && matchPercentage! > 0) ...[
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: compatibilityScoreColor(
                      matchPercentage!,
                      brightness: theme.brightness,
                    ).withValues(alpha: 0.12),
                    borderRadius: AppRadius.mdBorder,
                  ),
                  child: Text(
                    locale.percentMatch(matchPercentage!.round()),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: compatibilityScoreColor(
                        matchPercentage!,
                        brightness: theme.brightness,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  locale.listedByLabel(name),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (ownerMode != null)
                  Text(
                    _localizedMode(ownerMode!, locale),
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

  String _localizedMode(String mode, AppLocalizations locale) {
    switch (mode) {
      case 'co_hunter':
        return locale.ownerModeCoHunter;
      case 'room_poster':
        return locale.ownerModeRoomPoster;
      case 'open_to_both':
        return locale.ownerModeOpenToBoth;
      default:
        return humanizeFlatmatesToken(mode);
    }
  }
}

/// Quick facts (gender, sharing type, available from, furnished) under the
/// location row, as pine-soft pills from the one palette.
class _QuickStatPills extends StatelessWidget {
  const _QuickStatPills({required this.listing, required this.locale});

  final PropertyListing listing;
  final AppLocalizations locale;

  @override
  Widget build(BuildContext context) {
    final l = listing;
    ListingMetaItem item(IconData icon, String label) => ListingMetaItem(
      icon: icon,
      label: label,
      chipColor: MetaChipColor.green,
    );

    return FlatmatesListingMetaChips(
      items: [
        item(Icons.people_outline_rounded, switch (l.genderPreference) {
          'male' => locale.genderSuffixMaleOnly,
          'female' => locale.genderSuffixFemaleOnly,
          _ => locale.genderSuffixAny,
        }),
        if (l.sharingType != null && l.sharingType!.isNotEmpty)
          item(
            Icons.meeting_room_outlined,
            localizedFlatmatesSharingTypeLabel(locale, l.sharingType!),
          ),
        item(
          Icons.event_available_outlined,
          l.availableFrom != null
              ? DateFormat.yMMMd(locale.localeName).format(l.availableFrom!)
              : locale.flexibleLabel,
        ),
        if (l.isFurnished) item(Icons.chair_outlined, locale.featureFurnished),
      ],
    );
  }
}
