import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flatmates_app/core/theme/app_spacing.dart';
import 'package:flatmates_app/l10n/gen/app_localizations.dart';

class TermsCheckbox extends StatelessWidget {
  const TermsCheckbox({
    required this.accepted,
    required this.onChanged,
    required this.locale,
    required this.theme,
    super.key,
  });

  final bool accepted;
  final ValueChanged<bool> onChanged;
  final AppLocalizations locale;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 24,
          width: 24,
          child: Checkbox(
            value: accepted,
            onChanged: (v) => onChanged(v ?? false),
            activeColor: AppSemanticColors.accent,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: locale.termsAgreementPrefix),
                TextSpan(
                  text: locale.termsAndConditionsLabel,
                  style: TextStyle(
                    color: AppSemanticColors.accent,
                    decoration: TextDecoration.underline,
                    decorationColor: AppSemanticColors.accent,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => context.push('/terms-of-service'),
                ),
                TextSpan(text: locale.termsAgreementConjunction),
                TextSpan(
                  text: locale.privacyPolicy,
                  style: TextStyle(
                    color: AppSemanticColors.accent,
                    decoration: TextDecoration.underline,
                    decorationColor: AppSemanticColors.accent,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => context.push('/privacy-policy'),
                ),
              ],
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppSemanticColors.textSecondaryFor(theme.brightness),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
