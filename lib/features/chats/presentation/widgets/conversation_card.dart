import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/flatmates_card.dart';
import '../../../shared/presentation/flatmates_network_image.dart';
import '../../../shared/presentation/flatmates_ui.dart';
import '../../domain/chat_models.dart';

class ConversationCard extends StatelessWidget {
  const ConversationCard({
    required this.item,
    required this.onTap,
    super.key,
    this.highlightMode = false,
  });

  final ConversationSummaryModel item;
  final bool highlightMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final location = [
      if (item.peer.locality != null && item.peer.locality!.trim().isNotEmpty)
        item.peer.locality!.trim(),
      if (item.peer.city != null && item.peer.city!.trim().isNotEmpty)
        item.peer.city!.trim(),
    ].join(', ');
    final timestamp = item.lastMessageAt == null
        ? locale.chatReady
        : DateFormat(
            'd MMM, h:mm a',
            locale.localeName,
          ).format(item.lastMessageAt!.toLocal());

    return FlatmatesCard(
      onTap: onTap,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              highlightMode && item.peer.profileImageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(29),
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: FlatmatesAvatar(
                          name: item.peer.fullName,
                          imageUrl: item.peer.profileImageUrl,
                          size: 58,
                        ),
                      ),
                    )
                  : FlatmatesAvatar(
                      name: item.peer.fullName,
                      imageUrl: item.peer.profileImageUrl,
                      size: 58,
                    ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.peer.fullName,
                            style: theme.textTheme.titleLarge,
                          ),
                        ),
                        if (item.unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: AppSemanticColors.accent.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: AppRadius.pillBorder,
                            ),
                            child: Text(
                              '${item.unreadCount}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppSemanticColors.accent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (item.peer.mode != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        localizedFlatmatesModeLabel(locale, item.peer.mode!),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppSemanticColors.textSecondaryFor(
                            theme.brightness,
                          ),
                        ),
                      ),
                    ],
                    if (location.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: AppSemanticColors.textSecondaryFor(
                              theme.brightness,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              location,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (item.contextProperty != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppSemanticColors.secondarySurfaceFor(theme.brightness),
                borderRadius: AppRadius.sheetBorder,
              ),
              child: Row(
                children: [
                  if (item.contextProperty!.mainImageUrl != null)
                    FlatmatesNetworkImage(
                      imageUrl: item.contextProperty!.mainImageUrl!,
                      width: 76,
                      height: 76,
                      borderRadius: AppRadius.cardBorder,
                    )
                  else
                    _PropertyPreviewFallback(
                      title: item.contextProperty!.title,
                    ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.contextProperty!.title,
                          style: theme.textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        if (item.contextProperty!.monthlyRent != null)
                          Text(
                            locale.monthlyRentLabel(
                              item.contextProperty!.monthlyRent!
                                  .toStringAsFixed(0),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Text(
                  item.lastMessagePreview ?? locale.likesIncomingLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(timestamp, style: theme.textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          highlightMode
              ? FlatmatesButton(
                  label: locale.openConversationCta,
                  onPressed: onTap,
                  icon: Icons.chat_bubble_outline_rounded,
                )
              : Align(
                  alignment: Alignment.centerRight,
                  child: FlatmatesButton.tertiary(
                    label: locale.openConversationCta,
                    onPressed: onTap,
                  ),
                ),
        ],
      ),
    );
  }
}

class _PropertyPreviewFallback extends StatelessWidget {
  const _PropertyPreviewFallback({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 76,
      height: 76,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        borderRadius: AppRadius.cardBorder,
        gradient: LinearGradient(
          colors: [
            AppSemanticColors.accent.withValues(alpha: 0.9),
            AppSemanticColors.accent.withValues(alpha: 0.4),
          ],
        ),
      ),
      child: Center(
        child: Text(
          initialsFromName(title),
          style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}
