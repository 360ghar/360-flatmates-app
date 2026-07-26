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
      _asBool(data['has_more']) ??
      _asBool(data['hasMore']) ??
      (nextCursor != null && nextCursor.isNotEmpty);
  return (items: items, nextCursor: nextCursor, hasMore: hasMore);
}

/// Coerces gateway bool-ish values (`true`/`false`, `0`/`1`, `"true"`/`"false"`).
bool? _asBool(Object? raw) {
  if (raw is bool) return raw;
  if (raw is num) return raw != 0;
  if (raw is String) {
    final normalized = raw.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
      return true;
    }
    if (normalized == 'false' || normalized == '0' || normalized == 'no') {
      return false;
    }
  }
  return null;
}
