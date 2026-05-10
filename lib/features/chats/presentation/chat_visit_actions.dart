import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../visits/visits_repository.dart';

Future<void> confirmVisitFromChat({
  required BuildContext context,
  required WidgetRef ref,
  required VisitItem visit,
}) async {
  final locale = AppLocalizations.of(context);
  try {
    await ref.read(visitsRepositoryProvider).confirmVisit(visit.id);
    ref.invalidate(visitsProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(locale.visitConfirmed)));
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(locale.visitActionFailed)));
  }
}

Future<void> rescheduleVisitFromChat({
  required BuildContext context,
  required WidgetRef ref,
  required VisitItem visit,
}) async {
  final locale = AppLocalizations.of(context);
  final now = DateTime.now();
  final date = await showDatePicker(
    context: context,
    firstDate: now,
    lastDate: now.add(const Duration(days: 90)),
    initialDate: visit.scheduledDate.isAfter(now)
        ? visit.scheduledDate
        : now.add(const Duration(days: 1)),
  );
  if (date == null || !context.mounted) return;

  final scheduledTime = visit.scheduledDate.toLocal();
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(
      hour: scheduledTime.hour,
      minute: scheduledTime.minute,
    ),
  );
  if (time == null || !context.mounted) return;

  final newDate = DateTime(
    date.year,
    date.month,
    date.day,
    time.hour,
    time.minute,
  );
  try {
    await ref.read(visitsRepositoryProvider).rescheduleVisit(visit.id, newDate);
    ref.invalidate(visitsProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(locale.visitRescheduleCta)));
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(locale.visitActionFailed)));
  }
}
