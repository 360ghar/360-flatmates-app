import 'dart:async';

import 'package:flatmates_app/features/chats/application/cursor_list_controller.dart';
import 'package:flatmates_app/features/chats/chats_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _LikesPage = ({
  List<IncomingLikeModel> items,
  String? nextCursor,
  bool hasMore,
});

void main() {
  group('Swipe outgoing likes refresh', () {
    test(
      'refresh requested during in-flight load runs after it settles',
      () async {
        final backend = _BlockingChatsBackend();
        final container = _containerWith(backend);

        final notifier = container.read(
          outgoingLikesListControllerProvider.notifier,
        );
        final initialLoad = notifier.load();
        await backend.waitForOutgoingRequests(1);

        final refresh = notifier.refresh();

        backend.completeOutgoingRequest(
          0,
          _page([_like(id: 1, peerId: 10, peerName: 'Stale')]),
        );
        await _settleAsync();

        if (backend.outgoingRequestCount < 2) {
          await initialLoad;
          await refresh;
        }
        expect(
          backend.outgoingRequestCount,
          2,
          reason:
              'a swipe-triggered refresh must not be dropped while the '
              'initial outgoing-likes load is still in flight',
        );
        expect(backend.outgoingRequestCursors, const [null, null]);

        backend.completeOutgoingRequest(
          1,
          _page([_like(id: 2, peerId: 20, peerName: 'Fresh')]),
        );
        await initialLoad;
        await refresh;

        expect(_outgoingItems(container).map((like) => like.peer.id), const [
          20,
        ]);
      },
    );
  });
}

ProviderContainer _containerWith(_BlockingChatsBackend backend) {
  final container = ProviderContainer(
    overrides: [
      chatsRepositoryProvider.overrideWith(
        (ref) => _BlockingChatsRepository(ref, backend),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

List<IncomingLikeModel> _outgoingItems(ProviderContainer container) {
  return container
          .read(outgoingLikesListControllerProvider)
          .valueOrNull
          ?.items ??
      const <IncomingLikeModel>[];
}

IncomingLikeModel _like({
  required int id,
  required int peerId,
  required String peerName,
}) {
  return IncomingLikeModel(
    id: id,
    peer: ChatPeer(id: peerId, fullName: peerName),
    createdAt: DateTime.utc(2026).add(Duration(minutes: id)),
  );
}

_LikesPage _page(List<IncomingLikeModel> items) {
  return (items: items, nextCursor: null, hasMore: false);
}

Future<void> _settleAsync() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

class _BlockingChatsBackend {
  final List<_PendingOutgoingRequest> _outgoingRequests = [];
  Completer<void>? _nextRequestCompleter;

  int get outgoingRequestCount => _outgoingRequests.length;

  List<String?> get outgoingRequestCursors =>
      _outgoingRequests.map((request) => request.cursor).toList();

  Future<_LikesPage> fetchOutgoingLikesPage({String? cursor}) {
    final request = _PendingOutgoingRequest(cursor);
    _outgoingRequests.add(request);
    _nextRequestCompleter?.complete();
    _nextRequestCompleter = null;
    return request.completer.future;
  }

  Future<void> waitForOutgoingRequests(int count) async {
    while (_outgoingRequests.length < count) {
      _nextRequestCompleter = Completer<void>();
      await _nextRequestCompleter!.future.timeout(const Duration(seconds: 1));
    }
  }

  void completeOutgoingRequest(int index, _LikesPage page) {
    _outgoingRequests[index].completer.complete(page);
  }
}

class _PendingOutgoingRequest {
  _PendingOutgoingRequest(this.cursor);

  final String? cursor;
  final Completer<_LikesPage> completer = Completer<_LikesPage>();
}

class _BlockingChatsRepository extends ChatsRepository {
  _BlockingChatsRepository(super.ref, this.backend);

  final _BlockingChatsBackend backend;

  @override
  Future<_LikesPage> fetchOutgoingLikesPage({String? cursor, int limit = 20}) {
    return backend.fetchOutgoingLikesPage(cursor: cursor);
  }
}
