import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../bootstrap/catalog_helpers.dart';
import '../shared/presentation/components.dart';
import 'onboarding_controller.dart';

class BudgetTimelinePage extends ConsumerStatefulWidget {
  const BudgetTimelinePage({required this.onComplete, super.key});

  final void Function(Map<String, dynamic> data) onComplete;

  @override
  ConsumerState<BudgetTimelinePage> createState() => _BudgetTimelinePageState();
}

class _BudgetTimelinePageState extends ConsumerState<BudgetTimelinePage> {
  double _budgetMin = 5000;
  double _budgetMax = 25000;
  String _moveInTimeline = 'flexible';
  String? _budgetError;

  /// Hardcoded fallback timeline options used when the backend catalog is unavailable.
  static const _fallbackTimelineOptions = [
    _TimelineOption(key: 'immediate', icon: Icons.flash_on_rounded),
    _TimelineOption(
      key: 'this_month',
      icon: Icons.calendar_view_month_outlined,
    ),
    _TimelineOption(key: 'next_month', icon: Icons.event_outlined),
    _TimelineOption(key: 'flexible', icon: Icons.all_inclusive_rounded),
  ];

  /// Resolve timeline options: try backend catalog first, fall back to hardcoded.
  List<_TimelineOption> get _timelineOptions {
    final bootstrap = ref.watch(bootstrapControllerProvider).valueOrNull;
    final catalogOptions = bootstrap?.catalogOptions(
      'flatmates_move_in_timelines',
    );
    if (catalogOptions != null && catalogOptions.isNotEmpty) {
      return catalogOptions.map((opt) {
        final iconName = opt.meta['icon']?.toString() ?? '';
        return _TimelineOption(key: opt.id, icon: _iconFromName(iconName));
      }).toList();
    }
    return _fallbackTimelineOptions;
  }

  IconData _iconFromName(String name) {
    return switch (name) {
      'flash_on_rounded' => Icons.flash_on_rounded,
      'calendar_view_month_outlined' => Icons.calendar_view_month_outlined,
      'event_outlined' => Icons.event_outlined,
      'all_inclusive_rounded' => Icons.all_inclusive_rounded,
      _ => Icons.schedule_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final controllerState = ref.watch(onboardingControllerProvider);
    final completionPct = controllerState.completionPercentage;

    return Scaffold(
      body: SafeArea(
        minimum: AppSpacing.horizontalScreen,
        child: ListView(
          children: [
            const SizedBox(height: AppSpacing.sm),
            FlatmatesStepProgress.segments(
              currentStep: completionPct.round(),
              totalSteps: 100,
            ),
            const SizedBox(height: AppSpacing.section),
            Text(
              locale.budgetTimelineTitle,
              style: theme.textTheme.headlineLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              locale.budgetTimelineSubtitle,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppSemanticColors.textSecondaryFor(theme.brightness),
              ),
            ),
            const SizedBox(height: AppSpacing.section),
            FlatmatesCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    locale.monthlyBudgetLabel,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.screen),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${_budgetMin.toStringAsFixed(0)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppSemanticColors.accent,
                        ),
                      ),
                      Text(
                        '₹${_budgetMax.toStringAsFixed(0)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppSemanticColors.accent,
                        ),
                      ),
                    ],
                  ),
                  RangeSlider(
                    key: const Key('onboarding_budget_slider'),
                    values: RangeValues(_budgetMin, _budgetMax),
                    min: 5000,
                    max: 100000,
                    divisions: 19,
                    labels: RangeLabels(
                      '₹${_budgetMin.toStringAsFixed(0)}',
                      '₹${_budgetMax.toStringAsFixed(0)}',
                    ),
                    onChanged: (values) {
                      setState(() {
                        _budgetMin = values.start;
                        _budgetMax = values.end;
                        if (_budgetMin >= _budgetMax) {
                          _budgetError =
                              'Minimum budget must be less than maximum';
                        } else {
                          _budgetError = null;
                        }
                      });
                    },
                  ),
                  if (_budgetError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        _budgetError!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppSemanticColors.error,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FlatmatesCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    locale.moveInTimelineLabel,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: _timelineOptions.map((opt) {
                      final selected = _moveInTimeline == opt.key;
                      return FlatmatesChip(
                        key: Key('timeline_${opt.key}'),
                        icon: opt.icon,
                        label: _timelineLabel(locale, opt.key),
                        variant: FlatmatesChipVariant.choice,
                        selected: selected,
                        onSelected: (_) {
                          setState(() => _moveInTimeline = opt.key);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.screen + AppSpacing.lg),
            FlatmatesButton(
              key: const Key('onboarding_budget_next'),
              label: locale.onboardingNext,
              fullWidth: true,
              onPressed: _budgetError != null
                  ? null
                  : () => widget.onComplete({
                      'budget_min': _budgetMin,
                      'budget_max': _budgetMax,
                      'move_in_timeline': _moveInTimeline,
                    }),
              icon: Icons.arrow_forward_rounded,
            ),
          ],
        ),
      ),
    );
  }

  String _timelineLabel(AppLocalizations locale, String key) {
    // Try to find the label from the catalog first
    final bootstrap = ref.watch(bootstrapControllerProvider).valueOrNull;
    final catalogOptions = bootstrap?.catalogOptions(
      'flatmates_move_in_timelines',
    );
    if (catalogOptions != null) {
      for (final opt in catalogOptions) {
        if (opt.id == key) return opt.label;
      }
    }
    // Fall back to localized hardcoded labels
    switch (key) {
      case 'immediate':
        return locale.timelineImmediate;
      case 'this_month':
        return locale.timelineThisMonth;
      case 'next_month':
        return locale.timelineNextMonth;
      default:
        return locale.timelineFlexible;
    }
  }
}

class _TimelineOption {
  const _TimelineOption({required this.key, required this.icon});

  final String key;
  final IconData icon;
}
