import 'package:flutter/foundation.dart';

/// Maps a raw JSON list to `List<T>`, skipping items that fail to parse
/// instead of failing the whole list. Each skipped item is logged via
/// [debugPrint] with [label] for diagnosis.
List<T> safeJsonList<T>(
  List<dynamic>? rows,
  T Function(Map<String, dynamic> json) fromJson, {
  required String label,
}) {
  if (rows == null || rows.isEmpty) return const [];
  final result = <T>[];
  for (var i = 0; i < rows.length; i++) {
    final item = rows[i];
    if (item is! Map) {
      debugPrint('safeJsonList($label): item $i is not a Map, skipped');
      continue;
    }
    try {
      result.add(fromJson(Map<String, dynamic>.from(item)));
    } catch (e) {
      debugPrint('safeJsonList($label): item $i failed to parse, skipped: $e');
    }
  }
  return result;
}
