import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/flatmates_card.dart';
import '../../../shared/presentation/flatmates_ui.dart';
import '../../domain/chat_models.dart';

class ChatQnAAnswersCard extends StatelessWidget {
  const ChatQnAAnswersCard({
    required this.qna,
    required this.peerName,
    required this.onAnswer,
    super.key,
  });

  final ConversationQnAState qna;
  final String peerName;
  final VoidCallback onAnswer;

  @override
  Widget build(BuildContext context) {
    if (!qna.hasAnyAnswers) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    final currentUserAnswers = qna.currentUser;
    final peerAnswers = qna.peer;

    final title = qna.bothAnswered
        ? locale.qnaBothAnsweredBanner
        : qna.hasPeerAnswers
        ? locale.qnaPeerAnsweredBanner(peerName)
        : locale.qnaYouAnsweredBanner;

    return FlatmatesCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.quiz_outlined, color: AppSemanticColors.accent),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppSemanticColors.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (qna.hasPeerAnswers && !qna.hasCurrentUserAnswers) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        locale.qnaPeerAnsweredPrompt,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppSemanticColors.textSecondaryFor(
                            theme.brightness,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (peerAnswers?.hasAnyAnswer ?? false) ...[
            const SizedBox(height: AppSpacing.lg),
            _QnAAnswerSection(
              title: locale.qnaTheirAnswers(peerName),
              answers: peerAnswers!,
            ),
          ],
          if (currentUserAnswers?.hasAnyAnswer ?? false) ...[
            const SizedBox(height: AppSpacing.lg),
            _QnAAnswerSection(
              title: locale.qnaYourAnswers,
              answers: currentUserAnswers!,
            ),
          ],
          if (qna.hasPeerAnswers && !qna.hasCurrentUserAnswers) ...[
            const SizedBox(height: AppSpacing.lg),
            FlatmatesButton.secondary(
              label: locale.qnaAnswerCta,
              onPressed: onAnswer,
              icon: Icons.edit_outlined,
              fullWidth: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _QnAAnswerSection extends StatelessWidget {
  const _QnAAnswerSection({required this.title, required this.answers});

  final String title;
  final ConversationQnAAnswer answers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    final rows = [
      (question: locale.qnaQuestion1, answer: answers.q1),
      (question: locale.qnaQuestion2, answer: answers.q2),
      (question: locale.qnaQuestion3, answer: answers.q3),
    ].where((row) => row.answer?.trim().isNotEmpty ?? false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...rows.map(
          (row) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.question,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppSemanticColors.textSecondaryFor(theme.brightness),
                  ),
                ),
                const SizedBox(height: 2),
                Text(row.answer!.trim(), style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
