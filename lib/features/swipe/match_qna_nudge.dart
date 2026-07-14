import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../shared/presentation/flatmates_card.dart';
import '../shared/presentation/flatmates_toast.dart';
import '../shared/presentation/flatmates_ui.dart';
import 'application/match_qna_controller.dart';

/// Bottom sheet that nudges the user to answer 3 ice-breaker Q&A questions
/// after a match, before they start chatting.
class MatchQnANudgeSheet extends ConsumerStatefulWidget {
  const MatchQnANudgeSheet({required this.conversationId, super.key});

  final int conversationId;

  @override
  ConsumerState<MatchQnANudgeSheet> createState() => _MatchQnANudgeSheetState();
}

class _MatchQnANudgeSheetState extends ConsumerState<MatchQnANudgeSheet> {
  final _q1Controller = TextEditingController();
  final _q3Controller = TextEditingController();
  int _socialScale = 3; // 1–5, default middle

  @override
  void dispose() {
    _q1Controller.dispose();
    _q3Controller.dispose();
    super.dispose();
  }

  String _socialScaleLabel(AppLocalizations locale) {
    return switch (_socialScale) {
      1 => locale.qnaVeryPrivate,
      2 => locale.qnaMostlyPrivate,
      3 => locale.qnaBalanced,
      4 => locale.qnaMostlySocial,
      5 => locale.qnaVerySocial,
      _ => locale.qnaBalanced,
    };
  }

  Future<void> _submitAnswers() async {
    final locale = AppLocalizations.of(context);
    // Persist Q2 as a numeric scale "1".."5" so clients/locales share one
    // canonical payload (chats MatchQnA already does the same).
    final success = await ref
        .read(matchQnAControllerProvider.notifier)
        .submitAnswers(
          conversationId: widget.conversationId,
          q1: _q1Controller.text.trim(),
          q2: _socialScale.toString(),
          q3: _q3Controller.text.trim(),
        );
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop();
    } else {
      // Keep the nudge open so the user can retry without reopening.
      FlatmatesToast.error(context, locale.commonRetry);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    final isSubmitting = ref.watch(matchQnAControllerProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          locale.qnaNudgeTitle,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Q1
        FlatmatesCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                locale.qnaQuestion1,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _q1Controller,
                maxLines: 2,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: locale.qnaQuestion1,
                  contentPadding: const EdgeInsets.all(AppSpacing.md),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Q2 (social scale)
        FlatmatesCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                locale.qnaQuestion2,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Text(
                    locale.qnaVeryPrivate,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppSemanticColors.textSecondaryFor(
                        theme.brightness,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: _socialScale.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: _socialScaleLabel(locale),
                      onChanged: (v) =>
                          setState(() => _socialScale = v.round()),
                    ),
                  ),
                  Text(
                    locale.qnaVerySocial,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppSemanticColors.textSecondaryFor(
                        theme.brightness,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Q3
        FlatmatesCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                locale.qnaQuestion3,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _q3Controller,
                maxLines: 2,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: locale.qnaQuestion3,
                  contentPadding: const EdgeInsets.all(AppSpacing.md),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.screen),

        // Share Answers button
        FlatmatesButton(
          label: locale.qnaShareAnswers,
          onPressed: isSubmitting ? null : _submitAnswers,
          fullWidth: true,
        ),
        const SizedBox(height: AppSpacing.sm),

        // Skip for now
        Center(
          child: FlatmatesButton.tertiary(
            label: locale.qnaSkipForNow,
            onPressed: isSubmitting ? null : () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }
}
