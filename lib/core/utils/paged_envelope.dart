import 'safe_json_list.dart';

/// Parses the `CursorPage` the backend serves for every list route:
/// `{ items, next_cursor, has_more, limit, total }`.
///
/// Returns the items plus the cursor to pass back, unchanged, for the next
/// page. A row that does not parse is skipped and logged (see [safeJsonList]).
/// A missing envelope reads as an empty last page.
({List<T> items, String? nextCursor, bool hasMore}) parsePagedEnvelope<T>(
  Map<String, dynamic>? envelope,
  T Function(Map<String, dynamic> json) fromJson, {
  required String label,
}) {
  final root = envelope ?? const <String, dynamic>{};
  final rawItems = root['items'];
  final items = safeJsonList(
    rawItems is List ? rawItems : null,
    fromJson,
    label: label,
  );
  final rawNext = root['next_cursor'];
  final nextCursor = rawNext is String && rawNext.isNotEmpty ? rawNext : null;
  // `has_more` is always sent; a page that names a next cursor has more.
  final hasMore = root['has_more'] is bool
      ? root['has_more'] as bool
      : nextCursor != null;
  return (items: items, nextCursor: nextCursor, hasMore: hasMore);
}
