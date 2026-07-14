import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/features/chats/application/messages_controller.dart';
import 'package:flatmates_app/features/chats/domain/chat_models.dart';

ChatMessage _msg({
  required int id,
  required int senderId,
  String? body = 'hello',
  String messageType = 'text',
  DateTime? createdAt,
  String? attachmentUrl,
}) {
  return ChatMessage(
    id: id,
    conversationId: 10,
    senderId: senderId,
    body: body,
    messageType: messageType,
    createdAt: createdAt ?? DateTime(2025, 5, 15, 14, 30),
    attachmentUrl: attachmentUrl,
  );
}

void main() {
  group('pruneConfirmedPending', () {
    test('removes a pending message confirmed by a matching real row', () {
      final now = DateTime(2025, 5, 15, 14, 30);
      final pending = [_msg(id: -1, senderId: 1, body: 'hi', createdAt: now)];
      final real = [_msg(id: 100, senderId: 1, body: 'hi', createdAt: now)];
      final remaining = pruneConfirmedPending(real, pending);
      expect(remaining, isEmpty);
    });

    test('keeps a pending message with no matching real row', () {
      final now = DateTime(2025, 5, 15, 14, 30);
      final pending = [_msg(id: -1, senderId: 1, body: 'hi', createdAt: now)];
      final real = [
        _msg(id: 100, senderId: 1, body: 'different', createdAt: now),
      ];
      final remaining = pruneConfirmedPending(real, pending);
      expect(remaining.length, 1);
      expect(remaining.first.id, -1);
    });

    test('does not confirm against another sender', () {
      final now = DateTime(2025, 5, 15, 14, 30);
      final pending = [_msg(id: -1, senderId: 1, body: 'hi', createdAt: now)];
      final real = [_msg(id: 100, senderId: 2, body: 'hi', createdAt: now)];
      final remaining = pruneConfirmedPending(real, pending);
      expect(remaining.length, 1);
    });

    test('does not confirm against an old identical message', () {
      final now = DateTime(2025, 5, 15, 14, 30);
      final old = now.subtract(const Duration(hours: 1));
      final pending = [_msg(id: -1, senderId: 1, body: 'hi', createdAt: now)];
      final real = [_msg(id: 100, senderId: 1, body: 'hi', createdAt: old)];
      final remaining = pruneConfirmedPending(real, pending);
      expect(remaining.length, 1);
    });

    test('greedily consumes one real row per pending duplicate', () {
      final now = DateTime(2025, 5, 15, 14, 30);
      final pending = [
        _msg(id: -1, senderId: 1, body: 'hi', createdAt: now),
        _msg(id: -2, senderId: 1, body: 'hi', createdAt: now),
      ];
      final real = [_msg(id: 100, senderId: 1, body: 'hi', createdAt: now)];
      final remaining = pruneConfirmedPending(real, pending);
      // Only one pending is confirmed; the second stays until its own row
      // arrives.
      expect(remaining.length, 1);
    });

    test('matches image messages on attachment url', () {
      final now = DateTime(2025, 5, 15, 14, 30);
      final pending = [
        _msg(
          id: -1,
          senderId: 1,
          messageType: 'image',
          body: null,
          attachmentUrl: 'https://example.com/photo.jpg',
          createdAt: now,
        ),
      ];
      final real = [
        _msg(
          id: 100,
          senderId: 1,
          messageType: 'image',
          body: null,
          attachmentUrl: 'https://example.com/photo.jpg',
          createdAt: now,
        ),
      ];
      final remaining = pruneConfirmedPending(real, pending);
      expect(remaining, isEmpty);
    });

    test('ignores rows with non-positive ids as confirmation sources', () {
      final now = DateTime(2025, 5, 15, 14, 30);
      final pending = [_msg(id: -1, senderId: 1, body: 'hi', createdAt: now)];
      final real = [
        _msg(id: 0, senderId: 1, body: 'hi', createdAt: now),
        _msg(id: -5, senderId: 1, body: 'hi', createdAt: now),
      ];
      final remaining = pruneConfirmedPending(real, pending);
      expect(remaining.length, 1);
    });
  });

  group('mergeMessages', () {
    test('keeps messages missing from a stale refetch snapshot', () {
      final t1 = DateTime(2025, 5, 15, 14, 30);
      final t2 = DateTime(2025, 5, 15, 14, 31);
      final current = [
        _msg(id: 100, senderId: 1, createdAt: t1),
        _msg(id: 101, senderId: 2, createdAt: t2),
      ];
      // Stale refetch snapshot missing id 101 (raced with realtime).
      final refetched = [_msg(id: 100, senderId: 1, createdAt: t1)];
      final merged = mergeMessages(current, refetched);
      expect(merged.map((m) => m.id), containsAll([100, 101]));
    });

    test('refetched rows win for shared ids and result is sorted', () {
      final t1 = DateTime(2025, 5, 15, 14, 30);
      final t2 = DateTime(2025, 5, 15, 14, 31);
      final current = [
        _msg(id: 100, senderId: 1, body: 'old', createdAt: t1),
        _msg(id: 101, senderId: 2, body: 'keep', createdAt: t2),
      ];
      final refetched = [
        _msg(id: 100, senderId: 1, body: 'fresh', createdAt: t1),
      ];
      final merged = mergeMessages(current, refetched);
      // Sorted by createdAt ascending.
      expect(merged.first.id, 100);
      expect(merged.first.body, 'fresh');
      expect(merged.last.id, 101);
      expect(merged.last.body, 'keep');
    });
  });

  group('MessagesState.displayMessages', () {
    test('appends pending messages after authoritative ones', () {
      final state = MessagesState(
        messages: [_msg(id: 100, senderId: 1), _msg(id: 101, senderId: 2)],
        pendingMessages: [_msg(id: -1, senderId: 1, body: 'pending')],
      );
      final display = state.displayMessages;
      expect(display.length, 3);
      expect(display[0].id, 100);
      expect(display[1].id, 101);
      expect(display[2].id, -1);
    });
  });
}
