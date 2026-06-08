import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/errors/l10n_bridge.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../shared/presentation/flatmates_toast.dart';
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
    FlatmatesToast.success(context, locale.visitConfirmed);
  } catch (e) {
    debugPrint('confirmVisitFromChat failed for visit ${visit.id}: $e');
    if (!context.mounted) return;
    final msg = e is AppFailure
        ? e.userMessage(locale.toUserMessageL10n())
        : locale.visitActionFailed;
    FlatmatesToast.error(context, msg);
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
    FlatmatesToast.success(context, locale.visitRescheduleCta);
  } catch (e) {
    debugPrint('rescheduleVisitFromChat failed for visit ${visit.id}: $e');
    if (!context.mounted) return;
    final msg = e is AppFailure
        ? e.userMessage(locale.toUserMessageL10n())
        : locale.visitActionFailed;
    FlatmatesToast.error(context, msg);
  }
}
