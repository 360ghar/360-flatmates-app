import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/test_id.dart';

class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    required this.controller,
    required this.focusNode,
    required this.showEmoji,
    required this.onToggleEmoji,
    required this.onSend,
    this.onPickPhoto,
    this.isSending = false,
    this.isUploadingPhoto = false,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool showEmoji;
  final VoidCallback onToggleEmoji;
  final VoidCallback onSend;
  final VoidCallback? onPickPhoto;

  /// When true, keyboard submit and the send affordance are disabled so a
  /// double-tap cannot enqueue a second in-flight POST.
  final bool isSending;

  /// When true, send and photo controls are disabled while a gallery upload
  /// is in flight.
  final bool isUploadingPhoto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    final busy = isSending || isUploadingPhoto;
    final canSend = !busy;
    final canPickPhoto = onPickPhoto != null && !busy;

    final brightness = theme.brightness;
    final muted = AppSemanticColors.textSecondaryFor(brightness);

    // DESIGN.md input: paper-2 sheet, cut-md, e1, 2 px clay stroke while
    // focused. 48 dp icon buttons; the send button is a clay disc.
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.md,
        AppSpacing.base,
        AppSpacing.base,
      ),
      child: ListenableBuilder(
        listenable: focusNode,
        builder: (context, child) => DecoratedBox(
          decoration: BoxDecoration(
            color: AppSemanticColors.surfaceFor(brightness),
            borderRadius: AppRadius.mdBorder,
            boxShadow: AppShadows.e1(brightness),
          ),
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              borderRadius: AppRadius.mdBorder,
              border: Border.all(
                color: focusNode.hasFocus
                    ? AppSemanticColors.clayFor(brightness)
                    : AppSemanticColors.hairlineFor(brightness),
                width: focusNode.hasFocus ? 2 : 1,
              ),
            ),
            child: child,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              key: const Key('chat_emoji_button'),
              onPressed: onToggleEmoji,
              tooltip: locale.emojiCta,
              icon: Icon(
                showEmoji
                    ? Icons.keyboard_outlined
                    : Icons.emoji_emotions_outlined,
                color: showEmoji
                    ? AppSemanticColors.clayFor(brightness)
                    : muted,
                size: 24,
              ),
            ),
            Expanded(
              child: withTestId(
                const Key('chat_message_input'),
                TextField(
                  key: const Key('chat_message_input'),
                  controller: controller,
                  focusNode: focusNode,
                  textInputAction: TextInputAction.send,
                  onTap: () {
                    if (showEmoji) onToggleEmoji();
                  },
                  onSubmitted: canSend ? (_) => onSend() : null,
                  minLines: 1,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: locale.chatInputHint,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                  ),
                ),
              ),
            ),
            if (onPickPhoto != null)
              IconButton(
                key: const Key('chat_photo_button'),
                onPressed: canPickPhoto ? onPickPhoto : null,
                tooltip: locale.addPhotoCta,
                icon: isUploadingPhoto
                    ? SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: muted,
                        ),
                      )
                    : Icon(Icons.photo_outlined, color: muted, size: 24),
              ),
            withTestId(
              const Key('chat_send_button'),
              IconButton.filled(
                key: const Key('chat_send_button'),
                onPressed: canSend ? onSend : null,
                tooltip: locale.sendCta,
                style: IconButton.styleFrom(
                  backgroundColor: AppSemanticColors.clayFor(brightness),
                  foregroundColor: AppSemanticColors.onClayFor(brightness),
                  disabledBackgroundColor: AppSemanticColors.paperDeepFor(
                    brightness,
                  ),
                  disabledForegroundColor: AppSemanticColors.textTertiaryFor(
                    brightness,
                  ),
                ),
                icon: isSending
                    ? SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppSemanticColors.textTertiaryFor(brightness),
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
