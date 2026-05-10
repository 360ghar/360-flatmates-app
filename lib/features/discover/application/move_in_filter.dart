String? normalizeMoveInFilter(String? value) {
  final normalized = value?.trim().toLowerCase().replaceAll('-', '_');
  if (normalized == null ||
      normalized.isEmpty ||
      normalized == 'all' ||
      normalized == 'any' ||
      normalized == 'anytime' ||
      normalized == 'flexible' ||
      normalized == 'just_exploring') {
    return null;
  }
  return switch (normalized) {
    'immediate' || 'immediately' || 'now' => 'immediate',
    'this_month' || 'within_1_month' || 'within_a_month' => 'this_month',
    'next_month' => 'next_month',
    'within_2_weeks' || 'two_weeks' => 'within_2_weeks',
    _ => null,
  };
}

String? moveInFilterQueryValue(String? value) => normalizeMoveInFilter(value);

bool listingMatchesMoveInFilter(
  DateTime? availableFrom,
  String? filter, {
  DateTime? now,
}) {
  final normalized = normalizeMoveInFilter(filter);
  if (normalized == null) return true;
  if (availableFrom == null) return false;

  final localNow = now?.toLocal() ?? DateTime.now();
  final today = DateTime(localNow.year, localNow.month, localNow.day);
  final availableDay = availableFrom.toLocal();

  bool before(DateTime boundary) => availableDay.isBefore(boundary);

  return switch (normalized) {
    'immediate' => before(today.add(const Duration(days: 8))),
    'within_2_weeks' => before(today.add(const Duration(days: 15))),
    'this_month' => before(DateTime(today.year, today.month + 1)),
    'next_month' =>
      !availableDay.isBefore(DateTime(today.year, today.month + 1)) &&
          before(DateTime(today.year, today.month + 2)),
    _ => true,
  };
}
