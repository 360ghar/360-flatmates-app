import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_radius.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flatmates_app/core/theme/app_spacing.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/gen/app_localizations.dart';

class TermsCheckbox extends StatefulWidget {
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
  State<TermsCheckbox> createState() => _TermsCheckboxState();
}

class _TermsCheckboxState extends State<TermsCheckbox> {
  late final TapGestureRecognizer _termsTap = TapGestureRecognizer()
    ..onTap = () => context.push('/terms-of-service');
  late final TapGestureRecognizer _privacyTap = TapGestureRecognizer()
    ..onTap = () => context.push('/privacy-policy');

  @override
  void dispose() {
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = widget.locale;
    final theme = widget.theme;
    final clay = AppSemanticColors.clayFor(theme.brightness);
    final linkStyle = TextStyle(
      color: clay,
      decoration: TextDecoration.underline,
      decorationColor: clay,
    );

    // The whole row toggles, so the tap target is the full width and at
    // least 48 dp high. The links inside keep their own taps.
    return InkWell(
      onTap: () => widget.onChanged(!widget.accepted),
      borderRadius: AppRadius.smBorder,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                key: const Key('terms_checkbox'),
                value: widget.accepted,
                onChanged: (v) => widget.onChanged(v ?? false),
                activeColor: clay,
                checkColor: AppSemanticColors.onClayFor(theme.brightness),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                semanticLabel:
                    '${locale.termsAgreementPrefix}'
                    '${locale.termsAndConditionsLabel}'
                    '${locale.termsAgreementConjunction}'
                    '${locale.privacyPolicy}',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              // 3 px top pad centres the first 18 px text line on the 24 px
              // checkbox.
              child: Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: locale.termsAgreementPrefix),
                      TextSpan(
                        text: locale.termsAndConditionsLabel,
                        style: linkStyle,
                        recognizer: _termsTap,
                      ),
                      TextSpan(text: locale.termsAgreementConjunction),
                      TextSpan(
                        text: locale.privacyPolicy,
                        style: linkStyle,
                        recognizer: _privacyTap,
                      ),
                    ],
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppSemanticColors.textSecondaryFor(
                        theme.brightness,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
