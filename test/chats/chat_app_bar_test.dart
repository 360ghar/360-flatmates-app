import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flatmates_app/features/chats/chats_repository.dart';
import 'package:flatmates_app/features/chats/domain/chat_report_reason.dart';
import 'package:flatmates_app/features/chats/presentation/widgets/chat_app_bar.dart';

import '../helpers/test_helpers.dart';

void main() {
  testWidgets('chat app bar exposes implemented chat actions only', (
    tester,
  ) async {
    const conversation = ConversationSummaryModel(
      id: 7,
      peer: ChatPeer(id: 2, fullName: 'Aarav'),
    );

    await tester.pumpWidget(
      testableWidget(
        child: Scaffold(
          appBar: ChatAppBar(
            conversation: conversation,
            reportReasons: ChatReportReason.defaults(),
            onBlock: () {},
            onReport: () {},
            onUnmatch: () {},
            onCall: () {},
            onScheduleVisit: () {},
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('chat_call_button')), findsOneWidget);
    expect(find.byKey(const Key('chat_more_button')), findsOneWidget);
    expect(find.byKey(const Key('chat_video_button')), findsNothing);
  });
}
