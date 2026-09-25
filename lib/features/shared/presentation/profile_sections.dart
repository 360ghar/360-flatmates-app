import 'package:flutter/material.dart';

import '../../../core/compatibility/compatibility_engine.dart';
import '../../../core/compatibility/compatibility_ring.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../l10n/gen/app_localizations.dart';
import 'lifestyle_labels.dart';

typedef PreferenceRow = ({IconData icon, String label, String value});

// ── Preferences section (icon + label + value rows) ────────────────────

class PreferencesCard extends StatelessWidget {
  const PreferencesCard({super.key, required this.rows});

  final List<PreferenceRow> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppSemanticColors.secondarySurfaceFor(theme.brightness),
        borderRadius: AppRadius.mdBorder,
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(
                  rows[i].icon,
                  size: 16,
                  color: AppSemanticColors.clayFor(theme.brightness),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    rows[i].label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppSemanticColors.textTertiaryFor(
                        theme.brightness,
                      ),
                    ),
                  ),
                ),
                Text(
                  rows[i].value,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppSemanticColors.textPrimaryFor(theme.brightness),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Section header (label) ─────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Type only: no decorative bar beside the label.
    return Semantics(
      header: true,
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: AppSemanticColors.textSecondaryFor(theme.brightness),
        ),
      ),
    );
  }
}

// ── Lifestyle preference icons ─────────────────────────────────────────

typedef LifestyleCell = ({IconData icon, String dim, String value});

/// 2-column grid for lifestyle preferences: bare clay icon, dimension and
/// value, on a paper-1 panel.
class LifestyleGrid extends StatelessWidget {
  const LifestyleGrid({super.key, required this.cells});

  final List<LifestyleCell> cells;

  @override
  Widget build(BuildContext context) {
    if (cells.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppSemanticColors.secondarySurfaceFor(theme.brightness),
        borderRadius: AppRadius.mdBorder,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellW = (constraints.maxWidth - AppSpacing.sm) / 2;
          return Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final cell in cells)
                SizedBox(
                  width: cellW,
                  child: Row(
                    children: [
                      Icon(
                        cell.icon,
                        size: 20,
                        color: AppSemanticColors.clayFor(theme.brightness),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cell.dim,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppSemanticColors.textTertiaryFor(
                                  theme.brightness,
                                ),
                              ),
                            ),
                            Text(
                              cell.value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppSemanticColors.textPrimaryFor(
                                  theme.brightness,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ── Compatibility helpers ──────────────────────────────────────────────

/// Tone label for overall match percentage.
String matchToneLabel(AppLocalizations locale, double percentage) {
  if (percentage >= 70) return locale.matchToneGreat;
  if (percentage >= 40) return locale.matchToneWorkable;
  return locale.matchToneGaps;
}

/// Bucket dimension scores into aligned (≥70), workable (≥40), gaps (<40).
({int aligned, int workable, int gaps}) dimensionBuckets(
  List<CompatibilityDimension> dimensions,
) {
  var aligned = 0;
  var workable = 0;
  var gaps = 0;
  for (final d in dimensions) {
    if (d.score >= 70) {
      aligned++;
    } else if (d.score >= 40) {
      workable++;
    } else {
      gaps++;
    }
  }
  return (aligned: aligned, workable: workable, gaps: gaps);
}

IconData compatDimensionIcon(String key) {
  switch (key) {
    case 'sleep_schedule':
      return Icons.bedtime_outlined;
    case 'cleanliness':
      return Icons.cleaning_services_outlined;
    case 'food_habits':
      return Icons.restaurant_outlined;
    case 'smoking':
      return Icons.smoking_rooms_outlined;
    case 'drinking':
      return Icons.local_bar_outlined;
    case 'smoking_drinking':
      return Icons.local_bar_outlined;
    case 'guests_policy':
      return Icons.groups_outlined;
    case 'work_style':
      return Icons.work_outline_rounded;
    default:
      return Icons.tune_outlined;
  }
}

// ── Compatibility breakdown section ────────────────────────────────────

class CompatValueChip extends StatelessWidget {
  const CompatValueChip({
    super.key,
    required this.label,
    required this.emphasized,
  });

  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: emphasized
              ? AppSemanticColors.coralSoftFor(theme.brightness)
              : theme.colorScheme.surface,
          borderRadius: AppRadius.pillBorder,
          border: Border.all(
            color: emphasized
                ? AppSemanticColors.clayFor(
                    theme.brightness,
                  ).withValues(alpha: 0.2)
                : AppSemanticColors.hairlineFor(theme.brightness),
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: emphasized ? FontWeight.w600 : FontWeight.w500,
            color: emphasized
                ? AppSemanticColors.clayInkFor(theme.brightness)
                : AppSemanticColors.textSecondaryFor(theme.brightness),
          ),
        ),
      ),
    );
  }
}

class CompatBreakdownSection extends StatelessWidget {
  const CompatBreakdownSection({super.key, required this.result});

  final CompatibilityResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    if (result.dimensions.isEmpty) return const SizedBox.shrink();

    final buckets = dimensionBuckets(result.dimensions);
    final overallColor = compatibilityScoreColor(
      result.percentage,
      brightness: Theme.of(context).brightness,
    );
    final tone = matchToneLabel(locale, result.percentage);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppSemanticColors.secondarySurfaceFor(theme.brightness),
        borderRadius: AppRadius.mdBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary strip
          Row(
            children: [
              CompatibilityRing(
                percentage: result.percentage,
                size: 52,
                strokeWidth: 3,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tone,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: overallColor,
                      ),
                    ),

                    Text(
                      [
                        if (buckets.aligned > 0)
                          locale.compatAlignedCount(buckets.aligned),
                        if (buckets.workable > 0)
                          locale.compatWorkableCount(buckets.workable),
                        if (buckets.gaps > 0)
                          locale.compatGapCount(buckets.gaps),
                      ].join(' \u00b7 '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppSemanticColors.textTertiaryFor(
                          theme.brightness,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ...result.dimensions.map((dim) {
            final score = (dim.score / 100).clamp(0.0, 1.0);
            final color = compatibilityScoreColor(
              dim.score,
              brightness: Theme.of(context).brightness,
            );
            final peerLabel = lifestyleValueLabel(
              locale,
              dim.key,
              dim.peerValue,
            );
            final userLabel = lifestyleValueLabel(
              locale,
              dim.key,
              dim.userValue,
            );
            final icon = compatDimensionIcon(dim.key);
            final glyph = dim.score >= 70
                ? Icons.check_circle_rounded
                : dim.score >= 40
                ? Icons.remove_circle_outline
                : Icons.error_outline;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.base),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        icon,
                        size: 16,
                        color: AppSemanticColors.textSecondaryFor(
                          theme.brightness,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          compatSummaryLabel(locale, dim.summary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppSemanticColors.textPrimaryFor(
                              theme.brightness,
                            ),
                          ),
                        ),
                      ),
                      Icon(glyph, size: 14, color: color),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '${dim.score.round()}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      CompatValueChip(label: peerLabel, emphasized: true),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '\u00b7',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppSemanticColors.textTertiaryFor(
                            theme.brightness,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      CompatValueChip(
                        label: '${locale.matchSelfFallbackName}: $userLabel',
                        emphasized: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ClipRRect(
                    borderRadius: AppRadius.xsBorder,
                    child: LinearProgressIndicator(
                      value: score,
                      backgroundColor: color.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
