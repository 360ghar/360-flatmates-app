import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../chats/chats_repository.dart';
import '../shared/presentation/components.dart';
import 'application/visits_list_controller.dart';
import 'visits_repository.dart';

final _selectedDateProvider = StateProvider<DateTime>(
  (ref) => DateTime.now().add(const Duration(days: 1)),
);
final _selectedSlotProvider = StateProvider<String>((ref) => 'afternoon');
final _submittingVisitProvider = StateProvider<bool>((ref) => false);
final _conversationProvider = StateProvider<ConversationSummaryModel?>(
  (ref) => null,
);

class ScheduleVisitPage extends ConsumerStatefulWidget {
  const ScheduleVisitPage({
    required this.conversation,
    this.conversationId,
    super.key,
  });

  final ConversationSummaryModel? conversation;
  final int? conversationId;

  @override
  ConsumerState<ScheduleVisitPage> createState() => _ScheduleVisitPageState();
}

class _ScheduleVisitPageState extends ConsumerState<ScheduleVisitPage> {
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // The slot/date/conversation/submitting providers are file-level globals,
    // so they retain values from a previous scheduling session. Reset them on
    // entry so a fresh visit doesn't inherit a stale date, slot, or peer.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(_selectedDateProvider.notifier).state = DateTime.now().add(
        const Duration(days: 1),
      );
      ref.read(_selectedSlotProvider.notifier).state = 'afternoon';
      ref.read(_submittingVisitProvider.notifier).state = false;
      ref.read(_conversationProvider.notifier).state = widget.conversation;
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  /// Returns a local DateTime for the selected date and slot.
  /// The repository converts to UTC before sending to the backend.
  DateTime get _scheduledDate {
    final hour = switch (ref.read(_selectedSlotProvider)) {
      'morning' => 10,
      'evening' => 18,
      _ => 15,
    };
    final selectedDate = ref.read(_selectedDateProvider);
    return DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      hour,
    );
  }

  Future<void> _submit() async {
    final locale = AppLocalizations.of(context);
    final conversation = widget.conversation ?? ref.read(_conversationProvider);
    final property = conversation?.contextProperty;
    if (conversation == null || property == null) {
      FlatmatesToast.error(context, locale.visitScheduleNoConversation);
      return;
    }

    ref.read(_submittingVisitProvider.notifier).state = true;
    bool visitCreated = false;
    try {
      final timeSlotLabel = switch (ref.read(_selectedSlotProvider)) {
        'morning' => locale.timeSlotMorning,
        'evening' => locale.timeSlotEvening,
        _ => locale.timeSlotAfternoon,
      };
      await ref
          .read(visitsRepositoryProvider)
          .scheduleVisitAndNotify(
            propertyId: property.id,
            counterpartyUserId: conversation.peer.id,
            conversationId: conversation.id,
            scheduledDate: _scheduledDate,
            note: _noteController.text,
            timeSlotLabel: timeSlotLabel,
          );
      visitCreated = true;
      ref.invalidate(visitsListControllerProvider);
      ref.invalidate(visitsProvider);
      ref.invalidate(messagesProvider(conversation.id));
      if (!mounted) return;
      FlatmatesToast.success(context, locale.contactRequestSent);
      context.pop();
    } catch (error) {
      if (!mounted) return;
      final message = visitCreated
          ? locale.visitScheduledNotificationFailed
          : locale.visitRequestFailed;
      FlatmatesToast.error(context, message);
    } finally {
      if (mounted) ref.read(_submittingVisitProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    final fetchedConversation =
        widget.conversation == null && widget.conversationId != null
        ? ref.watch(conversationProvider(widget.conversationId!))
        : null;
    final conversation =
        widget.conversation ?? fetchedConversation?.valueOrNull;
    final property = conversation?.contextProperty;
    if (ref.read(_conversationProvider) == null &&
        widget.conversation == null &&
        conversation != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && ref.read(_conversationProvider) == null) {
          ref.read(_conversationProvider.notifier).state = conversation;
        }
      });
    }

    return Scaffold(
      appBar: FlatmatesHeader.logo(onBack: () => context.pop()),
      body: SafeArea(
        child: fetchedConversation?.isLoading == true
            ? const FlatmatesSkeleton.form()
            : fetchedConversation?.hasError == true
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(locale.errorUnknown, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FlatmatesButton(
                      label: locale.commonRetry,
                      onPressed: () => ref.invalidate(
                        conversationProvider(widget.conversationId!),
                      ),
                      fullWidth: true,
                    ),
                  ],
                ),
              )
            : property == null || conversation == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Text(
                    locale.visitScheduleNoConversation,
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.xl,
                  120,
                ),
                children: [
                  const SizedBox(height: AppSpacing.xs),
                  FlatmatesCard(
                    child: Row(
                      children: [
                        if (property.mainImageUrl != null)
                          FlatmatesNetworkImage(
                            imageUrl: property.mainImageUrl!,
                            width: 88,
                            height: 88,
                            borderRadius: BorderRadius.circular(14),
                          ),
                        if (property.mainImageUrl == null)
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              color: AppSemanticColors.accent.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.apartment_rounded,
                              color: AppSemanticColors.accent,
                            ),
                          ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                property.title,
                                style: theme.textTheme.titleLarge,
                              ),
                              const SizedBox(
                                height: AppSpacing.xs + AppSpacing.xs,
                              ),
                              Text(
                                conversation.peer.fullName,
                                style: theme.textTheme.bodyMedium,
                              ),
                              if (conversation.matchedAt != null) ...[
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  locale.matchedOnDate(
                                    DateFormat(
                                      'd MMM yyyy',
                                    ).format(conversation.matchedAt!),
                                  ),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppSemanticColors.textSecondaryFor(
                                      theme.brightness,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    locale.scheduleVisitTitle,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FlatmatesCard(
                    child: Builder(
                      builder: (context) {
                        final firstDate = DateUtils.dateOnly(DateTime.now());
                        final lastDate = firstDate.add(
                          const Duration(days: 90),
                        );
                        // Clamp the stored date into [firstDate, lastDate];
                        // CalendarDatePicker asserts initialDate is in range.
                        final selectedDate = ref.watch(_selectedDateProvider);
                        final initial = selectedDate.isBefore(firstDate)
                            ? firstDate
                            : selectedDate.isAfter(lastDate)
                            ? lastDate
                            : selectedDate;
                        return CalendarDatePicker(
                          initialDate: initial,
                          firstDate: firstDate,
                          lastDate: lastDate,
                          onDateChanged: (date) =>
                              ref.read(_selectedDateProvider.notifier).state =
                                  date,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    locale.selectTimeSlot,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      FlatmatesChip(
                        key: const Key('visit_morning_slot'),
                        variant: FlatmatesChipVariant.choice,
                        label: locale.timeSlotMorning,
                        selected: ref.watch(_selectedSlotProvider) == 'morning',
                        onSelected: (_) =>
                            ref.read(_selectedSlotProvider.notifier).state =
                                'morning',
                      ),
                      FlatmatesChip(
                        key: const Key('visit_afternoon_slot'),
                        variant: FlatmatesChipVariant.choice,
                        label: locale.timeSlotAfternoon,
                        selected:
                            ref.watch(_selectedSlotProvider) == 'afternoon',
                        onSelected: (_) =>
                            ref.read(_selectedSlotProvider.notifier).state =
                                'afternoon',
                      ),
                      FlatmatesChip(
                        key: const Key('visit_evening_slot'),
                        variant: FlatmatesChipVariant.choice,
                        label: locale.timeSlotEvening,
                        selected: ref.watch(_selectedSlotProvider) == 'evening',
                        onSelected: (_) =>
                            ref.read(_selectedSlotProvider.notifier).state =
                                'evening',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  TextField(
                    key: const Key('visit_note_input'),
                    controller: _noteController,
                    maxLength: 180,
                    minLines: 3,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: locale.addNoteOptional,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FlatmatesTrustBadge(
                    variant: FlatmatesTrustBadgeVariant.privacy,
                    label: locale.visitPrivacyNote(conversation.peer.fullName),
                    compact: true,
                  ),
                ],
              ),
      ),
      bottomNavigationBar: FlatmatesBottomActionBar(
        primaryButtonKey: const Key('visit_send_request_button'),
        label: ref.watch(_submittingVisitProvider)
            ? locale.sendingLabel
            : locale.sendRequestCta,
        icon: Icons.send_rounded,
        onPressed: ref.watch(_submittingVisitProvider) ? null : _submit,
      ),
    );
  }
}
