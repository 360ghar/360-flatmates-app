import 'package:flutter/material.dart';

/// Calendar bounds for a "pick a day" date picker.
///
/// [showDatePicker] and [CalendarDatePicker] operate on *calendar dates*, and
/// the picker asserts that `initialDate` sits inside `[first, last]`. Every
/// value returned here is therefore a local date-only [DateTime]:
///
/// * `first` is today, local.
/// * `last` is [windowDays] local calendar days later. `Duration(days: n)`
///   advances n x 24 h instead, which lands on 23:00 of the preceding day
///   across a DST fall-back and silently drops the final selectable day.
/// * `initial` is [preferred] (a stored visit date, converted with `toLocal()`
///   and normalized to a date) or tomorrow when nothing is preferred, clamped
///   into `[first, last]` so an older or out-of-range date cannot trip the
///   picker's assertion.
///
/// Pure and injectable so the date math is unit-testable.
({DateTime first, DateTime last, DateTime initial}) visitDatePickerBounds({
  required DateTime now,
  DateTime? preferred,
  int windowDays = 90,
}) {
  final first = DateUtils.dateOnly(now);
  final last = DateTime(first.year, first.month, first.day + windowDays);
  final wanted = preferred == null
      ? DateTime(first.year, first.month, first.day + 1)
      : DateUtils.dateOnly(preferred.toLocal());
  return (
    first: first,
    last: last,
    initial: wanted.isBefore(first)
        ? first
        : wanted.isAfter(last)
        ? last
        : wanted,
  );
}
