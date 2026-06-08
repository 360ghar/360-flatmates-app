import 'package:flutter/material.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';

/// Shared password-strength policy used by every screen that sets a password
/// (signup, mandatory set-password, change-password, reset-password): at least
/// 8 characters, 1 uppercase letter and 1 number. Keeps the rule consistent
/// across the app instead of each screen re-implementing it.
abstract final class PasswordPolicy {
  static final RegExp _uppercase = RegExp(r'[A-Z]');
  static final RegExp _number = RegExp(r'[0-9]');

  static const int minLength = 8;

  static bool hasMinLength(String value) => value.length >= minLength;
  static bool hasUppercase(String value) => _uppercase.hasMatch(value);
  static bool hasNumber(String value) => _number.hasMatch(value);

  /// Whether [value] satisfies the full policy.
  static bool isValid(String value) =>
      hasMinLength(value) && hasUppercase(value) && hasNumber(value);

  /// A localized error message for the first unmet rule, or null when valid.
  static String? validate(String value, AppLocalizations locale) {
    if (!hasMinLength(value)) return locale.passwordMinLength;
    if (!hasUppercase(value)) return locale.passwordRuleUppercase;
    if (!hasNumber(value)) return locale.passwordRuleNumber;
    return null;
  }
}

/// Live checklist of the [PasswordPolicy] rules with pass/fail indicators.
class PasswordRulesChecklist extends StatelessWidget {
  const PasswordRulesChecklist({required this.password, super.key});

  final String password;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PasswordRuleItem(
          passed: PasswordPolicy.hasMinLength(password),
          label: locale.passwordRuleMinLength,
        ),
        const SizedBox(height: AppSpacing.xs),
        _PasswordRuleItem(
          passed: PasswordPolicy.hasUppercase(password),
          label: locale.passwordRuleUppercase,
        ),
        const SizedBox(height: AppSpacing.xs),
        _PasswordRuleItem(
          passed: PasswordPolicy.hasNumber(password),
          label: locale.passwordRuleNumber,
        ),
      ],
    );
  }
}

class _PasswordRuleItem extends StatelessWidget {
  const _PasswordRuleItem({required this.passed, required this.label});

  final bool passed;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          passed ? Icons.check_circle : Icons.close,
          size: 18,
          color: passed ? AppSemanticColors.success : AppSemanticColors.error,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: passed
                ? AppSemanticColors.success
                : AppSemanticColors.textSecondaryFor(theme.brightness),
            fontWeight: passed ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
