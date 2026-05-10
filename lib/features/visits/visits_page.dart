import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../shared/presentation/flatmates_async_view.dart';
import '../shared/presentation/flatmates_card.dart';
import '../shared/presentation/flatmates_empty_state.dart';
import '../shared/presentation/flatmates_trust_badge.dart';
import '../shared/presentation/flatmates_ui.dart';
import 'visits_repository.dart';

class VisitsPage extends ConsumerStatefulWidget {
  const VisitsPage({super.key});

  @override
  ConsumerState<VisitsPage> createState() => _VisitsPageState();
}

class _VisitsPageState extends ConsumerState<VisitsPage> {
  @override
  Widget build(BuildContext context) {
    final visits = ref.watch(visitsProvider);
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: FlatmatesAsyncView<List<VisitItem>>(
          value: visits,
          empty: FlatmatesEmptyState(
            title: locale.emptyVisits,
            subtitle: locale.scheduleSubtitle,
            icon: Icons.calendar_today_rounded,
          ),
          onRetry: () => ref.invalidate(visitsProvider),
          data: (items) {
            // Organize into timeline sections
            final upcoming = items
                .where(
                  (v) => v.status == 'scheduled' || v.status == 'confirmed',
                )
                .toList();
            final requested = items
                .where((v) => v.status == 'requested')
                .toList();
            final completed = items
                .where((v) => v.status == 'completed')
                .toList();

            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(visitsProvider),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.screen,
                  AppSpacing.xl,
                  120,
                ),
                children: [
                  FlatmatesSectionHeader(
                    title: locale.scheduleTitle,
                    subtitle: locale.scheduleSubtitle,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (upcoming.isNotEmpty) ...[
                    _SectionHeader(title: locale.visitStatusConfirmed),
                    const SizedBox(height: AppSpacing.md),
                    ...upcoming.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                        child: _VisitCard(
                          item: item,
                          locale: locale,
                          theme: theme,
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
                    const SizedBox(height: AppSpacing.md),
                    ...requested.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                        child: _VisitCard(
                          item: item,
                          locale: locale,
                          theme: theme,
                          badgeVariant: FlatmatesTrustBadgeVariant.reviewed,
                          onConfirm: () => _confirmVisit(item),
                          onCancel: () => _cancelVisit(item),
                          onReschedule: () => _rescheduleVisit(item),
                        ),
                      ),
                    ),
                  ],
                  if (completed.isNotEmpty) ...[
                    _SectionHeader(title: locale.visitStatusCompleted),
                    const SizedBox(height: AppSpacing.md),
                    ...completed.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                        child: _VisitCard(
                          item: item,
                          locale: locale,
                          theme: theme,
                          badgeVariant: FlatmatesTrustBadgeVariant.safe,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmVisit(VisitItem item) async {
    final locale = AppLocalizations.of(context);
    try {
      await ref.read(visitsRepositoryProvider).confirmVisit(item.id);
      ref.invalidate(visitsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(locale.visitConfirmed)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(locale.visitActionFailed)));
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

    try {
      await ref.read(visitsRepositoryProvider).cancelVisit(item.id);
      ref.invalidate(visitsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(locale.visitCancelled)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(locale.visitActionFailed)));
    }
  }

  Future<void> _rescheduleVisit(VisitItem item) async {
    final locale = AppLocalizations.of(context);

    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      initialDate: item.scheduledDate.isAfter(DateTime.now())
          ? item.scheduledDate
          : DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;

    final now = DateTime.now();
    final scheduledTime = item.scheduledDate.toLocal();
    final initialTime = TimeOfDay(
      hour: scheduledTime.hour >= 0 && scheduledTime.hour < 24
          ? scheduledTime.hour
          : now.hour,
      minute: scheduledTime.minute >= 0 && scheduledTime.minute < 60
          ? scheduledTime.minute
          : 0,
    );

    final time = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (time == null || !mounted) return;

    final newDate = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    try {
      await ref
          .read(visitsRepositoryProvider)
          .rescheduleVisit(item.id, newDate);
      ref.invalidate(visitsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(locale.visitRescheduleCta)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(locale.visitActionFailed)));
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
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppSemanticColors.textSecondaryFor(theme.brightness),
      ),
    );
  }
}

class _VisitCard extends StatelessWidget {
  const _VisitCard({
    required this.item,
    required this.locale,
    required this.theme,
    required this.badgeVariant,
    this.onConfirm,
    this.onCancel,
    this.onReschedule,
  });

  final VisitItem item;
  final AppLocalizations locale;
  final ThemeData theme;
  final FlatmatesTrustBadgeVariant badgeVariant;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final VoidCallback? onReschedule;

  bool _hasActions(String status) {
    return status == 'requested' ||
        status == 'scheduled' ||
        status == 'confirmed';
  }

  @override
  Widget build(BuildContext context) {
    return FlatmatesCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppSemanticColors.accent,
                      AppSemanticColors.accent.withValues(alpha: 0.55),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.event_available_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.propertyTitle, style: theme.textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      DateFormat(
                        'd MMM yyyy, h:mm a',
                        locale.localeName,
                      ).format(item.scheduledDate.toLocal()),
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              FlatmatesTrustBadge(
                variant: badgeVariant,
                label: localizedFlatmatesVisitStatusLabel(locale, item.status),
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              InfoPill(
                icon: Icons.meeting_room_outlined,
                label: item.visitContext == 'flatmate_meet'
                    ? locale.flatmateMeetLabel
                    : locale.propertyTourLabel,
              ),
              InfoPill(
                icon: Icons.calendar_month_outlined,
                label: DateFormat(
                  'EEEE',
                  locale.localeName,
                ).format(item.scheduledDate.toLocal()),
              ),
            ],
          ),
          if (_hasActions(item.status)) ...[
            const SizedBox(height: AppSpacing.md),
            Row(children: _buildActions()),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildActions() {
    final actions = <Widget>[];

    if (item.status == 'requested') {
      if (onConfirm != null) {
        actions.add(
          Expanded(
            child: FlatmatesButton(
              key: const Key('visit_confirm_button'),
              label: locale.visitConfirmTitle,
              onPressed: onConfirm,
            ),
          ),
        );
      }
      actions.add(const SizedBox(width: AppSpacing.sm));
      if (onCancel != null) {
        actions.add(
          Expanded(
            child: FlatmatesButton.secondary(
              key: const Key('visit_cancel_button'),
              label: locale.visitCancelCta,
              onPressed: onCancel,
              destructive: true,
              height: 36,
            ),
          ),
        );
      }
    } else if (item.status == 'scheduled' || item.status == 'confirmed') {
      if (onReschedule != null) {
        actions.add(
          Expanded(
            child: FlatmatesButton.secondary(
              key: const Key('visit_reschedule_button'),
              label: locale.visitRescheduleCta,
              onPressed: onReschedule,
              height: 36,
            ),
          ),
        );
      }
      actions.add(const SizedBox(width: AppSpacing.sm));
      if (onCancel != null) {
        actions.add(
          Expanded(
            child: FlatmatesButton.secondary(
              key: const Key('visit_cancel_button'),
              label: locale.visitCancelCta,
              onPressed: onCancel,
              destructive: true,
              height: 36,
            ),
          ),
        );
      }
    }

    return actions;
  }
}
