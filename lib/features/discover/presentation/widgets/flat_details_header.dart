import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/compatibility/compatibility_ring.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
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
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.xl,
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
                    Text(
                      locale.listingLabel.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.6,
                        color: AppSemanticColors.textTertiaryFor(
                          isDark ? Brightness.dark : Brightness.light,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    if (l.isLive) _LivePill(isDark: isDark, locale: locale),
                    const Spacer(),
                    if (l.createdAt != null)
                      Text(
                        DateFormat.yMMMd(
                          locale.localeName,
                        ).format(l.createdAt!),
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
                    fontSize: AppTypography.displayLgSize,
                    fontWeight: AppTypography.displayLgWeight,
                    height: AppTypography.displayLgHeight,
                    letterSpacing: AppTypography.displayLgLetterSpacing,
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
    final locale = AppLocalizations.of(context);
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
              size: 52,
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
        return mode;
    }
  }
}
