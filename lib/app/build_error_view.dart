import 'package:flutter/material.dart';

import '../core/theme/app_semantic_colors.dart';
import '../l10n/gen/app_localizations.dart';

/// Release-mode replacement for Flutter's grey error box: a quiet paper
/// panel with a human message. Never shows the exception text.
class BuildErrorView extends StatelessWidget {
  const BuildErrorView({super.key});

  @override
  Widget build(BuildContext context) {
    // Follow the app's selected theme, not the OS setting: an explicit dark
    // theme must not paint a light panel (and the reverse). ErrorWidget
    // renders wherever the failure happened, so there may be no Theme or
    // MediaQuery above it — fall back to light.
    final brightness =
        Theme.maybeBrightnessOf(context) ??
        MediaQuery.maybePlatformBrightnessOf(context) ??
        Brightness.light;
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    return ColoredBox(
      color: AppSemanticColors.paper1For(brightness),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            l10n?.errorUnknown ?? 'Something went wrong.',
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            style: TextStyle(
              color: AppSemanticColors.textTertiaryFor(brightness),
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
