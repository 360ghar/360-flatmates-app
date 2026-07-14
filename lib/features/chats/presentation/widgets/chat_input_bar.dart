import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';

import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';

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

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.md,
        AppSpacing.base,
        AppSpacing.base,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppSemanticColors.secondarySurfaceFor(theme.brightness),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppSemanticColors.hairlineFor(
              theme.brightness,
            ).withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _InteractivePressScale(
              child: IconButton(
                key: const Key('chat_emoji_button'),
                padding: const EdgeInsets.all(AppSpacing.md),
                constraints: const BoxConstraints(),
                onPressed: onToggleEmoji,
                tooltip: locale.emojiCta,
                icon: Icon(
                  showEmoji
                      ? Icons.keyboard_outlined
                      : Icons.emoji_emotions_outlined,
                  color: showEmoji
                      ? AppSemanticColors.accent
                      : AppSemanticColors.textSecondaryFor(theme.brightness),
                  size: 24,
                ),
              ),
            ),
            Expanded(
              child: TextField(
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
                    vertical: AppSpacing.md,
                  ),
                ),
              ),
            ),
            if (onPickPhoto != null)
              _InteractivePressScale(
                child: IconButton(
                  key: const Key('chat_photo_button'),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  constraints: const BoxConstraints(),
                  onPressed: canPickPhoto ? onPickPhoto : null,
                  tooltip: locale.addPhotoCta,
                  icon: isUploadingPhoto
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppSemanticColors.textSecondaryFor(
                              theme.brightness,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.photo_outlined,
                          color: canPickPhoto
                              ? AppSemanticColors.textSecondaryFor(
                                  theme.brightness,
                                )
                              : AppSemanticColors.textSecondaryFor(
                                  theme.brightness,
                                ).withValues(alpha: 0.4),
                          size: 24,
                        ),
                ),
              ),
            _InteractivePressScale(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  0,
                  0,
                  AppSpacing.sm,
                  AppSpacing.sm,
                ),
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: Material(
                    color: canSend
                        ? AppSemanticColors.accent
                        : AppSemanticColors.accent.withValues(alpha: 0.5),
                    shape: const CircleBorder(),
                    child: InkWell(
                      key: const Key('chat_send_button'),
                      onTap: canSend ? onSend : null,
                      customBorder: const CircleBorder(),
                      child: isSending
                          ? const Padding(
                              padding: AppSpacing.edgeSm,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 16,
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

/// Applies standard interactive scale animation to any child when pressed.
class _InteractivePressScale extends StatefulWidget {
  const _InteractivePressScale({required this.child});

  final Widget child;

  @override
  State<_InteractivePressScale> createState() => _InteractivePressScaleState();
}

class _InteractivePressScaleState extends State<_InteractivePressScale> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _scale = 0.97),
      onPointerUp: (_) => setState(() => _scale = 1.0),
      onPointerCancel: (_) => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: AppMotion.durationOrZero(context, AppMotion.buttonPress),
        curve: AppMotion.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
