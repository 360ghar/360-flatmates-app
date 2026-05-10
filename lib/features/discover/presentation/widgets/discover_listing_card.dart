import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/compatibility/compatibility_engine.dart';
import '../../../../core/compatibility/compatibility_ring.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/flatmates_card.dart';
import '../../../shared/presentation/flatmates_chip.dart';
import '../../../shared/presentation/flatmates_network_image.dart';
import '../../../shared/presentation/flatmates_price_text.dart';
import '../../../shared/presentation/flatmates_ui.dart';
import '../../../bootstrap/bootstrap_controller.dart';
import '../../discover_repository.dart';

class DiscoverListingCard extends StatelessWidget {
  const DiscoverListingCard({
    required this.item,
    required this.onLike,
    super.key,
    this.badgeLabel,
  });

  final PropertyListing item;
  final VoidCallback onLike;
  final String? badgeLabel;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final bootstrap = ProviderScope.containerOf(
      context,
    ).read(bootstrapControllerProvider).valueOrNull;
    final userProfile = bootstrap?.profile;

    CompatibilityResult? compatibility;
    final prefs = item.preferences;
    if (userProfile != null &&
        prefs != null &&
        prefs.containsKey('sleep_schedule')) {
      compatibility = CompatibilityEngine.calculate(
        user: {
          'sleep_schedule': userProfile.sleepSchedule ?? 'flexible',
          'cleanliness': userProfile.cleanliness ?? 'tidy',
          'food_habits': userProfile.foodHabits ?? 'no_preference',
          'smoking_drinking': userProfile.smokingDrinking ?? 'neither',
          'guests_policy': userProfile.guestsPolicy ?? 'occasional_ok',
          'work_style': userProfile.workStyle ?? 'hybrid',
        },
        peer: {
          'sleep_schedule': prefs['sleep_schedule'] ?? 'flexible',
          'cleanliness': prefs['cleanliness'] ?? 'tidy',
          'food_habits': prefs['food_habits'] ?? 'no_preference',
          'smoking_drinking': prefs['smoking_drinking'] ?? 'neither',
          'guests_policy': prefs['guests_policy'] ?? 'occasional_ok',
          'work_style': prefs['work_style'] ?? 'hybrid',
        },
      );
    }

    final titleLocation = [
      if (item.locality != null && item.locality!.trim().isNotEmpty)
        item.locality!.trim(),
      if (item.subLocality != null && item.subLocality!.trim().isNotEmpty)
        item.subLocality!.trim(),
    ].join(', ');

