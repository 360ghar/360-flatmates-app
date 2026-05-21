import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../shared/presentation/flatmates_async_view.dart';
import '../shared/presentation/flatmates_card.dart';
import '../shared/presentation/flatmates_empty_state.dart';
import '../shared/presentation/flatmates_header.dart';
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
      appBar: FlatmatesHeader.backTitle(title: locale.scheduleTitle),
      body: FlatmatesAsyncView<List<VisitItem>>(
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
                  const SizedBox(height: AppSpacing.lg),
                  if (upcoming.isNotEmpty) ...[
                    _SectionHeader(title: locale.visitStatusConfirmed),
                    const SizedBox(height: AppSpacing.sm),
                    ...upcoming.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
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
                    const SizedBox(height: AppSpacing.sm),
                    ...requested.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
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
                    const SizedBox(height: AppSpacing.sm),
                    ...completed.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
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
      style: theme.textTheme.titleSmall?.copyWith(
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

  @override
  Widget build(BuildContext context) {
    final hasActions =
        item.status == 'requested' ||
        item.status == 'scheduled' ||
        item.status == 'confirmed';

    return FlatmatesCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppSemanticColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.event_available_outlined,
                  color: AppSemanticColors.accent,
                  size: 16,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.propertyTitle,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppSemanticColors.textPrimaryFor(
                          theme.brightness,
                        ),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      DateFormat(
                        'd MMM, h:mm a',
                        locale.localeName,
                      ).format(item.scheduledDate.toLocal()),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: AppSemanticColors.textTertiaryFor(
                          theme.brightness,
                        ),
                      ),
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
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                item.visitContext == 'flatmate_meet'
                    ? Icons.people_outline
                    : Icons.meeting_room_outlined,
                size: 12,
                color: AppSemanticColors.textTertiaryFor(theme.brightness),
              ),
              const SizedBox(width: 4),
              Text(
                item.visitContext == 'flatmate_meet'
                    ? locale.flatmateMeetLabel
                    : locale.propertyTourLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: AppSemanticColors.textTertiaryFor(theme.brightness),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.calendar_month_outlined,
                size: 12,
                color: AppSemanticColors.textTertiaryFor(theme.brightness),
              ),
              const SizedBox(width: 4),
              Text(
                DateFormat(
                  'EEEE',
                  locale.localeName,
                ).format(item.scheduledDate.toLocal()),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: AppSemanticColors.textTertiaryFor(theme.brightness),
                ),
              ),
            ],
          ),
          if (hasActions) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(children: _buildActions(context)),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    if (item.status == 'requested') {
      return [
        _CompactActionChip(
          label: locale.visitConfirmTitle,
          onTap: onConfirm,
          filled: true,
        ),
        const SizedBox(width: AppSpacing.xs),
        _CompactActionChip(
          label: locale.visitCancelCta,
          onTap: onCancel,
          destructive: true,
        ),
      ];
    }
    // scheduled / confirmed
    return [
      _CompactActionChip(label: locale.visitRescheduleCta, onTap: onReschedule),
      const SizedBox(width: AppSpacing.xs),
      _CompactActionChip(
        label: locale.visitCancelCta,
        onTap: onCancel,
        destructive: true,
      ),
    ];
  }
}

/// Tiny action chip for visit cards — avoids FlatmatesButton's 40dp minimum.
class _CompactActionChip extends StatelessWidget {
  const _CompactActionChip({
    required this.label,
    this.onTap,
    this.filled = false,
    this.destructive = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool filled;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final accent = destructive
        ? AppSemanticColors.error
        : AppSemanticColors.accent;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: filled ? accent : null,
            border: filled
                ? null
                : Border.all(color: accent.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: filled ? Colors.white : accent,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
