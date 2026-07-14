import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/sse_providers.dart';
import '../../l10n/gen/app_localizations.dart';
import '../discover/discover_repository.dart';
import '../shared/presentation/components.dart';
import 'presentation/widgets/listing_review_body.dart';

final listingReviewProvider = FutureProvider.family<PropertyListing, int>((
  ref,
  listingId,
) {
  return ref.watch(discoverRepositoryProvider).fetchListing(listingId);
});

class ListingUnderReviewPage extends ConsumerStatefulWidget {
  const ListingUnderReviewPage({required this.listingId, super.key});

  final int listingId;

  @override
  ConsumerState<ListingUnderReviewPage> createState() =>
      _ListingUnderReviewPageState();
}

class _ListingUnderReviewPageState
    extends ConsumerState<ListingUnderReviewPage> {
  @override
  Widget build(BuildContext context) {
    final listingAsync = ref.watch(listingReviewProvider(widget.listingId));

    // Listen for Realtime listing status changes and refresh.
    ref.listen(flatmatesRealtimeEventProvider, (previous, next) {
      final event = next.valueOrNull;
      if (event?.type == 'listing_status_changed') {
        final listingId =
            event!.data['listing_id'] as int? ??
            (event.data['listing_id'] as num?)?.toInt() ??
            (event.data['property_id'] as num?)?.toInt();
        if (listingId == widget.listingId) {
          ref.invalidate(listingReviewProvider(widget.listingId));
        }
      }
    });

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
}
