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
        AppSpacing.screen,
        AppSpacing.xs,
        AppSpacing.screen,
        0,
      ),
      child: FlatmatesCard(
        onTap: onTap,
        child: Row(
          children: [
            Icon(
              Icons.quiz_outlined,
              color: AppSemanticColors.clayFor(theme.brightness),
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
                      color: AppSemanticColors.clayFor(theme.brightness),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
              color: AppSemanticColors.clayFor(theme.brightness),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal "Break the ice" suggested-message chips, shown just ABOVE the
/// input bar so they're close to where the user composes a message.
///
/// Compact horizontal padding so more suggestions fit on screen.
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
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
        child: Row(
          children: [
            for (var i = 0; i < icebreakers.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.sm),
              // Shared 48 dp chip (the private one was about 26 dp high).
              // Tapping sends the suggestion, so it is an action, not a
              // filter: it has no selected state to announce.
              FlatmatesChip(
                label: icebreakers[i],
                variant: FlatmatesChipVariant.action,
                onSelected: (_) => onSelected(icebreakers[i]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
