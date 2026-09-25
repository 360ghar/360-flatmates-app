import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';

/// Segment toggle for tabs like Likes/Chat, listing status, room type.
///
/// The selected segment is a raised paper sheet that slides between
/// segments (instant under reduce motion).
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
    final brightness = theme.brightness;
    final ink = AppSemanticColors.textPrimaryFor(brightness);
    final inactive = AppSemanticColors.textSecondaryFor(brightness);
    final selectedIndex = segments.indexWhere((s) => s.$1 == selected);
    const innerRadius = BorderRadius.all(
      Radius.circular(AppRadius.md - AppSpacing.xs),
    );

    if (segments.isEmpty) {
      return const SizedBox.shrink();
    }

    // Track on paper-1; the selected segment rises one layer (paper-2 + e1),
    // like the active tab in the nav strip (DESIGN.md §8).
    return Container(
      padding: AppSpacing.edgeXs,
      decoration: BoxDecoration(
        color: AppSemanticColors.paper1For(brightness),
        borderRadius: AppRadius.mdBorder,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width;
          final segmentWidth = maxWidth / segments.length;

          return Stack(
            children: [
              if (selectedIndex >= 0)
                AnimatedPositioned(
                  left: selectedIndex * segmentWidth,
                  top: 0,
                  bottom: 0,
                  width: segmentWidth,
                  duration: AppMotion.durationOrZero(
                    context,
                    AppMotion.standard,
                  ),
                  curve: AppMotion.paperOut,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppSemanticColors.paper2For(brightness),
                      borderRadius: innerRadius,
                      boxShadow: AppShadows.e1(brightness),
                    ),
                  ),
                ),
              // Segment labels: non-positioned, so they set the height.
              Row(
                children: segments.asMap().entries.map((entry) {
                  final index = entry.key;
                  final (value, label, icon) = entry.value;
                  final isSelected = index == selectedIndex;
                  final color = isSelected ? ink : inactive;

                  return Expanded(
                    child: Semantics(
                      button: true,
                      selected: isSelected,
                      inMutuallyExclusiveGroup: true,
                      child: InkWell(
                        key: segmentKeys != null && index < segmentKeys!.length
                            ? segmentKeys![index]
                            : null,
                        onTap: () => onChanged(value),
                        borderRadius: innerRadius,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: AppSpacing.md,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (icon != null) ...[
                                Icon(icon, size: 16, color: color),
                                const SizedBox(width: AppSpacing.xs),
                              ],
                              Flexible(
                                child: Text(
                                  label,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: color,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
