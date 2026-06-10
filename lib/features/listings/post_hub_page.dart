import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../shared/presentation/components.dart';
import 'domain/listing_status.dart';
import 'listings_repository.dart';

/// Landing page for the Post tab (room poster mode) with two clear entries:
/// post a new listing, or manage existing ones.
class PostHubPage extends ConsumerWidget {
  const PostHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listings = ref.watch(myListingsProvider);
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final items = listings.valueOrNull;
    final activeCount = items
        ?.where((l) => listingMatchesTab(l, 'active'))
        .length;
    final draftCount = items
        ?.where((l) => listingMatchesTab(l, 'draft'))
        .length;

    return FlatmatesScreen(
      appBar: FlatmatesHeader.logo(
        actions: [
          IconButton(
            onPressed: () => context.push('/notifications'),
            icon: const Icon(Icons.notifications_outlined),
            tooltip: locale.notificationsTooltip,
          ),
          IconButton(
            onPressed: () => context.go('/chats'),
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: locale.chatTooltip,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(myListingsProvider);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
                vertical: AppSpacing.md,
              ),
              children: [
                Text(locale.postHubTitle, style: theme.textTheme.headlineLarge),
                const SizedBox(height: AppSpacing.lg),
                _HubCard(
                  key: const Key('post_hub_post_card'),
                  icon: Icons.add_home_outlined,
                  title: locale.postListingTitle,
                  subtitle: locale.postHubPostSubtitle,
                  onTap: () => context.push('/post/new'),
                ),
                const SizedBox(height: AppSpacing.md),
                _HubCard(
                  key: const Key('post_hub_manage_card'),
                  icon: Icons.dashboard_customize_outlined,
                  title: locale.manageListingsTitle,
                  subtitle: locale.postHubManageSubtitle,
                  counts: (activeCount != null && draftCount != null)
                      ? Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            FlatmatesChip(
                              label: locale.postHubActiveCount(activeCount),
                              variant: FlatmatesChipVariant.info,
                            ),
                            FlatmatesChip(
                              label: locale.postHubDraftCount(draftCount),
                              variant: FlatmatesChipVariant.info,
                            ),
                          ],
                        )
                      : null,
                  onTap: () => context.push('/manage-listings'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  const _HubCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.counts,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? counts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FlatmatesCard.elevated(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppSemanticColors.accent.withValues(alpha: 0.12),
            ),
            child: Icon(icon, size: 28, color: AppSemanticColors.accent),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppSemanticColors.textSecondaryFor(theme.brightness),
                  ),
                ),
                if (counts != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  counts!,
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(
            Icons.chevron_right_rounded,
            color: AppSemanticColors.textSecondaryFor(theme.brightness),
          ),
        ],
      ),
    );
  }
}
