import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/features/chats/application/messages_controller.dart';
import 'package:flatmates_app/features/chats/chats_repository.dart';
import 'package:flatmates_app/features/chats/presentation/widgets/message_list.dart';
import 'package:flatmates_app/features/visits/visits_repository.dart';

import '../../helpers/test_helpers.dart';

class _FakeMessagesController extends MessagesController {
  final MessagesState _state;

  _FakeMessagesController(this._state);

  @override
  MessagesState build(int conversationId) => _state;

  @override
  Future<void> loadOlder() async {}

  @override
  Future<void> markAsRead() async {}
}

void main() {
  group('MessageList scroll', () {
    testWidgets('pins newest message into view on first render', (
      tester,
    ) async {
      // Use a tall viewport so the ListView is scrollable, and enough
      // messages that the newest is off-screen until pinned.
      final messages = List.generate(
        20,
        (i) => ChatMessage(
          id: 100 + i,
          conversationId: 10,
          senderId: i % 2 == 0 ? 1 : 2,
          body: 'Message $i',
          createdAt: DateTime(2025, 5, 15, 14, 0 + i),
        ),
      );

      final fakeState = MessagesState(messages: messages, hasMoreOlder: false);

      await tester.pumpWidget(
        testableWidget(
          overrides: [
            messagesControllerProvider.overrideWith(
              () => _FakeMessagesController(fakeState),
            ),
          ],
          child: Scaffold(
            body: SizedBox(
              height: 300,
              child: MessageList(
                messagesState: fakeState,
                currentUserId: 1,
                conversation: const ConversationSummaryModel(
                  id: 10,
                  peer: ChatPeer(id: 2, fullName: 'Priya'),
                ),
                visitsAsync: const AsyncValue<List<VisitItem>>.data([]),
                onConfirmVisit: (_) {},
                onRescheduleVisit: (_) {},
                conversationId: 10,
              ),
            ),
          ),
        ),
      );

      // Allow post-frame scroll-to-bottom callbacks to run.
      // Use pump instead of pumpAndSettle to avoid timing out on
      // continuous animations.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // The newest message ("Message 19") should be visible after the
      // list pins to the bottom on first render.
      expect(find.text('Message 19'), findsOneWidget);
    });
  });
}
