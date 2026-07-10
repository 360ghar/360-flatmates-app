import 'package:flutter/material.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../skeleton_bone.dart';
import '../skeleton_tokens.dart';

/// Conversation cards only.
///
/// The chats page already owns the segmented control and safety banner, so
/// this skeleton must not re-draw them (and must not use an unbounded
/// [ListView] inside the parent scroll view).
class ConversationListSkeleton extends StatelessWidget {
  const ConversationListSkeleton({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final bone = SkeletonTokens.bone(brightness);
    final surface = SkeletonTokens.surface(brightness);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < itemCount; i++) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: AppRadius.cardBorder,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: FlatmatesSkeletonBone(
                                    width: 120,
                                    color: bone,
                                  ),
                                ),
                                if (i < 2) ...[
                                  const SizedBox(width: AppSpacing.sm),
                                  FlatmatesSkeletonBone(
                                    width: 24,
                                    height: 16,
                                    color: bone,
                                    borderRadius: AppRadius.pillBorder,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          FlatmatesSkeletonBone(
                            width: 60,
                            height: 10,
                            color: bone,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      FlatmatesSkeletonBone(width: 70, height: 10, color: bone),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          FlatmatesSkeletonBone(
                            width: 13,
                            height: 13,
                            color: bone,
                            borderRadius: BorderRadius.circular(6.5),
                          ),
                          const SizedBox(width: 2),
                          FlatmatesSkeletonBone(
                            width: 100,
                            height: 10,
                            color: bone,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      FlatmatesSkeletonBone(
                        width: double.infinity,
                        height: 12,
                        color: bone,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: SkeletonTokens.boneSoft(
                            brightness,
                          ).withValues(alpha: 0.5),
                          borderRadius: AppRadius.sheetBorder,
                        ),
                        child: Row(
                          children: [
                            FlatmatesSkeletonBone(
                              width: 40,
                              height: 40,
                              color: bone,
                              borderRadius: AppRadius.cardBorder,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FlatmatesSkeletonBone(
                                  width: 100,
                                  height: 10,
                                  color: bone,
                                ),
                                const SizedBox(height: 4),
                                FlatmatesSkeletonBone(
                                  width: 70,
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
              ],
            ),
          ),
          if (i < itemCount - 1) const SizedBox(height: AppSpacing.lg),
        ],
      ],
    );
  }
}
