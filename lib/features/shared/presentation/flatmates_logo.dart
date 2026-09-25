import 'package:flutter/material.dart';
import '../../../core/theme/app_semantic_colors.dart';

/// Brand logo: "36" + rotate_right icon (acts as the "0") + "FLATMATES".
///
/// This is intentional per DESIGN.md — the rotate_right icon visually
/// represents the "0" in "360", making the logo read as "360 FLATMATES".
/// Do NOT change "36" to "360" or replace the icon with a literal "0".
class FlatmatesLogo extends StatelessWidget {
  const FlatmatesLogo({
    super.key,
    this.compact = false,
    this.centered = false,
    this.toolbar = false,
  });

  final bool compact;
  final bool centered;

  /// Single-line mark sized for a 56px app bar (number + icon only).
  final bool toolbar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ink = AppSemanticColors.textPrimaryFor(theme.brightness);

    if (toolbar) {
      return RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '36',
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -1.2,
                color: ink,
                height: 1,
              ),
            ),
            const WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Icon(
                Icons.rotate_right_rounded,
                color: AppSemanticColors.primary,
                size: 24,
              ),
            ),
          ],
        ),
      );
    }

    final numberSize = compact ? 28.0 : 38.0;
    final labelSize = compact ? 13.0 : 15.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '36',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontSize: numberSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.4,
                  color: isDark
                      ? AppSemanticColors.darkInk
                      : AppSemanticColors.ink,
                ),
              ),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Transform.translate(
                  offset: Offset(0, compact ? -2 : -4),
                  child: Icon(
                    Icons.rotate_right_rounded,
                    color: AppSemanticColors.primary,
                    size: compact ? 30 : 38,
                  ),
                ),
              ),
            ],
          ),
        ),
        Text(
          'FLATMATES',
          style: theme.textTheme.labelLarge?.copyWith(
            color: AppSemanticColors.primary,
            fontSize: labelSize,
            letterSpacing: 1.6,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
