// Reads of the lifestyle keys of a listing's `listing_preferences`, one key
// and one type per attribute, as the backend declares them
// (`ListingPreferences.pets`, `ListingPreferences.parties_at_home`: strings).

/// `pets` values that say pets live in (or are welcome in) the flat.
const _petsValues = {'have_pets', 'has_pets', 'pet_friendly', 'yes', 'true'};

/// Whether the listing says pets are in the flat. `pets` is a string; any other
/// type is not a statement about pets.
bool listingHasPets(Map<String, dynamic>? preferences) {
  final value = preferences?['pets'];
  if (value is! String) return false;
  return _petsValues.contains(value.trim().toLowerCase());
}

/// The `parties_at_home` value of the listing (`never`, `occasional_weekends`,
/// `party_friendly`), or null when the listing has none.
String? listingPartiesAtHome(Map<String, dynamic>? preferences) {
  final value = preferences?['parties_at_home'];
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// Whether the listing says parties are part of life in the flat.
bool listingIsPartyFriendly(Map<String, dynamic>? preferences) =>
    listingPartiesAtHome(preferences) == 'party_friendly';