    return FlatmatesCard(
      key: Key('discover_listing_card_${item.id}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ListingImage(imageUrl: item.mainImageUrl, title: item.title),
          const SizedBox(width: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (compatibility != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          CompatibilityRing(
                            percentage: compatibility.percentage,
                            size: 32,
                            strokeWidth: 4,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${compatibility.percentage.toInt()}% match',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: compatibilityScoreColor(
                                      compatibility.percentage,
                                    ),
                                  ),
                                ),
                                if (compatibility.topMatchChips.isNotEmpty)
                                  Text(
                                    compatibility.topMatchChips.first,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: AppSemanticColors.textSecondaryFor(
                                        theme.brightness,
                                      ),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (badgeLabel != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InfoPill(label: badgeLabel!, highlighted: true),
                    ),
                  _CardPriceText(
                    amount: item.monthlyRent.round(),
                    period: 'month',
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(item.title, style: theme.textTheme.titleLarge),
                  ),
                  if (titleLocation.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 17,
                          color: AppSemanticColors.textSecondaryFor(
                            theme.brightness,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            titleLocation,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: AppSemanticColors.textSecondaryFor(
                                theme.brightness,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  Builder(
                    builder: (context) {
                      final infoPills = <Widget>[
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
                        if (item.areaSqft != null)
                          FlatmatesChip(
                            icon: Icons.straighten_outlined,
                            label: locale.homeAreaValue(
                              item.areaSqft!.toStringAsFixed(0),
                            ),
                            variant: FlatmatesChipVariant.info,
                          ),
                      ];
                      final overflow = infoPills.length > 3
                          ? infoPills.length - 3
                          : 0;
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ...infoPills.take(3),
                          if (overflow > 0)
                            FlatmatesChip(
                              label: '+$overflow',
                              variant: FlatmatesChipVariant.info,
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      FlatmatesAvatar(name: item.ownerName, size: 34),
                      const SizedBox(width: 10),
                      Flexible(
                        flex: 2,
                        child: Text(
                          item.ownerName ?? locale.ownerFallbackLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (item.interestCount > 0) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            locale.homeInterestCount(item.interestCount),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppSemanticColors.textSecondaryFor(
                                theme.brightness,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (item.description != null &&
                      item.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      item.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (item.features.isNotEmpty)
                        InfoPill(
                          icon: Icons.chair_outlined,
                          label: localizedFlatmatesFeatureLabel(
                            locale,
                            item.features.first,
                          ),
                          highlighted: item.isFurnished,
                        ),
                      if (item.availableFrom != null)
                        InfoPill(
                          icon: Icons.event_outlined,
                          label: locale.homeMoveInValue(
                            DateFormat(
                              'd MMM',
                              locale.localeName,
                            ).format(item.availableFrom!.toLocal()),
                          ),
                        ),
                      if (item.genderPreference != null)
                        InfoPill(
                          icon: Icons.group_outlined,
                          label: localizedFlatmatesGenderLabel(
                            locale,
                            item.genderPreference!,
                          ),
                        ),
                      if (item.sharingType != null)
                        InfoPill(
                          icon: Icons.meeting_room_outlined,
                          label: localizedFlatmatesSharingTypeLabel(
                            locale,
                            item.sharingType!,
                          ),
                        ),
                      if (item.availableFrom != null) ...[
                        () {
                          final daysUntilMoveIn = item.availableFrom!
                              .difference(DateTime.now())
                              .inDays;
                          if (daysUntilMoveIn == 0) {
                            return InfoPill(
                              icon: Icons.event_outlined,
                              label: locale.moveInToday,
                              highlighted: true,
                            );
                          } else if (daysUntilMoveIn >= 1 &&
                              daysUntilMoveIn <= 7) {
                            return InfoPill(
                              icon: Icons.event_outlined,
                              label: locale.moveInCountdownBadge(
                                daysUntilMoveIn,
                              ),
                              highlighted: true,
                            );
                          }
                          return const SizedBox.shrink();
                        }(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  FlatmatesButton(
                    key: Key('discover_like_${item.id}'),
                    label: locale.likeListingCta,
                    onPressed: onLike,
                    icon: Icons.favorite_border_rounded,
                    height: 42,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardPriceText extends StatelessWidget {
  const _CardPriceText({required this.amount, required this.period});

  final int amount;
  final String period;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = _formatCardRent(amount, period);

    return Semantics(
      label: FlatmatesPriceText.formatRupee(amount),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          maxLines: 1,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: AppSemanticColors.textPrimaryFor(theme.brightness),
            fontFamily: null,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            height: 1.05,
          ),
        ),
      ),
    );
  }

  static String _formatCardRent(int amount, String period) {
    if (amount >= 100000) {
      final lakhs = amount / 100000;
      final value = lakhs.toStringAsFixed(lakhs >= 10 ? 1 : 2);
      final compact = value.replaceAll(RegExp(r'\.?0+$'), '');
      return '₹${compact}L / $period';
    }
    return '${FlatmatesPriceText.formatRupee(amount)} / $period';
  }
}

class _ListingImage extends StatelessWidget {
  const _ListingImage({required this.imageUrl, required this.title});

  final String? imageUrl;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return SizedBox(
      width: 148,
      child: AspectRatio(
        aspectRatio: 0.82,
        child: ClipRRect(
          borderRadius: AppRadius.cardBorder,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasImage)
                FlatmatesNetworkImage(imageUrl: imageUrl!, fit: BoxFit.cover)
              else
                _ListingImageFallback(title: title),
              // Subtle bottom gradient overlay for depth
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.3),
                      ],
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 12,
                top: 12,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppSemanticColors.surfaceFor(
                      theme.brightness,
                    ).withValues(alpha: 0.95),
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      Icons.favorite_border_rounded,
                      color: AppSemanticColors.accent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListingImageFallback extends StatelessWidget {
  const _ListingImageFallback({required this.title});

  final String title;

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
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          const Icon(Icons.apartment_rounded, color: Colors.white, size: 30),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
