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
    this.onTap,
  });

  final String title;
  final String body;
  final String time;
  final IconData icon;

  /// Defaults to clay.
  final Color? iconColor;
  final bool isRead;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;

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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  time,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppSemanticColors.textTertiaryFor(brightness),
                  ),
                ),
                if (!isRead) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    width: AppSpacing.sm,
                    height: AppSpacing.sm,
                    decoration: BoxDecoration(
                      color: AppSemanticColors.clayFor(brightness),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
