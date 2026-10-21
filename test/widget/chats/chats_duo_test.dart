import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/core/domain/wire_enums.dart';
import 'package:flatmates_app/core/theme/app_breakpoints.dart';
import 'package:flatmates_app/features/chats/application/cursor_list_controller.dart';
import 'package:flatmates_app/features/chats/chats_repository.dart';
import 'package:flatmates_app/features/chats/conversations_page.dart';
import 'package:flatmates_app/features/chats/domain/chat_models.dart';
import 'package:flatmates_app/features/chats/presentation/widgets/chat_message_bubble.dart';
import 'package:flatmates_app/features/shared/presentation/flatmates_profile_grid_card.dart';
import 'package:flatmates_app/l10n/gen/app_localizations.dart';

import '../../helpers/test_helpers.dart';

/// The two widths this task turns on: the folded phone and the open foldable.
const _phone = Size(466, 678);
const _openLandscape = Size(951, 669);

const _longBody =
    'A very long message that has to wrap over several lines so the bubble '
    'reaches its maximum width instead of hugging the text.';

ChatMessage _textMessage() => ChatMessage(
  id: 100,
  conversationId: 10,
  senderId: 1,
  body: _longBody,
  createdAt: DateTime(2025, 5, 15, 14, 30),
);

ChatMessage _imageMessage() => ChatMessage(
  id: 101,
  conversationId: 10,
  senderId: 2,
  messageType: MessageType.image,
  createdAt: DateTime(2025, 5, 15, 14, 31),
  attachmentUrl: 'https://example.com/photo.jpg',
);

