import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Shimmer/skeleton loading states for feed, chats, cards.
///
/// Replaces `CircularProgressIndicator` on primary surfaces.
class FlatmatesSkeleton extends StatefulWidget {
  const FlatmatesSkeleton({
    super.key,
    this.itemCount = 1,
    this.variant = SkeletonVariant.card,
  });

  /// Card skeleton — approximates a listing card shape.
  const FlatmatesSkeleton.card({super.key})
    : itemCount = 1,
      variant = SkeletonVariant.card;

  /// List item skeleton — single row.
  const FlatmatesSkeleton.list({super.key})
    : itemCount = 1,
      variant = SkeletonVariant.listItem;

  /// Feed skeleton — multiple cards.
  const FlatmatesSkeleton.feed({super.key, this.itemCount = 3})
    : variant = SkeletonVariant.card;

  /// Profile header skeleton.
  const FlatmatesSkeleton.profile({super.key})
    : itemCount = 1,
      variant = SkeletonVariant.profile;

  final int itemCount;
  final SkeletonVariant variant;

  @override
  State<FlatmatesSkeleton> createState() => _FlatmatesSkeletonState();
}

enum SkeletonVariant { card, listItem, profile }

class _FlatmatesSkeletonState extends State<FlatmatesSkeleton> {
  @override
  Widget build(BuildContext context) {
    switch (widget.variant) {
      case SkeletonVariant.card:
        if (widget.itemCount <= 1) {
          return const _ShimmerBox(child: _CardSkeleton());
        }
        return SingleChildScrollView(
          child: Column(
            children: List.generate(
              widget.itemCount,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _ShimmerBox(child: const _CardSkeleton()),
              ),
            ),
          ),
        );
      case SkeletonVariant.listItem:
        if (widget.itemCount <= 1) {
          return const _ShimmerBox(child: _ListItemSkeleton());
        }
        return SingleChildScrollView(
          child: Column(
            children: List.generate(
              widget.itemCount,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _ShimmerBox(child: const _ListItemSkeleton()),
              ),
            ),
          ),
        );
      case SkeletonVariant.profile:
        return const _ShimmerBox(child: _ProfileSkeleton());
    }
  }
}

/// Internal shimmer animation wrapper.
class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox({required this.child});

  final Widget child;

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.skeletonShimmer,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark
        ? AppSemanticColors.darkSurfaceElevated
        : AppSemanticColors.paper2;
    final highlightColor = isDark
        ? AppSemanticColors.darkSurface
        : AppSemanticColors.card;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1 + 2 * _controller.value, 0),
              end: Alignment(1 + 2 * _controller.value, 0),
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final boneColor = isDark
        ? AppSemanticColors.darkSurfaceElevated
        : AppSemanticColors.paper2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image placeholder
        _Bone(
          width: double.infinity,
          height: 180,
          color: boneColor,
          borderRadius: AppRadius.cardBorder,
        ),
        const SizedBox(height: AppSpacing.md),
        // Title
        _Bone(width: 200, height: 16, color: boneColor),
        const SizedBox(height: AppSpacing.sm),
        // Subtitle
        _Bone(width: 140, height: 12, color: boneColor),
        const SizedBox(height: AppSpacing.sm),
        // Pills row
        Row(
          children: [
            _Bone(width: 60, height: 28, color: boneColor),
            const SizedBox(width: AppSpacing.sm),
            _Bone(width: 60, height: 28, color: boneColor),
            const SizedBox(width: AppSpacing.sm),
            _Bone(width: 60, height: 28, color: boneColor),
          ],
        ),
      ],
    );
  }
}

class _Bone extends StatelessWidget {
  const _Bone({
    required this.color,
    this.width,
    this.height = 14,
    this.borderRadius,
  });

  final Color color;
  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius ?? BorderRadius.circular(4),
      ),
    );
  }
}

class _ListItemSkeleton extends StatelessWidget {
  const _ListItemSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final boneColor = isDark
        ? AppSemanticColors.darkSurfaceElevated
        : AppSemanticColors.paper2;

    return Row(
      children: [
        _Bone(
          width: 48,
          height: 48,
          color: boneColor,
          borderRadius: BorderRadius.circular(24),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Bone(width: 180, height: 14, color: boneColor),
              const SizedBox(height: AppSpacing.sm),
              _Bone(width: 120, height: 10, color: boneColor),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final boneColor = isDark
        ? AppSemanticColors.darkSurfaceElevated
        : AppSemanticColors.paper2;

    return Column(
      children: [
        // Avatar
        _Bone(
          width: 130,
          height: 130,
          color: boneColor,
          borderRadius: BorderRadius.circular(65),
        ),
        const SizedBox(height: AppSpacing.lg),
        // Name
        _Bone(width: 160, height: 20, color: boneColor),
        const SizedBox(height: AppSpacing.sm),
        // Role badge
        _Bone(
          width: 100,
          height: 28,
          color: boneColor,
          borderRadius: AppRadius.pillBorder,
        ),
        const SizedBox(height: AppSpacing.sm),
        // Location
        _Bone(width: 140, height: 14, color: boneColor),
        const SizedBox(height: AppSpacing.section),
        // Menu rows
        for (var i = 0; i < 3; i++) ...[
          Row(
            children: [
              _Bone(
                width: 40,
                height: 40,
                color: boneColor,
                borderRadius: BorderRadius.circular(12),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _Bone(height: 16, color: boneColor)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}
