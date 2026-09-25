import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'flatmates_ui.dart';

/// Sticky bottom CTA bar on paper-2 with a top hairline.
///
/// Up to three actions: an optional icon toggle (for example Like), an
/// optional secondary (pine-soft fill, never an outline) and the primary.
/// Buttons have a 48 dp minimum height and grow with the text size.
class FlatmatesBottomActionBar extends StatelessWidget {
  const FlatmatesBottomActionBar({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.primaryButtonKey,
    this.secondaryLabel,
    this.secondaryOnPressed,
    this.secondaryIcon,
    this.secondaryButtonKey,
    this.tertiaryIcon,
    this.tertiaryOnPressed,
    this.tertiaryButtonKey,
    this.tertiaryLabel,
    this.tertiarySelected = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Key? primaryButtonKey;

  final String? secondaryLabel;
  final VoidCallback? secondaryOnPressed;
  final IconData? secondaryIcon;
  final Key? secondaryButtonKey;

  final IconData? tertiaryIcon;
  final VoidCallback? tertiaryOnPressed;
  final Key? tertiaryButtonKey;

  /// Tooltip and screen-reader name of the icon toggle.
  final String? tertiaryLabel;
  final bool tertiarySelected;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    final primary = FlatmatesButton(
      key: primaryButtonKey,
      label: label,
      onPressed: onPressed,
      icon: icon,
      fullWidth: true,
    );
    final secondary = secondaryLabel == null
        ? null
        : FlatmatesButton.secondary(
            key: secondaryButtonKey,
            label: secondaryLabel!,
            onPressed: secondaryOnPressed,
            icon: secondaryIcon,
            fullWidth: true,
          );

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.screen,
        right: AppSpacing.screen,
        top: AppSpacing.md,
        bottom: bottomInset + AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppSemanticColors.surfaceFor(brightness),
        border: Border(
          top: BorderSide(color: AppSemanticColors.hairlineFor(brightness)),
        ),
      ),
      child: Row(
        children: [
          if (tertiaryIcon != null) ...[
            _toggle(brightness),
            const SizedBox(width: AppSpacing.sm),
          ],
          if (secondary != null) ...[
            Expanded(child: secondary),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(child: primary),
        ],
      ),
    );
  }

  Widget _toggle(Brightness brightness) {
    final clay = AppSemanticColors.clayFor(brightness);
    final selected = tertiarySelected;
    final button = Material(
      color: selected
          ? AppSemanticColors.coralSoftFor(brightness)
          : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.mdBorder,
        side: BorderSide(
          color: selected ? clay : AppSemanticColors.hairlineFor(brightness),
        ),
      ),
      child: InkWell(
        key: tertiaryButtonKey,
        onTap: tertiaryOnPressed,
        customBorder: const RoundedRectangleBorder(
          borderRadius: AppRadius.mdBorder,
        ),
        child: SizedBox.square(
          dimension: kMinInteractiveDimension,
          child: Icon(
            tertiaryIcon,
            size: 22,
            color: selected
                ? clay
                : AppSemanticColors.textTertiaryFor(brightness),
          ),
        ),
      ),
    );
    final name = tertiaryLabel;
    return Semantics(
      button: true,
      toggled: selected,
      label: name,
      child: name == null ? button : Tooltip(message: name, child: button),
    );
  }
}
