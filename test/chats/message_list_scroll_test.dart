import 'package:flatmates_app/features/chats/application/messages_controller.dart';
import 'package:flatmates_app/features/chats/chats_repository.dart';
import 'package:flatmates_app/features/chats/presentation/widgets/message_list.dart';
import 'package:flatmates_app/features/visits/visits_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_helpers.dart';

ChatMessage _msg(int id) => ChatMessage(
  id: id,
  conversationId: 3,
  senderId: 1,
  body: 'Message $id',
  createdAt: DateTime(2026, 1, 1, 10).add(Duration(minutes: id)),
);

void main() {
  testWidgets('pins newest message into view on first render', (tester) async {
    final messages = [for (var i = 1; i <= 40; i++) _msg(i)];

    await tester.pumpWidget(
      testableWidget(
        overrides: [
          visitsProvider.overrideWith((ref) async => const <VisitItem>[]),
        ],
        child: Scaffold(
          body: Consumer(
            builder: (context, ref, _) {
              return MessageList(
                messagesState: MessagesState(messages: messages),
                currentUserId: 1,
                conversation: null,
                visitsAsync: const AsyncValue.data(<VisitItem>[]),
                onConfirmVisit: (_) {},
                onRescheduleVisit: (_) {},
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The post-frame jump should land at the bottom, so the last message is
    // rendered and the first is scrolled out of view.
    expect(find.text('Message 40'), findsOneWidget);
    expect(find.text('Message 1'), findsNothing);
  });
}
