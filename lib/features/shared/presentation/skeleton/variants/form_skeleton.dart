import 'package:flutter/material.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../skeleton_bone.dart';
import '../skeleton_tokens.dart';

/// Generic multi-field form with bottom primary CTA.
class FormSkeleton extends StatelessWidget {
  const FormSkeleton({super.key, this.fieldCount = 5});

  final int fieldCount;

  @override
  Widget build(BuildContext context) {
    final bone = SkeletonTokens.bone(Theme.of(context).brightness);
    final surface = SkeletonTokens.surface(Theme.of(context).brightness);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            children: [
              FlatmatesSkeletonBone(width: 180, height: 22, color: bone),
              const SizedBox(height: AppSpacing.sm),
              FlatmatesSkeletonBone(width: 240, height: 12, color: bone),
              const SizedBox(height: AppSpacing.xl),
              for (var i = 0; i < fieldCount; i++) ...[
                FlatmatesSkeletonBone(width: 100, height: 12, color: bone),
                const SizedBox(height: AppSpacing.sm),
                FlatmatesSkeletonBone(
                  width: double.infinity,
                  height: 56,
                  color: surface,
                  borderRadius: AppRadius.smBorder,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.md,
            AppSpacing.xl,
            MediaQuery.of(context).padding.bottom + AppSpacing.md,
          ),
          child: FlatmatesSkeletonBone(
            width: double.infinity,
            height: 52,
            color: bone,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ],
    );
  }
}
