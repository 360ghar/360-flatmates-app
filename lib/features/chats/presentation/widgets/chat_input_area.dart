import 'package:flutter/material.dart';

import 'chat_input_bar.dart';

class ChatInputArea extends StatelessWidget {
  const ChatInputArea({
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
    return ChatInputBar(
      controller: controller,
      focusNode: focusNode,
      showEmoji: showEmoji,
      onToggleEmoji: onToggleEmoji,
      onSend: onSend,
    );
  }
}
