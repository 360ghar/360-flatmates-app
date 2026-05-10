import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/flatmates_card.dart';
import '../../../shared/presentation/flatmates_ui.dart';
import '../../../shared/presentation/flatmates_listing_mini_card.dart';
import '../../chats_repository.dart';

class ChatPropertyCard extends StatelessWidget {
  const ChatPropertyCard({
    required this.conversation,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onViewListing,
    required this.onMiniCardTap,
    super.key,
  });

  final ConversationSummaryModel conversation;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onViewListing;
  final VoidCallback onMiniCardTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    final property = conversation.contextProperty;

    if (property == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 10),
      child: FlatmatesCard(
        padding: const EdgeInsets.all(14),
        child: GestureDetector(
          onTap: onToggleExpand,
          child: AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: FlatmatesListingMiniCard(
                        title: property.title,
                        rent: property.monthlyRent?.toInt() ?? 0,
                        imageUrl: property.mainImageUrl,
                        locality: null,
                        subtitle: property.ownerName != null
                            ? locale.byOwnerLabel(property.ownerName!)
                            : null,
                        compact: !isExpanded,
                        onTap: onMiniCardTap,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 250),
                      turns: isExpanded ? 0.5 : 0,
                      child: Icon(
                        Icons.expand_more_rounded,
                        size: 20,
                        color: AppSemanticColors.textSecondaryFor(
                          theme.brightness,
                        ),
                      ),
                    ),
                  ],
                ),
                if (isExpanded) ...[
                  if (conversation.matchedAt != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      DateFormat(
                        'MMM d, y',
                        locale.localeName,
                      ).format(conversation.matchedAt!.toLocal()),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppSemanticColors.textSecondaryFor(
                          theme.brightness,
                        ),
                        fontSize: 11,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  FlatmatesButton.secondary(
                    key: const Key('chat_property_view_listing'),
                    label: locale.viewListing,
                    onPressed: onViewListing,
                    icon: Icons.open_in_new,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
