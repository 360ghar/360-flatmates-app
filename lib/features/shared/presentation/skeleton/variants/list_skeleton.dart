import 'package:flutter/material.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../skeleton_bone.dart';
import '../skeleton_tokens.dart';

/// Avatar + two text lines + trailing action bone.
class ListItemSkeleton extends StatelessWidget {
  const ListItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final bone = SkeletonTokens.bone(Theme.of(context).brightness);

    return Row(
      children: [
        FlatmatesSkeletonBone(
          width: 48,
          height: 48,
          color: bone,
          borderRadius: BorderRadius.circular(24),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FlatmatesSkeletonBone(width: 180, color: bone),
              const SizedBox(height: AppSpacing.sm),
              FlatmatesSkeletonBone(width: 120, height: 10, color: bone),
            ],
          ),
        ),
        FlatmatesSkeletonBone(
          width: 28,
          height: 28,
          color: bone,
          borderRadius: BorderRadius.circular(AppRadius.sm - 1),
        ),
      ],
    );
  }
}

/// Multiple list rows for full-page list loading.
///
/// Uses a non-scrolling [Column] so it can sit inside parent scroll views
/// (e.g. chats peer enrichment) without unbounded-height errors. Full-page
/// callers wrap it in [SingleChildScrollView] or use [ListView] via shrinkWrap
/// when they need scroll.
class ListSkeleton extends StatelessWidget {
  const ListSkeleton({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    // No outer padding — parents (pages / FlatmatesAsyncView) own insets so
    // this can nest inside already-padded scroll views.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < itemCount; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          const ListItemSkeleton(),
        ],
      ],
    );
  }
}
