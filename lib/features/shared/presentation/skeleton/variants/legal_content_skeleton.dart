import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../skeleton_bone.dart';
import '../skeleton_tokens.dart';

/// Legal / markdown page: title + paragraph line bones.
class LegalContentSkeleton extends StatelessWidget {
  const LegalContentSkeleton({super.key});

  static const _lineWidths = <double?>[
    null,
    null,
    0.85,
    null,
    0.7,
    null,
    null,
    0.9,
    0.55,
    null,
    0.75,
    null,
  ];

  @override
  Widget build(BuildContext context) {
    final bone = SkeletonTokens.bone(Theme.of(context).brightness);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      children: [
        FlatmatesSkeletonBone(width: 200, height: 22, color: bone),
        const SizedBox(height: AppSpacing.xl),
        for (final fraction in _lineWidths) ...[
          LayoutBuilder(
            builder: (context, constraints) {
              final width = fraction == null
                  ? double.infinity
                  : constraints.maxWidth * fraction;
              return FlatmatesSkeletonBone(
                width: width,
                height: 12,
                color: bone,
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}
