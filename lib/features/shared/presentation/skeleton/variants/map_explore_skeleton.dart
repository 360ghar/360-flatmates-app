import 'package:flutter/material.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_semantic_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../skeleton_bone.dart';
import '../skeleton_tokens.dart';

/// Map explore: full-bleed map, frosted top bar, controls, bottom sheet cards.
class MapExploreSkeleton extends StatelessWidget {
  const MapExploreSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final bone = SkeletonTokens.bone(brightness);
    final isDark = brightness == Brightness.dark;
    final safeAreaTop = MediaQuery.of(context).padding.top;

    // No Scaffold — map_view_page (and callers) already provide one.
    return Stack(
      children: [
        Positioned.fill(child: Container(color: bone.withValues(alpha: 0.5))),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            color: isDark
                ? AppSemanticColors.frostOverlayDark
                : AppSemanticColors.frostOverlayLight,
            child: Padding(
              padding: EdgeInsets.only(top: safeAreaTop),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  AppSpacing.md,
                  AppSpacing.screen,
                  AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    FlatmatesSkeletonBone(
                      width: 140,
                      height: 36,
                      color: bone,
                      borderRadius: AppRadius.pillBorder,
                    ),
                    const Spacer(),
                    FlatmatesSkeletonBone(
                      width: 40,
                      height: 40,
                      color: bone,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FlatmatesSkeletonBone(
                      width: 40,
                      height: 40,
                      color: bone,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: AppSpacing.screen,
          top: safeAreaTop + 80,
          child: Column(
            children: [
              for (var i = 0; i < 4; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.sm),
                FlatmatesSkeletonBone(
                  width: 40,
                  height: 40,
                  color: bone,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ],
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? AppSemanticColors.frostOverlayDark
                  : AppSemanticColors.frostOverlayLight,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.card),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: FlatmatesSkeletonBone(
                    width: 40,
                    height: 4,
                    color: bone,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FlatmatesSkeletonBone(
                      width: 80,
                      height: 12,
                      color: bone,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    24,
                  ),
                  child: Row(
                    children: [
                      Flexible(child: _MiniCard(bone: bone)),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(child: _MiniCard(bone: bone)),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(child: _MiniCard(bone: bone)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({required this.bone});

  final Color bone;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FlatmatesSkeletonBone(
          height: 100,
          color: bone,
          borderRadius: AppRadius.cardBorder,
        ),
        const SizedBox(height: AppSpacing.sm),
        FlatmatesSkeletonBone(width: 80, height: 12, color: bone),
        const SizedBox(height: 4),
        FlatmatesSkeletonBone(width: 110, height: 10, color: bone),
      ],
    );
  }
}
