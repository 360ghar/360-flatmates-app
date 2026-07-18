import 'safe_json_list.dart';

/// Parses the standard `{ items, next_cursor, has_more, limit }` envelope that
/// the backend uses for all paginated list endpoints.
///
/// Returns the parsed items plus the cursor metadata needed to request the
/// next page. When [envelope] is missing (or null), returns an empty list with
/// `hasMore=false` so callers can treat both empty inputs and missing keys
/// identically.
({List<T> items, String? nextCursor, bool hasMore}) parsePagedEnvelope<T>(
  Map<String, dynamic>? envelope,
  T Function(Map<String, dynamic> json) fromJson, {
  required String label,
}) {
  final root = envelope ?? const <String, dynamic>{};
  // Some gateways wrap list payloads as `{ data: { items, ... } }`.
  final nested = root['data'];
  final data = nested is Map && root['items'] == null
      ? Map<String, dynamic>.from(nested)
      : root;
  final rawItems = data['items'] ?? data['results'] ?? data['data'];
  final items = safeJsonList(
    rawItems is List ? rawItems : null,
    fromJson,
    label: label,
  );
  final rawNext = data['next_cursor'] ?? data['nextCursor'];
  final nextCursor = rawNext?.toString();
  final hasMore =
      data['has_more'] as bool? ??
      data['hasMore'] as bool? ??
      (nextCursor != null && nextCursor.isNotEmpty);
  return (items: items, nextCursor: nextCursor, hasMore: hasMore);
}
