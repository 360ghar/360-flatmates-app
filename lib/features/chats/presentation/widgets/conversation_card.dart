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

const double _avatarSize = 44;
const double _avatarRadius = _avatarSize / 2;
const double _privacyBlurSigma = 8;
const double _propertyPreviewSize = 40;
const double _locationIconSize = 13;
const double _inlineGap = 2;

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
        ? ''
        : DateFormat(
            'd MMM, h:mm a',
            locale.localeName,
          ).format(item.lastMessageAt!.toLocal());

    return FlatmatesCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          highlightMode && item.peer.profileImageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(_avatarRadius),
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(
                      sigmaX: _privacyBlurSigma,
                      sigmaY: _privacyBlurSigma,
                    ),
                    child: FlatmatesAvatar(
                      name: item.peer.fullName,
                      imageUrl: item.peer.profileImageUrl,
                      size: _avatarSize,
                    ),
                  ),
                )
              : FlatmatesAvatar(
                  name: item.peer.fullName,
                  imageUrl: item.peer.profileImageUrl,
                  size: _avatarSize,
                ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Accent dot for unread threads — improves scannability.
                    if (item.unreadCount > 0) ...[
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppSemanticColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Expanded(
                      child: Text(
                        item.peer.fullName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: item.unreadCount > 0
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: item.unreadCount > 0
                              ? AppSemanticColors.textPrimaryFor(
                                  theme.brightness,
                                )
                              : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: const BoxDecoration(
                          color: AppSemanticColors.accent,
                          borderRadius: AppRadius.pillBorder,
                        ),
                        child: Text(
                          '${item.unreadCount}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    if (timestamp.isNotEmpty) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        timestamp,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppSemanticColors.textSecondaryFor(
                            theme.brightness,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (item.peer.mode != null) ...[
                  const SizedBox(height: _inlineGap),
                  Text(
                    localizedFlatmatesModeLabel(locale, item.peer.mode!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppSemanticColors.textSecondaryFor(
                        theme.brightness,
                      ),
                    ),
                  ),
                ],
                if (location.isNotEmpty) ...[
                  const SizedBox(height: _inlineGap),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: _locationIconSize,
                        color: AppSemanticColors.textSecondaryFor(
                          theme.brightness,
                        ),
                      ),
                      const SizedBox(width: _inlineGap),
                      Expanded(
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppSemanticColors.textSecondaryFor(
                              theme.brightness,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (item.lastMessagePreview != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    item.lastMessagePreview!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppSemanticColors.textSecondaryFor(
                        theme.brightness,
                      ),
                    ),
                  ),
                ],
                if (item.contextProperty != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppSemanticColors.secondarySurfaceFor(
                        theme.brightness,
                      ),
                      borderRadius: AppRadius.sheetBorder,
                    ),
                    child: Row(
                      children: [
                        if (item.contextProperty!.mainImageUrl != null)
                          FlatmatesNetworkImage(
                            imageUrl: item.contextProperty!.mainImageUrl!,
                            width: _propertyPreviewSize,
                            height: _propertyPreviewSize,
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
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (item.contextProperty!.monthlyRent != null)
                                Text(
                                  locale.monthlyRentLabel(
                                    item.contextProperty!.monthlyRent!
                                        .toStringAsFixed(0),
                                  ),
                                  style: theme.textTheme.bodySmall,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
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
      width: _propertyPreviewSize,
      height: _propertyPreviewSize,
      padding: const EdgeInsets.all(AppSpacing.xs),
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
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
