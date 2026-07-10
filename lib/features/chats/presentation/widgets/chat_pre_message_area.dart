import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/flatmates_card.dart';
import '../../../shared/presentation/flatmates_chip.dart';

/// Contextual QnA nudge banner shown ABOVE the message list for new matches.
///
/// Split out of the legacy `ChatPreMessageArea` so the suggested-message
/// chips ([ChatIcebreakerRow]) can live at the BOTTOM of the chat screen
/// (above the input bar) while this one-time match prompt stays near the top.
class ChatQnANudgeCard extends StatelessWidget {
  const ChatQnANudgeCard({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xs,
        AppSpacing.xl,
        0,
      ),
      child: FlatmatesCard(
        onTap: onTap,
        child: Row(
          children: [
            const Icon(
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
            const Icon(
              Icons.chevron_right_rounded,
              color: AppSemanticColors.accent,
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal "Break the ice" suggested-message chips, shown just ABOVE the
/// input bar so they're close to where the user composes a message.
class ChatIcebreakerRow extends StatelessWidget {
  const ChatIcebreakerRow({
    required this.icebreakers,
    required this.onSelected,
    super.key,
  });

  final List<String> icebreakers;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.sm,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Row(
          children: icebreakers.map((prompt) {
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: FlatmatesChip(
                label: prompt,
                onSelected: (_) => onSelected(prompt),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
