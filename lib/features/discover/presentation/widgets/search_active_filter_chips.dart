import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../shared/presentation/flatmates_chip.dart';

/// Horizontal scrollable list of active filter chips with remove buttons.
class ActiveFilterChips extends StatelessWidget {
  const ActiveFilterChips({required this.filters, super.key});

  final List<({String label, VoidCallback onRemove})> filters;

  @override
  Widget build(BuildContext context) {
    if (filters.isEmpty) return const SizedBox.shrink();

    // Vertical spacing is owned by FilterSheet (gap after search / before budget).
    return SizedBox(
      // Chips are at least 48 tall (48 x 48 remove target); scales with text.
      // 56 = 48 target + the chip's vertical padding, so the close target is
      // never squeezed below the 48 dp minimum.
      height: AppSpacing.scaled(context, 56),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, index) {
          final filter = filters[index];
          return FlatmatesChip(
            label: filter.label,
            variant: FlatmatesChipVariant.removable,
            onRemoved: filter.onRemove,
          );
        },
      ),
    );
  }
}
