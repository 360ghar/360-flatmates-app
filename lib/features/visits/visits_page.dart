import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_failure.dart';
import '../../core/errors/l10n_bridge.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../chats/application/cursor_list_controller.dart';
import '../shared/presentation/flatmates_async_view.dart';
import '../shared/presentation/flatmates_empty_state.dart';
import '../shared/presentation/flatmates_header.dart';
import '../shared/presentation/flatmates_skeleton.dart';
import '../shared/presentation/flatmates_toast.dart';
import '../shared/presentation/flatmates_trust_badge.dart';
import '../shared/presentation/flatmates_ui.dart';
import 'application/visits_actions_controller.dart';
import 'application/visits_list_controller.dart';
import 'visits_repository.dart';
import 'widgets/visit_card.dart';

/// Visit ids that currently have an action (confirm/cancel/reschedule)
/// in flight. Used to disable the card's action chips and prevent
/// double-submission of the same mutation.
final _pendingVisitActionsProvider = StateProvider.autoDispose<Set<int>>(
  (ref) => <int>{},
);

class VisitsPage extends ConsumerStatefulWidget {
  const VisitsPage({super.key});

  @override
  ConsumerState<VisitsPage> createState() => _VisitsPageState();
}

class _VisitsPageState extends ConsumerState<VisitsPage> {
  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<CursorListState<VisitItem>>>(
      visitsListControllerProvider,
      (previous, next) {
        if (next.isLoading && (previous == null || !previous.isLoading)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ref.read(visitsListControllerProvider.notifier).load();
          });
        }
      },
    );

    final visitsState = ref.watch(visitsListControllerProvider);
    final pending = ref.watch(_pendingVisitActionsProvider);
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final listHubBg = AppSemanticColors.secondarySurfaceFor(theme.brightness);

    return Scaffold(
      backgroundColor: listHubBg,
      appBar: FlatmatesHeader.backTitle(title: locale.scheduleTitle),
      body: FlatmatesAsyncView<CursorListState<VisitItem>>(
        value: visitsState,
        loading: const FlatmatesSkeleton.visitList(),
        isEmpty: (state) => state.items.isEmpty,
        empty: FlatmatesEmptyState(
          title: locale.emptyVisits,
          subtitle: locale.scheduleSubtitle,
          icon: Icons.calendar_today_rounded,
        ),
        onRetry: () =>
            ref.read(visitsListControllerProvider.notifier).refresh(),
        data: (state) {
          // Organize into timeline sections. Every status must land in
          // exactly one bucket so no visit silently disappears from the list.
          final items = state.items;
          final upcoming = items
              .where((v) => v.status == 'scheduled' || v.status == 'confirmed')
              .toList();
          final requested = items
              .where((v) => v.status == 'requested')
              .toList();
          const upcomingOrRequested = {'scheduled', 'confirmed', 'requested'};
          // Cancelled / completed / unknown statuses -> a single "Past" bucket.
          final past = items
              .where((v) => !upcomingOrRequested.contains(v.status))
              .toList();

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(visitsListControllerProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.screen,
                AppSpacing.screen,
                120,
              ),
              children: [
                FlatmatesSectionHeader(
                  title: locale.scheduleTitle,
                  subtitle: locale.scheduleSubtitle,
                ),
                const SizedBox(height: AppSpacing.lg),
                if (upcoming.isNotEmpty) ...[
                  _SectionHeader(title: locale.visitStatusConfirmed),
                  const SizedBox(height: AppSpacing.sm),
                  ...upcoming.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: VisitCard(
                        item: item,
                        locale: locale,
                        theme: theme,
                        busy: pending.contains(item.id),
                        badgeVariant: FlatmatesTrustBadgeVariant.verified,
                        onConfirm: () => _confirmVisit(item),
                        onCancel: () => _cancelVisit(item),
                        onReschedule: () => _rescheduleVisit(item),
                      ),
                    ),
                  ),
                ],
                if (requested.isNotEmpty) ...[
                  _SectionHeader(title: locale.visitStatusRequested),
                  const SizedBox(height: AppSpacing.sm),
                  ...requested.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: VisitCard(
                        item: item,
                        locale: locale,
                        theme: theme,
                        busy: pending.contains(item.id),
                        badgeVariant: FlatmatesTrustBadgeVariant.reviewed,
                        onConfirm: () => _confirmVisit(item),
                        onCancel: () => _cancelVisit(item),
                        onReschedule: () => _rescheduleVisit(item),
                      ),
                    ),
                  ),
                ],
                if (past.isNotEmpty) ...[
                  _SectionHeader(title: locale.visitStatusPast),
                  const SizedBox(height: AppSpacing.sm),
                  ...past.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: VisitCard(
                        item: item,
                        locale: locale,
                        theme: theme,
                        badgeVariant: FlatmatesTrustBadgeVariant.safe,
                      ),
                    ),
                  ),
                ],
                if (state.hasMore)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.lg,
                    ),
                    child: Center(
                      child: state.isLoadingMore
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : TextButton.icon(
                              onPressed: () => ref
                                  .read(visitsListControllerProvider.notifier)
                                  .loadMore(),
                              icon: const Icon(Icons.expand_more_rounded),
                              label: Text(locale.loadMoreCta),
                            ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Marks [id] as in-flight. Returns false if an action is already running
  /// for this visit (double-submit guard).
  bool _beginAction(int id) {
    final pending = ref.read(_pendingVisitActionsProvider);
    if (pending.contains(id)) return false;
    ref.read(_pendingVisitActionsProvider.notifier).state = {...pending, id};
    return true;
  }

  void _endAction(int id) {
    if (!mounted) return;
    final pending = ref.read(_pendingVisitActionsProvider);
    ref.read(_pendingVisitActionsProvider.notifier).state = {...pending}
      ..remove(id);
  }

  Future<void> _confirmVisit(VisitItem item) async {
    final locale = AppLocalizations.of(context);
    if (!_beginAction(item.id)) return;
    try {
      await ref.read(visitsActionsControllerProvider).confirm(item);
      if (!mounted) return;
      FlatmatesToast.success(context, locale.visitConfirmed);
    } catch (e) {
      debugPrint('VisitsPage._confirmVisit: $e');
      if (!mounted) return;
      final msg = e is AppFailure
          ? e.userMessage(locale.toUserMessageL10n())
          : locale.visitActionFailed;
      FlatmatesToast.error(context, msg);
    } finally {
      _endAction(item.id);
    }
  }

  Future<void> _cancelVisit(VisitItem item) async {
    final locale = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(locale.visitCancelCta),
        content: Text(locale.visitCancelConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(locale.cancelCta),
          ),
          FlatmatesButton(
            label: locale.visitCancelCta,
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (!_beginAction(item.id)) return;

    try {
      await ref.read(visitsActionsControllerProvider).cancel(item);
      if (!mounted) return;
      FlatmatesToast.success(context, locale.visitCancelled);
    } catch (e) {
      debugPrint('VisitsPage._cancelVisit: $e');
      if (!mounted) return;
      final msg = e is AppFailure
          ? e.userMessage(locale.toUserMessageL10n())
          : locale.visitActionFailed;
      FlatmatesToast.error(context, msg);
    } finally {
      _endAction(item.id);
    }
  }

  Future<void> _rescheduleVisit(VisitItem item) async {
    final locale = AppLocalizations.of(context);

    final now = DateTime.now();
    final scheduledLocal = item.scheduledDate.toLocal();
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
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(scheduledLocal),
    );
    if (time == null || !mounted) return;

    final newDate = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    // Reject a time in the past (date picker allows "today", time picker
    // allows any clock value, so the combination can land before now).
    if (!newDate.isAfter(DateTime.now())) {
      FlatmatesToast.error(context, locale.visitTimeInPast);
      return;
    }

    if (!_beginAction(item.id)) return;
    try {
      await ref.read(visitsActionsControllerProvider).reschedule(item, newDate);
      if (!mounted) return;
      FlatmatesToast.success(context, locale.visitRescheduled);
    } catch (e) {
      debugPrint('VisitsPage._rescheduleVisit: $e');
      if (!mounted) return;
      final msg = e is AppFailure
          ? e.userMessage(locale.toUserMessageL10n())
          : locale.visitActionFailed;
      FlatmatesToast.error(context, msg);
    } finally {
      _endAction(item.id);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppSemanticColors.textSecondaryFor(theme.brightness),
      ),
    );
  }
}
