import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../shared/presentation/components.dart';
import '../../../../l10n/gen/app_localizations.dart';

class PostYourSpaceCard extends StatelessWidget {
  const PostYourSpaceCard({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);

    final brightness = theme.brightness;
    final clay = AppSemanticColors.clayFor(brightness);

    // A clay-soft sheet with a bare icon (no tile, no tinted stroke).
    return FlatmatesCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.md,
      ),
      backgroundColor: AppSemanticColors.coralSoftFor(brightness),
      child: Row(
        children: [
          Icon(Icons.add_home_outlined, color: clay, size: 24),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  locale.postListingTitle,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppSemanticColors.textPrimaryFor(brightness),
                  ),
                ),
                Text(
                  locale.postListingCta,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppSemanticColors.clayInkFor(brightness),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Icon(Icons.chevron_right_rounded, color: clay, size: 20),
        ],
      ),
    );
  }
}

class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({
    required this.title,
    this.actionLabel,
    this.actionKey,
    this.onActionTap,
    super.key,
  });

  final String title;
  final String? actionLabel;
  final Key? actionKey;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppSemanticColors.textPrimaryFor(theme.brightness),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (actionLabel != null) ...[
          const SizedBox(width: AppSpacing.sm),
          FlatmatesButton.tertiary(
            key: actionKey,
            label: actionLabel!,
            onPressed: onActionTap,
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

    return Semantics(
      identifier: 'home_search_bar',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        // Looks like the DESIGN input: 48 high (grows with text), e1.
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppSemanticColors.surfaceFor(theme.brightness),
            borderRadius: AppRadius.mdBorder,
            boxShadow: AppShadows.e1(theme.brightness),
          ),
          child: Row(
            children: [
              Icon(
                AppIcons.search,
                color: AppSemanticColors.clayFor(theme.brightness),
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
              Icon(
                AppIcons.filter,
                color: AppSemanticColors.clayFor(theme.brightness),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
