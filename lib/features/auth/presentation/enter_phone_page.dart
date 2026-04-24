import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth_controller.dart';
import '../../../core/providers.dart';
import '../../../l10n/gen/app_localizations.dart';

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

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        minimum: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              locale.enterPhoneTitle,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(locale.enterPhoneSubtitle),
            const SizedBox(height: 24),
            TextField(
              key: const Key('enter_phone_input'),
              controller: _controller,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: locale.phoneNumberLabel),
            ),
            if (auth.status == AuthStatus.error &&
                auth.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                auth.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const Spacer(),
            FilledButton(
              key: const Key('enter_phone_otp_cta'),
              onPressed: () async {
                final phone = _controller.text.trim();
                await ref
                    .read(authControllerProvider.notifier)
                    .requestOtp(phone);
                if (!context.mounted) return;
                context.push('/otp?phone=${Uri.encodeComponent(phone)}');
              },
              child: Text(locale.continueWithOtp),
            ),
            if (config.enableDebugLogs) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                key: const Key('enter_phone_password_cta'),
                onPressed: () {
                  context.push(
                    '/login?phone=${Uri.encodeComponent(_controller.text.trim())}',
                  );
                },
                child: Text(locale.loginWithPassword),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  context.push(
                    '/signup?phone=${Uri.encodeComponent(_controller.text.trim())}',
                  );
                },
                child: Text(locale.createAccountCta),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
