import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flatmates_app/core/widgets/location_selector.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/flatmates_ui.dart';

class DiscoverHeader extends StatelessWidget {
  const DiscoverHeader({
    required this.greeting,
    required this.subtitle,
    required this.location,
    required this.avatarUrl,
    required this.userName,
    this.cityCounterLabel,
    this.onLocationTap,
    this.onNotificationTap,
    this.onAvatarTap,
    super.key,
  });

  final String greeting;
  final String subtitle;
  final String location;
  final String? avatarUrl;
  final String? userName;
  final String? cityCounterLabel;
  final VoidCallback? onLocationTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            LocationSelector(
              displayText: location.isEmpty ? null : location,
              onTap: onLocationTap,
            ),
            const Spacer(),
            IconButton.filledTonal(
              key: const Key('discover_notifications_button'),
              onPressed: onNotificationTap,
              tooltip: locale.notificationsTooltip,
              icon: const Icon(Icons.notifications_none_rounded),
              iconSize: 20,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onAvatarTap,
              child: FlatmatesAvatar(
                name: userName,
                imageUrl: avatarUrl,
                size: 40,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          greeting,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppSemanticColors.textPrimaryFor(theme.brightness),
            fontWeight: FontWeight.w800,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppSemanticColors.textSecondaryFor(theme.brightness),
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (cityCounterLabel != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.people_outline_rounded,
                size: 14,
                color: AppSemanticColors.accent,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  cityCounterLabel!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppSemanticColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
