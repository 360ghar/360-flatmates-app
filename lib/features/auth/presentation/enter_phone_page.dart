import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth_controller.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../shared/presentation/components.dart';
import 'widgets/terms_checkbox.dart';

class EnterPhonePage extends ConsumerStatefulWidget {
  const EnterPhonePage({super.key});

  @override
  ConsumerState<EnterPhonePage> createState() => _EnterPhonePageState();
}

class _EnterPhonePageState extends ConsumerState<EnterPhonePage> {
  final _controller = TextEditingController(text: '+91');
  bool _termsAccepted = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return FlatmatesScreen(
      appBar: AppBar(),
      scrollable: true,
      body: Column(
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
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    FlatmatesTrustBadge(
                      label: locale.yourNumberIsPrivate,
                      variant: FlatmatesTrustBadgeVariant.privacy,
                      compact: true,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TermsCheckbox(
                  accepted: _termsAccepted,
                  onChanged: (v) => setState(() => _termsAccepted = v),
                  locale: locale,
                  theme: theme,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.screen),
          FlatmatesButton(
            key: const Key('enter_phone_login_cta'),
            label: locale.loginWithPasswordCta,
            fullWidth: true,
            onPressed: !_termsAccepted
                ? null
                : () {
                    final phone = _controller.text.trim();
                    ref.read(pendingPhoneProvider.notifier).state = phone;
                    context.push('/login?phone=$phone');
                  },
          ),
          const SizedBox(height: AppSpacing.md),
          FlatmatesButton.tertiary(
            label: locale.createAccountCta,
            onPressed: !_termsAccepted
                ? null
                : () {
                    final phone = _controller.text.trim();
                    ref.read(pendingPhoneProvider.notifier).state = phone;
                    context.push('/signup?phone=$phone');
                  },
          ),
        ],
      ),
    );
  }
}
