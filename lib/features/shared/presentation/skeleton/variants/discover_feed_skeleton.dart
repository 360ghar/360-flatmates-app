import 'package:flutter/material.dart';

import '../../../../../core/theme/app_breakpoints.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../skeleton_bone.dart';
import '../skeleton_tokens.dart';

/// Discover home: greeting header + two horizontal card sections.
class DiscoverFeedSkeleton extends StatelessWidget {
  const DiscoverFeedSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final bone = SkeletonTokens.bone(Theme.of(context).brightness);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.lg,
        AppSpacing.screen,
        120,
      ),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FlatmatesSkeletonBone(width: 140, height: 24, color: bone),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      FlatmatesSkeletonBone(width: 14, color: bone),
                      const SizedBox(width: 4),
                      FlatmatesSkeletonBone(width: 100, color: bone),
                      const SizedBox(width: 4),
                      FlatmatesSkeletonBone(
                        width: 16,
                        height: 16,
                        color: bone,
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            FlatmatesSkeletonBone(
              width: 52,
              height: 52,
              color: bone,
              borderRadius: AppRadius.mdBorder,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        _SectionHeader(bone: bone),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 320,
          child: Row(
            children: [
              _FeedCard(bone: bone),
              const SizedBox(width: AppSpacing.sm),
              _FeedCard(bone: bone),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _SectionHeader(bone: bone),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 320,
          child: Row(
            children: [
              _FeedCard(bone: bone),
              const SizedBox(width: AppSpacing.sm),
              _FeedCard(bone: bone),
            ],
          ),
        ),
      ],
    );
  }
}

/// One row of listing-card placeholders (no header, not scrollable).
///
/// Same column count as the loaded grid (`AppBreakpoints.cardGridColumns`), so
/// a wide screen does not reflow when the feed arrives (DESIGN.md §8: the
/// skeleton has the layout of the loaded view).
class DiscoverFeedCardsSkeleton extends StatelessWidget {
  const DiscoverFeedCardsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final bone = SkeletonTokens.bone(Theme.of(context).brightness);
    final columns = AppBreakpoints.cardGridColumns(
      MediaQuery.sizeOf(context).width,
    );

    return SizedBox(
      height: 320,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var column = 0; column < columns; column++) ...[
            if (column > 0) const SizedBox(width: AppSpacing.md),
            _FeedCard(bone: bone),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.bone});

  final Color bone;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        FlatmatesSkeletonBone(width: 120, height: 18, color: bone),
        FlatmatesSkeletonBone(width: 60, color: bone),
      ],
    );
  }
}

class _FeedCard extends StatelessWidget {
  const _FeedCard({required this.bone});

  final Color bone;

  @override
  Widget build(BuildContext context) {
    final soft = SkeletonTokens.boneSoft(Theme.of(context).brightness);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
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
          const SizedBox(height: AppSpacing.sm),
          FlatmatesSkeletonBone(width: 80, color: bone),
          const SizedBox(height: 4),
          FlatmatesSkeletonBone(width: 120, height: 12, color: bone),
          const SizedBox(height: 4),
          FlatmatesSkeletonBone(width: 100, height: 10, color: bone),
        ],
      ),
    );
  }
}
