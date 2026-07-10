import 'package:flutter/material.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../skeleton_bone.dart';
import '../skeleton_tokens.dart';

/// Visits page body: section labels + visit cards.
///
/// AppBar already shows the page title, so this starts at section content.
class VisitListSkeleton extends StatelessWidget {
  const VisitListSkeleton({super.key, this.itemCount = 3});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final bone = SkeletonTokens.bone(brightness);
    final surface = SkeletonTokens.surface(brightness);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.screen,
        AppSpacing.xl,
        120,
      ),
      children: [
        FlatmatesSkeletonBone(width: 160, height: 20, color: bone),
        const SizedBox(height: 4),
        FlatmatesSkeletonBone(width: 120, color: bone),
        const SizedBox(height: AppSpacing.lg),
        FlatmatesSkeletonBone(width: 90, color: bone),
        const SizedBox(height: AppSpacing.sm),
        for (var i = 0; i < itemCount && i < 2; i++) ...[
          _VisitCard(bone: bone, surface: surface, showActions: i == 0),
          const SizedBox(height: AppSpacing.md),
        ],
        FlatmatesSkeletonBone(width: 90, color: bone),
        const SizedBox(height: AppSpacing.sm),
        _VisitCard(bone: bone, surface: surface, showActions: true),
        const SizedBox(height: AppSpacing.md),
        FlatmatesSkeletonBone(width: 90, color: bone),
        const SizedBox(height: AppSpacing.sm),
        _VisitCard(bone: bone, surface: surface, showActions: false),
      ],
    );
  }
}

class _VisitCard extends StatelessWidget {
  const _VisitCard({
    required this.bone,
    required this.surface,
    required this.showActions,
  });

  final Color bone;
  final Color surface;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadius.cardBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FlatmatesSkeletonBone(
                width: 32,
                height: 32,
                color: bone,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FlatmatesSkeletonBone(width: 140, color: bone),
                    const SizedBox(height: 2),
                    FlatmatesSkeletonBone(width: 100, height: 10, color: bone),
                  ],
                ),
              ),
              FlatmatesSkeletonBone(
                width: 64,
                height: 24,
                color: bone,
                borderRadius: AppRadius.pillBorder,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              FlatmatesSkeletonBone(
                width: 12,
                height: 12,
                color: bone,
                borderRadius: BorderRadius.circular(6),
              ),
              const SizedBox(width: 4),
              FlatmatesSkeletonBone(width: 70, height: 10, color: bone),
              const SizedBox(width: AppSpacing.sm),
              FlatmatesSkeletonBone(
                width: 12,
                height: 12,
                color: bone,
                borderRadius: BorderRadius.circular(6),
              ),
              const SizedBox(width: 4),
              FlatmatesSkeletonBone(width: 60, height: 10, color: bone),
            ],
          ),
          if (showActions) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: FlatmatesSkeletonBone(
                    height: 30,
                    color: bone,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: FlatmatesSkeletonBone(
                    height: 30,
                    color: bone,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
