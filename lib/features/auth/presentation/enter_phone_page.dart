import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth_controller.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../shared/presentation/components.dart';

class EnterPhonePage extends ConsumerStatefulWidget {
  const EnterPhonePage({super.key});

  @override
  ConsumerState<EnterPhonePage> createState() => _EnterPhonePageState();
}

class _EnterPhonePageState extends ConsumerState<EnterPhonePage> {
  final _controller = TextEditingController(text: '+91');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final config = ref.watch(appConfigProvider);
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        minimum: AppSpacing.horizontalScreen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(locale.enterPhoneTitle, style: theme.textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(locale.enterPhoneSubtitle),
            const SizedBox(height: AppSpacing.screen),
            FlatmatesCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    key: const Key('enter_phone_input'),
                    controller: _controller,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: locale.phoneNumberLabel,
                    ),
                  ),
                  if (auth.status == AuthStatus.error &&
                      auth.errorMessage != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      auth.errorMessage!,
                      style: TextStyle(color: AppSemanticColors.error),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  // Privacy reassurance
                  Row(
                    children: [
                      FlatmatesTrustBadge(
                        label: locale.yourNumberIsPrivate,
                        variant: FlatmatesTrustBadgeVariant.privacy,
                        compact: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            FlatmatesButton(
              key: const Key('enter_phone_otp_cta'),
              label: locale.continueWithOtp,
              fullWidth: true,
              onPressed: () async {
                final phone = _controller.text.trim();
                ref.read(pendingPhoneProvider.notifier).state = phone;
                await ref
                    .read(authControllerProvider.notifier)
                    .requestOtp(phone);
                if (!context.mounted) return;
                final auth = ref.read(authControllerProvider);
                if (auth.status == AuthStatus.error) return;
                context.push('/otp');
              },
            ),
            if (config.enableDebugLogs) ...[
              const SizedBox(height: AppSpacing.md),
              FlatmatesButton.secondary(
                key: const Key('enter_phone_password_cta'),
                label: locale.loginWithPassword,
                fullWidth: true,
                onPressed: () {
                  final phone = _controller.text.trim();
                  ref.read(pendingPhoneProvider.notifier).state = phone;
                  context.push('/login');
                },
              ),
              const SizedBox(height: AppSpacing.md),
              FlatmatesButton.tertiary(
                label: locale.createAccountCta,
                onPressed: () {
                  final phone = _controller.text.trim();
                  ref.read(pendingPhoneProvider.notifier).state = phone;
                  context.push('/signup');
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
