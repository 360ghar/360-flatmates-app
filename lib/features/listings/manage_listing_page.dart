import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/deep_links/deep_link_service.dart';
import '../../core/theme/theme.dart';
import '../../l10n/gen/app_localizations.dart';
import '../shared/presentation/components.dart';
import 'listings_repository.dart';
import 'presentation/widgets/manage_listing_card.dart';
import 'presentation/widgets/manage_stats_widgets.dart';

class ManageListingPage extends ConsumerStatefulWidget {
  const ManageListingPage({super.key});

  @override
  ConsumerState<ManageListingPage> createState() => _ManageListingPageState();
}

class _ManageListingPageState extends ConsumerState<ManageListingPage> {
  String _status = 'active'; // 'active', 'draft', 'expired'
  final _pausedListingIds = <int>{};
  final _pausingListingIds = <int>{};

  @override
  Widget build(BuildContext context) {
    final listings = ref.watch(myListingsProvider);
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
      body: Column(
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
                locale.manageListingTitle,
                style: theme.textTheme.headlineLarge,
              ),
            ),
          ),

          // "New Listing" CTA
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
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
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
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
              selected: _status,
              onChanged: (v) => setState(() => _status = v),
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

                final myListings = items.where(_matchesSelectedTab).toList();

                if (myListings.isEmpty) {
                  return FlatmatesEmptyState(
                    icon: Icons.add_home_outlined,
                    title: _status == 'active'
                        ? locale.activeListingsLabel
                        : _status == 'draft'
                        ? locale.draftsLabel
                        : locale.expiredLabel,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(myListingsProvider);
                  },
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screen,
                      AppSpacing.xs,
                      AppSpacing.screen,
                      AppSpacing.xl + AppSpacing.md,
                    ),
                    children: myListings.map((listing) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: ManageListingCard(
                          listing: listing,
                          status: _listingStatus(listing),
                          isPaused:
                              _pausedListingIds.contains(listing.id) ||
                              _listingStatus(listing) == 'paused',
                          isPausing: _pausingListingIds.contains(listing.id),
                          onTogglePause: (listingId, currentlyPaused) =>
                              _togglePause(listingId, currentlyPaused),
                          onShare: () => Share.share(
                            'Check out this flat on 360 FlatMates: ${listing.title} at ₹${listing.monthlyRent.toStringAsFixed(0)}/mo in ${listing.locality ?? listing.city ?? ""}\n${DeepLinkService.listingUrl(listing.id)}',
                          ),
                          onEdit: () =>
                              context.push('/post/new?listingId=${listing.id}'),
                          onViewStats: () => _showStatsBottomSheet(listing),
                          onReview: () =>
                              context.push('/listing-review/${listing.id}'),
                          onRenew: () =>
                              context.push('/post/new?listingId=${listing.id}'),
                          theme: theme,
                          locale: locale,
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
              loading: () => const FlatmatesSkeleton.list(),
              error: (e, _) =>
                  const FlatmatesErrorState(message: 'Could not load listings'),
            ),
          ),
        ],
      ),
    );
  }

  int _countForTab(List<dynamic> listings, String tab) {
    return listings.where((listing) => _matchesTab(listing, tab)).length;
  }

  bool _matchesSelectedTab(dynamic listing) => _matchesTab(listing, _status);

  bool _matchesTab(dynamic listing, String tab) {
    final status = _listingStatus(listing);
    return switch (tab) {
      'active' =>
        status == 'active' ||
            status == 'paused' ||
            status == 'pending_review' ||
            status == 'under_review',
      'draft' => status == 'draft' || status == 'rejected',
      'expired' => status == 'expired',
      _ => false,
    };
  }

  String _listingStatus(dynamic listing) {
    final status = (listing.status ?? listing.propertyStatus ?? '').toString();
    final preferences = listing.preferences;
    final expiresAtRaw = listing.expiresAt;
    final expiresAt = expiresAtRaw is String
        ? DateTime.tryParse(expiresAtRaw)
        : expiresAtRaw as DateTime?;
    final expiredByReview =
        preferences is Map &&
        preferences['auto_paused_reason'] == 'expired_move_in_date';
    if (expiredByReview ||
        expiresAt != null && expiresAt.isBefore(DateTime.now()) ||
        status == 'expired') {
      return 'expired';
    }
    if (status == 'paused') return 'paused';
    if (status == 'pending_review' || status == 'under_review') {
      return 'pending_review';
    }
    if (status == 'draft' || status == 'rejected') return status;
    if (status == 'live' ||
        status == 'approved' ||
        listing.isAvailable == true) {
      return 'active';
    }
    return status.isEmpty ? 'active' : status;
  }

  void _showStatsBottomSheet(dynamic listing) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    FlatmatesBottomSheet.show(
      context: context,
      title: listing.title ?? locale.listingStatsTitle,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatDialogRow(
              icon: Icons.visibility_outlined,
              label: locale.viewsStatLabel,
              value: _formatCount(listing.viewCount ?? 0),
              theme: theme,
            ),
            const SizedBox(height: AppSpacing.md),
            StatDialogRow(
              icon: Icons.favorite_outline,
              label: locale.likesStatLabel,
              value: _formatCount(listing.likeCount ?? 0),
              theme: theme,
            ),
            const SizedBox(height: AppSpacing.md),
            StatDialogRow(
              icon: Icons.handshake_outlined,
              label: locale.matchesStatLabel,
              value: _formatCount(listing.interestCount ?? 0),
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

  Future<void> _togglePause(int listingId, bool currentlyPaused) async {
    if (_pausingListingIds.contains(listingId)) return;
    setState(() => _pausingListingIds.add(listingId));
    try {
      await ref
          .read(listingsRepositoryProvider)
          .togglePause(listingId, paused: currentlyPaused);
      if (!mounted) return;
      setState(() {
        if (currentlyPaused) {
          _pausedListingIds.remove(listingId);
        } else {
          _pausedListingIds.add(listingId);
        }
      });
      ref.invalidate(myListingsProvider);
    } catch (e) {
      if (mounted) {
        final locale = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(locale.failedToUpdateListingStatus)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _pausingListingIds.remove(listingId));
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
