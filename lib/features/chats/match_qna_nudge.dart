import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../shared/presentation/flatmates_card.dart';
import '../shared/presentation/flatmates_ui.dart';

class MatchQnANudge extends ConsumerStatefulWidget {
  const MatchQnANudge({
    required this.peerName,
    required this.onComplete,
    super.key,
  });

  final String peerName;
  final void Function(Map<String, String> answers) onComplete;

  @override
  ConsumerState<MatchQnANudge> createState() => _MatchQnANudgeState();
}

class _MatchQnANudgeState extends ConsumerState<MatchQnANudge> {
  final _q1Controller = TextEditingController();
  int _q2Value = 2; // 1-5 scale, default middle
  final _q3Controller = TextEditingController();

  static const _q2Labels = [
    'Very private',
    'Private',
    'Mixed',
    'Social',
    'Very social',
  ];

  @override
  void dispose() {
    _q1Controller.dispose();
    _q3Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(locale.qnaNudgeTitle, style: theme.textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            locale.qnaNudgeSubtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppSemanticColors.textSecondaryFor(theme.brightness),
            ),
          ),
          const SizedBox(height: AppSpacing.screen),
          FlatmatesCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(locale.qnaQuestion1, style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _q1Controller,
                  maxLength: 100,
                  decoration: InputDecoration(
                    hintText: locale.qnaQuestion1Hint,
                    counterStyle: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FlatmatesCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(locale.qnaQuestion2, style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Slider(
                  value: _q2Value.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: _q2Labels[_q2Value - 1],
                  onChanged: (v) => setState(() => _q2Value = v.round()),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FlatmatesCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(locale.qnaQuestion3, style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _q3Controller,
                  maxLength: 60,
                  decoration: InputDecoration(
                    hintText: locale.qnaQuestion3Hint,
                    counterStyle: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.screen),
          FlatmatesButton(
            label: locale.qnaAnswerCta,
            onPressed: () {
              widget.onComplete({
                'q1': _q1Controller.text.trim(),
                'q2': _q2Value.toString(),
                'q3': _q3Controller.text.trim(),
              });
              Navigator.pop(context);
            },
            icon: Icons.check_rounded,
            fullWidth: true,
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: FlatmatesButton.tertiary(
              label: locale.qnaSkipCta,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
