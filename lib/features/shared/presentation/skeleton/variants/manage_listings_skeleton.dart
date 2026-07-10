import 'package:flutter/material.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../skeleton_bone.dart';
import '../skeleton_tokens.dart';

/// Manage-listings **cards only**.
///
/// The manage page already paints title, CTA, and segmented control above the
/// async body, so this skeleton must not duplicate that chrome.
class ManageListingsSkeleton extends StatelessWidget {
  const ManageListingsSkeleton({super.key, this.itemCount = 2});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final bone = SkeletonTokens.bone(brightness);
    final surface = SkeletonTokens.surface(brightness);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.xs,
        AppSpacing.screen,
        AppSpacing.xl + AppSpacing.md,
      ),
      children: [
        for (var i = 0; i < itemCount; i++) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Container(
              decoration: BoxDecoration(
                color: surface,
                borderRadius: AppRadius.cardBorder,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      FlatmatesSkeletonBone(
                        width: double.infinity,
                        height: 160,
                        color: bone,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppRadius.card),
                        ),
                      ),
                      Positioned(
                        top: AppSpacing.sm,
                        right: AppSpacing.sm,
                        child: FlatmatesSkeletonBone(
                          width: 64,
                          height: 28,
                          color: bone,
                          borderRadius: AppRadius.pillBorder,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FlatmatesSkeletonBone(
                          width: 160,
                          height: 16,
                          color: bone,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        FlatmatesSkeletonBone(width: 80, color: bone),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            for (final w in [40.0, 48.0, 44.0]) ...[
                              FlatmatesSkeletonBone(
                                width: w,
                                height: 20,
                                color: bone,
                                borderRadius: AppRadius.pillBorder,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  FlatmatesSkeletonBone(
                    width: double.infinity,
                    height: 1,
                    color: bone,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        FlatmatesSkeletonBone(
                          width: 28,
                          height: 28,
                          color: bone,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        FlatmatesSkeletonBone(
                          width: 100,
                          height: 12,
                          color: bone,
                        ),
                        const Spacer(),
                        FlatmatesSkeletonBone(
                          width: 80,
                          height: 10,
                          color: bone,
                        ),
                      ],
                    ),
                  ),
                  FlatmatesSkeletonBone(
                    width: double.infinity,
                    height: 1,
                    color: bone,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      children: [
                        for (var row = 0; row < 2; row++) ...[
                          if (row > 0) const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              for (var j = 0; j < 3; j++) ...[
                                Expanded(
                                  child: FlatmatesSkeletonBone(
                                    height: 28,
                                    color: bone,
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.sm,
                                    ),
                                  ),
                                ),
                                if (j < 2) const SizedBox(width: AppSpacing.sm),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
