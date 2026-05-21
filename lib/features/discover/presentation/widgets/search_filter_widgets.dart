import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';

import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../shared/presentation/flatmates_chip.dart';
import '../../../shared/presentation/flatmates_ui.dart';

class CollapsibleFilterSection extends StatefulWidget {
  const CollapsibleFilterSection({
    required this.title,
    required this.subtitle,
    required this.child,
    this.icon,
    this.iconColor,
    this.iconBgColor,
    this.initiallyExpanded = false,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBgColor;
  final bool initiallyExpanded;

  @override
  State<CollapsibleFilterSection> createState() =>
      _CollapsibleFilterSectionState();
}

class _CollapsibleFilterSectionState extends State<CollapsibleFilterSection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = widget.iconColor ?? AppSemanticColors.accent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Listener(
          onPointerDown: (_) => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                if (widget.icon != null)
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color:
                          widget.iconBgColor ??
                          accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.icon, size: 16, color: accentColor),
                  ),
                if (widget.icon != null)
                  const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: AppTypography.bodyLargeSize - 1,
                        ),
                      ),
                      if (widget.subtitle != null)
                        Text(
                          widget.subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppSemanticColors.textSecondaryFor(
                              theme.brightness,
                            ),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: AppMotion.fast,
                  curve: AppMotion.easeOutCubic,
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: AppSemanticColors.ink3,
                  ),
                ),
              ],
            ),
          ),
        ),
        ClipRect(
          child: AnimatedSize(
            duration: AppMotion.standard,
            curve: AppMotion.easeOutCubic,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.md,
                    ),
                    child: widget.child,
                  )
                : const SizedBox(width: double.infinity, height: 0),
          ),
        ),
      ],
    );
  }
}

class FilterSectionCard extends StatelessWidget {
  const FilterSectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.icon,
    this.iconColor,
    this.iconBgColor,
    this.initiallyExpanded = false,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBgColor;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm + AppSpacing.xs),
      decoration: BoxDecoration(
        color: isDark ? AppSemanticColors.darkSurface : AppSemanticColors.card,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(
          color: AppSemanticColors.line.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x061F1A14),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: CollapsibleFilterSection(
        title: title,
        subtitle: subtitle,
        icon: icon,
        iconColor: iconColor,
        iconBgColor: iconBgColor,
        initiallyExpanded: initiallyExpanded,
        child: child,
      ),
    );
  }
}

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
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
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
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
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
