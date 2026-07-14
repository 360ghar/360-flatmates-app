import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/features/chats/chats_repository.dart';
import 'package:flatmates_app/features/chats/presentation/widgets/chat_message_bubble.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('ChatMessageBubble', () {
    testWidgets('renders text message correctly', (tester) async {
      final message = ChatMessage(
        id: 100,
        conversationId: 10,
        senderId: 1,
        body: 'Hello world',
        createdAt: DateTime(2025, 5, 15, 14, 30),
      );

      await tester.pumpWidget(
        testableWidget(
          child: Scaffold(
            body: ChatMessageBubble(
              message: message,
              isMine: true,
              peerName: 'Priya',
              peerImageUrl: null,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hello world'), findsOneWidget);
    });

    testWidgets('renders image message with attachment', (tester) async {
      final message = ChatMessage(
        id: 101,
        conversationId: 10,
        senderId: 2,
        messageType: 'image',
        createdAt: DateTime(2025, 5, 15, 14, 31),
        attachmentUrl: 'https://example.com/photo.jpg',
      );

      await tester.pumpWidget(
        testableWidget(
          child: Scaffold(
            body: ChatMessageBubble(
              message: message,
              isMine: false,
              peerName: 'Priya',
              peerImageUrl: null,
            ),
          ),
        ),
      );
      // FlatmatesNetworkImage uses CachedNetworkImage which may show a
      // placeholder in tests; pump a few frames to let it settle without
      // waiting for the network image to load (which never completes in
      // tests).
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // The image message should not render the body text (body is null).
      // Instead it renders the attachment via FlatmatesNetworkImage.
      expect(find.text('Hello world'), findsNothing);
      // Verify at least one Image-related widget is present (the network
      // image widget tree).
      expect(find.byType(Image), findsWidgets);
    });
  });
}
