// Helpers that keep DropdownButton values in sync with item ids.
//
// Flutter asserts that the selected value matches exactly one item. Catalog
// ids and legacy client defaults can drift (e.g. move-in `flexible` vs
// `just_exploring`), so callers must sanitize before passing `initialValue`.

/// Returns [value] only when it appears exactly once among [itemIds].
String? dropdownValueInIds(String? value, Iterable<String?> itemIds) {
  if (value == null) return null;
  var count = 0;
  for (final id in itemIds) {
    if (id == value) count++;
    if (count > 1) return null;
  }
  return count == 1 ? value : null;
}

/// Like [dropdownValueInIds], but falls back to the first non-null id when
/// [value] is missing (required dropdowns).
String? dropdownValueOrFirst(String? value, Iterable<String?> itemIds) {
  final matched = dropdownValueInIds(value, itemIds);
  if (matched != null) return matched;
  for (final id in itemIds) {
    if (id != null) return id;
  }
  return null;
}

/// Maps a move-in timeline value onto an id that exists in [itemIds].
///
/// Server catalog (`flatmates_move_in_timelines`) uses ids like
/// `immediately` / `just_exploring`, while older clients, OpenAPI docs, and
/// local fallbacks used `immediate` / `flexible`. Prefer an exact match, then
/// the first alias that is present in [itemIds].
String? resolveMoveInTimelineId(String? value, Iterable<String?> itemIds) {
  final ids = <String>{
    for (final id in itemIds)
      if (id != null && id.isNotEmpty) id,
  };
  if (ids.isEmpty) return null;

  final raw = value?.trim().toLowerCase().replaceAll('-', '_');
  if (raw != null && raw.isNotEmpty && ids.contains(raw)) return raw;

  final candidates = _moveInAliasCandidates(raw);
  for (final candidate in candidates) {
    if (ids.contains(candidate)) return candidate;
  }
  return null;
}

/// Alias groups ordered by preference (catalog id first, then legacy).
List<String> _moveInAliasCandidates(String? normalized) {
  switch (normalized) {
    case null:
    case '':
    case 'flexible':
    case 'anytime':
    case 'all':
    case 'any':
    case 'just_exploring':
      return const ['just_exploring', 'flexible', 'anytime'];
    case 'immediate':
    case 'immediately':
    case 'now':
      return const ['immediately', 'immediate'];
    case 'this_month':
    case 'within_1_month':
    case 'within_a_month':
    case 'within_month':
      return const ['within_1_month', 'this_month', 'within_month'];
    case 'next_month':
    case 'within_3_months':
      return const ['next_month', 'within_3_months'];
    case 'within_2_weeks':
    case 'two_weeks':
      return const ['within_2_weeks', 'two_weeks'];
    default:
      return const [];
  }
}
