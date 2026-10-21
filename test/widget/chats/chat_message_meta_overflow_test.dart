import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/features/chats/chats_repository.dart';
import 'package:flatmates_app/features/chats/presentation/widgets/chat_message_bubble.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('ChatMessageBubble meta row', () {
    testWidgets('does not overflow a 320 dp phone at 2x text scale', (
      tester,
    ) async {
      // The meta row (time + receipt label) is the widest fixed content in the
      // bubble. With non-flexible labels it overflowed by ~180 px here, which
      // the 1x tests never see.
      final message = ChatMessage(
        id: 300,
        conversationId: 10,
        senderId: 1,
        body: 'Hi',
        createdAt: DateTime(2025, 5, 15, 14, 30),
      );

      await tester.pumpWidget(
        testableWidget(
          child: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(2),
            ),
            child: Scaffold(
              body: ChatMessageBubble(
                message: message,
                isMine: true,
                peerName: 'Priya',
                peerImageUrl: null,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
