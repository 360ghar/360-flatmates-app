import 'package:flutter/material.dart';

import '../../../../../core/theme/app_semantic_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../skeleton_bone.dart';
import '../skeleton_tokens.dart';

/// Alternating sent/received message bubbles.
class ChatMessagesSkeleton extends StatelessWidget {
  const ChatMessagesSkeleton({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final bone = SkeletonTokens.bone(Theme.of(context).brightness);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      itemCount: itemCount * 2,
      itemBuilder: (_, index) {
        final isTimestampRow = index.isOdd;
        final msgIndex = index ~/ 2;
        final isMine = msgIndex.isEven;

        if (isTimestampRow) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              mainAxisAlignment: isMine
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: [
                FlatmatesSkeletonBone(width: 40, height: 8, color: bone),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            mainAxisAlignment: isMine
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMine) ...[
                FlatmatesSkeletonBone(
                  width: 32,
                  height: 32,
                  color: bone,
                  borderRadius: BorderRadius.circular(16),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                  decoration: BoxDecoration(
                    color: isMine
                        ? AppSemanticColors.accent.withValues(alpha: 0.2)
                        : SkeletonTokens.surface(Theme.of(context).brightness),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FlatmatesSkeletonBone(
                        width: msgIndex % 3 == 0
                            ? double.infinity
                            : 180 + (msgIndex % 3) * 20.0,
                        color: isMine
                            ? AppSemanticColors.accent.withValues(alpha: 0.15)
                            : bone,
                      ),
                      if (msgIndex % 2 == 0) ...[
                        const SizedBox(height: 8),
                        FlatmatesSkeletonBone(
                          width: 140,
                          color: isMine
                              ? AppSemanticColors.accent.withValues(alpha: 0.15)
                              : bone,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