Widget _wrap(Widget child) => MaterialApp(
  locale: const Locale('en'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: Scaffold(body: child),
);

/// Pumps one bubble at [size].
Future<void> _pumpBubble(
  WidgetTester tester,
  Size size,
  ChatMessage message, {
  bool isMine = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    _wrap(
      ChatMessageBubble(
        message: message,
        isMine: isMine,
        peerName: 'Priya',
        peerImageUrl: null,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

/// The bubble's painted width: the [DecoratedBox] behind its text.
Size _bubbleSize(WidgetTester tester) {
  final bubble = find
      .ancestor(of: find.text(_longBody), matching: find.byType(DecoratedBox))
      .first;
  return tester.getSize(bubble);
}

/// Every `maxWidth` the bubble caps itself with.
List<double> _bubbleCaps(WidgetTester tester) => tester
    .widgetList<ConstrainedBox>(
      find.descendant(
        of: find.byType(ChatMessageBubble),
        matching: find.byType(ConstrainedBox),
      ),
    )
    .map((box) => box.constraints.maxWidth)
    .toList();

// ── Likes grid fakes ───────────────────────────────────────────────────

IncomingLikeModel _like(int id) => IncomingLikeModel(
  id: id,
  peer: ChatPeer(id: 100 + id, fullName: 'Peer $id', locality: 'Koramangala'),
  createdAt: DateTime(2025, 5, 15, 14, 30),
);

/// A Likes controller that renders [count] cards without touching the network.
class _LoadedIncomingLikesController extends IncomingLikesController {
  _LoadedIncomingLikesController(this.count);

  final int count;

  @override
  AsyncValue<CursorListState<IncomingLikeModel>> build() {
    return AsyncValue.data(
      CursorListState<IncomingLikeModel>(
        items: [for (var i = 1; i <= count; i++) _like(i)],
        hasMore: false,
      ),
    );
  }

  @override
  Future<({List<IncomingLikeModel> items, String? nextCursor, bool hasMore})>
  fetchPage({String? cursor}) async {
    return (
      items: const <IncomingLikeModel>[],
      nextCursor: null,
      hasMore: false,
    );
  }
}

/// A Likes controller that never resolves, so the tab renders its skeleton.
class _LoadingIncomingLikesController extends IncomingLikesController {
  @override
  AsyncValue<CursorListState<IncomingLikeModel>> build() {
    return const AsyncValue<CursorListState<IncomingLikeModel>>.loading();
  }

  @override
  Future<({List<IncomingLikeModel> items, String? nextCursor, bool hasMore})>
  fetchPage({String? cursor}) async {
    return (
      items: const <IncomingLikeModel>[],
      nextCursor: null,
      hasMore: false,
    );
  }
}

class _EmptyConversationsController extends ConversationsListController {
  @override
  AsyncValue<CursorListState<ConversationSummaryModel>> build() {
    return const AsyncValue.data(
      CursorListState<ConversationSummaryModel>(items: [], hasMore: false),
    );
  }

  @override
  Future<
    ({List<ConversationSummaryModel> items, String? nextCursor, bool hasMore})
  >
  fetchPage({String? cursor}) async {
    return (
      items: const <ConversationSummaryModel>[],
      nextCursor: null,
      hasMore: false,
    );
  }
}

class _EmptyOutgoingLikesController extends OutgoingLikesController {
  @override
  AsyncValue<CursorListState<OutgoingLikeModel>> build() {
    return const AsyncValue.data(
      CursorListState<OutgoingLikeModel>(items: [], hasMore: false),
    );
  }

  @override
  Future<({List<OutgoingLikeModel> items, String? nextCursor, bool hasMore})>
  fetchPage({String? cursor}) async {
    return (
      items: const <OutgoingLikeModel>[],
      nextCursor: null,
      hasMore: false,
    );
  }
}

/// Pumps the Likes tab at [size] with [controller].
Future<void> _pumpLikesTab(
  WidgetTester tester,
  Size size,
  IncomingLikesController Function() controller, {
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    testableWidget(
      overrides: [
        conversationsListControllerProvider.overrideWith(
          _EmptyConversationsController.new,
        ),
        incomingLikesListControllerProvider.overrideWith(controller),
        outgoingLikesListControllerProvider.overrideWith(
          _EmptyOutgoingLikesController.new,
        ),
      ],
      child: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: const ConversationsPage(initialTab: 'likes'),
        ),
      ),
    ),
  );
  // pump() twice rather than pumpAndSettle(): the page owns a rise animation
  // and a skeleton shimmer that never settle.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

SliverGridDelegateWithFixedCrossAxisCount _gridDelegate(WidgetTester tester) {
  final grid = tester.widget<GridView>(find.byType(GridView).first);
  return grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
}

void main() {
  group('chat bubble is capped on a wide viewport', () {
    testWidgets('951 dp: the bubble is 560 dp, not 713', (tester) async {
      await _pumpBubble(tester, _openLandscape, _textMessage());

      // 0.75 * 951 would be 713 dp.
      expect(AppBreakpoints.chatBubbleMaxWidth(951), 560);
      expect(_bubbleCaps(tester), contains(560));
      expect(_bubbleSize(tester).width, 560);
      expect(tester.takeException(), isNull);
    });

    testWidgets('466 dp: the bubble is still width * 0.75', (tester) async {
      await _pumpBubble(tester, _phone, _textMessage());

      expect(AppBreakpoints.chatBubbleMaxWidth(466), 349.5);
      expect(_bubbleCaps(tester), contains(349.5));
      expect(_bubbleSize(tester).width, 349.5);
      expect(tester.takeException(), isNull);
    });

    testWidgets('951 dp: the 4:3 image bubble still reads correctly', (
      tester,
    ) async {
      await _pumpBubble(tester, _openLandscape, _imageMessage(), isMine: false);

      // 80 % of the capped bubble, at 4:3.
      final image = tester.getSize(find.byType(AspectRatio).first);
      expect(image.width, 560 * 0.8);
      expect(image.height, closeTo(560 * 0.8 * 3 / 4, 0.01));
      expect(tester.takeException(), isNull);
    });
  });

  group('Likes grid follows the profile-grid breakpoints', () {
    testWidgets('466 dp lays out 2 columns with square photos', (tester) async {
      await _pumpLikesTab(
        tester,
        _phone,
        () => _LoadedIncomingLikesController(6),
      );

      final delegate = _gridDelegate(tester);
      expect(delegate.crossAxisCount, 2);

      // The ratio has to agree with the count: cell = square photo + 56 dp CTA.
      final cell = tester.getSize(find.byType(FlatmatesProfileGridCard).first);
      expect(cell.width, closeTo(211, 0.5));
      expect(cell.height - cell.width, closeTo(56, 0.5));
      expect(tester.takeException(), isNull);
    });

    testWidgets('951 dp lays out 4 columns with the same cell shape', (
      tester,
    ) async {
      await _pumpLikesTab(
        tester,
        _openLandscape,
        () => _LoadedIncomingLikesController(8),
      );

      final delegate = _gridDelegate(tester);
      expect(delegate.crossAxisCount, 4);

      // The grid sits inside the page gutter (and inside the 720 dp reading
      // column `FlatmatesScreen` applies at 951), so the cells are 163 dp wide.
      final cell = tester.getSize(find.byType(FlatmatesProfileGridCard).first);
      expect(cell.width, closeTo(163, 0.5));
      expect(cell.height - cell.width, closeTo(56, 0.5));

      // Four cards share the first row.
      final tops = <double>{};
      for (final element in find.byType(FlatmatesProfileGridCard).evaluate()) {
        tops.add(tester.getTopLeft(find.byWidget(element.widget)).dy);
      }
      expect(tops.length, 2);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the skeleton matches the loaded grid at both widths', (
      tester,
    ) async {
      for (final size in [_phone, _openLandscape]) {
        await _pumpLikesTab(
          tester,
          size,
          () => _LoadedIncomingLikesController(8),
        );
        final loaded = _gridDelegate(tester);
        final loadedColumns = loaded.crossAxisCount;
        final loadedRatio = loaded.childAspectRatio;

        await _pumpLikesTab(
          tester,
          size,
          () => _LoadingIncomingLikesController(),
        );
        final skeleton = _gridDelegate(tester);

        expect(
          skeleton.crossAxisCount,
          loadedColumns,
          reason: 'skeleton columns at ${size.width}x${size.height}',
        );
        expect(
          skeleton.childAspectRatio,
          closeTo(loadedRatio, 0.0001),
          reason: 'skeleton cell shape at ${size.width}x${size.height}',
        );
      }
    });

    testWidgets('4 columns of 163 dp cards survive a 2x text scale', (
      tester,
    ) async {
      await _pumpLikesTab(
        tester,
        _openLandscape,
        () => _LoadedIncomingLikesController(8),
        textScale: 2,
      );

      // The reserve under the photo is the text-scaled Match CTA, so the cells
      // stay `square photo + CTA` and nothing overflows.
      final delegate = _gridDelegate(tester);
      expect(delegate.crossAxisCount, 4);

      final cell = tester.getSize(find.byType(FlatmatesProfileGridCard).first);
      expect(cell.width, closeTo(163, 0.5));
      expect(cell.height - cell.width, closeTo(112, 1));
      expect(tester.takeException(), isNull);
    });
  });
}
