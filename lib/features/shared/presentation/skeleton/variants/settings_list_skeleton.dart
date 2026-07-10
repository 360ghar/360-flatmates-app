import 'package:flutter/material.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../skeleton_bone.dart';
import '../skeleton_tokens.dart';

/// Settings-style rows with trailing switch bones.
class SettingsListSkeleton extends StatelessWidget {
  const SettingsListSkeleton({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final bone = SkeletonTokens.bone(Theme.of(context).brightness);
    final surface = SkeletonTokens.surface(Theme.of(context).brightness);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      children: [
        const SizedBox(height: AppSpacing.lg),
        FlatmatesSkeletonBone(width: 220, color: bone),
        const SizedBox(height: AppSpacing.xl),
        Container(
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FlatmatesSkeletonBone(width: 140, color: bone),
                            const SizedBox(height: 4),
                            FlatmatesSkeletonBone(
                              width: 200,
                              height: 10,
                              color: bone,
                            ),
                          ],
                        ),
                      ),
                      FlatmatesSkeletonBone(
                        width: 48,
                        height: 28,
                        color: bone,
                        borderRadius: AppRadius.pillBorder,
                      ),
                    ],
                  ),
                ),
                if (i < itemCount - 1)
                  Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.md),
                    child: FlatmatesSkeletonBone(
                      width: double.infinity,
                      height: 1,
                      color: bone,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
