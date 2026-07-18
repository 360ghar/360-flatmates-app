import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_failure.dart';
import '../chats/chats_repository.dart'
    show conversationsProvider, incomingLikesProvider, peerProfileProvider;
import '../chats/application/cursor_list_controller.dart';
import '../../core/errors/l10n_bridge.dart';
import '../../core/theme/theme.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../shared/presentation/components.dart';
import 'application/discover_feed_controller.dart';
import 'application/property_listing_seed_store.dart';
import 'discover_repository.dart';
import 'presentation/widgets/flat_details_actions.dart';
import 'presentation/widgets/full_screen_gallery.dart';
import 'presentation/widgets/flat_details_about.dart';
import 'presentation/widgets/flat_details_header.dart';
import 'presentation/widgets/flat_details_location.dart';
import 'presentation/widgets/flat_details_media.dart';
import 'presentation/widgets/staggered_card_appear.dart';
import 'share_listing_card.dart';

// Scoped per listingId so carousel index / contact / schedule flags do not
// leak across different flat-details navigations.
final _currentImageIndexProvider = StateProvider.autoDispose.family<int, int>(
  (ref, listingId) => 0,
);
final _contactingProvider = StateProvider.autoDispose.family<bool, int>(
  (ref, listingId) => false,
);
final _schedulingProvider = StateProvider.autoDispose.family<bool, int>(
  (ref, listingId) => false,
);

class FlatDetailsPage extends ConsumerStatefulWidget {
  const FlatDetailsPage({
    required this.listingId,
    this.seededListing,
    super.key,
  });

  final int listingId;

  /// Pre-loaded listing passed from the review page (or any caller that already
  /// has the data) so the initial GET /properties/{id} is skipped for pending
  /// listings when the public hide returns 404. Mirrored into
  /// [propertyListingSeedStoreProvider] so GoRouter rebuilds keep working.
  final PropertyListing? seededListing;

  @override
  ConsumerState<FlatDetailsPage> createState() => _FlatDetailsPageState();
}

class _FlatDetailsPageState extends ConsumerState<FlatDetailsPage> {
  int? _conversationId;

  /// Local listing shown without hitting the network. Non-null when a seed was
  /// passed via [FlatDetailsPage.seededListing] or recovered from the durable
  /// seed store. Cleared on successful pull-to-refresh.
  PropertyListing? _localListing;

  /// When true, ignore the durable store and force a network fetch (refresh).
  bool _forceNetwork = false;

