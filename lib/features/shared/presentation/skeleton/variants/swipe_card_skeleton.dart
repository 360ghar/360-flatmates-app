import 'package:flutter/material.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../skeleton_bone.dart';
import '../skeleton_tokens.dart';

/// Tall swipe deck card: hero image + detail section.
///
/// Fills available height so short viewports (and tests) do not overflow.
class SwipeCardSkeleton extends StatelessWidget {
  const SwipeCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final bone = SkeletonTokens.bone(brightness);
    final surface = SkeletonTokens.surface(brightness);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: AppRadius.cardBorder,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  FlatmatesSkeletonBone.fill(color: bone),
                  Positioned(
                    top: AppSpacing.md,
                    left: AppSpacing.md,
                    child: FlatmatesSkeletonBone(
                      width: 60,
                      height: 24,
                      color: bone,
                      borderRadius: AppRadius.pillBorder,
                    ),
                  ),
                  Positioned(
                    top: AppSpacing.md,
                    right: AppSpacing.md,
                    child: FlatmatesSkeletonBone(
                      width: 60,
                      height: 28,
                      color: bone,
                      borderRadius: AppRadius.pillBorder,
                    ),
                  ),
                  Positioned(
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    bottom: AppSpacing.md,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FlatmatesSkeletonBone(
                          width: 140,
                          height: 20,
                          color: bone,
                        ),
                        const SizedBox(height: 4),
                        FlatmatesSkeletonBone(
                          width: 100,
                          height: 12,
                          color: bone,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            FlatmatesSkeletonBone(
                              width: 12,
                              height: 12,
                              color: bone,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            const SizedBox(width: 4),
                            FlatmatesSkeletonBone(
                              width: 80,
                              height: 10,
                              color: bone,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FlatmatesSkeletonBone(width: 80, color: bone),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        for (final w in [56.0, 64.0, 56.0]) ...[
                          FlatmatesSkeletonBone(
                            width: w,
                            height: 24,
                            color: bone,
                            borderRadius: AppRadius.pillBorder,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FlatmatesSkeletonBone(
                      width: double.infinity,
                      height: 6,
                      color: bone,
                      borderRadius: AppRadius.pillBorder,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FlatmatesSkeletonBone(width: 100, color: bone),
                    const SizedBox(height: AppSpacing.sm),
                    FlatmatesSkeletonBone(
                      width: double.infinity,
                      height: 12,
                      color: bone,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    FlatmatesSkeletonBone(
                      width: double.infinity,
                      height: 12,
                      color: bone,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    FlatmatesSkeletonBone(width: 160, height: 12, color: bone),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        for (final w in [64.0, 72.0, 56.0]) ...[
                          FlatmatesSkeletonBone(
                            width: w,
                            height: 28,
                            color: bone,
                            borderRadius: AppRadius.pillBorder,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
