import 'package:flutter/material.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_semantic_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../skeleton_bone.dart';
import '../skeleton_tokens.dart';

/// Flat details: carousel, meta, chips, stats, bottom action bar.
class FlatDetailsSkeleton extends StatelessWidget {
  const FlatDetailsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final bone = SkeletonTokens.bone(brightness);
    final surface = SkeletonTokens.surface(brightness);
    final isDark = brightness == Brightness.dark;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Stack(
                children: [
                  FlatmatesSkeletonBone(
                    width: double.infinity,
                    height: 220,
                    color: bone,
                  ),
                  Positioned(
                    top: AppSpacing.lg,
                    left: AppSpacing.lg,
                    child: FlatmatesSkeletonBone(
                      width: 36,
                      height: 36,
                      color: bone,
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  Positioned(
                    top: AppSpacing.lg,
                    right: AppSpacing.lg + 44,
                    child: FlatmatesSkeletonBone(
                      width: 36,
                      height: 36,
                      color: bone,
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  Positioned(
                    top: AppSpacing.lg,
                    right: AppSpacing.lg,
                    child: FlatmatesSkeletonBone(
                      width: 36,
                      height: 36,
                      color: bone,
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.xl,
                  AppSpacing.xl,
                  AppSpacing.screen,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: FlatmatesSkeletonBone(
                            width: 200,
                            height: 24,
                            color: bone,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        FlatmatesSkeletonBone(
                          width: 100,
                          height: 20,
                          color: bone,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        FlatmatesSkeletonBone(
                          width: 18,
                          height: 18,
                          color: bone,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        FlatmatesSkeletonBone(width: 160, color: bone),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final w in [72.0, 80.0, 56.0, 64.0, 68.0])
                          FlatmatesSkeletonBone(
                            width: w,
                            height: 32,
                            color: bone,
                            borderRadius: AppRadius.pillBorder,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.screen),
                    FlatmatesSkeletonBone(width: 120, height: 16, color: bone),
                    const SizedBox(height: AppSpacing.sm),
                    FlatmatesSkeletonBone(width: double.infinity, color: bone),
                    const SizedBox(height: AppSpacing.sm),
                    FlatmatesSkeletonBone(width: double.infinity, color: bone),
                    const SizedBox(height: AppSpacing.sm),
                    FlatmatesSkeletonBone(width: 200, color: bone),
                    const SizedBox(height: AppSpacing.screen),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(bone: bone, surface: surface),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _StatCard(bone: bone, surface: surface),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.only(
            left: AppSpacing.xl,
            right: AppSpacing.xl,
            top: AppSpacing.md,
            bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? AppSemanticColors.frostOverlayDark
                : AppSemanticColors.frostOverlayLight,
          ),
          child: Row(
            children: [
              Expanded(
                child: FlatmatesSkeletonBone(
                  height: 48,
                  color: bone,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FlatmatesSkeletonBone(
                  height: 48,
                  color: AppSemanticColors.accent.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.bone, required this.surface});

  final Color bone;
  final Color surface;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadius.cardBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FlatmatesSkeletonBone(width: 80, height: 10, color: bone),
          const SizedBox(height: AppSpacing.sm),
          FlatmatesSkeletonBone(width: 60, color: bone),
        ],
      ),
    );
  }
}
