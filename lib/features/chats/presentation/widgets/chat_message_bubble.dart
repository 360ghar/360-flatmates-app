import 'package:flutter/material.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/flatmates_card.dart';
import '../../../shared/presentation/flatmates_network_image.dart';
import '../../../shared/presentation/flatmates_trust_badge.dart';
import '../../../shared/presentation/flatmates_ui.dart';
import '../../../visits/visits_repository.dart';
import '../../chats_repository.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    required this.message,
    required this.isMine,
    required this.peerName,
    required this.peerImageUrl,
    super.key,
    this.visit,
    this.onConfirmVisit,
    this.onRescheduleVisit,
  });

  final ChatMessage message;
  final bool isMine;
  final String? peerName;
  final String? peerImageUrl;
  final VisitItem? visit;
  final ValueChanged<VisitItem>? onConfirmVisit;
  final ValueChanged<VisitItem>? onRescheduleVisit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    final time = messageTimestamp(locale, message.createdAt);

    if (message.messageType == 'visit_request') {
      return _VisitRequestCard(
        message: message,
        isMine: isMine,
        peerName: peerName,
        peerImageUrl: peerImageUrl,
        visit: visit,
        onConfirmVisit: onConfirmVisit,
        onRescheduleVisit: onRescheduleVisit,
        time: time,
      );
    }

    // Bubbles take at most 75 % of the screen and shrink with the row, so
    // a long message never overflows a narrow phone.
    final maxBubble = MediaQuery.sizeOf(context).width * 0.75;

    if (message.messageType == 'image' && message.attachmentUrl != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.base),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: isMine
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            if (!isMine) ...[
              FlatmatesAvatar(name: peerName, imageUrl: peerImageUrl, size: 40),
              const SizedBox(width: AppSpacing.sm),
            ],
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxBubble * 0.8),
                child: Column(
                  crossAxisAlignment: isMine
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    // Fixed aspect so the list does not jump when it loads.
                    Semantics(
                      image: true,
                      label: locale.messageAttachment,
                      child: AspectRatio(
                        aspectRatio: 4 / 3,
                        child: FlatmatesNetworkImage(
                          imageUrl: message.attachmentUrl!,
                          fit: BoxFit.cover,
                          borderRadius: AppRadius.lgBorder,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _MessageMeta(message: message, isMine: isMine, time: time),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.base),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isMine) ...[
            FlatmatesAvatar(name: peerName, imageUrl: peerImageUrl, size: 32),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxBubble),
              child: Column(
                crossAxisAlignment: isMine
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: isMine
                          ? AppSemanticColors.clayFor(theme.brightness)
                          : AppSemanticColors.paperDeepFor(theme.brightness),
                      borderRadius: AppRadius.lgBorder,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      child: Text(
                        message.body ??
                            AppLocalizations.of(context).messageAttachment,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: isMine
                              ? AppSemanticColors.onClayFor(theme.brightness)
                              : AppSemanticColors.textPrimaryFor(
                                  theme.brightness,
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _MessageMeta(message: message, isMine: isMine, time: time),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitRequestCard extends StatelessWidget {
  const _VisitRequestCard({
    required this.message,
    required this.isMine,
    required this.peerName,
    required this.peerImageUrl,
    required this.time,
    this.visit,
    this.onConfirmVisit,
    this.onRescheduleVisit,
  });

  final ChatMessage message;
  final bool isMine;
  final String? peerName;
  final String? peerImageUrl;
  final VisitItem? visit;
  final ValueChanged<VisitItem>? onConfirmVisit;
  final ValueChanged<VisitItem>? onRescheduleVisit;
  final String time;

  /// Derive visit status from the live visit row, message metadata, or body.
  String get _status {
    final visitStatus = visit?.status;
    if (visitStatus != null && visitStatus.isNotEmpty) return visitStatus;
    final metadataStatus = message.visitStatus;
    if (metadataStatus != null && metadataStatus.isNotEmpty) {
      return metadataStatus;
    }
    final body = message.body?.toLowerCase() ?? '';
    if (body.contains('confirmed')) return 'confirmed';
    if (body.contains('cancelled') || body.contains('canceled')) {
      return 'cancelled';
    }
    // Backend wire default for a new visit request.
    return 'requested';
  }

  Color _statusColor(String status, Brightness brightness) {
    switch (status) {
      case 'confirmed':
        return AppSemanticColors.pineFor(brightness);
      case 'cancelled':
        return AppSemanticColors.dangerFor(brightness);
      default:
        return AppSemanticColors.warningInkFor(brightness);
    }
  }

  Color _statusBgColor(String status, Brightness brightness) {
    // Dark-aware semantic soft backgrounds so the strip clears a real value
    // gap against textPrimaryFor(brightness) in BOTH themes. The legacy
    // light-only tokens (warningBg #F7F7F7, errorBg #FFD1DA, greenSoft) sat
    // light in dark mode while the text flipped to darkInk #F7F7F7 — the
    // requested/reschedule date rendered byte-identical (1:1 contrast).
    switch (status) {
      case 'confirmed':
        return AppSemanticColors.greenSoftFor(brightness);
      case 'cancelled':
        return AppSemanticColors.errorSoftFor(brightness);
      default:
        return AppSemanticColors.warningSoftFor(brightness);
    }
  }

  FlatmatesTrustBadgeVariant _badgeVariant(String status) {
    switch (status) {
      case 'confirmed':
        return FlatmatesTrustBadgeVariant.verified;
      case 'cancelled':
        return FlatmatesTrustBadgeVariant.safe;
      default:
        return FlatmatesTrustBadgeVariant.reviewed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    final status = _status;
    final statusColor = _statusColor(status, theme.brightness);
    final statusBg = _statusBgColor(status, theme.brightness);
    final scheduledDate = visit?.scheduledDate ?? message.visitScheduledDate;
    final scheduleText = scheduledDate == null
        ? message.body ?? locale.visitRequested
        : messageTimestamp(locale, scheduledDate);
    // Respond only while the visit still needs counterparty action.
    // Wire values: requested | reschedule_suggested (not legacy scheduled/rescheduled).
    final canRespond =
        !isMine &&
        visit != null &&
        onConfirmVisit != null &&
        onRescheduleVisit != null &&
        (status == 'requested' || status == 'reschedule_suggested');

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.base),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isMine) ...[
            FlatmatesAvatar(name: peerName, imageUrl: peerImageUrl, size: 40),
            const SizedBox(width: AppSpacing.sm),
          ],
          // Status shows in the icon, title and badge: no accent stripe.
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.8,
              ),
              child: FlatmatesCard(
                margin: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.event_available_rounded,
                          size: 20,
                          color: statusColor,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            locale.scheduleVisitCta,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: AppRadius.mdBorder,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 16,
                            color: statusColor,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              scheduleText,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppSemanticColors.textPrimaryFor(
                                  theme.brightness,
                                ),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (canRespond) ...[
                      const SizedBox(height: AppSpacing.md),
                      _VisitResponseActions(
                        confirmLabel: locale.visitConfirmCta,
                        rescheduleLabel: locale.visitRescheduleCta,
                        onConfirm: () => onConfirmVisit?.call(visit!),
                        onReschedule: () => onRescheduleVisit?.call(visit!),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    // Wrap: badge and time share a row when they fit.
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        FlatmatesTrustBadge(
                          label: status == 'confirmed'
                              ? locale.visitStatusConfirmed
                              : status == 'cancelled'
                              ? locale.visitStatusCancelled
                              : status == 'completed'
                              ? locale.visitStatusCompleted
                              : status == 'requested' ||
                                    status == 'reschedule_suggested'
                              ? locale.visitStatusRequested
                              : locale.visitStatusScheduled,
                          variant: _badgeVariant(status),
                          compact: true,
                        ),
                        _MessageMeta(
                          message: message,
                          isMine: isMine,
                          time: time,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Confirm / reschedule pair for a visit request.
///
/// Side by side when both labels still fit inside the two lines
/// [FlatmatesButton] renders before ellipsizing; stacked when they do not
/// ("Suggest another time" on a 320 dp phone). The decision is measured from
/// the labels, the current text scale and the button style's own horizontal
/// padding — not a fixed breakpoint.
class _VisitResponseActions extends StatelessWidget {
  const _VisitResponseActions({
    required this.confirmLabel,
    required this.rescheduleLabel,
    required this.onConfirm,
    required this.onReschedule,
  });

  final String confirmLabel;
  final String rescheduleLabel;
  final VoidCallback onConfirm;
  final VoidCallback onReschedule;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final confirm = FlatmatesButton(
          label: confirmLabel,
          onPressed: onConfirm,
          fullWidth: true,
        );
        final reschedule = FlatmatesButton.secondary(
          label: rescheduleLabel,
          onPressed: onReschedule,
          fullWidth: true,
        );

        if (!_fitsSideBySide(context, constraints.maxWidth)) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              confirm,
              const SizedBox(height: AppSpacing.sm),
              reschedule,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: confirm),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: reschedule),
          ],
        );
      },
    );
  }

  bool _fitsSideBySide(BuildContext context, double available) {
    final perButton = (available - AppSpacing.sm) / 2;
    final labelWidth = perButton - _buttonChromeWidth(context);
    if (labelWidth <= 0) return false;

    final style = Theme.of(context).textTheme.labelLarge;
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    return [confirmLabel, rescheduleLabel].every((label) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: style),
        textDirection: direction,
        textScaler: scaler,
        maxLines: 2,
      )..layout(maxWidth: labelWidth);
      return !painter.didExceedMaxLines;
    });
  }

  /// Horizontal space the button style keeps around its label. The app theme
  /// sets it (24 each side, `app_theme.dart`); the fallback mirrors that so a
  /// missing theme entry cannot keep the pair side by side when the labels
  /// need stacking.
  double _buttonChromeWidth(BuildContext context) {
    final padding = Theme.of(
      context,
    ).filledButtonTheme.style?.padding?.resolve(const <WidgetState>{});
    return padding?.horizontal ?? 2 * AppSpacing.lg;
  }
}

