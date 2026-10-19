import 'package:flutter/material.dart';

import '../../../../../core/theme/app_breakpoints.dart';
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
    // The row floor and the photo edge both grow with the viewport, exactly as
    // the loaded card's do. A hard 110 dp here under-reserved the row by 30 dp
    // from 600 and 50 dp from 900, so the list jumped the moment data arrived —
    // the reflow this skeleton exists to prevent (DESIGN.md §8).
    final thumb = AppBreakpoints.browseThumbSize(
      MediaQuery.sizeOf(context).width,
    );

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.md,
        AppSpacing.screen,
        AppSpacing.xl,
      ),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, _) {
        return Container(
          height: thumb,
          decoration: BoxDecoration(
            color: surface,
            borderRadius: AppRadius.cardBorder,
          ),
          child: Row(
            children: [
              FlatmatesSkeletonBone(
                width: thumb,
                height: thumb,
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
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          FlatmatesSkeletonBone(
                            width: 12,
                            height: 12,
                            color: bone,
                            borderRadius: AppRadius.smBorder,
                          ),
                          const SizedBox(width: AppSpacing.xxs),
                          Flexible(
                            child: FlatmatesSkeletonBone(
                              width: 100,
                              height: 10,
                              color: bone,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
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
