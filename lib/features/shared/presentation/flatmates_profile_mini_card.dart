import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'flatmates_ui.dart';

/// Reusable person preview for likes, chat, flatmate references.
///
/// Compact row with avatar + name + metadata.
class FlatmatesProfileMiniCard extends StatelessWidget {
  const FlatmatesProfileMiniCard({
    required this.name,
    super.key,
    this.imageUrl,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.avatarSize = 44,
  });

  final String name;
  final String? imageUrl;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final double avatarSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitleColor = AppSemanticColors.textTertiaryFor(theme.brightness);

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.mdBorder,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.sm,
        ),
        child: Row(
          children: [
            FlatmatesAvatar(name: name, imageUrl: imageUrl, size: avatarSize),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: subtitleColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
