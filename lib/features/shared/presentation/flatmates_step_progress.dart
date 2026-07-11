import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Progress style — dots, segments, or linear bar.
enum FlatmatesStepProgressStyle { dots, segments, linear }

/// Dot/segment/linear progress for onboarding, mode selection, listing steps, quiz.
///
/// Replaces ad-hoc progress indicators across the app.
class FlatmatesStepProgress extends StatelessWidget {
  const FlatmatesStepProgress({
    required this.currentStep,
    required this.totalSteps,
    super.key,
    this.style = FlatmatesStepProgressStyle.segments,
  });

  const FlatmatesStepProgress.dots({
    required this.currentStep,
    required this.totalSteps,
    super.key,
  }) : style = FlatmatesStepProgressStyle.dots;

  const FlatmatesStepProgress.segments({
    required this.currentStep,
    required this.totalSteps,
    super.key,
  }) : style = FlatmatesStepProgressStyle.segments;

  const FlatmatesStepProgress.linear({
    required this.currentStep,
    required this.totalSteps,
    super.key,
  }) : style = FlatmatesStepProgressStyle.linear;

  final int currentStep;
  final int totalSteps;
  final FlatmatesStepProgressStyle style;

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case FlatmatesStepProgressStyle.dots:
        return _DotProgress(currentStep: currentStep, totalSteps: totalSteps);
      case FlatmatesStepProgressStyle.segments:
        return _SegmentProgress(
          currentStep: currentStep,
          totalSteps: totalSteps,
        );
      case FlatmatesStepProgressStyle.linear:
        return _LinearProgress(
          currentStep: currentStep,
          totalSteps: totalSteps,
        );
    }
  }
}

class _DotProgress extends StatelessWidget {
  const _DotProgress({required this.currentStep, required this.totalSteps});

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final inactive = AppSemanticColors.hairlineFor(
      Theme.of(context).brightness,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalSteps, (index) {
        final isActive = index == currentStep;
        final isCompleted = index < currentStep;
        final color = isActive || isCompleted
            ? AppSemanticColors.accent
            : inactive;

        return AnimatedContainer(
          duration: AppMotion.standard,
          curve: AppMotion.easeOutCubic,
          margin: EdgeInsets.only(
            right: index < totalSteps - 1 ? AppSpacing.sm : 0,
          ),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _SegmentProgress extends StatelessWidget {
  const _SegmentProgress({required this.currentStep, required this.totalSteps});

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final inactive = AppSemanticColors.hairlineFor(
      Theme.of(context).brightness,
    ).withValues(alpha: 0.3);
    return Row(
      children: List.generate(totalSteps, (index) {
        final isCompleted = index < currentStep;
        final isCurrent = index == currentStep;
        final color = isCompleted || isCurrent
            ? AppSemanticColors.accent
            : inactive;

        return Expanded(
          child: AnimatedContainer(
            duration: AppMotion.standard,
            curve: AppMotion.easeOutCubic,
            margin: EdgeInsets.only(
              right: index < totalSteps - 1 ? AppSpacing.xs : 0,
            ),
            height: 4,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

class _LinearProgress extends StatelessWidget {
  const _LinearProgress({required this.currentStep, required this.totalSteps});

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final progress = totalSteps > 0 ? currentStep / totalSteps : 0.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 4,
        backgroundColor: AppSemanticColors.hairlineFor(
          Theme.of(context).brightness,
        ).withValues(alpha: 0.3),
        valueColor: const AlwaysStoppedAnimation(AppSemanticColors.accent),
      ),
    );
  }
}
