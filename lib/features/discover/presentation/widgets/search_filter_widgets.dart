import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../shared/presentation/flatmates_card.dart';
import '../../../shared/presentation/flatmates_chip.dart';
import '../../../shared/presentation/flatmates_ui.dart';

/// Collapsible filter section using [ExpansionTile] with icon + styled header.
class CollapsibleFilterSection extends StatelessWidget {
  const CollapsibleFilterSection({
    required this.title,
    required this.subtitle,
    required this.child,
    this.icon,
    this.initiallyExpanded = false,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final IconData? icon;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ExpansionTile(
      title: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppSemanticColors.accent),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 12,
                color: AppSemanticColors.textSecondaryFor(theme.brightness),
              ),
            )
          : null,
      initiallyExpanded: initiallyExpanded,
      shape: const RoundedRectangleBorder(),
      collapsedShape: const RoundedRectangleBorder(),
      childrenPadding: const EdgeInsets.only(bottom: 14),
      children: [child],
    );
  }
}

/// A filter card wrapping a [CollapsibleFilterSection] in a [FlatmatesCard].
class FilterSectionCard extends StatelessWidget {
  const FilterSectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.icon,
    this.initiallyExpanded = false,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final IconData? icon;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return FlatmatesCard(
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: CollapsibleFilterSection(
        title: title,
        subtitle: subtitle,
        icon: icon,
        initiallyExpanded: initiallyExpanded,
        child: child,
      ),
    );
  }
}

/// Chip wrap for location-style filter where values are string list.
class FilterChipWrap extends StatelessWidget {
  const FilterChipWrap({
    required this.values,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<String> values;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return Text(
        'No options available',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.map((value) {
        return FlatmatesChip(
          label: humanizeFlatmatesToken(value),
          variant: FlatmatesChipVariant.filter,
          selected: selected == value,
          onSelected: (_) => onSelected(value),
        );
      }).toList(),
    );
  }
}

/// Filter chips built from catalog or fallback options.
class CatalogFilterChips extends StatelessWidget {
  const CatalogFilterChips({
    required this.options,
    required this.selectedId,
    required this.anyKey,
    required this.onSelected,
    super.key,
  });

  final List<({String id, String label})> options;
  final String selectedId;
  final String anyKey;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return Text(
        'No options available',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        return FlatmatesChip(
          label: opt.label,
          variant: FlatmatesChipVariant.choice,
          selected: selectedId == opt.id,
          onSelected: (_) => onSelected(opt.id),
        );
      }).toList(),
    );
  }
}
