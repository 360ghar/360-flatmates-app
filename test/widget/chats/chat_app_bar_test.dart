import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/features/chats/chats_repository.dart';
import 'package:flatmates_app/features/chats/domain/chat_report_reason.dart';
import 'package:flatmates_app/features/chats/presentation/widgets/chat_app_bar.dart';

import '../../helpers/test_helpers.dart';

ConversationSummaryModel _conversation({bool withProperty = true}) {
  return ConversationSummaryModel(
    id: 10,
    source: 'match',
    peer: const ChatPeer(id: 2, fullName: 'Priya Patel'),
    contextProperty: withProperty
        ? const ChatPropertyContext(id: 42, title: 'Modern 2BHK')
        : null,
  );
}

Widget _wrap(PreferredSizeWidget child) {
  return testableWidget(child: Scaffold(appBar: child));
}

void main() {
  group('ChatAppBar', () {
    testWidgets('exposes implemented chat actions only', (tester) async {
      // With a context property, the schedule-visit action is implemented
      // and should appear. Without one, it must not render.
      final convWithProperty = _conversation();
      final convWithoutProperty = _conversation(withProperty: false);

      // With property: call + schedule-visit + more buttons present.
      await tester.pumpWidget(
        _wrap(
          ChatAppBar(
            conversation: convWithProperty,
            reportReasons: ChatReportReason.defaults(),
            onBlock: () {},
            onReport: () {},
            onUnmatch: () {},
            onCall: () {},
            onScheduleVisit: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('chat_call_button')), findsOneWidget);
      expect(
        find.byKey(const Key('chat_schedule_visit_button')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('chat_more_button')), findsOneWidget);

      // Without property: schedule-visit button must not be shown.
      await tester.pumpWidget(
        _wrap(
          ChatAppBar(
            conversation: convWithoutProperty,
            reportReasons: ChatReportReason.defaults(),
            onBlock: () {},
            onReport: () {},
            onUnmatch: () {},
            onCall: () {},
            onScheduleVisit: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('chat_call_button')), findsOneWidget);
      expect(find.byKey(const Key('chat_schedule_visit_button')), findsNothing);
      expect(find.byKey(const Key('chat_more_button')), findsOneWidget);
    });
  });
}
