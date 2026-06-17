import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_spacing.dart';
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
                child: const Icon(
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
          busy: busy,
        ),
        const SizedBox(width: AppSpacing.xs),
        _CompactActionChip(
          label: locale.visitCancelCta,
          onTap: onCancel,
          destructive: true,
          disabled: busy,
        ),
      ];
    }
    // scheduled / confirmed
    return [
      _CompactActionChip(
        label: locale.visitRescheduleCta,
        onTap: onReschedule,
        disabled: busy,
      ),
      const SizedBox(width: AppSpacing.xs),
      _CompactActionChip(
        label: locale.visitCancelCta,
        onTap: onCancel,
        destructive: true,
        disabled: busy,
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
    this.busy = false,
    this.disabled = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool filled;
  final bool destructive;

  /// Shows an inline spinner (the action this chip triggers is in flight).
  final bool busy;

  /// Greys out and ignores taps (another action on the same visit is busy).
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final accent = destructive
        ? AppSemanticColors.error
        : AppSemanticColors.accent;
    final inactive = busy || disabled;
    final effectiveAccent = inactive ? accent.withValues(alpha: 0.4) : accent;
    final foreground = filled ? Colors.white : effectiveAccent;

    return Expanded(
      child: Semantics(
        button: true,
        enabled: !inactive,
        label: label,
        child: GestureDetector(
          onTap: inactive ? null : onTap,
          child: Container(
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: filled ? effectiveAccent : null,
              border: filled
                  ? null
                  : Border.all(color: effectiveAccent.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: busy
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(foreground),
                    ),
                  )
                : Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: foreground,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
        ),
      ),
    );
  }
}
