import 'package:flutter/material.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'flatmates_card.dart';

/// Notification list item card — matches screenshot #17 pattern.
/// Unread items get a left accent border + dot indicator.
class FlatmatesNotificationCard extends StatelessWidget {
  const FlatmatesNotificationCard({
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    super.key,
    this.isRead = false,
    this.onTap,
  });

  final String title;
  final String body;
  final String time;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
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
        backgroundColor: isRead
            ? null
            : AppSemanticColors.secondarySurfaceFor(brightness),
        padding: AppSpacing.edgeBase,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: iconColor),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: isRead ? FontWeight.w600 : FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    body,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                      height: 1.35,
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
              children: [
                Text(
                  time,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: AppSemanticColors.textTertiaryFor(brightness),
                  ),
                ),
                if (!isRead) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppSemanticColors.accent,
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
