import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/deep_links/deep_link_service.dart';
import '../../core/errors/app_failure.dart';
import '../../core/errors/l10n_bridge.dart';
import '../../core/theme/theme.dart';
import '../../l10n/gen/app_localizations.dart';
import '../discover/domain/property_listing.dart';
import '../shared/presentation/components.dart';
import 'application/manage_listings_actions_controller.dart';
import 'domain/listing_status.dart';
import 'my_listings_controller.dart';
import 'presentation/widgets/manage_listing_card.dart';
import 'presentation/widgets/manage_stats_widgets.dart';

class ManageListingPage extends ConsumerStatefulWidget {
  const ManageListingPage({super.key});

  @override
  ConsumerState<ManageListingPage> createState() => _ManageListingPageState();
}

class _ManageListingPageState extends ConsumerState<ManageListingPage> {
  final _scrollController = ScrollController();

  /// 'active', 'draft', or 'expired'
  String _manageTab = 'active';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(myListingsListControllerProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Triggers a load-more when the user scrolls near the bottom of the
  /// listing list. Backed by cursor pagination in
  /// [MyListingsController].
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 240) {
      Future.microtask(() {
        if (!mounted) return;
        ref.read(myListingsListControllerProvider.notifier).loadMore();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final listingsState = ref.watch(myListingsListControllerProvider);
    final status = _manageTab;
    final actionsState = ref.watch(manageListingsActionsControllerProvider);
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final items = listingsState.valueOrNull?.items ?? const <PropertyListing>[];

    return FlatmatesScreen(
      appBar: FlatmatesHeader.logo(
        onBack: () => context.pop(),
        actions: [
          FlatmatesChromeIconButton(
            onPressed: () => context.push('/notifications'),
            icon: Icons.notifications_outlined,
            tooltip: locale.notificationsTooltip,
          ),
          FlatmatesChromeIconButton(
            onPressed: () => context.go('/chats'),
            icon: Icons.chat_bubble_outline,
            tooltip: locale.chatTooltip,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  0,
                  AppSpacing.screen,
                  AppSpacing.md,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    locale.manageListingsTitle,
                    style: theme.textTheme.headlineLarge,
                  ),
                ),
              ),

              // "New Listing" CTA
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screen,
                ),
                child: FlatmatesButton(
                  key: const Key('manage_new_listing_button'),
                  label: locale.postListingTitle,
                  onPressed: () => context.push('/post/new'),
                  icon: Icons.add,
                  fullWidth: true,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Segmented tab control
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screen,
                ),
                child: FlatmatesSegmentedControl<String>(
                  segments: [
                    (
                      'active',
                      '${locale.activeListingsLabel} (${_countForTab(items, 'active')})',
                      null,
                    ),
                    (
                      'draft',
                      '${locale.draftsLabel} (${_countForTab(items, 'draft')})',
                      null,
                    ),
                    (
                      'expired',
                      '${locale.expiredLabel} (${_countForTab(items, 'expired')})',
                      null,
                    ),
                  ],
                  selected: status,
                  onChanged: (v) => setState(() => _manageTab = v),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Listings content
              Expanded(
                child: listingsState.when(
                  data: (state) {
                    if (items.isEmpty && !state.hasMore) {
                      return FlatmatesEmptyState(
                        icon: Icons.add_home_outlined,
                        title: locale.emptyListings,
                        ctaLabel: locale.postListingTitle,
                        onCtaTap: () => context.push('/post/new'),
                      );
                    }

                    final myListings = items
                        .where((listing) => listingMatchesTab(listing, status))
                        .toList();

                    if (myListings.isEmpty) {
                      return FlatmatesEmptyState(
                        icon: Icons.add_home_outlined,
                        title: status == 'active'
                            ? locale.activeListingsLabel
                            : status == 'draft'
                            ? locale.draftsLabel
                            : locale.expiredLabel,
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        await ref
                            .read(myListingsListControllerProvider.notifier)
                            .refresh();
                      },
                      child: ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screen,
                          AppSpacing.xs,
                          AppSpacing.screen,
                          AppSpacing.xl + AppSpacing.md,
                        ),
                        itemCount: myListings.length + (state.hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= myListings.length) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.lg,
                              ),
                              child: Center(
                                child: state.isLoadingMore
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : TextButton.icon(
                                        onPressed: () => ref
                                            .read(
                                              myListingsListControllerProvider
                                                  .notifier,
                                            )
                                            .loadMore(),
                                        icon: const Icon(
                                          Icons.expand_more_rounded,
                                        ),
                                        label: Text(locale.loadMoreCta),
                                      ),
                              ),
                            );
                          }
                          final listing = myListings[index];
                          final statusKey = listingStatus(listing);
                          final isPaused = actionsState.isPaused(
                            listing.id,
                            fromListing: statusKey == 'paused',
                          );
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.md,
                            ),
                            child: ManageListingCard(
                              listing: listing,
                              status: isPaused ? 'paused' : statusKey,
                              isPaused: isPaused,
                              isPausing: actionsState.isPausing(listing.id),
                              onTogglePause: (listingId, currentlyPaused) =>
                                  _togglePause(
                                    context,
                                    listingId,
                                    currentlyPaused,
                                  ),
                              onShare: () => Share.share(
                                '${locale.shareListingText(listing.title, listing.monthlyRent.toStringAsFixed(0), listing.locality ?? listing.city ?? '')}\n${DeepLinkService.listingUrl(listing.id)}',
                              ),
                              onCopyLink: () => _copyLink(context, listing.id),
                              onEdit: () => context.push(
                                '/post/new?listingId=${listing.id}',
                              ),
                              onViewStats: () =>
                                  _showStatsBottomSheet(context, listing),
                              onReview: () =>
                                  context.push('/listing-review/${listing.id}'),
                              onRenew: () => context.push(
                                '/post/new?listingId=${listing.id}',
                              ),
                              theme: theme,
                              locale: locale,
                            ),
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const FlatmatesSkeleton.manageListings(),
                  error: (e, _) => FlatmatesErrorState(
                    message: locale.couldNotLoadListings,
                    onRetry: () => ref
                        .read(myListingsListControllerProvider.notifier)
                        .refresh(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _countForTab(List<PropertyListing> listings, String tab) {
    return listings.where((listing) => listingMatchesTab(listing, tab)).length;
  }

  Future<void> _copyLink(BuildContext context, int listingId) async {
    final locale = AppLocalizations.of(context);
    await Clipboard.setData(
      ClipboardData(text: DeepLinkService.listingUrl(listingId)),
    );
    if (!context.mounted) return;
    FlatmatesToast.success(context, locale.linkCopiedToast);
  }

  void _showStatsBottomSheet(BuildContext context, PropertyListing listing) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    FlatmatesBottomSheet.show(
      context: context,
      title: listing.title,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatDialogRow(
              icon: Icons.visibility_outlined,
              label: locale.viewsStatLabel,
              value: _formatCount(listing.viewCount),
              theme: theme,
            ),
            const SizedBox(height: AppSpacing.md),
            StatDialogRow(
              icon: Icons.favorite_outline,
              label: locale.likesStatLabel,
              value: _formatCount(listing.likeCount),
              theme: theme,
            ),
            const SizedBox(height: AppSpacing.md),
            StatDialogRow(
              icon: Icons.handshake_outlined,
              label: locale.matchesStatLabel,
              value: _formatCount(listing.interestCount),
              theme: theme,
            ),
            const SizedBox(height: AppSpacing.lg),
            FlatmatesButton(
              label: locale.closeCta,
              onPressed: () => Navigator.pop(sheetContext),
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }

  static String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }

  Future<void> _togglePause(
    BuildContext context,
    int listingId,
    bool currentlyPaused,
  ) async {
    final locale = AppLocalizations.of(context);
    try {
      await ref
          .read(manageListingsActionsControllerProvider.notifier)
          .togglePause(listingId, currentlyPaused: currentlyPaused);
      if (!context.mounted) return;
      FlatmatesToast.success(
        context,
        currentlyPaused ? locale.listingResumed : locale.listingPaused,
      );
    } catch (e) {
      if (!context.mounted) return;
      final msg = e is AppFailure
          ? e.userMessage(locale.toUserMessageL10n())
          : locale.failedToUpdateListingStatus;
      FlatmatesToast.error(context, msg);
    }
  }
}
