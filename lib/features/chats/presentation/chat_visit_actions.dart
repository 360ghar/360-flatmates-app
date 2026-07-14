import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/errors/l10n_bridge.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../shared/presentation/flatmates_toast.dart';
import '../../visits/application/visits_actions_controller.dart';
import '../../visits/application/visits_list_controller.dart';
import '../../visits/visits_repository.dart';

/// Visit ids currently mutating from chat so double-taps cannot fire twice.
final _pendingChatVisitActions = <int>{};

Future<void> confirmVisitFromChat({
  required BuildContext context,
  required WidgetRef ref,
  required VisitItem visit,
}) async {
  if (!_pendingChatVisitActions.add(visit.id)) return;
  final locale = AppLocalizations.of(context);
  try {
    await ref.read(visitsActionsControllerProvider).confirm(visit);
    // Actions controller already invalidates both providers; keep explicit
    // invalidation so chat-origin updates stay resilient if controller changes.
    ref.invalidate(visitsProvider);
    ref.invalidate(visitsListControllerProvider);
    if (!context.mounted) return;
    FlatmatesToast.success(context, locale.visitConfirmed);
  } catch (e) {
    debugPrint('confirmVisitFromChat failed for visit ${visit.id}: $e');
    if (!context.mounted) return;
    final msg = e is AppFailure
        ? e.userMessage(locale.toUserMessageL10n())
        : locale.visitActionFailed;
    FlatmatesToast.error(context, msg);
  } finally {
    _pendingChatVisitActions.remove(visit.id);
  }
}

Future<void> rescheduleVisitFromChat({
  required BuildContext context,
  required WidgetRef ref,
  required VisitItem visit,
}) async {
  if (_pendingChatVisitActions.contains(visit.id)) return;
  final locale = AppLocalizations.of(context);

  final now = DateTime.now();
  final scheduledLocal = visit.scheduledDate.toLocal();
  final firstDate = DateUtils.dateOnly(now);
  final lastDate = firstDate.add(const Duration(days: 90));
  var initialDate = scheduledLocal.isAfter(now)
      ? DateUtils.dateOnly(scheduledLocal)
      : firstDate.add(const Duration(days: 1));
  if (initialDate.isBefore(firstDate)) initialDate = firstDate;
  if (initialDate.isAfter(lastDate)) initialDate = lastDate;

  final date = await showDatePicker(
    context: context,
    firstDate: firstDate,
    lastDate: lastDate,
    initialDate: initialDate,
  );
  if (date == null || !context.mounted) return;

  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(scheduledLocal),
  );
  if (time == null || !context.mounted) return;

  final newDate = DateTime(
    date.year,
    date.month,
    date.day,
    time.hour,
    time.minute,
  );

  // Date picker allows "today"; time picker allows any clock value — reject past.
  if (!newDate.isAfter(DateTime.now())) {
    FlatmatesToast.error(context, locale.visitTimeInPast);
    return;
  }

  if (!_pendingChatVisitActions.add(visit.id)) return;
  try {
    await ref.read(visitsActionsControllerProvider).reschedule(visit, newDate);
    ref.invalidate(visitsProvider);
    ref.invalidate(visitsListControllerProvider);
    if (!context.mounted) return;
    FlatmatesToast.success(context, locale.visitRescheduled);
  } catch (e) {
    debugPrint('rescheduleVisitFromChat failed for visit ${visit.id}: $e');
    if (!context.mounted) return;
    final msg = e is AppFailure
        ? e.userMessage(locale.toUserMessageL10n())
        : locale.visitActionFailed;
    FlatmatesToast.error(context, msg);
  } finally {
    _pendingChatVisitActions.remove(visit.id);
  }
}
