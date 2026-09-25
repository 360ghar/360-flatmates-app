import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/mutable_notifier.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/flatmates_empty_state.dart';
import '../../discover_repository.dart';
import 'discover_listing_card.dart';

/// Map carousel card geometry — shared with [MapViewPage] scroll-to-selected.
/// Sized so ~1.5–2 cards peek on a phone with balanced photo + readable text.
const kMapCarouselCardWidth = 188.0;

/// Image (16:10 @ 188 → ~118) + pad + rent/locality (~50 at 1x text).
const kMapCarouselCardHeight = 168.0;

/// Card slot height at the current text size: the image part is fixed, the
/// text part grows so rent and locality never clip.
double mapCarouselCardHeight(BuildContext context) =>
    118 + AppSpacing.scaled(context, kMapCarouselCardHeight - 118);

/// Leading and trailing inset of the card list (the page gutter).
const kMapCarouselPadding = AppSpacing.screen;

/// Bottom draggable sheet that surfaces a horizontally-scrolling list of
/// listings overlaid on the map view. Highlights the selected property
/// via [selectedPropertyProvider] and reports the centered card back so
/// the map can recenter.
class MapListingsBottomSheet extends ConsumerWidget {
  const MapListingsBottomSheet({
    required this.listings,
    required this.scrollController,
    required this.onTap,
    required this.onLike,
    super.key,
  });

  final List<PropertyListing> listings;
  final ScrollController scrollController;
  final void Function(PropertyListing) onTap;
  final void Function(PropertyListing) onLike;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    final brightness = theme.brightness;
    final cardHeight = mapCarouselCardHeight(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Tight height so the sheet hugs content (no empty band under cards):
        // Handle: sm top + 4 line + sm bottom = 20
        // Title: ~20 line + sm bottom = 28
        // Cards: kMapCarouselCardHeight
        // Bottom: sm + safe area (tighter than lg)
        final safeAreaBottom = MediaQuery.paddingOf(context).bottom;
        final bottomPadding = AppSpacing.sm + safeAreaBottom;
        const handleHeight = AppSpacing.sm * 2 + AppSpacing.xs;
        final titleHeight = AppSpacing.scaled(context, 22) + AppSpacing.sm;
        final contentHeight =
            handleHeight + titleHeight + cardHeight + bottomPadding;
        const collapsedHeight = 60.0;

        final maxFraction = (contentHeight / constraints.maxHeight).clamp(
          0.1,
          1.0,
        );
        final minFraction = (collapsedHeight / constraints.maxHeight).clamp(
          0.05,
          maxFraction,
        );

        return DraggableScrollableSheet(
          initialChildSize: maxFraction,
          minChildSize: minFraction,
          maxChildSize: maxFraction,
          snap: true,
          snapSizes: [minFraction, maxFraction],
          builder: (context, sheetScrollController) {
            // Paper-2 sheet with the e3 shadow (DESIGN.md §8).
            return Container(
              decoration: BoxDecoration(
                color: AppSemanticColors.surfaceFor(brightness),
                borderRadius: AppRadius.sheetTopBorder,
                boxShadow: AppShadows.e3(brightness),
              ),
              child: SingleChildScrollView(
                controller: sheetScrollController,
                child: Padding(
                  padding: EdgeInsets.only(bottom: bottomPadding),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                        child: Center(
                          child: Container(
                            width: AppSpacing.s40,
                            height: AppSpacing.xs,
                            decoration: BoxDecoration(
                              color: AppSemanticColors.textTertiaryFor(
                                brightness,
                              ).withValues(alpha: 0.4),
                              borderRadius: AppRadius.xsBorder,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          kMapCarouselPadding,
                          0,
                          kMapCarouselPadding,
                          AppSpacing.sm,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: Text(
                            locale.clusterListingsCount(listings.length),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppSemanticColors.textPrimaryFor(
                                brightness,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: cardHeight,
                        child: listings.isEmpty
                            ? FlatmatesEmptyState(
                                title: locale.noListingsMatchFilters,
                                icon: Icons.search_off_rounded,
                                compact: true,
                              )
                            : _HorizontalCardList(
                                listings: listings,
                                scrollController: scrollController,
                                onTap: onTap,
                                onLike: onLike,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Tracks whether the list is scrolling due to a programmatic tap on the map.
final mapProgrammaticScrollProvider =
    NotifierProvider.autoDispose<AutoDisposeMutableNotifier<bool>, bool>(
      () => AutoDisposeMutableNotifier(false),
    );

class _HorizontalCardList extends ConsumerWidget {
  const _HorizontalCardList({
    required this.listings,
    required this.scrollController,
    required this.onTap,
    required this.onLike,
  });

  final List<PropertyListing> listings;
  final ScrollController scrollController;
  final void Function(PropertyListing) onTap;
  final void Function(PropertyListing) onLike;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (ref.read(mapProgrammaticScrollProvider)) return false;

        if (notification is ScrollUpdateNotification ||
            notification is ScrollEndNotification) {
          if (!scrollController.hasClients) return false;

          final offset = scrollController.offset;
          final viewportWidth = MediaQuery.sizeOf(context).width;
          const itemWidth = kMapCarouselCardWidth;
          const padding = kMapCarouselPadding;
          const spacing = AppSpacing.sm;
          const totalItemWidth = itemWidth + spacing;

          final centerOffset = offset + viewportWidth / 2;
          final rawIndex =
              (centerOffset - padding - itemWidth / 2) / totalItemWidth;
          final index = rawIndex.round().clamp(0, listings.length - 1);

          final visibleItem = listings[index];
          final currentSelected = ref.read(selectedPropertyProvider);
          if (currentSelected?.id != visibleItem.id) {
            ref.read(selectedPropertyProvider.notifier).set(visibleItem);
          }
        }
        return false;
      },
      child: ListView.builder(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: kMapCarouselPadding),
        itemCount: listings.length,
        itemBuilder: (context, index) {
          final item = listings[index];
          final selectedProperty = ref.watch(selectedPropertyProvider);
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: SizedBox(
              width: kMapCarouselCardWidth,
              child: DiscoverListingCard(
                cardKey: Key('map_sheet_card_${item.id}'),
                item: item,
                isSelected: item.id == selectedProperty?.id,
                compact: true,
                onTap: () => onTap(item),
                onLike: () => onLike(item),
              ),
            ),
          );
        },
      ),
    );
  }
}
