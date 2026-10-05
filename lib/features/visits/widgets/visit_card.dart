import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/theme.dart';
import 'package:intl/intl.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../shared/presentation/flatmates_card.dart';
import '../../shared/presentation/flatmates_trust_badge.dart';
import '../../shared/presentation/flatmates_ui.dart';
import '../visits_repository.dart';

/// A single visit row used by the visits list. Renders the property, schedule
/// time, context and status, plus inline confirm / reschedule / cancel actions
/// for actionable statuses.
class VisitCard extends StatelessWidget {
  const VisitCard({
    required this.item,
    required this.locale,
    required this.theme,
    required this.badgeVariant,
    this.busy = false,
    this.onConfirm,
    this.onCancel,
    this.onReschedule,
    super.key,
  });

  final VisitItem item;
  final AppLocalizations locale;
  final ThemeData theme;
  final FlatmatesTrustBadgeVariant badgeVariant;

  /// True while an action for this visit is in flight (shows a spinner on the
  /// triggering chip and disables the rest).
  final bool busy;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final VoidCallback? onReschedule;

  @override
  Widget build(BuildContext context) {
    final b = theme.brightness;
    // Only cards that were given handlers get actions: a past visit keeps
    // its "confirmed" status but can no longer be changed.
    final hasActions =
        onCancel != null &&
        (item.status == 'requested' ||
            item.status == 'reschedule_suggested' ||
            item.status == 'confirmed');
    final meta = theme.textTheme.bodySmall?.copyWith(
      color: AppSemanticColors.textSecondaryFor(b),
    );
    final local = item.scheduledDate.toLocal();
    final isMeet = item.visitContext == 'flatmate_meet';

    return FlatmatesCard(
      backgroundColor: AppSemanticColors.surfaceFor(b),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.md,
        AppSpacing.base,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.propertyTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppSemanticColors.textPrimaryFor(b),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Flexible: at large text sizes the status ellipsizes instead
              // of pushing the row past its width.
              Flexible(
                child: FlatmatesTrustBadge(
                  variant: badgeVariant,
                  label: localizedFlatmatesVisitStatusLabel(
                    locale,
                    item.status,
                  ),
                  compact: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            DateFormat('EEEE d MMM, h:mm a', locale.localeName).format(local),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppSemanticColors.textPrimaryFor(b),
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Row(
            children: [
              Icon(
                isMeet ? Icons.people_outline : Icons.meeting_room_outlined,
                size: 16,
                color: AppSemanticColors.textSecondaryFor(b),
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  isMeet ? locale.flatmateMeetLabel : locale.propertyTourLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: meta,
                ),
              ),
            ],
          ),
          if (hasActions) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: _buildActions(),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildActions() {
    final cancel = FlatmatesButton.tertiary(
      label: locale.visitCancelCta,
      destructive: true,
      onPressed: busy ? null : onCancel,
    );
    // requested / reschedule_suggested: the counterparty confirms or cancels.
    if (item.status == 'requested' || item.status == 'reschedule_suggested') {
      return [
        FlatmatesButton(
          label: locale.visitConfirmCta,
          onPressed: busy ? null : onConfirm,
        ),
        cancel,
      ];
    }
    // confirmed: suggest a new time, or cancel.
    return [
      FlatmatesButton.secondary(
        label: locale.visitRescheduleCta,
        onPressed: busy ? null : onReschedule,
      ),
      cancel,
    ];
  }
}
