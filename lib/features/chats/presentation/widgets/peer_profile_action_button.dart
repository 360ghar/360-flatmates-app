import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Tone of a [PeerActionButton]: clay-soft for the main action, pine-soft
/// for the others, and danger ink on paper for a destructive action.
enum PeerActionButtonColor { primary, secondary, destructive }

/// Compact icon-over-label action button used in the peer profile action
/// strip (Message, Call, Schedule Visit, Report).
///
/// The label wraps to two lines at large text sizes. Put the buttons in an
/// [IntrinsicHeight] row with stretched children so they share one height.
class PeerActionButton extends StatelessWidget {
  const PeerActionButton({
    required this.icon,
    required this.label,
    this.color = PeerActionButtonColor.secondary,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final PeerActionButtonColor color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final enabled = onTap != null;

    final (Color bg, Color fg) = !enabled
        ? (AppSemanticColors.paper2For(b), AppSemanticColors.textTertiaryFor(b))
        : switch (color) {
            PeerActionButtonColor.primary => (
              AppSemanticColors.coralSoftFor(b),
              AppSemanticColors.clayInkFor(b),
            ),
            PeerActionButtonColor.secondary => (
              AppSemanticColors.greenSoftFor(b),
              AppSemanticColors.greenInkFor(b),
            ),
            PeerActionButtonColor.destructive => (
              AppSemanticColors.paper2For(b),
              AppSemanticColors.dangerFor(b),
            ),
          };

    return Semantics(
      button: true,
      enabled: enabled,
      child: Material(
        color: bg,
        borderRadius: AppRadius.smBorder,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.smBorder,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.sm,
              horizontal: AppSpacing.xs,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: fg),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: AppTypography.microLabelSize,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Equal-width, equal-height strip of [PeerActionButton]s.
///
/// When the tiles would be too narrow for their labels (a small phone or a
/// large text size), the strip wraps into rows of two.
class PeerActionRow extends StatelessWidget {
  const PeerActionRow({required this.children, super.key});

  final List<Widget> children;

  /// Narrowest tile that still fits "Message" at 1x.
  static const double _minTileWidth = 72;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.xs;
        // TextScaler can scale nonlinearly, so derive the multiplier from the
        // real label size instead of scaling 1.
        final textScaler = MediaQuery.textScalerOf(context);
        final scale =
            textScaler.scale(AppTypography.microLabelSize) /
            AppTypography.microLabelSize;
        final n = children.length;
        final fitsOneRow =
            constraints.maxWidth >= n * _minTileWidth * scale + (n - 1) * gap;
        final perRow = fitsOneRow ? n : 2;

        final rows = <Widget>[];
        for (var start = 0; start < n; start += perRow) {
          final slice = children.skip(start).take(perRow).toList();
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < perRow; i++) ...[
                    if (i > 0) const SizedBox(width: gap),
                    Expanded(
                      child: i < slice.length
                          ? slice[i]
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, row) in rows.indexed) ...[
              if (i > 0) const SizedBox(height: gap),
              row,
            ],
          ],
        );
      },
    );
  }
}
