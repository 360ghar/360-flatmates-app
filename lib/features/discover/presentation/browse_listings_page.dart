import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/errors/l10n_bridge.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../shared/presentation/components.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../discover_repository.dart';
import '../application/discover_feed_controller.dart';
import 'widgets/filter_sheet.dart';

final _isSearchActiveProvider = StateProvider<bool>((ref) => false);
final _cardPressedProvider = StateProvider.family<bool, int>(
  (ref, index) => false,
);

class BrowseListingsPage extends ConsumerStatefulWidget {
  const BrowseListingsPage({super.key});

  @override
  ConsumerState<BrowseListingsPage> createState() => _BrowseListingsPageState();
}

class _BrowseListingsPageState extends ConsumerState<BrowseListingsPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final filters = ref.read(discoverFeedControllerProvider).filters;
    _searchController.text = filters.query ?? '';
    if (_searchController.text.isNotEmpty) {
      ref.read(_isSearchActiveProvider.notifier).state = true;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final feedState = ref.watch(discoverFeedControllerProvider);
    final filtered = ref.watch(filteredListingsProvider);
    final isSearchActive = ref.watch(_isSearchActiveProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: locale.backCta,
        ),
        titleSpacing: 0,
        title: isSearchActive
            ? Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: FlatmatesSearchBar(
                  controller: _searchController,
                  hint: locale.searchCityOrAreaHint,
                  onChanged: (query) {
                    ref
                        .read(discoverFeedControllerProvider.notifier)
                        .updateSearchQuery(query.isEmpty ? null : query);
                  },
                  trailingIcon: _searchController.text.isNotEmpty
                      ? Icons.close_rounded
                      : null,
                  onTrailingTap: () {
                    _searchController.clear();
                    ref
                        .read(discoverFeedControllerProvider.notifier)
                        .updateSearchQuery(null);
                  },
                  autofocus: _searchController.text.isEmpty,
                ),
              )
            : Text(locale.homePickedForYou),
        actions: [
          if (isSearchActive)
            IconButton(
              key: const Key('browse_search_close'),
              tooltip: locale.closeSearch,
              onPressed: () {
                _searchController.clear();
                ref
                    .read(discoverFeedControllerProvider.notifier)
                    .updateSearchQuery(null);
                ref.read(_isSearchActiveProvider.notifier).state = false;
              },
              icon: const Icon(Icons.close_rounded),
            )
          else
            IconButton(
              key: const Key('browse_search_open'),
              tooltip: locale.searchCityOrAreaHint,
              onPressed: () =>
                  ref.read(_isSearchActiveProvider.notifier).state = true,
              icon: const Icon(AppIcons.search),
            ),
          IconButton(
            key: const Key('browse_filter_tune'),
            tooltip: locale.searchFiltersTitle,
            onPressed: () => showFiltersSheet(context),
            icon: const Icon(AppIcons.filter),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: feedState.isLoading && filtered.isEmpty
          ? const FlatmatesSkeleton.browseListings()
          : filtered.isEmpty && feedState.hasError
          ? FlatmatesErrorState(
              message: locale.actionFailedRetry,
              onRetry: () =>
                  ref.read(discoverFeedControllerProvider.notifier).refresh(),
            )
          : filtered.isEmpty
          ? FlatmatesEmptyState(
              title: locale.homeNoResults,
              subtitle: locale.homeNoResultsSubtitle,
              icon: Icons.search_off_rounded,
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                120,
              ),
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                return _BrowseListingsCard(item: filtered[index], index: index);
              },
            ),
    );
  }
}

class _BrowseListingsCard extends ConsumerStatefulWidget {
  const _BrowseListingsCard({required this.item, required this.index});

  final PropertyListing item;
  final int index;

  @override
  ConsumerState<_BrowseListingsCard> createState() =>
      _BrowseListingsCardState();
}

class _BrowseListingsCardState extends ConsumerState<_BrowseListingsCard> {
  Future<void> _handleLike() async {
    final locale = AppLocalizations.of(context);
    final wasLiked = widget.item.liked ?? false;
    try {
      final conversationId = await ref
          .read(discoverFeedControllerProvider.notifier)
          .toggleLike(widget.item.id);
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
        ),
      if (item.bathrooms != null)
        ListingMetaItem(
          icon: Icons.bathtub_outlined,
          label: locale.homeBathsValue(item.bathrooms!),
        ),
      if (item.areaSqft != null)
        ListingMetaItem(
          icon: Icons.square_foot_outlined,
          label: locale.sqftLabel(item.areaSqft!.round()),
        ),
      ListingMetaItem(
        icon: Icons.people_outline_rounded,
        label: switch (item.genderPreference) {
          'male' => locale.genderSuffixMaleOnly,
          'female' => locale.genderSuffixFemaleOnly,
          _ => locale.genderSuffixAny,
        },
      ),
    ];
    final distanceLabel = (item.distanceKm != null && item.distanceKm! > 0)
        ? locale.distanceAway(item.distanceKm!.toStringAsFixed(1))
        : null;

    final hasImage =
        item.effectiveMainImageUrl != null &&
        item.effectiveMainImageUrl!.trim().isNotEmpty;
    final pressed = ref.watch(_cardPressedProvider(widget.index));

    return Listener(
      onPointerDown: (_) =>
          ref.read(_cardPressedProvider(widget.index).notifier).state = true,
      onPointerUp: (_) =>
          ref.read(_cardPressedProvider(widget.index).notifier).state = false,
      onPointerCancel: (_) =>
          ref.read(_cardPressedProvider(widget.index).notifier).state = false,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.easeOutCubic,
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
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(AppRadius.card),
                    ),
                    child: SizedBox(
                      width: 110,
                      child: hasImage
                          ? FlatmatesNetworkImage(
                              imageUrl: item.effectiveMainImageUrl!,
                              width: 110,
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
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      child: Column(
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
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        right: AppSpacing.sm,
                        top: AppSpacing.sm,
                      ),
                      child: FlatmatesLikeButton(
                        key: Key('browse_like_${item.id}'),
                        liked: item.liked ?? false,
                        onTap: () => unawaited(_handleLike()),
                        size: 44,
                        radius: 12,
                        backgroundColor: AppSemanticColors.accentSoft,
                        unlikedColor: AppSemanticColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
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
