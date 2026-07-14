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
  const FlatDetailsPage({required this.listingId, super.key});

  final int listingId;

  @override
  ConsumerState<FlatDetailsPage> createState() => _FlatDetailsPageState();
}

class _FlatDetailsPageState extends ConsumerState<FlatDetailsPage> {
  int? _conversationId;

  @override
  void didUpdateWidget(covariant FlatDetailsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.listingId != widget.listingId) {
      _conversationId = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final listingState = ref.watch(propertyListingProvider(widget.listingId));
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

    return listingState.when(
      data: (listing) {
        final hasLiked = listing.liked ?? false;
        final ownerId = listing.owner?.id ?? listing.ownerId;
        // Only treat the owner as tappable / matchable when the viewer is a
        // resolved, different user. Unresolved bootstrap (null) is "unknown".
        final isSelfOwned = currentUserId == null || currentUserId == ownerId;
        final canViewOwner = ownerId != null && !isSelfOwned;
        // Watching the peer profile here warms it so the sheet opens with data
        // ready, and sources the header match ring reactively.
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
                  onRefresh: () {
                    ref.invalidate(propertyListingProvider(widget.listingId));
                    return ref.read(
                      propertyListingProvider(widget.listingId).future,
                    );
                  },
                  child: ListView(
                    // Section widgets each own their trailing AppSpacing.screen
                    // gap, so we use a single bottom pad here for the action
                    // bar clearance (no per-section divider — keeps rhythm even).
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
                          // Header carousel requires a non-null callback; no-op
                          // when self-owned so favorite matches bottom-bar disable.
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
      },
      loading: () =>
          const FlatmatesScreen(body: FlatmatesSkeleton.flatDetails()),
      error: (e, _) {
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
      // No extra Padding wrapper: FlatmatesBottomSheet already provides
      // horizontal padding (AppSpacing.screen) and a Flexible scroll region.
      // A wrapper here would compound and cause overflow on narrow screens.
      builder: (context) => ShareListingCard(listing: listing),
    );
  }

  /// Invalidates the providers that surface like state on other screens so the
  /// change is reflected app-wide. Mirrors the discover feed's onLike handler.
  void _syncLikeAcrossViews() {
    ref.read(discoverFeedControllerProvider.notifier).refresh();
    ref.invalidate(discoverListingsProvider);
    ref.invalidate(conversationsProvider);
    ref.invalidate(incomingLikesProvider);
    // The Liked tab cursor is updated by PropertyListingController. The legacy
    // FutureProviders above are not watched by any tab, so refresh only the
    // cursor controllers for Chats and Likes.
    ref.invalidate(conversationsListControllerProvider);
    ref.invalidate(incomingLikesListControllerProvider);
  }

  Future<void> _handleShortlist(PropertyListing listing) async {
    try {
      final cid = await ref
          .read(propertyListingProvider(widget.listingId).notifier)
          .toggleLike();
      if (cid != null) _conversationId = cid;
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
