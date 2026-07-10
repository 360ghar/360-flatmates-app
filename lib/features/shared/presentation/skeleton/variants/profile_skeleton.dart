import 'package:flutter/material.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../skeleton_bone.dart';
import '../skeleton_tokens.dart';

/// Profile page: compact header, strength card, menu groups.
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final bone = SkeletonTokens.bone(Theme.of(context).brightness);
    final surface = SkeletonTokens.surface(Theme.of(context).brightness);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      children: [
        Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                FlatmatesSkeletonBone(
                  width: 80,
                  height: 80,
                  color: bone,
                  borderRadius: BorderRadius.circular(12),
                ),
                Positioned(
                  right: -2,
                  bottom: 2,
                  child: FlatmatesSkeletonBone(
                    width: 30,
                    height: 30,
                    color: bone,
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.xl),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FlatmatesSkeletonBone(width: 160, height: 20, color: bone),
                  const SizedBox(height: 6),
                  FlatmatesSkeletonBone(
                    width: 120,
                    height: 28,
                    color: bone,
                    borderRadius: AppRadius.pillBorder,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      FlatmatesSkeletonBone(
                        width: 16,
                        height: 16,
                        color: bone,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      const SizedBox(width: 4),
                      FlatmatesSkeletonBone(width: 120, color: bone),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.screen),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: AppRadius.cardBorder,
          ),
          child: Row(
            children: [
              FlatmatesSkeletonBone(
                width: 44,
                height: 44,
                color: bone,
                borderRadius: BorderRadius.circular(22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FlatmatesSkeletonBone(width: 160, color: bone),
                    const SizedBox(height: 4),
                    FlatmatesSkeletonBone(width: 120, height: 10, color: bone),
                  ],
                ),
              ),
              FlatmatesSkeletonBone(
                width: 20,
                height: 20,
                color: bone,
                borderRadius: BorderRadius.circular(10),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        FlatmatesSkeletonBone(width: 80, height: 10, color: bone),
        const SizedBox(height: AppSpacing.sm),
        _MenuCard(bone: bone, surface: surface, itemCount: 4),
        const SizedBox(height: AppSpacing.xl),
        FlatmatesSkeletonBone(width: 60, height: 10, color: bone),
        const SizedBox(height: AppSpacing.sm),
        _MenuCard(bone: bone, surface: surface, itemCount: 1),
        const SizedBox(height: AppSpacing.xl),
        FlatmatesSkeletonBone(width: 70, height: 10, color: bone),
        const SizedBox(height: AppSpacing.sm),
        _MenuCard(bone: bone, surface: surface, itemCount: 2),
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: FlatmatesSkeletonBone(width: 80, height: 16, color: bone),
        ),
      ],
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.bone,
    required this.surface,
    required this.itemCount,
  });

  final Color bone;
  final Color surface;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadius.cardBorder,
      ),
      child: Column(
        children: [
          for (var i = 0; i < itemCount; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  FlatmatesSkeletonBone(
                    width: 40,
                    height: 40,
                    color: bone,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: FlatmatesSkeletonBone(color: bone)),
                  FlatmatesSkeletonBone(
                    width: 16,
                    height: 16,
                    color: bone,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ],
              ),
            ),
            if (i < itemCount - 1)
              Padding(
                padding: const EdgeInsets.only(left: 72),
                child: FlatmatesSkeletonBone(
                  width: double.infinity,
                  height: 1,
                  color: bone,
                ),
              ),
          ],
        ],
      ),
    );
  }
}
