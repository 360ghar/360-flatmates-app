import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_failure.dart';
import '../chats/chats_repository.dart'
    show
        conversationsProvider,
        incomingLikesProvider,
        outgoingLikesProvider,
        peerProfileProvider;
import '../../core/errors/l10n_bridge.dart';
import '../../core/theme/theme.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../shared/presentation/components.dart';
import 'application/discover_feed_controller.dart';
import 'discover_repository.dart';
import 'presentation/widgets/full_screen_gallery.dart';
import 'presentation/widgets/flat_details_about.dart';
import 'presentation/widgets/flat_details_header.dart';
import 'presentation/widgets/flat_details_location.dart';
import 'presentation/widgets/flat_details_media.dart';
import 'presentation/widgets/owner_profile_sheet.dart';
import 'presentation/widgets/staggered_card_appear.dart';
import 'share_listing_card.dart';

class FlatDetailsPage extends ConsumerStatefulWidget {
  const FlatDetailsPage({required this.listingId, super.key});

  final int listingId;

  @override
  ConsumerState<FlatDetailsPage> createState() => _FlatDetailsPageState();
}

class _FlatDetailsPageState extends ConsumerState<FlatDetailsPage> {
  int _currentImageIndex = 0;
  bool _contacting = false;
  int? _conversationId;

