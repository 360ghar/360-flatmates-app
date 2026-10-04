import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/core/theme/app_spacing.dart';
import 'package:flatmates_app/core/theme/app_theme.dart';
import 'package:flatmates_app/features/chats/chats_repository.dart';
import 'package:flatmates_app/features/chats/presentation/widgets/chat_message_bubble.dart';
import 'package:flatmates_app/features/shared/presentation/flatmates_button.dart';
import 'package:flatmates_app/features/visits/visits_repository.dart';

import '../../helpers/test_helpers.dart';

VisitItem _visit() => VisitItem(
  id: 7,
  propertyTitle: 'Modern 2BHK',
  status: 'requested',
  scheduledDate: DateTime(2025, 5, 20, 11),
  visitContext: 'incoming',
);

ChatMessage _visitRequestMessage() => ChatMessage(
  id: 200,
  conversationId: 10,
  senderId: 2,
  messageType: 'visit_request',
  createdAt: DateTime(2025, 5, 15, 14, 30),
);

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

  group('ChatMessageBubble visit request actions', () {
    /// The visit card geometry from `message_list.dart`: the screen width
    /// minus the 16 dp list gutter, the 40 dp avatar and its 8 dp gap, the
    /// 16 dp card padding and the 8 dp gap between the two buttons.
    ///
    /// The test font draws every glyph as a 16 px square, so the labels are
    /// much wider than Roboto's: a viewport that keeps the pair side by side
    /// here is wider than the ~398 dp the real font needs.
    Future<void> pumpVisitRequest(
      WidgetTester tester, {
      required double width,
      double textScale = 1,
    }) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        testableWidget(
          child: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(textScale),
              ),
              child: Theme(
                data: AppTheme.build(brightness: Brightness.light),
                child: Scaffold(
                  body: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screen,
                    ),
                    child: ChatMessageBubble(
                      message: _visitRequestMessage(),
                      isMine: false,
                      peerName: 'Priya Patel',
                      peerImageUrl: null,
                      visit: _visit(),
                      onConfirmVisit: (_) {},
                      onRescheduleVisit: (_) {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('stacks the CTAs when a 320 dp phone leaves ~100 dp each', (
      tester,
    ) async {
      await pumpVisitRequest(tester, width: 320);

      final buttons = find.byType(FlatmatesButton);
      expect(buttons, findsNWidgets(2));
      final confirm = tester.getRect(buttons.at(0));
      final reschedule = tester.getRect(buttons.at(1));

      // Stacked: full-width rows, one under the other.
      expect(reschedule.top, greaterThanOrEqualTo(confirm.bottom));
      expect(reschedule.left, confirm.left);
      expect(reschedule.width, confirm.width);
      // The card content is 320 - 32 (gutter) - 48 (avatar + gap) - 32 (card
      // padding) = 208 dp, so each CTA gets the whole row.
      expect(confirm.width, greaterThan(150));
    });

    testWidgets('keeps the CTAs side by side when the card is wide enough', (
      tester,
    ) async {
      await pumpVisitRequest(tester, width: 700);

      final buttons = find.byType(FlatmatesButton);
      expect(buttons, findsNWidgets(2));
      final confirm = tester.getRect(buttons.at(0));
      final reschedule = tester.getRect(buttons.at(1));

      expect(reschedule.left, greaterThan(confirm.left));
      expect(reschedule.width, confirm.width);
      // Same row: the two rects overlap vertically.
      expect(reschedule.top, lessThan(confirm.bottom));
      expect(confirm.top, lessThan(reschedule.bottom));
    });

    testWidgets('stacks on a wide screen once the labels grow', (
      tester,
    ) async {
      // Same viewport as the side-by-side case, twice the text size: the
      // decision follows the label metrics, not a fixed breakpoint.
      await pumpVisitRequest(tester, width: 700, textScale: 2);

      final confirm = tester.getRect(find.byType(FlatmatesButton).at(0));
      final reschedule = tester.getRect(find.byType(FlatmatesButton).at(1));
      expect(reschedule.top, greaterThanOrEqualTo(confirm.bottom));
    });
  });
}
