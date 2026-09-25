import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/errors/app_failure.dart';
import '../../core/errors/l10n_bridge.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../chats/chats_repository.dart';
import '../shared/presentation/components.dart';
import '../shared/presentation/paper/paper_scene.dart';
import 'application/visits_actions_controller.dart';

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

  // Ephemeral form state: each visit starts from these defaults.
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _slot = 'afternoon';
  bool _submitting = false;

  /// The conversation passed in, or the one fetched by [conversationId].
  ConversationSummaryModel? get _conversation {
    final id = widget.conversationId;
    return widget.conversation ??
        (id == null ? null : ref.read(conversationProvider(id)).valueOrNull);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  /// Returns a local DateTime for the selected date and slot.
  /// The repository converts to UTC before sending to the backend.
  DateTime get _scheduledDate {
    final hour = switch (_slot) {
      'morning' => 10,
      'evening' => 18,
      _ => 15,
    };
    final selectedDate = _selectedDate;
    return DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      hour,
    );
  }

  Future<void> _submit() async {
    // Guard against a same-frame double-tap firing two POSTs → two visit rows.
    // The button is disabled while submitting, but a rapid tap can land both
    // taps before the rebuild disables it. (#24)
    if (_submitting) return;
    final locale = AppLocalizations.of(context);
    final conversation = _conversation;
    final property = conversation?.contextProperty;
    if (conversation == null || property == null) {
      FlatmatesToast.error(context, locale.visitScheduleNoConversation);
      return;
    }

    // Reject today + past morning (or any slot that has already passed).
    final scheduledDate = _scheduledDate;
    if (!scheduledDate.isAfter(DateTime.now())) {
      FlatmatesToast.error(context, locale.visitTimeInPast);
      return;
    }

    setState(() => _submitting = true);
    var visitCreated = false;
    try {
      final timeSlotLabel = switch (_slot) {
        'morning' => locale.timeSlotMorning,
        'evening' => locale.timeSlotEvening,
        _ => locale.timeSlotAfternoon,
      };
      await ref
          .read(visitsActionsControllerProvider)
          .schedule(
            propertyId: property.id,
            counterpartyUserId: conversation.peer.id,
            conversationId: conversation.id,
            scheduledDate: scheduledDate,
            locale: locale,
            note: _noteController.text,
            timeSlotLabel: timeSlotLabel,
          );
      visitCreated = true;
      if (!mounted) return;
      FlatmatesToast.success(context, locale.visitRequestSent);
      context.pop();
    } catch (e) {
      debugPrint('ScheduleVisitPage._submit: $e');
      if (!mounted) return;
      final message = visitCreated
          ? locale.visitScheduledNotificationFailed
          : e is AppFailure
          ? e.userMessage(locale.toUserMessageL10n())
          : locale.visitRequestFailed;
      FlatmatesToast.error(context, message);
    } finally {
      if (mounted) setState(() => _submitting = false);
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

    return FlatmatesScreen(
      appBar: FlatmatesHeader.logo(onBack: () => context.pop()),
      body: fetchedConversation?.isLoading == true
          ? const FlatmatesSkeleton.form()
          : fetchedConversation?.hasError == true
          ? FlatmatesErrorState(
              message: locale.couldNotLoadContent,
              onRetry: () =>
                  ref.invalidate(conversationProvider(widget.conversationId!)),
            )
          : property == null || conversation == null
          ? FlatmatesEmptyState(
              title: locale.visitScheduleNoConversation,
              prop: PaperProp.chat,
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.screen),
              children: [
                _PropertySummary(
                  thumbnail: property.mainImageUrl != null
                      ? FlatmatesNetworkImage(
                          imageUrl: property.mainImageUrl!,
                          width: 88,
                          height: 88,
                          borderRadius: AppRadius.mdBorder,
                        )
                      : Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: AppSemanticColors.paperDeepFor(
                              theme.brightness,
                            ),
                            borderRadius: AppRadius.mdBorder,
                          ),
                          child: Icon(
                            Icons.apartment_rounded,
                            color: AppSemanticColors.textTertiaryFor(
                              theme.brightness,
                            ),
                          ),
                        ),
                  details: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(property.title, style: theme.textTheme.titleLarge),
                      const SizedBox(height: AppSpacing.sm),
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
                              locale.localeName,
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
                      final lastDate = firstDate.add(const Duration(days: 90));
                      // Clamp the stored date into [firstDate, lastDate];
                      // CalendarDatePicker asserts initialDate is in range.
                      final selectedDate = _selectedDate;
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
                            setState(() => _selectedDate = date),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(locale.selectTimeSlot, style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    FlatmatesChip(
                      key: const Key('visit_morning_slot'),
                      variant: FlatmatesChipVariant.choice,
                      label: locale.timeSlotMorning,
                      selected: _slot == 'morning',
                      onSelected: (_) => setState(() => _slot = 'morning'),
                    ),
                    FlatmatesChip(
                      key: const Key('visit_afternoon_slot'),
                      variant: FlatmatesChipVariant.choice,
                      label: locale.timeSlotAfternoon,
                      selected: _slot == 'afternoon',
                      onSelected: (_) => setState(() => _slot = 'afternoon'),
                    ),
                    FlatmatesChip(
                      key: const Key('visit_evening_slot'),
                      variant: FlatmatesChipVariant.choice,
                      label: locale.timeSlotEvening,
                      selected: _slot == 'evening',
                      onSelected: (_) => setState(() => _slot = 'evening'),
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
      bottomNavigationBar: FlatmatesBottomActionBar(
        primaryButtonKey: const Key('visit_send_request_button'),
        label: _submitting ? locale.sendingLabel : locale.sendRequestCta,
        icon: Icons.send_rounded,
        onPressed: _submitting ? null : _submit,
      ),
    );
  }
}

/// Property thumbnail beside its details; stacked at large text sizes so
/// the title keeps the full card width.
class _PropertySummary extends StatelessWidget {
  const _PropertySummary({required this.thumbnail, required this.details});

  final Widget thumbnail;
  final Widget details;

  @override
  Widget build(BuildContext context) {
    final large = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    return FlatmatesCard(
      child: large
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                thumbnail,
                const SizedBox(height: AppSpacing.md),
                details,
              ],
            )
          : Row(
              children: [
                thumbnail,
                const SizedBox(width: AppSpacing.md),
                Expanded(child: details),
              ],
            ),
    );
  }
}
