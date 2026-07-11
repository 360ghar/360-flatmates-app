import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/features/chats/chats_repository.dart';
import 'package:flatmates_app/features/shared/presentation/flatmates_ui.dart';
import 'package:flatmates_app/features/visits/schedule_visit_page.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('ScheduleVisitPage', () {
    const conversation = ConversationSummaryModel(
      id: 10,
      source: 'match',
      peer: ChatPeer(id: 2, fullName: 'Priya Patel'),
      contextProperty: ChatPropertyContext(
        id: 42,
        title: 'Modern 2BHK in Koramangala',
        monthlyRent: 24000.0,
      ),
    );

    testWidgets('renders date picker, time slots, and send button', (
      tester,
    ) async {
      await tester.pumpWidget(
        testableWidget(
          child: const ScheduleVisitPage(conversation: conversation),
        ),
      );
      // Use pump instead of pumpAndSettle to avoid timing out on
      // CalendarDatePicker animations. Pump multiple frames to allow
      // the post-frame callback in initState to run.
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Date picker (CalendarDatePicker) is rendered at the top.
      expect(find.byType(CalendarDatePicker), findsOneWidget);

      // Send request button is in the bottom action bar (always visible).
      expect(
        find.byKey(const Key('visit_send_request_button')),
        findsOneWidget,
      );

      // Time slot chips are below the fold in the ListView — drag
      // down to bring them into view.
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('visit_morning_slot')), findsOneWidget);
      expect(find.byKey(const Key('visit_afternoon_slot')), findsOneWidget);
      expect(find.byKey(const Key('visit_evening_slot')), findsOneWidget);
    });

    testWidgets('past date is rejected (validation)', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: const ScheduleVisitPage(conversation: conversation),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // The CalendarDatePicker enforces firstDate = today, preventing
      // the user from selecting a past date in the first place.
      final datePicker = tester.widget<CalendarDatePicker>(
        find.byType(CalendarDatePicker),
      );
      final today = DateTime.now();
      expect(
        datePicker.firstDate.year == today.year &&
            datePicker.firstDate.month == today.month &&
            datePicker.firstDate.day == today.day,
        isTrue,
      );

      // The send button should be enabled (not submitting) and wired.
      final sendButton = tester.widget<FlatmatesButton>(
        find.byKey(const Key('visit_send_request_button')),
      );
      expect(sendButton.onPressed, isNotNull);
    });
  });
}
