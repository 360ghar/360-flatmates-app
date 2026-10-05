import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/flatmates_card.dart';
import '../../../shared/presentation/flatmates_network_image.dart';
import '../../../shared/presentation/flatmates_price_text.dart';
import '../../../shared/presentation/flatmates_ui.dart';
import '../../domain/chat_models.dart';

const double _avatarSize = 44;
const double _privacyBlurSigma = 8;
const double _propertyPreviewSize = 40;
const double _locationIconSize = 13;
const double _inlineGap = 2;

class ConversationCard extends StatelessWidget {
  const ConversationCard({
    required this.item,
    required this.onTap,
    super.key,
    this.cardKey,
    this.highlightMode = false,
  });

  final ConversationSummaryModel item;
  final Key? cardKey;
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
        : messageTimestamp(locale, item.lastMessageAt!);

    final isUnread = item.unreadCount > 0;
    final brightness = theme.brightness;

    // At large text sizes the name gets its own line (up to two), with the
    // unread count and time under it, so it is never cut to a few letters.
    final large = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    final secondaryStyle = theme.textTheme.bodySmall?.copyWith(
      color: AppSemanticColors.textSecondaryFor(brightness),
    );
    final nameText = Text(
      item.peer.fullName,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
        color: isUnread ? AppSemanticColors.textPrimaryFor(brightness) : null,
      ),
      maxLines: large ? 2 : 1,
      overflow: TextOverflow.ellipsis,
    );
    final unreadBadge = Semantics(
      label: locale.unreadMessagesCount(item.unreadCount),
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: AppSemanticColors.clayFor(brightness),
          borderRadius: AppRadius.pillBorder,
        ),
        child: Text(
          '${item.unreadCount}',
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppSemanticColors.onClayFor(brightness),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
    final timeText = Text(
      timestamp,
      style: theme.textTheme.bodySmall?.copyWith(
        color: AppSemanticColors.textSecondaryFor(theme.brightness),
      ),
    );

    // Paper-2 cards on the list hub; an unread thread gets the clay-soft fill.
    return FlatmatesCard(
      key: cardKey,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      backgroundColor: isUnread
          ? AppSemanticColors.coralSoftFor(brightness)
          : AppSemanticColors.surfaceFor(brightness),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          highlightMode && item.peer.profileImageUrl != null
              ? ClipOval(
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
                if (large) ...[
                  nameText,
                  if (isUnread || timestamp.isNotEmpty)
                    Row(
                      children: [
                        if (isUnread) ...[
                          unreadBadge,
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        if (timestamp.isNotEmpty) Flexible(child: timeText),
                      ],
                    ),
                ] else
                  Row(
                    children: [
                      Expanded(child: nameText),
                      if (isUnread) unreadBadge,
                      if (timestamp.isNotEmpty) ...[
                        const SizedBox(width: AppSpacing.sm),
                        timeText,
                      ],
                    ],
                  ),
                if (large) ...[
                  if (item.peer.mode != null)
                    Text(
                      localizedFlatmatesModeLabel(locale, item.peer.mode!),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: secondaryStyle,
                    ),
                  if (location.isNotEmpty)
                    Text(
                      location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: secondaryStyle,
                    ),
                ] else if (item.peer.mode != null || location.isNotEmpty) ...[
                  const SizedBox(height: _inlineGap),
                  Row(
                    children: [
                      if (item.peer.mode != null)
                        Flexible(
                          child: Text(
                            localizedFlatmatesModeLabel(
                              locale,
                              item.peer.mode!,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppSemanticColors.textSecondaryFor(
                                theme.brightness,
                              ),
                            ),
                          ),
                        ),
                      if (item.peer.mode != null && location.isNotEmpty)
                        Text(
                          ' · ',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppSemanticColors.textSecondaryFor(
                              theme.brightness,
                            ),
                          ),
                        ),
                      if (location.isNotEmpty) ...[
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
                    ],
                  ),
                ],
                if (item.lastMessagePreview != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    item.lastMessagePreview!,
                    maxLines: large ? 2 : 1,
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
                      borderRadius: AppRadius.mdBorder,
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
                                    FlatmatesPriceText.formatRupee(
                                      item.contextProperty!.monthlyRent!
                                          .round(),
                                    ),
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
        // Flat clay-soft, not a clay gradient: no stop of the old gradient
        // kept the initials at AA (about 2.2:1 dark / 2.0:1 light).
        // clay-ink on clay-soft is an asserted pair in
        // test/core/theme/contrast_test.dart (8.4:1 light, 4.8:1 dark).
        color: AppSemanticColors.coralSoftFor(theme.brightness),
      ),
      child: Center(
        child: Text(
          initialsFromName(title),
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppSemanticColors.clayInkFor(theme.brightness),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
