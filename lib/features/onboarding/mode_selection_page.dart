import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../bootstrap/catalog_helpers.dart';
import '../shared/presentation/components.dart';

class ModeSelectionPage extends ConsumerStatefulWidget {
  const ModeSelectionPage({required this.onModeSelected, super.key});

  final void Function(String mode) onModeSelected;

  /// Optional back handler. Mode selection is the first interactive step, so
  /// this is normally null and no back affordance is shown.

  @override
  ConsumerState<ModeSelectionPage> createState() => _ModeSelectionPageState();
}

class _ModeSelectionPageState extends ConsumerState<ModeSelectionPage> {
  String? _selectedMode;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final bootstrap = ref.watch(bootstrapControllerProvider).valueOrNull;
    final catalogModes =
        bootstrap?.catalogOptions('flatmates_modes') ?? const [];
    final modes = catalogModes.isNotEmpty
        ? catalogModes
        : [
            CatalogOption(
              id: 'co_hunter',
              label: locale.modeCoHunter,
              meta: {'description': locale.modeCoHunterDesc},
            ),
            CatalogOption(
              id: 'room_poster',
              label: locale.modeRoomPoster,
              meta: {'description': locale.modeRoomPosterDesc},
            ),
            CatalogOption(
              id: 'open_to_both',
              label: locale.modeOpenToBoth,
              meta: {'description': locale.modeOpenToBothDesc},
            ),
          ];

    return Material(
      // Steps sit inside the onboarding FlatmatesScreen, which owns the
      // scaffold and safe area; this only gives fields a Material ancestor.
      type: MaterialType.transparency,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.lg,
          AppSpacing.screen,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Heading, subtitle and cards scroll together; the CTA stays.
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locale.modeSelectionTitle,
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      locale.modeSelectionSubtitle,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppSemanticColors.textSecondaryFor(
                          theme.brightness,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    for (final mode in modes)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                        child: _ModeCard(
                          key: Key('mode_${mode.id}'),
                          icon: _iconForMode(mode.id),
                          title: mode.label,
                          description:
                              mode.meta['description']?.toString() ?? '',
                          isSelected: _selectedMode == mode.id,
                          onTap: () => setState(() => _selectedMode = mode.id),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
              child: FlatmatesButton(
                key: const Key('mode_continue'),
                label: locale.modeContinue,
                fullWidth: true,
                onPressed: _selectedMode != null
                    ? () => widget.onModeSelected(_selectedMode!)
                    : null,
                icon: Icons.arrow_forward_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForMode(String mode) {
    return switch (mode) {
      'room_poster' => Icons.home_outlined,
      'open_to_both' => Icons.swap_horiz,
      _ => Icons.group_outlined,
    };
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final clay = AppSemanticColors.clayFor(brightness);

    // FlatmatesCard owns the press feedback. Selected = clay-soft fill and a
    // clay edge (DESIGN.md §8), plus a check in place of the chevron.
    return Semantics(
      selected: isSelected,
      inMutuallyExclusiveGroup: true,
      child: FlatmatesCard(
        onTap: onTap,
        backgroundColor: isSelected
            ? AppSemanticColors.coralSoftFor(brightness)
            : null,
        borderColor: isSelected
            ? clay
            : AppSemanticColors.hairlineFor(brightness).withValues(alpha: 0.4),
        child: Row(
          children: [
            Icon(icon, color: clay, size: 28),
            const SizedBox(width: AppSpacing.base),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppSemanticColors.textSecondaryFor(brightness),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.chevron_right,
              color: isSelected
                  ? clay
                  : AppSemanticColors.textTertiaryFor(brightness),
            ),
          ],
        ),
      ),
    );
  }
}