  @override
  void didUpdateWidget(covariant FlatDetailsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.listingId != widget.listingId) {
      _currentImageIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final listingState = ref.watch(propertyListingProvider(widget.listingId));
    final locale = AppLocalizations.of(context);
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
                          currentIndex: _currentImageIndex,
                          onPageChanged: (index) =>
                              setState(() => _currentImageIndex = index),
                          onBack: () => context.pop(),
                          onShare: () => _showShareSheet(listing),
                          onFavorite: () => _handleShortlist(listing),
                          isFavorite: hasLiked,
                          onOwnerTap: canViewOwner
                              ? () => _handleOwnerTap(listing)
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
                          onVoteSocietyTag: (tag, vote) =>
                              _handleSocietyTagVote(listing, tag, vote),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              FlatmatesBottomActionBar(
                primaryButtonKey: const Key('flat_contact_button'),
                label: hasLiked ? locale.openChatCta : locale.contactCta,
                onPressed: () => _handleContact(listing),
                icon: Icons.send_rounded,
                secondaryLabel: hasLiked ? locale.scheduleVisitCta : null,
                secondaryOnPressed: hasLiked
                    ? () => _handleScheduleVisit(listing)
                    : null,
                secondaryIcon: Icons.calendar_month_outlined,
                tertiaryIcon: hasLiked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                tertiaryOnPressed: () => _handleShortlist(listing),
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
      initialIndex: _currentImageIndex,
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
    ref.invalidate(outgoingLikesProvider);
  }

  Future<void> _handleShortlist(PropertyListing listing) async {
    try {
      final cid = await ref
          .read(propertyListingProvider(widget.listingId).notifier)
          .toggleLike();
      if (cid != null) _conversationId = cid;
      _syncLikeAcrossViews();
    } catch (e) {
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
    if (_contacting) return;
    setState(() => _contacting = true);

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
      if (mounted) {
        final locale = AppLocalizations.of(context);
        final msg = e is AppFailure
            ? e.userMessage(locale.toUserMessageL10n())
            : locale.actionFailedRetry;
        FlatmatesToast.error(context, msg);
      }
    }

    if (mounted) {
      setState(() => _contacting = false);
    }
  }

  Future<void> _handleScheduleVisit(PropertyListing listing) async {
    final currentUserId = ref
        .read(bootstrapControllerProvider)
        .valueOrNull
        ?.profile
        .id;
    if (currentUserId == null) return;

    final locale = AppLocalizations.of(context);
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      initialDate: now.add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;

    final timeSlot = await _showTimeSlotPicker();
    if (timeSlot == null || !mounted) return;

    final scheduledDate = DateTime(
      date.year,
      date.month,
      date.day,
      timeSlot.hour,
      timeSlot.minute,
    );

    final ownerId = listing.owner?.id ?? listing.ownerId;
    if (ownerId == null) return;

    // Ensure we have a conversation ID for the visit
    int cid;
    if (_conversationId != null) {
      cid = _conversationId!;
    } else {
      final wasLiked = listing.liked ?? false;
      final result = await ref
          .read(propertyListingProvider(widget.listingId).notifier)
          .ensureLiked();
      if (result == null) {
        if (mounted) FlatmatesToast.error(context, locale.actionFailedRetry);
        return;
      }
      _conversationId = result;
      cid = result;
      if (!wasLiked) _syncLikeAcrossViews();
    }

    try {
      await ref
          .read(discoverRepositoryProvider)
          .scheduleVisit(
            propertyId: listing.id,
            counterpartyUserId: ownerId,
            conversationId: cid,
            scheduledDate: scheduledDate,
            note: locale.visitFromDetailPageNote,
          );
      ref.invalidate(propertyListingProvider(widget.listingId));
      if (mounted) {
        FlatmatesToast.success(context, locale.visitRequestSent);
      }
    } catch (e) {
      if (mounted) {
        final msg = e is AppFailure
            ? e.userMessage(locale.toUserMessageL10n())
            : locale.actionFailedRetry;
        FlatmatesToast.error(context, msg);
      }
    }
  }

  Future<TimeOfDay?> _showTimeSlotPicker() async {
    final locale = AppLocalizations.of(context);
    return showDialog<TimeOfDay>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(locale.selectTimeSlot),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(locale.timeSlotMorning),
              subtitle: const Text('10:00 AM'),
              leading: const Icon(Icons.wb_sunny_outlined),
              onTap: () =>
                  Navigator.of(ctx).pop(const TimeOfDay(hour: 10, minute: 0)),
            ),
            ListTile(
              title: Text(locale.timeSlotAfternoon),
              subtitle: const Text('3:00 PM'),
              leading: const Icon(Icons.wb_cloudy_outlined),
              onTap: () =>
                  Navigator.of(ctx).pop(const TimeOfDay(hour: 15, minute: 0)),
            ),
            ListTile(
              title: Text(locale.timeSlotEvening),
              subtitle: const Text('6:00 PM'),
              leading: const Icon(Icons.nights_stay_outlined),
              onTap: () =>
                  Navigator.of(ctx).pop(const TimeOfDay(hour: 18, minute: 0)),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSocietyTagVote(
    PropertyListing listing,
    String tag,
    String vote,
  ) async {
    try {
      await ref
          .read(discoverRepositoryProvider)
          .voteSocietyTag(listingId: listing.id, tag: tag, vote: vote);
      ref.invalidate(propertyListingProvider(widget.listingId));
    } catch (e) {
      if (mounted) {
        final locale = AppLocalizations.of(context);
        final msg = e is AppFailure
            ? e.userMessage(locale.toUserMessageL10n())
            : locale.actionFailedRetry;
        FlatmatesToast.error(context, msg);
      }
    }
  }

  void _handleOwnerTap(PropertyListing listing) {
    final ownerId = listing.owner?.id ?? listing.ownerId;
    if (ownerId == null) {
      debugPrint(
        'FlatDetailsPage._handleOwnerTap: no ownerId on listing ${listing.id}',
      );
      return;
    }

    final currentUserId = ref
        .read(bootstrapControllerProvider)
        .valueOrNull
        ?.profile
        .id;
    // Hardened self-owner guard: an unresolved (null) viewer is treated as
    // "not allowed to open" rather than silently bypassing the check. This
    // also prevents the owner sheet from ever showing the viewer's own
    // profile when tapping through their own listing.
    if (currentUserId == null || currentUserId == ownerId) {
      debugPrint(
        'FlatDetailsPage._handleOwnerTap: suppressed self/null owner view',
      );
      return;
    }

    // Prefer the nested owner name (now populated by the backend) and fall
    // back to the flat owner_name field, then a generic label.
    final locale = AppLocalizations.of(context);
    final ownerName = listing.owner?.fullName.trim().isNotEmpty == true
        ? listing.owner!.fullName
        : (listing.ownerName?.trim().isNotEmpty == true
              ? listing.ownerName!
              : locale.ownerFallbackLabel);

    OwnerProfileSheet.show(
      context: context,
      ownerId: ownerId,
      listingOwnerName: ownerName,
      onSendMessage: () {
        Navigator.of(context).pop();
        _handleContact(listing);
      },
    );
  }
}
