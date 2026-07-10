import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import 'skeleton_tokens.dart';

/// A single rectangular (or pill/circle) placeholder bone.
///
/// Prefer placing bones inside [FlatmatesSkeletonShimmer] so they animate
/// together. Color defaults to the theme bone token when omitted.
///
/// When [height] is null the bone expands to the parent’s max height
/// (useful inside [AspectRatio] / [Stack] / [Expanded]).
class FlatmatesSkeletonBone extends StatelessWidget {
  const FlatmatesSkeletonBone({
    super.key,
    this.width,
    this.height = 14,
    this.borderRadius,
    this.color,
  });

  /// Full-bleed bone that fills available constraints.
  const FlatmatesSkeletonBone.fill({super.key, this.borderRadius, this.color})
    : width = null,
      height = null;

  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? SkeletonTokens.bone(brightness),
        borderRadius: borderRadius ?? AppRadius.xsBorder,
      ),
    );
  }
}
