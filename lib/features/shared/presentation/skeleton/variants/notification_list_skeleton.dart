import 'package:flutter/material.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../skeleton_bone.dart';
import '../skeleton_tokens.dart';

/// Notification list items with soft unread tint (no side stripe).
class NotificationListSkeleton extends StatelessWidget {
  const NotificationListSkeleton({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final bone = SkeletonTokens.bone(brightness);

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      itemCount: itemCount,
      itemBuilder: (_, index) {
        final isUnread = index < 2;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          decoration: BoxDecoration(
            color: isUnread ? SkeletonTokens.unreadTint(brightness) : null,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            color: isUnread
                ? Colors.transparent
                : Theme.of(context).cardTheme.color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: AppSpacing.edgeLg,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FlatmatesSkeletonBone(
                    width: 48,
                    height: 48,
                    color: bone,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FlatmatesSkeletonBone(
                          width: 140,
                          height: 16,
                          color: bone,
                        ),
                        const SizedBox(height: 4),
                        FlatmatesSkeletonBone(
                          width: double.infinity,
                          height: 12,
                          color: bone,
                        ),
                        const SizedBox(height: 4),
                        FlatmatesSkeletonBone(
                          width: 180,
                          height: 12,
                          color: bone,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: FlatmatesSkeletonBone(
                          width: 40,
                          height: 10,
                          color: bone,
                        ),
                      ),
                      if (isUnread) ...[
                        const SizedBox(height: 6),
                        FlatmatesSkeletonBone(
                          width: 10,
                          height: 10,
                          color: bone,
                          borderRadius: AppRadius.pillBorder,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
