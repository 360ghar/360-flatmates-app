import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_failure.dart';
import '../../core/errors/l10n_bridge.dart';
import '../../core/theme/theme.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../shared/presentation/components.dart';
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
  Map<String, dynamic>? _ownerPeer;
  bool _peerFetched = false;
  int? _conversationId;

  @override
  void didUpdateWidget(covariant FlatDetailsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.listingId != widget.listingId) {
      _peerFetched = false;
      _ownerPeer = null;
      _currentImageIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final listingState = ref.watch(propertyListingProvider(widget.listingId));
    final locale = AppLocalizations.of(context);
    final currentUserId =
        ref.watch(bootstrapControllerProvider).valueOrNull?.profile.id;

    return listingState.when(
      data: (listing) {
        final hasLiked = listing.liked ?? false;
        final hasOwnerId = (listing.owner?.id ?? listing.ownerId) != null;
        final matchPercentage =
            (_ownerPeer?['match_percentage'] as num?)?.toDouble();

        _maybeFetchOwnerPeer(listing);

        return FlatmatesScreen(
          useSafeArea: false,
          body: Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () {
                    ref.invalidate(
                      propertyListingProvider(widget.listingId),
                    );
                    return ref.read(
                      propertyListingProvider(widget.listingId).future,
                    );
                  },
                  child: ListView(
                    padding: EdgeInsets.zero,
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
                          onOwnerTap: hasOwnerId
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
                secondaryOnPressed:
                    hasLiked ? () => _handleScheduleVisit(listing) : null,
                secondaryIcon: Icons.calendar_month_outlined,
                tertiaryIcon:
                    hasLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                tertiaryOnPressed: () => _handleShortlist(listing),
                tertiarySelected: hasLiked,
                tertiaryButtonKey: const Key('flat_shortlist_button'),
              ),
            ],
          ),
        );
      },
      loading: () => const FlatmatesScreen(
        body: FlatmatesSkeleton.flatDetails(),
      ),
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

  void _maybeFetchOwnerPeer(PropertyListing listing) {
    if (_peerFetched) return;
    final ownerId = listing.owner?.id ?? listing.ownerId;
    if (ownerId == null) return;

    final currentUserId =
        ref.read(bootstrapControllerProvider).valueOrNull?.profile.id;
    // Only skip if bootstrap has loaded AND the user is the owner.
    if (currentUserId != null && currentUserId == ownerId) {
      _peerFetched = true;
      return;
    }

    _peerFetched = true;
    ref
        .read(discoverRepositoryProvider)
        .fetchOwnerPeer(ownerId)
        .then((data) {
      if (mounted) {
        setState(() => _ownerPeer = data);
      }
    });
  }

  Future<void> _openGallery(List<String> images) {
    return FullScreenGallery.open(
      context: context,
      images: images,
      initialIndex: _currentImageIndex,
    );
  }

  Future<void> _showShareSheet(PropertyListing listing) async {
    await FlatmatesBottomSheet.show<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ShareListingCard(listing: listing),
      ),
    );
  }

  Future<void> _handleShortlist(PropertyListing listing) async {
    try {
      final hasLiked = listing.liked ?? false;
      final cid = await ref.read(discoverRepositoryProvider).setLiked(
            listing.id,
            !hasLiked,
          );
      if (cid != null) _conversationId = cid;
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

  Future<void> _handleContact(PropertyListing listing) async {
    if (_contacting) return;
    setState(() => _contacting = true);

    try {
      final hasLiked = listing.liked ?? false;
      final repo = ref.read(discoverRepositoryProvider);
      final cid = await repo.setLiked(listing.id, true);
      if (cid != null) _conversationId = cid;
      if (!hasLiked) {
        ref.invalidate(propertyListingProvider(widget.listingId));
      }

      if (mounted && cid != null) {
        context.push('/chats/$cid');
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
    final currentUserId =
        ref.read(bootstrapControllerProvider).valueOrNull?.profile.id;
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
      final repo = ref.read(discoverRepositoryProvider);
      final result = await repo.setLiked(listing.id, true);
      if (result == null) {
        if (mounted) FlatmatesToast.error(context, locale.actionFailedRetry);
        return;
      }
      _conversationId = result;
      cid = result;
      ref.invalidate(propertyListingProvider(widget.listingId));
    }

    try {
      await ref.read(discoverRepositoryProvider).scheduleVisit(
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
              onTap: () => Navigator.of(ctx).pop(
                const TimeOfDay(hour: 10, minute: 0),
              ),
            ),
            ListTile(
              title: Text(locale.timeSlotAfternoon),
              subtitle: const Text('3:00 PM'),
              leading: const Icon(Icons.wb_cloudy_outlined),
              onTap: () => Navigator.of(ctx).pop(
                const TimeOfDay(hour: 15, minute: 0),
              ),
            ),
            ListTile(
              title: Text(locale.timeSlotEvening),
              subtitle: const Text('6:00 PM'),
              leading: const Icon(Icons.nights_stay_outlined),
              onTap: () => Navigator.of(ctx).pop(
                const TimeOfDay(hour: 18, minute: 0),
              ),
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
      await ref.read(discoverRepositoryProvider).voteSocietyTag(
            listingId: listing.id,
            tag: tag,
            vote: vote,
          );
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
    if (ownerId == null) return;

    final currentUserId =
        ref.read(bootstrapControllerProvider).valueOrNull?.profile.id;
    if (currentUserId != null && currentUserId == ownerId) return;

    // Trigger a fetch if we haven't fetched yet, so the sheet has data.
    if (!_peerFetched) {
      _maybeFetchOwnerPeer(listing);
    }

    OwnerProfileSheet.show(
      context: context,
      peerData: _ownerPeer,
      listingOwnerName: listing.ownerName ?? 'Owner',
      onSendMessage: () {
        Navigator.of(context).pop();
        _handleContact(listing);
      },
    );
  }
}
