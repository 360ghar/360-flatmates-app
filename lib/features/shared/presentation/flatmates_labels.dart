import 'package:intl/intl.dart';
import '../../../l10n/gen/app_localizations.dart';

// ── Localization helpers ────────────────────────────────────────────────

String localizedFlatmatesModeLabel(AppLocalizations locale, String mode) {
  switch (mode.trim().toLowerCase()) {
    case 'room_poster':
      return locale.modeRoomPoster;
    case 'seeker':
      return locale.modeSeeker;
    case 'co_hunter':
      return locale.modeCoHunter;
    case 'open_to_both':
      return locale.modeOpenToBoth;
    default:
      return humanizeFlatmatesToken(mode);
  }
}

String localizedFlatmatesGenderLabel(AppLocalizations locale, String value) {
  switch (value.trim().toLowerCase()) {
    case 'any':
      return locale.genderAny;
    case 'male':
      return locale.genderMale;
    case 'female':
      return locale.genderFemale;
    default:
      return humanizeFlatmatesToken(value);
  }
}

String localizedFlatmatesAgeBucket(AppLocalizations locale, String? bucket) {
  if (bucket == null) return '';
  switch (bucket.trim()) {
    case '18-24':
      return locale.ageBucket18_24;
    case '25-30':
      return locale.ageBucket25_30;
    case '31-35':
      return locale.ageBucket31_35;
    case '36-40':
      return locale.ageBucket36_40;
    case '41-45':
      return locale.ageBucket41_45;
    case '46+':
      return locale.ageBucket46Plus;
    default:
      return humanizeFlatmatesToken(bucket);
  }
}

String localizedFlatmatesSharingTypeLabel(
  AppLocalizations locale,
  String value,
) {
  switch (value.trim().toLowerCase()) {
    case 'private_room':
      return locale.sharingPrivateRoom;
    case 'shared_room':
      return locale.sharingSharedRoom;
    default:
      return humanizeFlatmatesToken(value);
  }
}

String localizedFlatmatesVisitStatusLabel(
  AppLocalizations locale,
  String value,
) {
  switch (value.trim().toLowerCase()) {
    case 'scheduled':
      return locale.visitStatusScheduled;
    case 'confirmed':
      return locale.visitStatusConfirmed;
    case 'completed':
      return locale.visitStatusCompleted;
    case 'cancelled':
    case 'canceled':
      return locale.visitStatusCancelled;
    case 'requested':
      return locale.visitStatusRequested;
    default:
      return humanizeFlatmatesToken(value);
  }
}

String localizedFlatmatesFeatureLabel(AppLocalizations locale, String value) {
  switch (value.trim().toLowerCase()) {
    case 'furnished':
      return locale.featureFurnished;
    case 'semi_furnished':
      return locale.featureSemiFurnished;
    case 'wifi':
    case 'wi_fi':
    case 'wi-fi':
    case 'high_speed_wifi':
    case 'fast_wifi':
      return locale.featureWifi;
    case 'balcony':
      return locale.featureBalcony;
    case 'attached_bathroom':
      return locale.featureAttachedBathroom;
    case 'parking':
      return locale.featureParking;
    case 'ac':
    case 'air_conditioning':
      return locale.featureAc;
    case 'washing_machine':
      return locale.featureWashingMachine;
    default:
      return humanizeFlatmatesToken(value);
  }
}

String humanizeFlatmatesToken(String value) {
  return value
      .split(RegExp(r'[_\s-]+'))
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

/// Compacts a count for stat rows: 1000 → "1k", 1500 → "1.5k", 2000000 → "2M".
///
/// A whole thousand/million drops its `.0`. Case is deliberate and matches the
/// existing manage-listings copy: lowercase `k`, uppercase `M`.
String compactCount(int count) {
  if (count >= 1000000) {
    final m = count / 1000000;
    return '${m.toStringAsFixed(m.truncateToDouble() == m ? 0 : 1)}M';
  }
  if (count >= 1000) {
    final k = count / 1000;
    return '${k.toStringAsFixed(k.truncateToDouble() == k ? 0 : 1)}k';
  }
  return count.toString();
}

/// Chat message timestamp: time only for today, date + time otherwise.
///
/// Examples: "3:04 PM" (today), "12 Mar, 3:04 PM" (any other day).
///
/// Always pass the active [locale] — its `localeName` is handed to
/// [DateFormat] so Hindi renders Devanagari month names rather than English.
String messageTimestamp(AppLocalizations locale, DateTime timestamp) {
  final local = timestamp.toLocal();
  final now = DateTime.now();
  final isToday =
      local.year == now.year &&
      local.month == now.month &&
      local.day == now.day;
  return DateFormat(
    isToday ? 'h:mm a' : 'd MMM, h:mm a',
    locale.localeName,
  ).format(local);
}

/// Compacts a rupee amount for tight pills: 15000 → "15k", 150000 → "1.5L".
///
/// Returns the bare number — callers prefix the rupee symbol, or use
/// [budgetRangeText] which does it via the ARB.
String shortMoney(double value) {
  if (value >= 100000) return '${(value / 100000).toStringAsFixed(1)}L';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}k';
  return value.toStringAsFixed(0);
}

/// Localized compact budget range for swipe / profile stat pills.
///
/// Examples: "₹15k – ₹20k/month", "₹15k/month+", "Up to ₹20k/month".
/// Returns an empty string when both bounds are null.
///
/// The two-sided form reuses [AppLocalizations.budgetRangeLabel] so the rupee
/// symbol and the dash come from the ARB, and the suffix is
/// [AppLocalizations.perMonthSuffix] rather than a hardcoded "/mo".
String budgetRangeText(AppLocalizations locale, double? min, double? max) {
  final suffix = locale.perMonthSuffix;
  if (min != null && max != null) {
    return '${locale.budgetRangeLabel(shortMoney(min), shortMoney(max))}'
        '$suffix';
  }
  if (min != null) return '₹${shortMoney(min)}$suffix+';
  // TODO(l10n): "Up to" has no ARB key yet — see the sweep report.
  if (max != null) return 'Up to ₹${shortMoney(max)}$suffix';
  return '';
}

/// Formats a distance in kilometers to a localized human-readable string.
///
/// Examples: "500m away", "2.5km away", "15km away"
String formatDistanceText(AppLocalizations locale, double? distanceKm) {
  if (distanceKm == null) return '';
  if (distanceKm < 1) return locale.distanceMeters((distanceKm * 1000).round());
  if (distanceKm < 10) {
    return locale.distanceKmDecimal(distanceKm.toStringAsFixed(1));
  }
  return locale.distanceKm(distanceKm.round());
}
