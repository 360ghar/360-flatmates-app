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
      // Dense chip padding (~26–28) + hairline; keep a little slack for
      // the close glyph and selection scale.
      height: 32,
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
