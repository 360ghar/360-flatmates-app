import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/l10n_bridge.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/components.dart';
import '../../application/discover_feed_controller.dart';
import '../../discover_repository.dart';

final browseCardPressedProvider = StateProvider.family<bool, int>(
  (ref, index) => false,
);

class BrowseListingsCard extends ConsumerStatefulWidget {
  const BrowseListingsCard({
    required this.item,
    required this.index,
    super.key,
  });

  final PropertyListing item;
  final int index;

  @override
  ConsumerState<BrowseListingsCard> createState() => _BrowseListingsCardState();
}

class _BrowseListingsCardState extends ConsumerState<BrowseListingsCard> {
  Future<void> _handleLike() async {
    final locale = AppLocalizations.of(context);
    final wasLiked = widget.item.liked ?? false;
    try {
      final conversationId = await ref
          .read(discoverFeedControllerProvider.notifier)
          .toggleLike(widget.item.id, property: widget.item);
      if (!mounted) return;
      if (wasLiked) {
        FlatmatesToast.success(context, locale.likeRemovedToast);
      } else {
        FlatmatesToast.success(
          context,
          conversationId == null
              ? locale.contactRequestSent
              : locale.contactRequestWithConversation(conversationId),
        );
      }
    } catch (e) {
      debugPrint('BrowseListingsCard._handleLike failed: $e');
      if (!mounted) return;
      final msg = e is AppFailure
          ? e.userMessage(locale.toUserMessageL10n())
          : locale.actionFailedRetry;
      FlatmatesToast.error(context, msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    final item = widget.item;
    final isDark = theme.brightness == Brightness.dark;

    final titleLocation = [
      if (item.locality != null && item.locality!.trim().isNotEmpty)
        item.locality!.trim(),
      if (item.subLocality != null && item.subLocality!.trim().isNotEmpty)
        item.subLocality!.trim(),
    ].join(', ');

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
        label: switch (item.genderPreference) {
          'male' => locale.genderSuffixMaleOnly,
          'female' => locale.genderSuffixFemaleOnly,
          _ => locale.genderSuffixAny,
        },
        chipColor: MetaChipColor.orange,
      ),
    ];
    final distanceLabel = (item.distanceKm != null && item.distanceKm! > 0)
        ? locale.distanceAway(item.distanceKm!.toStringAsFixed(1))
        : null;

    final hasImage =
        item.effectiveMainImageUrl != null &&
        item.effectiveMainImageUrl!.trim().isNotEmpty;
    final pressed = ref.watch(browseCardPressedProvider(widget.index));

    return Listener(
      onPointerDown: (_) =>
          ref.read(browseCardPressedProvider(widget.index).notifier).state =
              true,
      onPointerUp: (_) =>
          ref.read(browseCardPressedProvider(widget.index).notifier).state =
              false,
      onPointerCancel: (_) =>
          ref.read(browseCardPressedProvider(widget.index).notifier).state =
              false,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.easeOutCubic,
        // Content may grow past 110 (meta wrap / text scale); floor matches
        // the prior design height and the browse skeleton.
        constraints: const BoxConstraints(minHeight: 110),
        decoration: BoxDecoration(
          color: isDark
              ? AppSemanticColors.darkSurface
              : AppSemanticColors.card,
          borderRadius: AppRadius.cardBorder,
          boxShadow: [
            AppShadows.cardFor(theme.brightness),
            if (pressed) AppShadows.subtleGlowFor(theme.brightness),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: AppRadius.cardBorder,
          child: InkWell(
            onTap: () => context.push('/flat-details/${item.id}'),
            borderRadius: AppRadius.cardBorder,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 110,
                  height: 110,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(AppRadius.card),
                        ),
                        child: hasImage
                            ? FlatmatesNetworkImage(
                                imageUrl: item.effectiveMainImageUrl!,
                                width: 110,
                                height: 110,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppSemanticColors.accent.withValues(
                                        alpha: 0.85,
                                      ),
                                      AppSemanticColors.accent.withValues(
                                        alpha: 0.45,
                                      ),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.apartment_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                              ),
                      ),
                      Positioned(
                        top: AppSpacing.sm,
                        right: AppSpacing.sm,
                        child: FlatmatesLikeButton(
                          key: Key('browse_like_${item.id}'),
                          liked: item.liked ?? false,
                          onTap: () => unawaited(_handleLike()),
                          size: 40,
                          backgroundColor: AppSemanticColors.coralSoftFor(
                            Theme.of(context).brightness,
                          ),
                          unlikedColor: AppSemanticColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _formatRent(item.monthlyRent.round()),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppSemanticColors.textPrimaryFor(
                              theme.brightness,
                            ),
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          item.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (titleLocation.isNotEmpty) ...[
                          const SizedBox(height: 2),
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
                              if (distanceLabel != null) ...[
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  distanceLabel,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppSemanticColors.accent,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                        if (metaItems.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          FlatmatesListingMetaChips(items: metaItems),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
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
