import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'flatmates_network_image.dart';

/// Reusable listing preview card for chat, visits, map, manage.
///
/// Displays thumbnail + title + price + locality in a compact row.
class FlatmatesListingMiniCard extends StatelessWidget {
  const FlatmatesListingMiniCard({
    required this.title,
    required this.rent,
    super.key,
    this.imageUrl,
    this.locality,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.compact = false,
  });

  final String title;
  final int rent;
  final String? imageUrl;
  final String? locality;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondaryColor = AppSemanticColors.textSecondaryFor(theme.brightness);
    final thumbSize = compact ? 56.0 : 88.0;

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.cardBorder,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          if (imageUrl != null && imageUrl!.isNotEmpty)
            FlatmatesNetworkImage(
              imageUrl: imageUrl!,
              width: thumbSize,
              height: thumbSize,
              borderRadius: BorderRadius.circular(AppRadius.md),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: SizedBox(
                width: thumbSize,
                height: thumbSize,
                child: _placeholder(),
              ),
            ),
          const SizedBox(width: AppSpacing.md),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: compact ? 14 : 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: secondaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (locality != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: secondaryColor,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          locality!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: secondaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Trailing
          ?trailing,
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Builder(
      builder: (context) {
        final brightness = Theme.of(context).brightness;
        return Container(
          color: AppSemanticColors.coralSoftFor(brightness),
          child: Icon(
            Icons.home_rounded,
            color: AppSemanticColors.accent.withValues(alpha: 0.4),
            size: compact ? 24 : 32,
          ),
        );
      },
    );
  }
}
