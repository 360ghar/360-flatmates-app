import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_semantic_colors.dart';
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
    final time = DateFormat(
      'h:mm a',
      locale.localeName,
    ).format(message.createdAt.toLocal());

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

    if (message.messageType == 'image' && message.attachmentUrl != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: isMine
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            if (!isMine) ...[
              FlatmatesAvatar(name: peerName, imageUrl: peerImageUrl, size: 40),
              const SizedBox(width: 10),
            ],
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: Column(
                crossAxisAlignment: isMine
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  FlatmatesNetworkImage(
                    imageUrl: message.attachmentUrl!,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _MessageMeta(message: message, isMine: isMine, time: time),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 290),
            child: Column(
              crossAxisAlignment: isMine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: isMine
                        ? AppSemanticColors.accent
                        : AppSemanticColors.disabledSurfaceFor(
                            theme.brightness,
                          ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                    child: Text(
                      message.body ??
                          AppLocalizations.of(context).messageAttachment,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: isMine
                            ? Colors.white
                            : AppSemanticColors.textPrimaryFor(
                                theme.brightness,
                              ),
                        height: 1.45,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                _MessageMeta(message: message, isMine: isMine, time: time),
              ],
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
    return 'scheduled';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return AppSemanticColors.success;
      case 'cancelled':
        return AppSemanticColors.error;
      default:
        return AppSemanticColors.warning;
    }
  }

  Color _statusBgColor(String status) {
    switch (status) {
      case 'confirmed':
        return AppSemanticColors.greenSoft;
      case 'cancelled':
        return AppSemanticColors.errorBg;
      default:
        return AppSemanticColors.warningBg;
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
    final statusColor = _statusColor(status);
    final statusBg = _statusBgColor(status);
    final scheduledDate = visit?.scheduledDate ?? message.visitScheduledDate;
    final scheduleText = scheduledDate == null
        ? message.body ?? locale.visitRequested
        : DateFormat(
            'd MMM, h:mm a',
            locale.localeName,
          ).format(scheduledDate.toLocal());
    final canRespond =
        !isMine &&
        visit != null &&
        onConfirmVisit != null &&
        onRescheduleVisit != null &&
        (status == 'scheduled' || status == 'rescheduled');

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isMine) ...[
            FlatmatesAvatar(name: peerName, imageUrl: peerImageUrl, size: 40),
            const SizedBox(width: 10),
          ],
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 270),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border(left: BorderSide(color: statusColor, width: 4)),
              ),
              child: FlatmatesCard(
                margin: EdgeInsets.zero,
                borderRadius: BorderRadius.circular(18),
                borderColor: statusColor.withValues(alpha: 0.3),
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
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(12),
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
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: () => onConfirmVisit?.call(visit!),
                              child: Text(locale.visitConfirmCta),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => onRescheduleVisit?.call(visit!),
                              child: Text(locale.visitRescheduleCta),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        FlatmatesTrustBadge(
                          label: status == 'confirmed'
                              ? locale.visitStatusConfirmed
                              : status == 'cancelled'
                              ? locale.visitStatusCancelled
                              : status == 'scheduled' || status == 'rescheduled'
                              ? locale.visitStatusScheduled
                              : locale.visitStatusRequested,
                          variant: _badgeVariant(status),
                          compact: true,
                        ),
                        const Spacer(),
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
        ? AppSemanticColors.accent
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
            fontSize: 11,
            color: AppSemanticColors.textSecondaryFor(theme.brightness),
          ),
        ),
        if (isMine) ...[
          const SizedBox(width: 6),
          Icon(receiptIcon, size: 14, color: receiptColor),
          const SizedBox(width: 3),
          Text(
            receipt,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: receiptColor,
              fontWeight: isRead ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
