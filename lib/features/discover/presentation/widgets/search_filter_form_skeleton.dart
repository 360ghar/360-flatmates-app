import 'package:flutter/material.dart';

import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class SearchFilterFormSkeleton extends StatefulWidget {
  const SearchFilterFormSkeleton({super.key});

  @override
  State<SearchFilterFormSkeleton> createState() =>
      _SearchFilterFormSkeletonState();
}

class _SearchFilterFormSkeletonState extends State<SearchFilterFormSkeleton>
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark
        ? AppSemanticColors.darkSurfaceElevated
        : AppSemanticColors.paper2;
    final highlight = isDark
        ? AppSemanticColors.darkSurface
        : AppSemanticColors.card;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(-1 + 2 * _controller.value, 0),
            end: Alignment(1 + 2 * _controller.value, 0),
            colors: [base, highlight, base],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(bounds),
          child: child,
        );
      },
      child: Column(
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
                _Bone(
                  height: 48,
                  color: base,
                  borderRadius: AppRadius.pillBorder,
                ),
                const SizedBox(height: AppSpacing.lg),
                _Card(
                  color: base,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Bone(width: 120, height: 16, color: base),
                      const SizedBox(height: AppSpacing.md),
                      _Bone(
                        height: 6,
                        color: base,
                        borderRadius: AppRadius.pillBorder,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _Bone(width: 60, height: 12, color: base),
                          _Bone(width: 60, height: 12, color: base),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ..._buildSkeletonCards(base),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: _Bone(
              height: 52,
              color: base,
              borderRadius: AppRadius.pillBorder,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSkeletonCards(Color base) {
    return [
      for (var i = 0; i < 4; i++) ...[
        _SectionCard(boneColor: base),
        const SizedBox(height: AppSpacing.md),
      ],
      _SectionCard(boneColor: base, extraRow: true),
    ];
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.4),
        borderRadius: AppRadius.cardBorder,
      ),
      child: child,
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.boneColor, this.extraRow = false});

  final Color boneColor;
  final bool extraRow;

  @override
  Widget build(BuildContext context) {
    return _Card(
      color: boneColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Bone(
                width: 36,
                height: 36,
                color: boneColor,
                borderRadius: BorderRadius.circular(12),
              ),
              const SizedBox(width: AppSpacing.md),
              _Bone(width: 140, color: boneColor),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _Bone(
                width: 72,
                height: 32,
                color: boneColor,
                borderRadius: AppRadius.pillBorder,
              ),
              const SizedBox(width: AppSpacing.sm),
              _Bone(
                width: 72,
                height: 32,
                color: boneColor,
                borderRadius: AppRadius.pillBorder,
              ),
              const SizedBox(width: AppSpacing.sm),
              _Bone(
                width: 72,
                height: 32,
                color: boneColor,
                borderRadius: AppRadius.pillBorder,
              ),
            ],
          ),
          if (extraRow) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                _Bone(
                  width: 72,
                  height: 32,
                  color: boneColor,
                  borderRadius: AppRadius.pillBorder,
                ),
                const SizedBox(width: AppSpacing.sm),
                _Bone(
                  width: 72,
                  height: 32,
                  color: boneColor,
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
