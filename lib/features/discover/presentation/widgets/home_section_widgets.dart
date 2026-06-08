import 'package:flutter/material.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/flatmates_card.dart';

class MarketInsightCard extends StatelessWidget {
  const MarketInsightCard({
    required this.count,
    required this.onTap,
    super.key,
  });

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);

    return FlatmatesCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      borderColor: AppSemanticColors.accent.withValues(alpha: 0.16),
      backgroundColor: AppSemanticColors.accent.withValues(alpha: 0.08),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppSemanticColors.accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              color: AppSemanticColors.accent,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  locale.homeMarketInsight(count),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppSemanticColors.textPrimaryFor(theme.brightness),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  locale.homeMarketInsightCta,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppSemanticColors.accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppSemanticColors.accent,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class PostYourSpaceCard extends StatelessWidget {
  const PostYourSpaceCard({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);

    return FlatmatesCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      borderColor: AppSemanticColors.accent.withValues(alpha: 0.16),
      backgroundColor: AppSemanticColors.accent.withValues(alpha: 0.08),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppSemanticColors.accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_home_outlined,
              color: AppSemanticColors.accent,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  locale.postListingTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppSemanticColors.textPrimaryFor(theme.brightness),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  locale.postListingCta,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppSemanticColors.accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppSemanticColors.accent,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({
    required this.title,
    this.actionLabel,
    this.onActionTap,
    super.key,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppSemanticColors.textPrimaryFor(theme.brightness),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (actionLabel != null) ...[
          const SizedBox(width: AppSpacing.sm),
          TextButton(
            onPressed: onActionTap,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            ),
            child: Text(
              actionLabel!,
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppSemanticColors.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: AppSemanticColors.surfaceFor(theme.brightness),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: AppSemanticColors.line.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.search_rounded,
              color: AppSemanticColors.accent,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                AppLocalizations.of(context).homeSearchHint,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppSemanticColors.textSecondaryFor(theme.brightness),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppSemanticColors.accentSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.tune_rounded,
                color: AppSemanticColors.accent,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuickFiltersRow extends StatelessWidget {
  const QuickFiltersRow({
    required this.filters,
    required this.onFilterTap,
    super.key,
  });

  final List<String> filters;
  final void Function(String) onFilterTap;

  @override
  Widget build(BuildContext context) {
    if (filters.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final filter = filters[index];
          return ActionChip(
            label: Text(
              filter,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppSemanticColors.textPrimaryFor(theme.brightness),
              ),
            ),
            backgroundColor: AppSemanticColors.surfaceFor(theme.brightness),
            side: BorderSide(
              color: AppSemanticColors.line.withValues(alpha: 0.2),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            onPressed: () => onFilterTap(filter),
          );
        },
      ),
    );
  }
}
