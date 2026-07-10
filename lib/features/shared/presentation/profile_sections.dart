import 'package:flutter/material.dart';

import '../../../core/compatibility/compatibility_engine.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../l10n/gen/app_localizations.dart';
import 'flatmates_ui.dart';

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
        color: AppSemanticColors.paper2,
        borderRadius: AppRadius.mdBorder,
        border: Border.all(color: AppSemanticColors.line, width: 0.5),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(rows[i].icon, size: 16, color: AppSemanticColors.accent),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    rows[i].label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 11,
                      color: AppSemanticColors.textTertiaryFor(
                        theme.brightness,
                      ),
                    ),
                  ),
                ),
                Text(
                  rows[i].value,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 12,
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

// ── Section header (accent bar + label) ────────────────────────────────

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: const BoxDecoration(
            color: AppSemanticColors.accent,
            borderRadius: AppRadius.smBorder,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppSemanticColors.textSecondaryFor(theme.brightness),
          ),
        ),
      ],
    );
  }
}

// ── Lifestyle preference icons ─────────────────────────────────────────

typedef LifestyleCell = ({IconData icon, String dim, String value});

/// 2-column icon tile grid for lifestyle preferences. Matches the style used
/// on the swipe card: paper2 container, accentSoft icon boxes, dim/value text.
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
        color: AppSemanticColors.paper2,
        borderRadius: AppRadius.mdBorder,
        border: Border.all(color: AppSemanticColors.line, width: 0.5),
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
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: AppSemanticColors.accentSoft,
                          borderRadius: AppRadius.smBorder,
                        ),
                        child: Icon(
                          cell.icon,
                          size: 16,
                          color: AppSemanticColors.accent,
                        ),
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
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 10,
                                color: AppSemanticColors.textTertiaryFor(
                                  theme.brightness,
                                ),
                              ),
                            ),
                            Text(
                              cell.value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 12,
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: emphasized
              ? AppSemanticColors.accentSoft
              : theme.colorScheme.surface,
          borderRadius: AppRadius.pillBorder,
          border: Border.all(
            color: emphasized
                ? AppSemanticColors.accent.withValues(alpha: 0.2)
                : AppSemanticColors.line,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 10,
            fontWeight: emphasized ? FontWeight.w600 : FontWeight.w500,
            color: emphasized
                ? AppSemanticColors.accent
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
    final overallColor = compatibilityScoreColor(result.percentage);
    final tone = matchToneLabel(locale, result.percentage);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppSemanticColors.paper2,
        borderRadius: AppRadius.mdBorder,
        border: Border.all(color: AppSemanticColors.line, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary strip
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: overallColor, width: 3),
                  color: overallColor.withValues(alpha: 0.08),
                ),
                child: Text(
                  result.percentage > 0
                      ? '${result.percentage.round()}%'
                      : '\u2014',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: overallColor,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tone,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: overallColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (buckets.aligned > 0)
                          locale.compatAlignedCount(buckets.aligned),
                        if (buckets.workable > 0)
                          locale.compatWorkableCount(buckets.workable),
                        if (buckets.gaps > 0)
                          locale.compatGapCount(buckets.gaps),
                      ].join(' \u00b7 '),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 11,
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
          const SizedBox(height: AppSpacing.md),
          Container(height: 0.5, color: AppSemanticColors.line),
          const SizedBox(height: AppSpacing.md),
          ...result.dimensions.map((dim) {
            final score = (dim.score / 100).clamp(0.0, 1.0);
            final color = compatibilityScoreColor(dim.score);
            final peerLabel = humanizeFlatmatesToken(dim.peerValue);
            final userLabel = humanizeFlatmatesToken(dim.userValue);
            final icon = compatDimensionIcon(dim.key);
            final glyph = dim.score >= 70
                ? Icons.check_circle_rounded
                : dim.score >= 40
                ? Icons.remove_circle_outline
                : Icons.error_outline;

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
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
                          dim.summary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppSemanticColors.textPrimaryFor(
                              theme.brightness,
                            ),
                          ),
                        ),
                      ),
                      Icon(glyph, size: 14, color: color),
                      const SizedBox(width: 4),
                      Text(
                        '${dim.score.round()}%',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      CompatValueChip(label: peerLabel, emphasized: true),
                      const SizedBox(width: 6),
                      Text(
                        '\u00b7',
                        style: TextStyle(
                          color: AppSemanticColors.textTertiaryFor(
                            theme.brightness,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      CompatValueChip(
                        label: '${locale.matchSelfFallbackName}: $userLabel',
                        emphasized: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
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
