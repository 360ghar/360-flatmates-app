import 'package:flutter/material.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'flatmates_card.dart';

/// Notification row. Unread rows are a raised paper-2 card (e2) with a clay
/// dot; read rows sit flat on paper-1, so unread reads as more prominent.
class FlatmatesNotificationCard extends StatelessWidget {
  const FlatmatesNotificationCard({
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    super.key,
    this.iconColor,
    this.isRead = false,
    this.unreadLabel,
    this.onTap,
  });

  final String title;
  final String body;
  final String time;
  final IconData icon;

  /// Defaults to clay.
  final Color? iconColor;
  final bool isRead;

  /// Screen-reader name of the unread dot (for example "Unread").
  final String? unreadLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    // At large text sizes the time moves under the text so the title keeps
    // the full width instead of breaking mid-word.
    final large = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    final timeText = Text(
      time,
      style: theme.textTheme.bodySmall?.copyWith(
        color: AppSemanticColors.textTertiaryFor(brightness),
      ),
    );
    final dot = isRead
        ? null
        : Semantics(
            label: unreadLabel,
            child: Container(
              width: AppSpacing.sm,
              height: AppSpacing.sm,
              decoration: BoxDecoration(
                color: AppSemanticColors.clayFor(brightness),
                shape: BoxShape.circle,
              ),
            ),
          );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screen,
        vertical: AppSpacing.xs,
      ),
      child: FlatmatesCard(
        onTap: onTap,
        bordered: !isRead,
        backgroundColor: isRead
            ? AppSemanticColors.paper1For(brightness)
            : null,
        padding: AppSpacing.edgeBase,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bare icon, no tile behind it (DESIGN.md §9).
            Icon(
              icon,
              size: 24,
              color: iconColor ?? AppSemanticColors.clayFor(brightness),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: isRead ? FontWeight.w500 : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    body,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppSemanticColors.textSecondaryFor(brightness),
                    ),
                    maxLines: large ? 3 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (large) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Flexible(child: timeText),
                        if (dot != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          dot,
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (!large) ...[
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  timeText,
                  if (dot != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    dot,
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
