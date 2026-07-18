import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/sse_providers.dart';
import '../../l10n/gen/app_localizations.dart';
import '../discover/application/property_listing_seed_store.dart';
import '../discover/discover_repository.dart';
import '../shared/presentation/components.dart';
import 'presentation/widgets/listing_review_body.dart';

/// Provider used only when navigating to the review page without a local seed
/// (e.g. manage-listings → review after a cold start). Prefers the durable
/// seed store so pending listings never hard-depend on GET after a GoRouter
/// refresh drops `state.extra`.
final listingReviewProvider = FutureProvider.family<PropertyListing, int>((
  ref,
  listingId,
) async {
  final seeded = ref
      .read(propertyListingSeedStoreProvider.notifier)
      .get(listingId);
  // Prefer seed for pending/rejected so a slow/failed GET never blocks the
  // under-review screen with a false "no internet" error. Still try GET so
  // cold-start opens with the latest moderation status when the network works.
  if (seeded != null && (seeded.isUnderReview || seeded.isRejected)) {
    try {
      final fresh = await ref
          .watch(discoverRepositoryProvider)
          .fetchListing(listingId);
      ref.read(propertyListingSeedStoreProvider.notifier).put(fresh);
      return fresh;
    } catch (e) {
      debugPrint('listingReviewProvider seed-fallback($listingId): $e');
      return seeded;
    }
  }
  try {
    final fresh = await ref
        .watch(discoverRepositoryProvider)
        .fetchListing(listingId);
    ref.read(propertyListingSeedStoreProvider.notifier).put(fresh);
    return fresh;
  } catch (e) {
    if (seeded != null) return seeded;
    rethrow;
  }
});

class ListingUnderReviewPage extends ConsumerStatefulWidget {
  const ListingUnderReviewPage({
    required this.listingId,
    this.seededListing,
    super.key,
  });

  final int listingId;

  /// When navigating immediately after property creation, the listing object
  /// parsed from the POST response is passed here. Also mirrored into
  /// [propertyListingSeedStoreProvider] so router rebuilds keep working.
  final PropertyListing? seededListing;

  @override
  ConsumerState<ListingUnderReviewPage> createState() =>
      _ListingUnderReviewPageState();
}

class _ListingUnderReviewPageState
    extends ConsumerState<ListingUnderReviewPage> {
  /// Mutable copy that gets replaced when a Realtime status-change event fires.
  PropertyListing? _liveListing;

  @override
  void initState() {
    super.initState();
    // Prefer navigation extra; fall back to durable store immediately so the
    // first frame does not flash a network error when GoRouter dropped extra.
    _liveListing =
        widget.seededListing ??
        ref
            .read(propertyListingSeedStoreProvider.notifier)
            .get(widget.listingId);
    // Defer store *write* and a background reconcile — mutating providers
    // during initState first frame is discouraged; read above is fine.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final seed = widget.seededListing ?? _liveListing;
      if (seed != null) {
        ref.read(propertyListingSeedStoreProvider.notifier).put(seed);
        // Soft reconcile so an approved listing is not stuck on the seed
        // "under review" UI when the network is fine.
        unawaited(_refreshAfterStatusChange());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Prefer in-memory seed (navigation extra or durable store recovery).
    final live = _liveListing;
    if (live != null) {
      _listenForStatusChanges();
      return FlatmatesScreen(
        body: ListingReviewBody(listing: live, listingId: widget.listingId),
      );
    }

    // No seed — navigated from manage-listings or deep-link: use the provider.
    final listingAsync = ref.watch(listingReviewProvider(widget.listingId));
    _listenForStatusChanges();

    return FlatmatesScreen(
      body: listingAsync.when(
        data: (listing) =>
            ListingReviewBody(listing: listing, listingId: widget.listingId),
        loading: () => const FlatmatesSkeleton.feed(itemCount: 2),
        error: (e, _) => FlatmatesErrorState(
          message: AppLocalizations.of(context).couldNotLoadReviewStatus,
          onRetry: () =>
              ref.invalidate(listingReviewProvider(widget.listingId)),
        ),
      ),
    );
  }

  void _listenForStatusChanges() {
    ref.listen(flatmatesRealtimeEventProvider, (previous, next) {
      final event = next.valueOrNull;
      if (event?.type == 'listing_status_changed') {
        final listingId =
            event!.data['listing_id'] as int? ??
            (event.data['listing_id'] as num?)?.toInt() ??
            (event.data['property_id'] as num?)?.toInt();
        if (listingId == widget.listingId) {
          unawaited(_refreshAfterStatusChange());
        }
      }
    });
  }

  /// Refetch after SSE, but keep the seed if GET fails (still pending and
  /// optional-auth / public hide can still 404).
  Future<void> _refreshAfterStatusChange() async {
    try {
      final fresh = await ref
          .read(discoverRepositoryProvider)
          .fetchListing(widget.listingId);
      ref.read(propertyListingSeedStoreProvider.notifier).put(fresh);
      if (!mounted) return;
      setState(() => _liveListing = fresh);
    } catch (e) {
      debugPrint('ListingUnderReviewPage._refreshAfterStatusChange: $e');
      // Keep existing seed / live listing so the owner still sees status UI.
    }
  }
}
