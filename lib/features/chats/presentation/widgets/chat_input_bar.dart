import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';

class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    required this.controller,
    required this.onSend,
    required this.onAttachment,
    super.key,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onAttachment;

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
          children: [
            _InteractivePressScale(
              child: IconButton(
                key: const Key('chat_attachment_button'),
                onPressed: onAttachment,
                icon: Icon(
                  Icons.attach_file_rounded,
                  color: AppSemanticColors.textSecondaryFor(theme.brightness),
                  size: 22,
                ),
              ),
            ),
            Expanded(
              child: TextField(
                key: const Key('chat_message_input'),
                controller: controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
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
            SizedBox(
              width: 44,
              height: 44,
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
            const SizedBox(width: AppSpacing.xs),
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
