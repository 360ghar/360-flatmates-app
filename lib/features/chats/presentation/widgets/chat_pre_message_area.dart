import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/flatmates_card.dart';
import '../../../shared/presentation/flatmates_chip.dart';

class ChatPreMessageArea extends StatelessWidget {
  const ChatPreMessageArea({
    required this.showQnANudge,
    required this.onQnATap,
    required this.icebreakers,
    required this.onIcebreakerSelected,
    super.key,
  });

  final bool showQnANudge;
  final VoidCallback onQnATap;
  final List<String> icebreakers;
  final ValueChanged<String> onIcebreakerSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xs,
        AppSpacing.xl,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showQnANudge) ...[
            FlatmatesCard(
              onTap: onQnATap,
              child: Row(
                children: [
                  Icon(
                    Icons.quiz_outlined,
                    color: AppSemanticColors.accent,
                    size: 28,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          locale.qnaNudgeTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppSemanticColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          locale.qnaNudgeSubtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppSemanticColors.textSecondaryFor(
                              theme.brightness,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppSemanticColors.accent,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          Text(locale.icebreakerTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              children: icebreakers.map((prompt) {
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: FlatmatesChip(
                    variant: FlatmatesChipVariant.filter,
                    label: prompt,
                    onSelected: (_) => onIcebreakerSelected(prompt),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
