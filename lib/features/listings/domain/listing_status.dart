import '../../discover/domain/property_listing.dart';

/// Derives the effective status of a listing from its raw fields.
///
/// Shared by the post hub (tab counts) and the manage listings page so both
/// always agree on which bucket a listing falls into.
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
  if (status == 'live' || status == 'approved' || listing.isAvailable) {
    return 'active';
  }
  return status.isEmpty ? 'active' : status;
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
