import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/l10n_bridge.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../bootstrap/bootstrap_controller.dart';
import '../../../shared/presentation/components.dart';
import '../../../visits/application/visits_actions_controller.dart';
import '../../discover_repository.dart';
import 'owner_profile_sheet.dart';

Future<TimeOfDay?> showFlatDetailsTimeSlotPicker(BuildContext context) async {
  final locale = AppLocalizations.of(context);
  const slots = [
    TimeOfDay(hour: 10, minute: 0),
    TimeOfDay(hour: 15, minute: 0),
    TimeOfDay(hour: 18, minute: 0),
  ];
  return FlatmatesDialog.custom<TimeOfDay>(
    context,
    title: locale.selectTimeSlot,
    body: (ctx, _) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (slot, time, icon) in [
          (slots[0], locale.timeSlotMorningTime, Icons.wb_sunny_outlined),
          (slots[1], locale.timeSlotAfternoonTime, Icons.wb_cloudy_outlined),
          (slots[2], locale.timeSlotEveningTime, Icons.nights_stay_outlined),
        ])
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(flatDetailsTimeSlotLabel(locale, slot)),
            subtitle: Text(time),
            leading: Icon(icon),
            onTap: () => Navigator.of(ctx).pop(slot),
          ),
      ],
    ),
  );
}

String flatDetailsTimeSlotLabel(AppLocalizations locale, TimeOfDay timeSlot) {
  return switch (timeSlot.hour) {
    10 => locale.timeSlotMorning,
    18 => locale.timeSlotEvening,
    _ => locale.timeSlotAfternoon,
  };
}

Future<void> handleSocietyTagVote({
  required WidgetRef ref,
  required BuildContext context,
  required PropertyListing listing,
  required String tag,
  required String vote,
  required int listingId,
}) async {
  try {
    await ref
        .read(propertyListingProvider(listingId).notifier)
        .voteSocietyTag(tag: tag, vote: vote);
  } catch (e) {
    debugPrint('FlatDetailsActions.handleSocietyTagVote: $e');
    if (context.mounted) {
      final locale = AppLocalizations.of(context);
      final msg = e is AppFailure
          ? e.userMessage(locale.toUserMessageL10n())
          : locale.actionFailedRetry;
      FlatmatesToast.error(context, msg);
    }
  }
}

void handleOwnerTap({
  required WidgetRef ref,
  required BuildContext context,
  required PropertyListing listing,
  required VoidCallback onContact,
  VoidCallback? onScheduleVisit,
}) {
  final ownerId = listing.owner?.id ?? listing.ownerId;
  if (ownerId == null) {
    debugPrint(
      'FlatDetailsActions.handleOwnerTap: no ownerId on listing ${listing.id}',
    );
    return;
  }

  final currentUserId = ref
      .read(bootstrapControllerProvider)
      .valueOrNull
      ?.profile
      .id;
  if (currentUserId == null || currentUserId == ownerId) {
    debugPrint(
      'FlatDetailsActions.handleOwnerTap: suppressed self/null owner view',
    );
    return;
  }

  final locale = AppLocalizations.of(context);
  final ownerName = listing.owner?.fullName.trim().isNotEmpty == true
      ? listing.owner!.fullName
      : (listing.ownerName?.trim().isNotEmpty == true
            ? listing.ownerName!
            : locale.ownerFallbackLabel);

  OwnerProfileSheet.show(
    context: context,
    ownerId: ownerId,
    listingOwnerName: ownerName,
    onSendMessage: () {
      Navigator.of(context).pop();
      onContact();
    },
    onScheduleVisit: () {
      Navigator.of(context).pop();
      onScheduleVisit?.call();
    },
  );
}

Future<void> scheduleVisitFromDetails({
  required WidgetRef ref,
  required BuildContext context,
  required PropertyListing listing,
  required int listingId,
  required int? conversationId,
  required void Function(int? cid) onConversationId,
  required VoidCallback onLikeSynced,
  required void Function(bool scheduling) setScheduling,
}) async {
  final currentUserId = ref
      .read(bootstrapControllerProvider)
      .valueOrNull
      ?.profile
      .id;
  if (currentUserId == null) return;

  final locale = AppLocalizations.of(context);
  final now = DateTime.now();

  final date = await showDatePicker(
    context: context,
    firstDate: now,
    lastDate: now.add(const Duration(days: 90)),
    initialDate: now.add(const Duration(days: 1)),
  );
  if (date == null || !context.mounted) return;

  final timeSlot = await showFlatDetailsTimeSlotPicker(context);
  if (timeSlot == null || !context.mounted) return;

  final scheduledDate = DateTime(
    date.year,
    date.month,
    date.day,
    timeSlot.hour,
    timeSlot.minute,
  );
  if (!scheduledDate.isAfter(DateTime.now())) {
    if (context.mounted) {
      FlatmatesToast.error(context, locale.visitTimeInPast);
    }
    return;
  }

  final ownerId = listing.owner?.id ?? listing.ownerId;
  if (ownerId == null) return;

  setScheduling(true);
  try {
    var cid = conversationId;
    if (cid == null) {
      final wasLiked = listing.liked ?? false;
      int? result;
      try {
        result = await ref
            .read(propertyListingProvider(listingId).notifier)
            .ensureLiked(listing);
      } catch (e) {
        debugPrint('FlatDetailsActions.scheduleVisit.ensureLiked: $e');
        if (context.mounted) {
          final msg = e is AppFailure
              ? e.userMessage(locale.toUserMessageL10n())
              : locale.actionFailedRetry;
          FlatmatesToast.error(context, msg);
        }
        return;
      }
      if (result == null) {
        if (context.mounted) {
          FlatmatesToast.error(context, locale.actionFailedRetry);
        }
        return;
      }
      cid = result;
      onConversationId(result);
      if (!wasLiked) onLikeSynced();
    }

    // Read both notifiers before the await: this widget may be gone after.
    final listingNotifier = ref.read(
      propertyListingProvider(listingId).notifier,
    );
    await ref
        .read(visitsActionsControllerProvider)
        .schedule(
          propertyId: listing.id,
          counterpartyUserId: ownerId,
          conversationId: cid,
          scheduledDate: scheduledDate,
          locale: locale,
          note: locale.visitFromDetailPageNote,
          timeSlotLabel: flatDetailsTimeSlotLabel(locale, timeSlot),
        );
    listingNotifier.refresh();
    if (context.mounted) {
      FlatmatesToast.success(context, locale.visitRequestSent);
    }
  } catch (e) {
    debugPrint('FlatDetailsActions.scheduleVisit: $e');
    if (context.mounted) {
      final msg = e is AppFailure
          ? e.userMessage(locale.toUserMessageL10n())
          : locale.actionFailedRetry;
      FlatmatesToast.error(context, msg);
    }
  } finally {
    setScheduling(false);
  }
}
