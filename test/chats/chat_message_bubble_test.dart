import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flatmates_app/features/chats/chats_repository.dart';
import 'package:flatmates_app/features/chats/presentation/widgets/chat_message_bubble.dart';

import '../helpers/test_helpers.dart';

void main() {
  ChatMessage message({DateTime? readAt, int senderId = 1}) {
    return ChatMessage(
      id: 10,
      conversationId: 3,
      senderId: senderId,
      body: 'Hello',
      createdAt: DateTime(2026, 1, 1, 10),
      readAt: readAt,
    );
  }

  testWidgets('outgoing unread messages show sent receipt', (tester) async {
    await tester.pumpWidget(
      testableWidget(
        child: Scaffold(
          body: ChatMessageBubble(
            message: message(),
            isMine: true,
            peerName: 'Aarav',
            peerImageUrl: null,
          ),
        ),
      ),
    );

    expect(find.text('Sent'), findsOneWidget);
    expect(find.byIcon(Icons.done_rounded), findsOneWidget);
  });

  testWidgets('outgoing read messages show read receipt', (tester) async {
    await tester.pumpWidget(
      testableWidget(
        child: Scaffold(
          body: ChatMessageBubble(
            message: message(readAt: DateTime(2026, 1, 1, 11)),
            isMine: true,
            peerName: 'Aarav',
            peerImageUrl: null,
          ),
        ),
      ),
    );

    expect(find.text('Read'), findsOneWidget);
    expect(find.byIcon(Icons.done_all_rounded), findsOneWidget);
  });

  testWidgets('incoming messages hide read receipt labels', (tester) async {
    await tester.pumpWidget(
      testableWidget(
        child: Scaffold(
          body: ChatMessageBubble(
            message: message(senderId: 2),
            isMine: false,
            peerName: 'Aarav',
            peerImageUrl: null,
          ),
        ),
      ),
    );

    expect(find.text('Sent'), findsNothing);
    expect(find.text('Read'), findsNothing);
  });

  testWidgets('optimistic (negative id) messages show Sending, not Sent', (
    tester,
  ) async {
    final optimistic = ChatMessage(
      id: -1,
      conversationId: 3,
      senderId: 1,
      body: 'In flight',
      createdAt: DateTime(2026, 1, 1, 10),
    );

    await tester.pumpWidget(
      testableWidget(
        child: Scaffold(
          body: ChatMessageBubble(
            message: optimistic,
            isMine: true,
            peerName: 'Aarav',
            peerImageUrl: null,
          ),
        ),
      ),
    );

    expect(find.text('Sending...'), findsOneWidget);
    expect(find.text('Sent'), findsNothing);
    expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
  });
}
