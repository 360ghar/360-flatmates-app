import 'package:flutter/material.dart';

import '../core/theme/app_semantic_colors.dart';
import '../l10n/gen/app_localizations.dart';

/// Release-mode replacement for Flutter's grey error box: a quiet paper
/// panel with a human message. Never shows the exception text.
class BuildErrorView extends StatelessWidget {
  const BuildErrorView({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.maybePlatformBrightnessOf(context);
    final dark = brightness == Brightness.dark;
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final ink = dark ? AppSemanticColors.darkMuted : AppSemanticColors.muted;
    return ColoredBox(
      color: dark ? AppSemanticColors.darkPaper1 : AppSemanticColors.paper1,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            l10n?.errorUnknown ?? 'Something went wrong.',
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            style: TextStyle(color: ink, fontSize: 14),
          ),
        ),
      ),
    );
  }
}
