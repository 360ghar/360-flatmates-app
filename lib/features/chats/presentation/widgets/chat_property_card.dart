import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/components.dart';
import '../../chats_repository.dart';

class ChatPropertyCard extends StatelessWidget {
  const ChatPropertyCard({
    required this.conversation,
    required this.onTap,
    super.key,
  });

  final ConversationSummaryModel conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    final property = conversation.contextProperty;

    if (property == null) return const SizedBox.shrink();

    return FlatmatesCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.cardBorder,
        child: Row(
          children: [
            _buildThumbnail(property, theme),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    property.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (property.ownerName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      locale.byOwnerLabel(property.ownerName!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppSemanticColors.textSecondaryFor(
                          theme.brightness,
                        ),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: AppSemanticColors.textTertiaryFor(theme.brightness),
            ),
          ],
        ),
      ),
    );
  }

  static const _thumbSize = 72.0;

  Widget _buildThumbnail(ChatPropertyContext property, ThemeData theme) {
    if (property.mainImageUrl != null && property.mainImageUrl!.isNotEmpty) {
      return FlatmatesNetworkImage(
        imageUrl: property.mainImageUrl!,
        width: _thumbSize,
        height: _thumbSize,
        borderRadius: BorderRadius.circular(AppRadius.md),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: SizedBox(
        width: _thumbSize,
        height: _thumbSize,
        child: Container(
          color: AppSemanticColors.accentSoft,
          child: Icon(
            Icons.home_rounded,
            color: AppSemanticColors.accent.withValues(alpha: 0.4),
            size: 28,
          ),
        ),
      ),
    );
  }
}
