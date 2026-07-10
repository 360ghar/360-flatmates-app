import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../shared/presentation/flatmates_chip.dart';
import '../../../shared/presentation/flatmates_ui.dart';

/// A compact, always-expanded filter section: a small header row
/// (optional icon chip + title + inline selected-value) with its
/// options shown directly beneath. Replaces the old collapsible
/// section so all filter values are visible at once in the modal.
class CompactFilterSection extends StatelessWidget {
  const CompactFilterSection({
    required this.title,
    required this.child,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.iconBgColor,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBgColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = iconColor ?? AppSemanticColors.accent;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconBgColor ?? accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 16, color: accentColor),
                ),
                const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: AppTypography.bodyMdSize - 1,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
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
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
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
    this.keyPrefix,
    super.key,
  });

  final List<({String id, String label})> options;
  final String selectedId;
  final String anyKey;
  final ValueChanged<String> onSelected;
  final String? keyPrefix;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return Text(
        'No options available',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }
    final chipKeys = _chipKeys();
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: List.generate(options.length, (i) {
        final opt = options[i];
        return FlatmatesChip(
          key: chipKeys[i],
          label: opt.label,
          variant: FlatmatesChipVariant.choice,
          selected: selectedId == opt.id,
          onSelected: (_) => onSelected(opt.id),
        );
      }),
    );
  }

  /// Stable, Maestro-friendly chip keys that are also guaranteed unique.
  ///
  /// [_stableKeySuffix] deliberately collapses some catalog ids to a shared
  /// readable form so E2E selectors stay stable (e.g. `search_room_type_private`
  /// regardless of whether the server lists `private_room` or `master_bedroom`).
  /// But that collapse is many-to-one: if the server-driven catalog ever
  /// surfaces two ids that map to the same suffix (e.g. both `private_room` and
  /// `master_bedroom`, or `no_preference` alongside the `anyKey` option), the
  /// naive key would be duplicated and Flutter throws "Duplicate keys found".
  /// The first occurrence keeps the clean key (so Maestro selectors still
  /// resolve); any later duplicate falls back to its raw, unique id.
  List<Key?> _chipKeys() {
    if (keyPrefix == null) {
      return List<Key?>.filled(options.length, null);
    }
    final used = <String>{};
    final keys = <Key?>[];
    for (final opt in options) {
      final base = _stableKeySuffix(opt.id);
      var suffix = base;
      if (!used.add(suffix)) {
        var n = 2;
        do {
          suffix = n == 2 ? '${base}_${opt.id}' : '${base}_${opt.id}_$n';
          n++;
        } while (!used.add(suffix));
      }
      keys.add(Key('${keyPrefix!}_$suffix'));
    }
    return keys;
  }

  String _stableKeySuffix(String id) {
    if (id == anyKey) return 'any';
    return switch (id) {
      'private_room' || 'master_bedroom' => 'private',
      'shared_room' => 'shared',
      'no_preference' => 'any',
      _ => id,
    };
  }
}
