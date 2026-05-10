import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/flatmates_trust_badge.dart';
import 'chat_input_bar.dart';

class ChatInputArea extends StatelessWidget {
  const ChatInputArea({
    required this.controller,
    required this.onSend,
    required this.onAttachment,
    required this.onEmoji,
    super.key,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onAttachment;
  final VoidCallback onEmoji;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: FlatmatesTrustBadge(
            label: locale.messagesArePrivate,
            variant: FlatmatesTrustBadgeVariant.privacy,
            compact: true,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        ChatInputBar(
          controller: controller,
          onSend: onSend,
          onAttachment: onAttachment,
          onEmoji: onEmoji,
        ),
      ],
    );
  }
}
