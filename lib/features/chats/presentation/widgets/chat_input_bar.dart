import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';

class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    required this.controller,
    required this.focusNode,
    required this.showEmoji,
    required this.onToggleEmoji,
    required this.onSend,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool showEmoji;
  final VoidCallback onToggleEmoji;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppSemanticColors.secondarySurfaceFor(theme.brightness),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppSemanticColors.line.withValues(alpha: 0.35),
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
                onSubmitted: (_) => onSend(),
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
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            _InteractivePressScale(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 8, 8),
                child: SizedBox(
                  width: 32,
                  height: 32,
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
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