  @override
  void initState() {
    super.initState();
    // Prefer navigation extra; fall back to durable store on first frame so
    // router rebuilds that drop `extra` still show the under-review preview.
    _localListing =
        widget.seededListing ??
        ref
            .read(propertyListingSeedStoreProvider.notifier)
            .get(widget.listingId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final seed = widget.seededListing ?? _localListing;
      if (seed != null) {
        ref.read(propertyListingSeedStoreProvider.notifier).put(seed);
      }
    });
  }

  @override
  void didUpdateWidget(covariant FlatDetailsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.listingId != widget.listingId) {
      _conversationId = null;
      _localListing = widget.seededListing;
      _forceNetwork = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final currentImageIndex = ref.watch(
      _currentImageIndexProvider(widget.listingId),
    );
    final isContacting = ref.watch(_contactingProvider(widget.listingId));
    final isScheduling = ref.watch(_schedulingProvider(widget.listingId));
    final currentUserId = ref
        .watch(bootstrapControllerProvider)
        .valueOrNull
        ?.profile
        .id;

    // Use the local seed directly — no provider fetch, no 404 for pending listings.
    if (_localListing != null && !_forceNetwork) {
      return _buildContent(
        context,
        listing: _localListing!,
        locale: locale,
        currentImageIndex: currentImageIndex,
        isContacting: isContacting,
        isScheduling: isScheduling,
        currentUserId: currentUserId,
      );
    }

    // No seed — watch the provider (navigated from discover, manage-listings,
    // deep-link, or after pull-to-refresh cleared the seed).
    final listingState = ref.watch(propertyListingProvider(widget.listingId));
    return listingState.when(
      data: (listing) => _buildContent(
        context,
        listing: listing,
        locale: locale,
        currentImageIndex: currentImageIndex,
        isContacting: isContacting,
        isScheduling: isScheduling,
        currentUserId: currentUserId,
      ),
      loading: () =>
          const FlatmatesScreen(body: FlatmatesSkeleton.flatDetails()),
      error: (e, _) {
        // Prefer durable seed over a hard error (pending listings can 404 for
        // non-owners / optional-auth races).
        final fallback = ref
            .read(propertyListingSeedStoreProvider.notifier)
            .get(widget.listingId);
        if (fallback != null) {
          return _buildContent(
            context,
            listing: fallback,
            locale: locale,
            currentImageIndex: currentImageIndex,
            isContacting: isContacting,
            isScheduling: isScheduling,
            currentUserId: currentUserId,
          );
        }
        final message = e is AppFailure
            ? e.userMessage(locale.toUserMessageL10n())
            : locale.couldNotLoadListing;
        return FlatmatesScreen(
          body: FlatmatesErrorState(
            message: message,
            onRetry: () =>
                ref.invalidate(propertyListingProvider(widget.listingId)),
          ),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required PropertyListing listing,
    required AppLocalizations locale,
    required int currentImageIndex,
    required bool isContacting,
    required bool isScheduling,
    required int? currentUserId,
  }) {
    final hasLiked = listing.liked ?? false;
    final ownerId = listing.owner?.id ?? listing.ownerId;
    // When seed omits owner_id (sparse POST body), treat as self-owned so
    // contact/like stay disabled on the poster's own under-review preview.
    final isSelfOwned =
        currentUserId == null || ownerId == null || currentUserId == ownerId;
    final canViewOwner = ownerId != null && !isSelfOwned;
    final matchPercentage = canViewOwner
        ? (ref
                      .watch(peerProfileProvider(ownerId))
                      .valueOrNull?['match_percentage']
                  as num?)
              ?.toDouble()
        : null;

    return FlatmatesScreen(
      useSafeArea: false,
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                // Bypass seed-preferring provider so pull-to-refresh always
                // hits the network (pending seeds short-circuit the family).
                setState(() => _forceNetwork = true);
                try {
                  final fresh = await ref
                      .read(discoverRepositoryProvider)
                      .fetchListing(widget.listingId);
                  ref
                      .read(propertyListingSeedStoreProvider.notifier)
                      .put(fresh);
                  ref.invalidate(propertyListingProvider(widget.listingId));
                  if (!mounted) return;
                  setState(() {
                    _localListing = fresh;
                    _forceNetwork = false;
                  });
                } catch (e) {
                  debugPrint('FlatDetailsPage.onRefresh: $e');
                  // Keep the previous seed if GET fails (still under review).
                  if (!mounted) return;
                  setState(() => _forceNetwork = false);
                }
              },
              child: ListView(
                padding: const EdgeInsets.only(bottom: AppSpacing.section),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  StaggeredCardAppear(
                    index: 0,
                    child: FlatDetailsHeader(
                      listing: listing,
                      currentIndex: currentImageIndex,
                      onPageChanged: (index) =>
                          ref
                                  .read(
                                    _currentImageIndexProvider(
                                      widget.listingId,
                                    ).notifier,
                                  )
                                  .state =
                              index,
                      onBack: () => context.pop(),
                      onShare: () => _showShareSheet(listing),
                      onFavorite: isSelfOwned
                          ? () {}
                          : () => _handleShortlist(listing),
                      isFavorite: hasLiked,
                      onOwnerTap: canViewOwner
                          ? () => handleOwnerTap(
                              ref: ref,
                              context: context,
                              listing: listing,
                              onContact: () => _handleContact(listing),
                            )
                          : null,
                      onImageTap: listing.imageUrls.isNotEmpty
                          ? () => _openGallery(listing.imageUrls)
                          : null,
                      matchPercentage: matchPercentage,
                    ),
                  ),
                  StaggeredCardAppear(
                    index: 1,
                    child: FlatDetailsAbout(listing: listing),
                  ),
                  StaggeredCardAppear(
                    index: 2,
                    child: FlatDetailsMedia(listing: listing),
                  ),
                  StaggeredCardAppear(
                    index: 3,
                    child: FlatDetailsLocation(
                      listing: listing,
                      currentUserId: currentUserId,
                      onVoteSocietyTag: (tag, vote) => handleSocietyTagVote(
                        ref: ref,
                        context: context,
                        listing: listing,
                        tag: tag,
                        vote: vote,
                        listingId: widget.listingId,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          FlatmatesBottomActionBar(
            primaryButtonKey: const Key('flat_contact_button'),
            label: hasLiked ? locale.openChatCta : locale.contactCta,
            onPressed: isSelfOwned || isContacting
                ? null
                : () => _handleContact(listing),
            icon: Icons.send_rounded,
            secondaryLabel: hasLiked && !isSelfOwned
                ? locale.scheduleVisitCta
                : null,
            secondaryOnPressed: hasLiked && !isSelfOwned && !isScheduling
                ? () {
                    if (ref.read(_schedulingProvider(widget.listingId))) {
                      return;
                    }
                    unawaited(
                      scheduleVisitFromDetails(
                        ref: ref,
                        context: context,
                        listing: listing,
                        listingId: widget.listingId,
                        conversationId: _conversationId,
                        onConversationId: (cid) => _conversationId = cid,
                        onLikeSynced: _syncLikeAcrossViews,
                        setScheduling: (v) {
                          if (mounted) {
                            ref
                                    .read(
                                      _schedulingProvider(
                                        widget.listingId,
                                      ).notifier,
                                    )
                                    .state =
                                v;
                          }
                        },
                      ),
                    );
                  }
                : null,
            secondaryIcon: Icons.calendar_month_outlined,
            tertiaryIcon: hasLiked
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            tertiaryOnPressed: isSelfOwned
                ? null
                : () => _handleShortlist(listing),
            tertiarySelected: hasLiked,
            tertiaryButtonKey: const Key('flat_shortlist_button'),
          ),
        ],
      ),
    );
  }

  Future<void> _openGallery(List<String> images) {
    return FullScreenGallery.open(
      context: context,
      images: images,
      initialIndex: ref.read(_currentImageIndexProvider(widget.listingId)),
      heroTagPrefix: 'flat-gallery-${widget.listingId}',
    );
  }

  Future<void> _showShareSheet(PropertyListing listing) async {
    await FlatmatesBottomSheet.show<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => ShareListingCard(listing: listing),
    );
  }

  void _syncLikeAcrossViews() {
    ref.read(discoverFeedControllerProvider.notifier).refresh();
    ref.invalidate(discoverListingsProvider);
    ref.invalidate(conversationsProvider);
    ref.invalidate(incomingLikesProvider);
    ref.invalidate(conversationsListControllerProvider);
    ref.invalidate(incomingLikesListControllerProvider);
  }

  Future<void> _handleShortlist(PropertyListing listing) async {
    // When using a local seed, sync the like through the provider so it
    // persists. After the optimistic update, update the local copy too.
    try {
      final cid = await ref
          .read(propertyListingProvider(widget.listingId).notifier)
          .toggleLike();
      if (cid != null) _conversationId = cid;
      // Mirror the optimistic like state back into the local listing so the
      // heart icon flips without needing to clear the seed.
      if (_localListing != null && mounted) {
        final newLiked = !(listing.liked ?? false);
        setState(() {
          _localListing = _localListing!.copyWith(
            liked: newLiked,
            likeCount: _localListing!.likeCount + (newLiked ? 1 : -1),
          );
        });
      }
      _syncLikeAcrossViews();
    } catch (e) {
      debugPrint('FlatDetailsPage._handleShortlist: $e');
      if (mounted) {
        final locale = AppLocalizations.of(context);
        final msg = e is AppFailure
            ? e.userMessage(locale.toUserMessageL10n())
            : locale.actionFailedRetry;
        FlatmatesToast.error(context, msg);
      }
    }
  }

  Future<void> _handleContact(PropertyListing listing) async {
    if (ref.read(_contactingProvider(widget.listingId))) return;
    ref.read(_contactingProvider(widget.listingId).notifier).state = true;

    try {
      final hasLiked = listing.liked ?? false;
      final cid = await ref
          .read(propertyListingProvider(widget.listingId).notifier)
          .ensureLiked();
      if (cid != null) _conversationId = cid;
      if (!hasLiked) {
        _syncLikeAcrossViews();
      }

      if (mounted && cid != null) {
        unawaited(context.push('/chats/$cid'));
      } else if (mounted) {
        FlatmatesToast.info(
          context,
          AppLocalizations.of(context).contactRequestSent,
        );
      }
    } catch (e) {
      debugPrint('FlatDetailsPage._handleContact: $e');
      if (mounted) {
        final locale = AppLocalizations.of(context);
        final msg = e is AppFailure
            ? e.userMessage(locale.toUserMessageL10n())
            : locale.actionFailedRetry;
        FlatmatesToast.error(context, msg);
      }
    }

    if (mounted) {
      ref.read(_contactingProvider(widget.listingId).notifier).state = false;
    }
  }
}
