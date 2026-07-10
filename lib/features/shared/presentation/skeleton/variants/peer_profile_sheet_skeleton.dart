import 'package:flutter/material.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../skeleton_bone.dart';
import '../skeleton_tokens.dart';

/// Bottom-sheet peer/owner profile: avatar, name, match ring, chips, bio.
class PeerProfileSheetSkeleton extends StatelessWidget {
  const PeerProfileSheetSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final bone = SkeletonTokens.bone(Theme.of(context).brightness);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FlatmatesSkeletonBone(
            width: 40,
            height: 4,
            color: bone,
            borderRadius: BorderRadius.circular(2),
          ),
          const SizedBox(height: AppSpacing.xl),
          FlatmatesSkeletonBone(
            width: 88,
            height: 88,
            color: bone,
            borderRadius: BorderRadius.circular(44),
          ),
          const SizedBox(height: AppSpacing.md),
          FlatmatesSkeletonBone(width: 140, height: 20, color: bone),
          const SizedBox(height: AppSpacing.sm),
          FlatmatesSkeletonBone(
            width: 72,
            height: 72,
            color: bone,
            borderRadius: BorderRadius.circular(36),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.center,
            children: [
              for (final w in [64.0, 72.0, 56.0, 68.0])
                FlatmatesSkeletonBone(
                  width: w,
                  height: 28,
                  color: bone,
                  borderRadius: AppRadius.pillBorder,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Align(
            alignment: Alignment.centerLeft,
            child: FlatmatesSkeletonBone(width: 80, color: bone),
          ),
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
          FlatmatesSkeletonBone(width: 200, color: bone),
          const SizedBox(height: AppSpacing.xl),
          FlatmatesSkeletonBone(
            width: double.infinity,
            height: 48,
            color: bone,
            borderRadius: BorderRadius.circular(10),
          ),
        ],
      ),
    );
  }
}
