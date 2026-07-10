import 'package:flutter/material.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../skeleton_bone.dart';
import '../skeleton_tokens.dart';

/// Compact horizontal listing rows (image left, meta right).
class BrowseListingsSkeleton extends StatelessWidget {
  const BrowseListingsSkeleton({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final bone = SkeletonTokens.bone(brightness);
    final soft = SkeletonTokens.boneSoft(brightness);
    final surface = SkeletonTokens.surface(brightness);

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 120),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, _) {
        return Container(
          height: 110,
          decoration: BoxDecoration(
            color: surface,
            borderRadius: AppRadius.cardBorder,
          ),
          child: Row(
            children: [
              FlatmatesSkeletonBone(
                width: 110,
                height: 110,
                color: bone,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AppRadius.card),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FlatmatesSkeletonBone(width: 80, height: 16, color: bone),
                      const SizedBox(height: AppSpacing.xs),
                      FlatmatesSkeletonBone(width: 140, color: bone),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          FlatmatesSkeletonBone(
                            width: 12,
                            height: 12,
                            color: bone,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          const SizedBox(width: 2),
                          FlatmatesSkeletonBone(
                            width: 100,
                            height: 10,
                            color: bone,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      FlatmatesSkeletonBone(
                        width: 120,
                        height: 10,
                        color: bone,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  right: AppSpacing.sm,
                  top: AppSpacing.sm,
                ),
                child: FlatmatesSkeletonBone(
                  width: 28,
                  height: 28,
                  color: soft,
                  borderRadius: BorderRadius.circular(AppRadius.sm - 1),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
