import 'package:flutter/material.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../skeleton_bone.dart';
import '../skeleton_tokens.dart';

/// Search filter sheet: budget slider card + chip sections + bottom CTA.
class SearchFiltersSkeleton extends StatelessWidget {
  const SearchFiltersSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final bone = SkeletonTokens.bone(Theme.of(context).brightness);
    final surface = SkeletonTokens.surface(Theme.of(context).brightness);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            children: [
              FlatmatesSkeletonBone(
                height: 48,
                color: bone,
                borderRadius: AppRadius.pillBorder,
              ),
              const SizedBox(height: AppSpacing.lg),
              _Card(
                surface: surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FlatmatesSkeletonBone(width: 120, height: 16, color: bone),
                    const SizedBox(height: AppSpacing.md),
                    FlatmatesSkeletonBone(
                      height: 6,
                      color: bone,
                      borderRadius: AppRadius.pillBorder,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        FlatmatesSkeletonBone(
                          width: 60,
                          height: 12,
                          color: bone,
                        ),
                        FlatmatesSkeletonBone(
                          width: 60,
                          height: 12,
                          color: bone,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              for (var i = 0; i < 4; i++) ...[
                _SectionCard(bone: bone, surface: surface),
                const SizedBox(height: AppSpacing.md),
              ],
              _SectionCard(bone: bone, surface: surface, extraRow: true),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: FlatmatesSkeletonBone(
            height: 52,
            color: bone,
            borderRadius: AppRadius.pillBorder,
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.surface, required this.child});

  final Color surface;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadius.cardBorder,
      ),
      child: child,
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.bone,
    required this.surface,
    this.extraRow = false,
  });

  final Color bone;
  final Color surface;
  final bool extraRow;

  @override
  Widget build(BuildContext context) {
    return _Card(
      surface: surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FlatmatesSkeletonBone(
                width: 36,
                height: 36,
                color: bone,
                borderRadius: BorderRadius.circular(12),
              ),
              const SizedBox(width: AppSpacing.md),
              FlatmatesSkeletonBone(width: 140, color: bone),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.sm),
                FlatmatesSkeletonBone(
                  width: 72,
                  height: 32,
                  color: bone,
                  borderRadius: AppRadius.pillBorder,
                ),
              ],
            ],
          ),
          if (extraRow) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                FlatmatesSkeletonBone(
                  width: 72,
                  height: 32,
                  color: bone,
                  borderRadius: AppRadius.pillBorder,
                ),
                const SizedBox(width: AppSpacing.sm),
                FlatmatesSkeletonBone(
                  width: 72,
                  height: 32,
                  color: bone,
                  borderRadius: AppRadius.pillBorder,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
