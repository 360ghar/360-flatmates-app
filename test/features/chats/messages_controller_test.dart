import 'package:flatmates_app/features/chats/application/messages_controller.dart';
import 'package:flatmates_app/features/chats/chats_repository.dart';
import 'package:flutter_test/flutter_test.dart';

ChatMessage _message({
  required int id,
  int senderId = 1,
  String? body,
  String messageType = 'text',
  String? attachmentUrl,
  DateTime? createdAt,
}) {
  return ChatMessage(
    id: id,
    conversationId: 10,
    senderId: senderId,
    body: body,
    messageType: messageType,
    createdAt: createdAt ?? DateTime(2026, 6, 10, 12),
    attachmentUrl: attachmentUrl,
  );
}

void main() {
  group('pruneConfirmedPending', () {
    test('removes a pending message confirmed by a matching real row', () {
      final pending = [_message(id: -1, body: 'hello')];
      final real = [_message(id: 100, body: 'hello')];

      expect(pruneConfirmedPending(real, pending), isEmpty);
    });

    test('keeps a pending message with no matching real row', () {
      final pending = [_message(id: -1, body: 'hello')];
      final real = [_message(id: 100, body: 'different')];

      expect(pruneConfirmedPending(real, pending), pending);
    });

    test('does not confirm against another sender', () {
      final pending = [_message(id: -1, body: 'hello')];
      final real = [_message(id: 100, senderId: 2, body: 'hello')];

      expect(pruneConfirmedPending(real, pending), pending);
    });

    test('does not confirm against an old identical message', () {
      final pending = [_message(id: -1, body: 'ok')];
      final real = [
        _message(id: 100, body: 'ok', createdAt: DateTime(2026, 6, 10, 11)),
      ];

      expect(pruneConfirmedPending(real, pending), pending);
    });

    test('greedily consumes one real row per pending duplicate', () {
      final pending = [
        _message(id: -1, body: 'ok'),
        _message(id: -2, body: 'ok'),
      ];

      // Only one real row arrived so far: only one pending is pruned.
      final oneReal = [_message(id: 100, body: 'ok')];
      final remaining = pruneConfirmedPending(oneReal, pending);
      expect(remaining, hasLength(1));
      expect(remaining.single.id, -2);

      // Both real rows arrived: both pendings are pruned.
      final bothReal = [
        _message(id: 100, body: 'ok'),
        _message(id: 101, body: 'ok'),
      ];
      expect(pruneConfirmedPending(bothReal, pending), isEmpty);
    });

    test('matches image messages on attachment url', () {
      final pending = [
        _message(
          id: -1,
          messageType: 'image',
          attachmentUrl: 'https://cdn.example.com/a.jpg',
        ),
      ];
      final confirmed = [
        _message(
          id: 100,
          messageType: 'image',
          attachmentUrl: 'https://cdn.example.com/a.jpg',
        ),
      ];
      final other = [
        _message(
          id: 100,
          messageType: 'image',
          attachmentUrl: 'https://cdn.example.com/b.jpg',
        ),
      ];

      expect(pruneConfirmedPending(confirmed, pending), isEmpty);
      expect(pruneConfirmedPending(other, pending), pending);
    });

    test('ignores rows with non-positive ids as confirmation sources', () {
      final pending = [_message(id: -1, body: 'hello')];
      final real = [_message(id: -3, body: 'hello')];

      expect(pruneConfirmedPending(real, pending), pending);
    });
  });

  group('mergeMessages', () {
    test('keeps messages missing from a stale refetch snapshot', () {
      // Realtime delivered message 12 while the refetch (taken before 12
      // existed) was in flight — the merge must not drop it.
      final current = [
        _message(id: 11, body: 'mine', createdAt: DateTime(2026, 6, 10, 12)),
        _message(
          id: 12,
          senderId: 2,
          body: 'reply',
          createdAt: DateTime(2026, 6, 10, 12, 1),
        ),
      ];
      final refetched = [
        _message(id: 11, body: 'mine', createdAt: DateTime(2026, 6, 10, 12)),
      ];

      final merged = mergeMessages(current, refetched);
      expect(merged.map((m) => m.id).toList(), [11, 12]);
    });

    test('refetched rows win for shared ids and result is sorted', () {
      final current = [
        _message(id: 2, body: 'b', createdAt: DateTime(2026, 6, 10, 12, 2)),
        _message(id: 1, body: 'a', createdAt: DateTime(2026, 6, 10, 12)),
      ];
      final updated = _message(
        id: 1,
        body: 'a',
        createdAt: DateTime(2026, 6, 10, 12),
      );
      final merged = mergeMessages(current, [updated]);

      expect(merged.map((m) => m.id).toList(), [1, 2]);
      expect(identical(merged.first, updated), isTrue);
    });
  });

  group('MessagesState.displayMessages', () {
    test('appends pending messages after authoritative ones', () {
      final state = MessagesState(
        messages: [_message(id: 1, body: 'a')],
        pendingMessages: [_message(id: -1, body: 'b')],
      );

      expect(state.displayMessages.map((m) => m.id).toList(), [1, -1]);
    });
  });
}
