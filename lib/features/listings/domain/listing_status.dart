import '../../../core/domain/wire_enums.dart';
import '../../discover/domain/property_listing.dart';

/// Derives the manage-listings bucket of a listing from its raw fields.
///
/// Shared by the post hub (tab counts) and the manage listings page so both
/// always agree on which bucket a listing falls into.
///
/// Backend has two different "status" concepts:
/// - `listing_preferences.moderation_status`, a `ListingModerationStatus`
///   (`pending_review`, `live`, `paused`, `rejected`)
/// - top-level `Property.status` lifecycle (`available`, `sold`, `rented`, ...)
///
/// The DTO prefers moderation_status, then falls back to Property.status.
///
/// Returns `expired` (a past `expires_at`), `paused`, `pending_review`, `rejected` or `active`.
/// A lifecycle value, or one this build does not know, is `active`: an owner
/// listing never falls into a gap that matches no manage tab.
String listingStatus(PropertyListing listing) {
  // `expires_at` is a public key. The auto-pause keys are admin-only, so an
  // auto-paused listing reads as `paused`; Resume then answers 409.
  final expiresAt = listing.expiresAt;
  if (expiresAt != null && expiresAt.isBefore(DateTime.now())) {
    return 'expired';
  }
  return switch (listing.moderationStatus) {
    ListingModerationStatus.paused => 'paused',
    ListingModerationStatus.pendingReview => 'pending_review',
    ListingModerationStatus.rejected => 'rejected',
    ListingModerationStatus.live || null => 'active',
  };
}

/// Whether [listing] belongs to the given manage tab
/// ('active', 'draft' or 'expired'). The `draft` tab holds the listings the
/// owner has to fix (rejected).
bool listingMatchesTab(PropertyListing listing, String tab) {
  final status = listingStatus(listing);
  return switch (tab) {
    'active' =>
      status == 'active' || status == 'paused' || status == 'pending_review',
    'draft' => status == 'rejected',
    'expired' => status == 'expired',
    _ => false,
  };
}
