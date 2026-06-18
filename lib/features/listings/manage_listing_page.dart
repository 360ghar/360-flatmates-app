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
import 'domain/listing_status.dart';
import 'listings_repository.dart';
import 'presentation/widgets/manage_listing_card.dart';
import 'presentation/widgets/manage_stats_widgets.dart';

final _manageTabProvider = StateProvider<String>(
  (ref) => 'active',
); // 'active', 'draft', 'expired'
final _pausedListingIdsProvider = StateProvider<Set<int>>((ref) => <int>{});
final _pausingListingIdsProvider = StateProvider<Set<int>>((ref) => <int>{});

class ManageListingPage extends ConsumerWidget {
  const ManageListingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listings = ref.watch(myListingsProvider);
    final status = ref.watch(_manageTabProvider);
    final pausedListingIds = ref.watch(_pausedListingIdsProvider);
    final pausingListingIds = ref.watch(_pausingListingIdsProvider);
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return FlatmatesScreen(
      appBar: FlatmatesHeader.logo(
        onBack: () => context.pop(),
        actions: [
          _InteractivePressScale(
            child: IconButton(
              onPressed: () => context.push('/notifications'),
              icon: const Icon(Icons.notifications_outlined),
              tooltip: locale.notificationsTooltip,
            ),
          ),
          _InteractivePressScale(
            child: IconButton(
              onPressed: () => context.go('/chats'),
              icon: const Icon(Icons.chat_bubble_outline),
              tooltip: locale.chatTooltip,
            ),
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
                      '${locale.activeListingsLabel} (${_countForTab(listings.valueOrNull ?? const [], 'active')})',
                      null,
                    ),
                    (
                      'draft',
                      '${locale.draftsLabel} (${_countForTab(listings.valueOrNull ?? const [], 'draft')})',
                      null,
                    ),
                    (
                      'expired',
                      '${locale.expiredLabel} (${_countForTab(listings.valueOrNull ?? const [], 'expired')})',
                      null,
                    ),
                  ],
                  selected: status,
                  onChanged: (v) =>
                      ref.read(_manageTabProvider.notifier).state = v,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Listings content
              Expanded(
                child: listings.when(
                  data: (items) {
                    if (items.isEmpty) {
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
                        ref.invalidate(myListingsProvider);
                      },
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screen,
                          AppSpacing.xs,
                          AppSpacing.screen,
                          AppSpacing.xl + AppSpacing.md,
                        ),
                        children: myListings.map((listing) {
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.md,
                            ),
                            child: ManageListingCard(
                              listing: listing,
                              status: listingStatus(listing),
                              isPaused:
                                  pausedListingIds.contains(listing.id) ||
                                  listingStatus(listing) == 'paused',
                              isPausing: pausingListingIds.contains(listing.id),
                              onTogglePause: (listingId, currentlyPaused) =>
                                  _togglePause(
                                    context,
                                    ref,
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
                        }).toList(),
                      ),
                    );
                  },
                  loading: () => const FlatmatesSkeleton.manageListings(),
                  error: (e, _) => FlatmatesErrorState(
                    message: locale.couldNotLoadListings,
                    onRetry: () => ref.invalidate(myListingsProvider),
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
    WidgetRef ref,
    int listingId,
    bool currentlyPaused,
  ) async {
    final pausingIds = ref.read(_pausingListingIdsProvider);
    if (pausingIds.contains(listingId)) return;
    ref.read(_pausingListingIdsProvider.notifier).state = {
      ...pausingIds,
      listingId,
    };
    try {
      await ref
          .read(listingsRepositoryProvider)
          .togglePause(listingId, paused: currentlyPaused);
      if (!context.mounted) return;
      final pausedIds = ref.read(_pausedListingIdsProvider);
      ref.read(_pausedListingIdsProvider.notifier).state = currentlyPaused
          ? ({...pausedIds}..remove(listingId))
          : {...pausedIds, listingId};
      ref.invalidate(myListingsProvider);
      final locale = AppLocalizations.of(context);
      FlatmatesToast.success(
        context,
        currentlyPaused ? locale.listingResumed : locale.listingPaused,
      );
    } catch (e) {
      if (context.mounted) {
        final locale = AppLocalizations.of(context);
        final msg = e is AppFailure
            ? e.userMessage(locale.toUserMessageL10n())
            : locale.failedToUpdateListingStatus;
        FlatmatesToast.error(context, msg);
      }
    } finally {
      if (context.mounted) {
        ref.read(_pausingListingIdsProvider.notifier).state = {
          ...ref.read(_pausingListingIdsProvider),
        }..remove(listingId);
      }
    }
  }
}

/// Applies standard interactive scale animation to any child when pressed.
class _InteractivePressScale extends StatefulWidget {
  const _InteractivePressScale({required this.child});

  final Widget child;

  @override
  State<_InteractivePressScale> createState() => _InteractivePressScaleState();
}

class _InteractivePressScaleState extends State<_InteractivePressScale> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _scale = 0.97),
      onPointerUp: (_) => setState(() => _scale = 1.0),
      onPointerCancel: (_) => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: AppMotion.durationOrZero(context, AppMotion.buttonPress),
        curve: AppMotion.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
