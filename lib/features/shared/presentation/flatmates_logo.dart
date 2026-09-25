import 'package:flutter/material.dart';

import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Brand wordmark, same as the web logo: "360" in clay and "Flatmates" in
/// ink, both Gambarino, on one baseline. Sentence case, no tracking.
class FlatmatesLogo extends StatelessWidget {
  const FlatmatesLogo({
    super.key,
    this.compact = false,
    this.centered = false,
    this.toolbar = false,
  });

  final bool compact;
  final bool centered;

  /// One line sized for a 56 px app bar.
  final bool toolbar;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final (number, word) = toolbar
        ? (24.0, 20.0)
        : compact
        ? (24.0, 20.0)
        : (34.0, 28.0);
    TextStyle style(double size, Color color) => TextStyle(
      fontFamily: AppTypography.displayFamily,
      fontSize: size,
      height: 1,
      color: color,
    );

    return Semantics(
      label: '360 Flatmates',
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '360 ',
              style: style(number, AppSemanticColors.clayFor(b)),
            ),
            TextSpan(
              text: 'Flatmates',
              style: style(word, AppSemanticColors.textPrimaryFor(b)),
            ),
          ],
        ),
        textAlign: centered ? TextAlign.center : TextAlign.start,
        // A wordmark is a picture: it keeps its size at any text scale (the
        // screen-reader label carries the name).
        textScaler: TextScaler.noScaling,
        maxLines: 1,
      ),
    );
  }
}
