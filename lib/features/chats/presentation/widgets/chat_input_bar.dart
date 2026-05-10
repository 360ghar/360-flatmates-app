import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';

class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
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
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: [
          IconButton(
            key: const Key('chat_emoji_button'),
            onPressed: onEmoji,
            icon: Icon(
              Icons.sentiment_satisfied_alt_rounded,
              color: AppSemanticColors.textSecondaryFor(theme.brightness),
              size: 24,
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppSemanticColors.secondarySurfaceFor(theme.brightness),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppSemanticColors.line.withValues(alpha: 0.35),
                ),
              ),
              child: TextField(
                key: const Key('chat_message_input'),
                controller: controller,
                decoration: InputDecoration(
                  hintText: locale.chatInputHint,
                  hintStyle: TextStyle(
                    color: AppSemanticColors.textSecondaryFor(
                      theme.brightness,
                    ).withValues(alpha: 0.6),
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            key: const Key('chat_attachment_button'),
            onPressed: onAttachment,
            icon: Icon(
              Icons.attach_file_rounded,
              color: AppSemanticColors.textSecondaryFor(theme.brightness),
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          SizedBox(
            width: 48,
            height: 48,
            child: Material(
              color: AppSemanticColors.accent,
              shape: const CircleBorder(),
              child: InkWell(
                key: const Key('chat_send_button'),
                onTap: onSend,
                customBorder: const CircleBorder(),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
