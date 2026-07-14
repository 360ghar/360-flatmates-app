import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/l10n_bridge.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../bootstrap/bootstrap_controller.dart';
import '../../../chats/chats_repository.dart' show messagesProvider;
import '../../../shared/presentation/components.dart';
import '../../../visits/application/visits_list_controller.dart';
import '../../../visits/visits_repository.dart';
import '../../discover_repository.dart';
import 'owner_profile_sheet.dart';

Future<TimeOfDay?> showFlatDetailsTimeSlotPicker(BuildContext context) async {
  final locale = AppLocalizations.of(context);
  return showDialog<TimeOfDay>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(locale.selectTimeSlot),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(locale.timeSlotMorning),
            subtitle: const Text('10:00 AM'),
            leading: const Icon(Icons.wb_sunny_outlined),
            onTap: () =>
                Navigator.of(ctx).pop(const TimeOfDay(hour: 10, minute: 0)),
          ),
          ListTile(
            title: Text(locale.timeSlotAfternoon),
            subtitle: const Text('3:00 PM'),
            leading: const Icon(Icons.wb_cloudy_outlined),
            onTap: () =>
                Navigator.of(ctx).pop(const TimeOfDay(hour: 15, minute: 0)),
          ),
          ListTile(
            title: Text(locale.timeSlotEvening),
            subtitle: const Text('6:00 PM'),
            leading: const Icon(Icons.nights_stay_outlined),
            onTap: () =>
                Navigator.of(ctx).pop(const TimeOfDay(hour: 18, minute: 0)),
          ),
        ],
      ),
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
        .read(discoverRepositoryProvider)
        .voteSocietyTag(listingId: listing.id, tag: tag, vote: vote);
    ref.invalidate(propertyListingProvider(listingId));
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
            .ensureLiked();
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

    await ref
        .read(visitsRepositoryProvider)
        .scheduleVisitAndNotify(
          propertyId: listing.id,
          counterpartyUserId: ownerId,
          conversationId: cid,
          scheduledDate: scheduledDate,
          note: locale.visitFromDetailPageNote,
          timeSlotLabel: flatDetailsTimeSlotLabel(locale, timeSlot),
        );
    ref.invalidate(propertyListingProvider(listingId));
    ref.invalidate(visitsListControllerProvider);
    ref.invalidate(visitsProvider);
    ref.invalidate(messagesProvider(cid));
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
