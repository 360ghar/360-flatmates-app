import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flatmates_app/features/chats/application/messages_controller.dart';
import 'package:flatmates_app/features/chats/chat_thread_page.dart';
import 'package:flatmates_app/features/chats/chats_repository.dart';
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

  @override
  Future<void> refetchLatest() async {}
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetTestAppPreferences();
  });

  group('ChatThreadPage', () {
    testWidgets(
      'renders message input and app bar when conversation is loaded',
      (tester) async {
        const conversation = ConversationSummaryModel(
          id: 10,
          source: 'match',
          peer: ChatPeer(id: 2, fullName: 'Priya Patel'),
          contextProperty: ChatPropertyContext(id: 42, title: 'Modern 2BHK'),
        );

        final fakeMessagesState = MessagesState(
          messages: [
            ChatMessage(
              id: 100,
              conversationId: 10,
              senderId: 2,
              body: 'Hello!',
              createdAt: DateTime(2025, 5, 15, 14, 30),
            ),
          ],
          hasMoreOlder: false,
        );

        final widget = await testableWidgetAsync(
          overrides: [
            messagesControllerProvider.overrideWith(
              () => _FakeMessagesController(fakeMessagesState),
            ),
            visitsProvider.overrideWith((ref) async => const <VisitItem>[]),
          ],
          child: const ChatThreadPage(
            conversationId: 10,
            conversation: conversation,
          ),
        );

        await tester.pumpWidget(widget);
        // Use pump instead of pumpAndSettle to avoid timing out on
        // continuous animations (FlatmatesAvatar shimmer, etc.).
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // The app bar with the peer name should be visible.
        expect(find.text('Priya Patel'), findsWidgets);
        // The message input should be rendered.
        expect(find.byKey(const Key('chat_message_input')), findsOneWidget);
        // The existing message should be visible.
        expect(find.text('Hello!'), findsOneWidget);

        // Pump with a longer duration to let the ModeTooltipController's
        // scheduled timer fire so no timers are pending at test end.
        await tester.pump(const Duration(seconds: 5));
        await tester.pump(const Duration(milliseconds: 100));
      },
    );
  });
}
