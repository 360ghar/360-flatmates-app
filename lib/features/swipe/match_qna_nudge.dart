import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/endpoints.dart';
import '../../core/providers.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../shared/presentation/flatmates_card.dart';
import '../shared/presentation/flatmates_ui.dart';

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
  bool _isSubmitting = false;

  @override
  void dispose() {
    _q1Controller.dispose();
    _q3Controller.dispose();
    super.dispose();
  }

  Future<void> _submitAnswers() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      await ref
          .read(apiClientProvider)
          .post(
            FlatmatesEndpoints.conversationQnA(widget.conversationId),
            data: {
              'answers': {
                '0': _q1Controller.text.trim(),
                '1': _socialScaleValue,
                '2': _q3Controller.text.trim(),
              },
            },
          );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        final locale = AppLocalizations.of(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(locale.commonRetry)));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String get _socialScaleValue {
    const labels = [
      'Very private',
      'Mostly private',
      'Balanced',
      'Mostly social',
      'Very social',
    ];
    return labels[_socialScale - 1];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);

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
                      label: _socialScaleValue,
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
          onPressed: _isSubmitting ? null : _submitAnswers,
          fullWidth: true,
        ),
        const SizedBox(height: AppSpacing.sm),

        // Skip for now
        Center(
          child: FlatmatesButton.tertiary(
            label: locale.qnaSkipForNow,
            onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }
}
