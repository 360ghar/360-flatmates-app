import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flatmates_app/core/widgets/location_selector.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/flatmates_ui.dart';

/// Header for the discover page with greeting, location, notification bell,
/// and user avatar.
class DiscoverHeader extends StatelessWidget {
  const DiscoverHeader({
    required this.greeting,
    required this.location,
    required this.avatarUrl,
    required this.userName,
    this.cityCounterLabel,
    this.onLocationTap,
    this.onNotificationTap,
    super.key,
  });

  final String greeting;
  final String location;
  final String? avatarUrl;
  final String? userName;
  final String? cityCounterLabel;
  final VoidCallback? onLocationTap;
  final VoidCallback? onNotificationTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting, style: theme.textTheme.headlineMedium),
              const SizedBox(height: 4),
              LocationSelector(
                displayText: location.isEmpty ? null : location,
                onTap: onLocationTap ?? () {},
              ),
              if (cityCounterLabel != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.people_outline_rounded,
                      size: 16,
                      color: AppSemanticColors.accent,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        cityCounterLabel!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppSemanticColors.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        IconButton.filledTonal(
          key: const Key('discover_notifications_button'),
          onPressed: onNotificationTap,
          tooltip: locale.notificationsTooltip,
          icon: const Icon(Icons.notifications_none_rounded),
        ),
        const SizedBox(width: 8),
        FlatmatesAvatar(name: userName, imageUrl: avatarUrl, size: 48),
      ],
    );
  }
}
