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
        _FeedRow(bone: bone),
        const SizedBox(height: AppSpacing.xl),
        _SectionHeader(bone: bone),
        const SizedBox(height: AppSpacing.sm),
        _FeedRow(bone: bone),
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
    return _FeedRow(bone: SkeletonTokens.bone(Theme.of(context).brightness));
  }
}

/// A full row of card placeholders at the loaded grid's column count.
///
/// The row has no fixed height: each [_FeedCard] is a 1:1 photo plus the text
/// block the loaded card draws under it, so the row tracks the loaded row's
/// height at any column count. The fixed 320 it replaces was measured against
/// nothing: it was 11 dp too tall at 466 dp (309 loaded), 18 dp at 669
/// (302) and 43 dp at 951 (277), and the page jumped by that much the moment
/// the feed arrived — the opposite of what this skeleton is for.
class _FeedRow extends StatelessWidget {
  const _FeedRow({required this.bone});

  final Color bone;

  @override
  Widget build(BuildContext context) {
    final columns = AppBreakpoints.cardGridColumns(
      MediaQuery.sizeOf(context).width,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var column = 0; column < columns; column++) ...[
          if (column > 0) const SizedBox(width: AppSpacing.md),
          _FeedCard(bone: bone),
        ],
      ],
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

  /// Line heights of the loaded card's text block, in order: its own top
  /// padding, the title, the 2 dp gap, the locality row, the 4 dp gap, the
  /// meta-chip run, the 4 dp gap and the rent line.
  ///
  /// The block is 104 dp. A loaded card with a locality and no deposit measures
  /// 98 dp when its rent fits one line and 114 dp when the rent wraps to two
  /// (it does at the 163 dp card of a 4-column grid), so the row stays within
  /// ~16 dp of the loaded row at every column count. That residual is inherent:
  /// the wrap depends on the price string, which the skeleton cannot know. The
  /// bones are line-shaped rather than exact, so their sum is a fixed 104 dp
  /// rather than tracking the card's text metrics.
  static const double _topPad = AppSpacing.sm + AppSpacing.xxs;
  static const double _titleLine = 20;
  static const double _gapAfterTitle = AppSpacing.xxs;
  static const double _localityLine = 20;
  static const double _gapBeforeChips = AppSpacing.xs;
  static const double _chipRun = 24;
  static const double _gapBeforeRent = AppSpacing.xs;
  static const double _rentLine = 20;

  @override
  Widget build(BuildContext context) {
    final soft = SkeletonTokens.boneSoft(Theme.of(context).brightness);
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The loaded card's photo is `AspectRatio(1)`: the placeholder has to
          // be the same shape, or the image bone is not the size the photo will
          // be and the row height is wrong by exactly that difference.
          AspectRatio(
            aspectRatio: 1,
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
          const SizedBox(height: _topPad),
          FlatmatesSkeletonBone(width: 96, height: _titleLine, color: bone),
          const SizedBox(height: _gapAfterTitle),
          FlatmatesSkeletonBone(width: 128, height: _localityLine, color: bone),
          const SizedBox(height: _gapBeforeChips),
          FlatmatesSkeletonBone(width: 132, height: _chipRun, color: bone),
          const SizedBox(height: _gapBeforeRent),
          FlatmatesSkeletonBone(width: 84, height: _rentLine, color: bone),
        ],
      ),
    );
  }
}
