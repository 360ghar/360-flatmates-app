import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';

class FlatmatesGoogleSignInButton extends StatelessWidget {
  const FlatmatesGoogleSignInButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: theme.colorScheme.outline),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/icons/google.png',
                    width: 20,
                    height: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    label,
                    style: theme.textTheme.labelLarge,
                  ),
                ],
              ),
      ),
    );
  }
}
