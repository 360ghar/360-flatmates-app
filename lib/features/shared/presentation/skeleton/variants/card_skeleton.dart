import 'package:flutter/material.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../skeleton_bone.dart';
import '../skeleton_tokens.dart';

/// Listing-style card: image hero, heart bone, price + title lines.
class CardSkeleton extends StatelessWidget {
  const CardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final bone = SkeletonTokens.bone(Theme.of(context).brightness);
    final soft = SkeletonTokens.boneSoft(Theme.of(context).brightness);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 16 / 10,
          child: Stack(
            fit: StackFit.expand,
            children: [
              FlatmatesSkeletonBone.fill(
                color: bone,
                borderRadius: AppRadius.cardBorder,
              ),
              Positioned(
                top: AppSpacing.sm,
                right: AppSpacing.sm,
                child: FlatmatesSkeletonBone(
                  width: 28,
                  height: 28,
                  color: soft,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FlatmatesSkeletonBone(width: 100, height: 16, color: bone),
              const SizedBox(height: AppSpacing.xs),
              FlatmatesSkeletonBone(width: 180, color: bone),
              const SizedBox(height: AppSpacing.xs),
              FlatmatesSkeletonBone(width: 140, height: 10, color: bone),
              const SizedBox(height: AppSpacing.xs),
              FlatmatesSkeletonBone(width: 120, height: 10, color: bone),
            ],
          ),
        ),
      ],
    );
  }
}
