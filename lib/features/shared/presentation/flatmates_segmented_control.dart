import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';

/// Animated segment toggle for tabs like Likes/Chat, listing status, room type.
///
/// Uses a sliding pill indicator for smooth segment transitions.
class FlatmatesSegmentedControl<T> extends StatelessWidget {
  const FlatmatesSegmentedControl({
    required this.segments,
    required this.selected,
    required this.onChanged,
    super.key,
    this.segmentKeys,
  });

  /// Each segment: (value, label, optional icon).
  final List<(T, String, IconData?)> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  /// Optional per-segment keys, matched by index.
  final List<Key?>? segmentKeys;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inactiveColor = theme.brightness == Brightness.dark
        ? AppSemanticColors.paper3
        : AppSemanticColors.ink2;
    final selectedIndex = segments.indexWhere((s) => s.$1 == selected);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? AppSemanticColors.darkSurfaceElevated.withValues(alpha: 0.5)
            : AppSemanticColors.paper2,
        borderRadius: AppRadius.pillBorder,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = constraints.maxWidth / segments.length;

          return Stack(
            children: [
              // Sliding pill indicator — aligned to exact segment boundaries
              if (selectedIndex >= 0)
                AnimatedPositioned(
                  left: selectedIndex * segmentWidth,
                  top: 0,
                  bottom: 0,
                  width: segmentWidth,
                  duration: AppMotion.segmentTransition,
                  curve: AppMotion.easeOutQuart,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppSemanticColors.accent,
                        borderRadius: AppRadius.pillBorder,
                        boxShadow: [AppShadows.subtleGlowFor(theme.brightness)],
                      ),
                    ),
                  ),
                ),
              // Segment labels — non-positioned, determines Stack height
              Row(
                children: segments.asMap().entries.map((entry) {
                  final index = entry.key;
                  final (value, label, icon) = entry.value;
                  final isSelected = index == selectedIndex;

                  return Expanded(
                    child: GestureDetector(
                      key: segmentKeys != null && index < segmentKeys!.length
                          ? segmentKeys![index]
                          : null,
                      onTap: () => onChanged(value),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm + AppSpacing.xs,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (icon != null) ...[
                              Icon(
                                icon,
                                size: 16,
                                color: isSelected
                                    ? Colors.white
                                    : inactiveColor,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                            ],
                            Flexible(
                              child: Text(
                                label,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: isSelected
                                      ? Colors.white
                                      : inactiveColor,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}
