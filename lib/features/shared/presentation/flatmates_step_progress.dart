import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Progress style — dots, segments, or linear bar.
enum FlatmatesStepProgressStyle { dots, segments, linear }

/// Dot/segment/linear progress for onboarding, mode selection, listing steps, quiz.
///
/// Active parts are clay, the track is ink-3 at 30 % (both follow brightness).
/// [semanticsLabel] (for example "Step 2 of 4") is read by screen readers.
class FlatmatesStepProgress extends StatelessWidget {
  const FlatmatesStepProgress({
    required this.currentStep,
    required this.totalSteps,
    super.key,
    this.style = FlatmatesStepProgressStyle.segments,
    this.semanticsLabel,
  });

  const FlatmatesStepProgress.dots({
    required this.currentStep,
    required this.totalSteps,
    super.key,
    this.semanticsLabel,
  }) : style = FlatmatesStepProgressStyle.dots;

  const FlatmatesStepProgress.segments({
    required this.currentStep,
    required this.totalSteps,
    super.key,
    this.semanticsLabel,
  }) : style = FlatmatesStepProgressStyle.segments;

  const FlatmatesStepProgress.linear({
    required this.currentStep,
    required this.totalSteps,
    super.key,
    this.semanticsLabel,
  }) : style = FlatmatesStepProgressStyle.linear;

  final int currentStep;
  final int totalSteps;
  final FlatmatesStepProgressStyle style;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final active = AppSemanticColors.clayFor(brightness);
    // Ink-3 at 30 %: visible on every paper layer in both themes.
    final track = AppSemanticColors.textTertiaryFor(
      brightness,
    ).withValues(alpha: 0.3);
    final duration = AppMotion.durationOrZero(context, AppMotion.standard);

    final Widget bar = switch (style) {
      FlatmatesStepProgressStyle.dots => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(totalSteps, (index) {
          final isActive = index == currentStep;
          return AnimatedContainer(
            duration: duration,
            curve: AppMotion.paperOut,
            margin: EdgeInsets.only(
              right: index < totalSteps - 1 ? AppSpacing.sm : 0,
            ),
            width: isActive ? AppSpacing.lg : AppSpacing.sm,
            height: AppSpacing.sm,
            decoration: BoxDecoration(
              color: index <= currentStep ? active : track,
              borderRadius: AppRadius.pillBorder,
            ),
          );
        }),
      ),
      FlatmatesStepProgressStyle.segments => Row(
        children: List.generate(totalSteps, (index) {
          return Expanded(
            child: AnimatedContainer(
              duration: duration,
              curve: AppMotion.paperOut,
              margin: EdgeInsets.only(
                right: index < totalSteps - 1 ? AppSpacing.xs : 0,
              ),
              height: AppSpacing.xs,
              decoration: BoxDecoration(
                color: index <= currentStep ? active : track,
                borderRadius: AppRadius.pillBorder,
              ),
            ),
          );
        }),
      ),
      FlatmatesStepProgressStyle.linear => LinearProgressIndicator(
        value: totalSteps > 0 ? currentStep / totalSteps : 0.0,
        minHeight: AppSpacing.xs,
        borderRadius: AppRadius.pillBorder,
        backgroundColor: track,
        valueColor: AlwaysStoppedAnimation(active),
      ),
    };

    final label = semanticsLabel;
    if (label == null) return bar;
    return Semantics(
      label: label,
      child: ExcludeSemantics(child: bar),
    );
  }
}
