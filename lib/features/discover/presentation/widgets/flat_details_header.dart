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
                  color: AppSemanticColors.textPrimaryFor(
                    isDark ? Brightness.dark : Brightness.light,
                  ),
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

/// Scannable quick-stat pills (gender, sharing type, available from, furnished)
/// shown below the location row — inspired by the swipe card's quick-stat
/// overlay. Uses brightness-aware soft pastel fills (not light paper2).
class _QuickStatPills extends StatelessWidget {
  const _QuickStatPills({required this.listing, required this.locale});

  final PropertyListing listing;
  final AppLocalizations locale;

  @override
  Widget build(BuildContext context) {
    final l = listing;
    final pills = <_StatPill>[];

    // Gender preference
    final genderLabel = switch (l.genderPreference) {
      'male' => locale.genderSuffixMaleOnly,
      'female' => locale.genderSuffixFemaleOnly,
      _ => locale.genderSuffixAny,
    };
    pills.add(
      _StatPill(
        icon: Icons.people_outline_rounded,
        label: genderLabel,
        palette: _StatPillPalette.orange,
      ),
    );

    // Sharing type / room type
    if (l.sharingType != null && l.sharingType!.isNotEmpty) {
      pills.add(
        _StatPill(
          icon: Icons.meeting_room_outlined,
          label: localizedFlatmatesSharingTypeLabel(locale, l.sharingType!),
          palette: _StatPillPalette.purple,
        ),
      );
    }

    // Available from (schedule / move-in fact)
    final availableLabel = l.availableFrom != null
        ? DateFormat.yMMMd(locale.localeName).format(l.availableFrom!)
        : locale.flexibleLabel;
    pills.add(
      _StatPill(
        icon: Icons.event_available_outlined,
        label: availableLabel,
        palette: _StatPillPalette.blue,
      ),
    );

    // Furnished
    if (l.isFurnished) {
      pills.add(
        _StatPill(
          icon: Icons.chair_outlined,
          label: locale.featureFurnished,
          palette: _StatPillPalette.green,
        ),
      );
    }

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [for (final pill in pills) _StatPillChip(pill: pill)],
    );
  }
}

enum _StatPillPalette { orange, blue, purple, green }

class _StatPill {
  const _StatPill({
    required this.icon,
    required this.label,
    required this.palette,
  });
  final IconData icon;
  final String label;
  final _StatPillPalette palette;
}

class _StatPillChip extends StatelessWidget {
  const _StatPillChip({required this.pill});
  final _StatPill pill;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final isDark = brightness == Brightness.dark;
    final (bg, fg) = _resolve(pill.palette, isDark);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.pillBorder,
        border: Border.all(color: fg.withValues(alpha: 0.25), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(pill.icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(
            pill.label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color) _resolve(_StatPillPalette palette, bool isDark) {
    final brightness = isDark ? Brightness.dark : Brightness.light;
    return switch (palette) {
      _StatPillPalette.orange => (
        AppSemanticColors.orangeSoftFor(brightness),
        isDark ? AppSemanticColors.orangeMid : AppSemanticColors.orangeInk,
      ),
      _StatPillPalette.blue => (
        AppSemanticColors.blueSoftFor(brightness),
        isDark ? AppSemanticColors.blueMid : AppSemanticColors.blueInk,
      ),
      _StatPillPalette.purple => (
        AppSemanticColors.purpleSoftFor(brightness),
        isDark ? AppSemanticColors.purpleMid : AppSemanticColors.purpleInk,
      ),
      _StatPillPalette.green => (
        AppSemanticColors.greenSoftFor(brightness),
        AppSemanticColors.greenInkFor(brightness),
      ),
    };
  }
}