class _MessageMeta extends StatelessWidget {
  const _MessageMeta({
    required this.message,
    required this.isMine,
    required this.time,
  });

  final ChatMessage message;
  final bool isMine;
  final String time;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    // Optimistic bubbles (negative ids) are not yet confirmed by the backend,
    // so they must show "Sending…" rather than a false "Sent" receipt.
    final isPending = message.id < 0;
    final isRead = message.readAt != null;
    final receipt = isPending
        ? locale.sendingLabel
        : isRead
        ? locale.readReceiptRead
        : locale.readReceiptSent;
    final receiptColor = isRead
        ? AppSemanticColors.clayFor(theme.brightness)
        : AppSemanticColors.textSecondaryFor(theme.brightness);
    final receiptIcon = isPending
        ? Icons.schedule_rounded
        : isRead
        ? Icons.done_all_rounded
        : Icons.done_rounded;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          time,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppSemanticColors.textSecondaryFor(theme.brightness),
          ),
        ),
        if (isMine) ...[
          const SizedBox(width: AppSpacing.sm),
          Icon(receiptIcon, size: 14, color: receiptColor),
          const SizedBox(width: AppSpacing.xs),
          Text(
            receipt,
            style: theme.textTheme.bodySmall?.copyWith(
              color: receiptColor,
              fontWeight: isRead ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
