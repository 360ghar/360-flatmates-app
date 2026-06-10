import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../bootstrap/catalog_helpers.dart';
import '../shared/presentation/components.dart';

class ModeSelectionPage extends ConsumerStatefulWidget {
  const ModeSelectionPage({required this.onModeSelected, super.key});

  final void Function(String mode) onModeSelected;

  @override
  ConsumerState<ModeSelectionPage> createState() => _ModeSelectionPageState();
}

class _ModeSelectionPageState extends ConsumerState<ModeSelectionPage> {
  String? _selectedMode;

  static const _totalSteps = 4;

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

    return Scaffold(
      body: SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Back arrow ---
            IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Back',
            ),
            const SizedBox(height: AppSpacing.md),
            // --- Progress indicator using shared component ---
            const FlatmatesStepProgress.dots(
              currentStep: 0,
              totalSteps: _totalSteps,
            ),
            const SizedBox(height: AppSpacing.section),
            // --- Heading & subtitle ---
            Text(
              locale.modeSelectionTitle,
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 26,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              locale.modeSelectionSubtitle,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppSemanticColors.textSecondaryFor(theme.brightness),
              ),
            ),
            const SizedBox(height: AppSpacing.section),
            // --- Option cards ---
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...modes.map((mode) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _ModeCard(
                          key: Key('mode_${mode.id}'),
                          icon: _iconForMode(mode.id),
                          title: mode.label,
                          description:
                              mode.meta['description']?.toString() ?? '',
                          isSelected: _selectedMode == mode.id,
                          onTap: () => setState(() => _selectedMode = mode.id),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // --- CTA ---
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
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

class _ModeCard extends StatefulWidget {
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
  State<_ModeCard> createState() => _ModeCardState();
}

class _ModeCardState extends State<_ModeCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: AppMotion.buttonPress,
        curve: AppMotion.easeOutBack,
        child: FlatmatesCard(
          onTap: widget.onTap,
          borderColor: widget.isSelected
              ? AppSemanticColors.accent
              : AppSemanticColors.line.withValues(alpha: 0.4),
          borderGlow: widget.isSelected,
          elevation: widget.isSelected ? 2 : 0.5,
          child: Row(
            children: [
              // Left: circle with icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppSemanticColors.accent.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  color: AppSemanticColors.accent,
                  size: 26,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              // Center: title + description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      widget.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppSemanticColors.textSecondaryFor(
                          theme.brightness,
                        ),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Right: chevron
              Icon(
                Icons.chevron_right,
                color: AppSemanticColors.textTertiaryFor(theme.brightness),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
