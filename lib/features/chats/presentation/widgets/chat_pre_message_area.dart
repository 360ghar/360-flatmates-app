import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/flatmates_card.dart';

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
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < icebreakers.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.xs),
              _IcebreakerChip(
                label: icebreakers[i],
                onTap: () => onSelected(icebreakers[i]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Dense pill used only for icebreaker suggestions (tighter than
/// [FlatmatesChip] so more prompts stay visible horizontally).
class _IcebreakerChip extends StatelessWidget {
  const _IcebreakerChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final background = isDark
        ? AppSemanticColors.darkSurface
        : AppSemanticColors.canvas;
    final foreground = isDark
        ? AppSemanticColors.darkBody
        : AppSemanticColors.body;
    final border = AppSemanticColors.hairlineFor(theme.brightness);

    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.pillBorder,
        side: BorderSide(color: border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.pillBorder,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
