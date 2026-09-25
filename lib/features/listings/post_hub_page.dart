import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_radius.dart';
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

    // Counts for the Manage card. Prefer real data whenever it exists (even
    // during a failed background refresh); otherwise a load failure must be
    // visible and recoverable, not a silent disappearance of the chips.
    Widget? manageCounts;
    if (activeCount != null && draftCount != null) {
      // Plain text, not a pair of pills.
      manageCounts = Text(
        '${locale.postHubActiveCount(activeCount)} · '
        '${locale.postHubDraftCount(draftCount)}',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: AppSemanticColors.textPrimaryFor(theme.brightness),
          fontWeight: FontWeight.w600,
        ),
      );
    } else if (listings.isLoading) {
      // One bone the size of the counts line (no layout jump on load).
      manageCounts = const FlatmatesSkeletonShimmer(
        child: FlatmatesSkeletonBone(
          width: 140,
          height: 16,
          borderRadius: AppRadius.xsBorder,
        ),
      );
    } else if (listings.hasError) {
      manageCounts = Wrap(
        spacing: AppSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            locale.couldNotLoadListings,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppSemanticColors.textSecondaryFor(theme.brightness),
            ),
          ),
          FlatmatesButton.tertiary(
            label: locale.commonRetry,
            onPressed: () => ref.invalidate(myListingsProvider),
          ),
        ],
      );
    }

    return FlatmatesScreen(
      appBar: FlatmatesHeader.logo(
        actions: [
          FlatmatesChromeIconButton(
            key: const Key('post_notifications_button'),
            onPressed: () => context.push('/notifications'),
            icon: Icons.notifications_outlined,
            tooltip: locale.notificationsTooltip,
          ),
          FlatmatesChromeIconButton(
            onPressed: () => context.go('/chats'),
            icon: Icons.chat_bubble_outline,
            tooltip: locale.chatTooltip,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: RefreshIndicator(
            // Keeps the spinner until the reload lands; a failure shows in
            // the Manage card, so it is only logged here.
            onRefresh: () async {
              try {
                final _ = await ref.refresh(myListingsProvider.future);
              } catch (e) {
                debugPrint('PostHubPage.onRefresh: $e');
              }
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
                  counts: manageCounts,
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
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          // Bare clay icon: no tinted circle behind it.
          Icon(
            icon,
            size: 32,
            color: AppSemanticColors.clayFor(theme.brightness),
          ),
          const SizedBox(width: AppSpacing.base),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleLarge),
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
