import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/features/chats/presentation/widgets/chat_input_bar.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('ChatInputBar', () {
    testWidgets('renders text input and send button', (tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();
      addTearDown(() {
        controller.dispose();
        focusNode.dispose();
      });

      await tester.pumpWidget(
        testableWidget(
          child: Scaffold(
            body: ChatInputBar(
              controller: controller,
              focusNode: focusNode,
              showEmoji: false,
              onToggleEmoji: () {},
              onSend: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('chat_message_input')), findsOneWidget);
      expect(find.byKey(const Key('chat_send_button')), findsOneWidget);
    });

    testWidgets('emoji button toggles emoji picker', (tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();
      addTearDown(() {
        controller.dispose();
        focusNode.dispose();
      });

      var emojiToggled = false;

      await tester.pumpWidget(
        testableWidget(
          child: Scaffold(
            body: ChatInputBar(
              controller: controller,
              focusNode: focusNode,
              showEmoji: false,
              onToggleEmoji: () => emojiToggled = true,
              onSend: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the emoji button.
      await tester.tap(find.byKey(const Key('chat_emoji_button')));
      await tester.pumpAndSettle();

      expect(emojiToggled, isTrue);
    });
  });
}
