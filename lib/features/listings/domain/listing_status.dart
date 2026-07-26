import '../../discover/domain/property_listing.dart';

/// Derives the effective status of a listing from its raw fields.
///
/// Shared by the post hub (tab counts) and the manage listings page so both
/// always agree on which bucket a listing falls into.
///
/// Backend has two different "status" concepts:
/// - `listing_preferences.moderation_status` (pending_review / live / rejected / …)
/// - top-level `Property.status` lifecycle (`available`, `sold`, `rented`, …)
///
/// The DTO prefers moderation_status, then falls back to Property.status.
/// When moderation_status is missing, fallback `"available"` must still map
/// into a manage tab — otherwise newly created pending listings disappear
/// from Active / Draft / Expired entirely.
String listingStatus(PropertyListing listing) {
  final status = listing.status ?? listing.propertyStatus ?? '';
  final expiresAt = listing.expiresAt;
  final expiredByReview =
      listing.preferences?['auto_paused_reason'] == 'expired_move_in_date';
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
  // Moderation "live"/"approved", lifecycle "available", or explicit availability.
  // Also treat empty / unknown lifecycle noise as active so owner listings never
  // fall into a gap that matches no manage tab.
  if (status == 'live' ||
      status == 'approved' ||
      status == 'available' ||
      status == 'under_offer' ||
      status == 'maintenance' ||
      listing.isAvailable ||
      status.isEmpty) {
    return 'active';
  }
  // Terminal lifecycle states that are not the flatmates "expired" bucket
  // still surface under Active so the owner can find and edit them.
  if (status == 'sold' || status == 'rented') {
    return 'active';
  }
  // Unknown values: prefer Active over orphaning the card from every tab.
  return 'active';
}

/// Whether [listing] belongs to the given manage tab
/// ('active', 'draft' or 'expired').
bool listingMatchesTab(PropertyListing listing, String tab) {
  final status = listingStatus(listing);
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
