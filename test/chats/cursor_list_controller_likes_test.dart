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
  group('OutgoingLikesController optimistic liked peers', () {
    test(
      'upsertOutgoingLike replaces by peer id without duplicating',
      () async {
        final backend = _ScriptedChatsBackend(
          outgoingPages: [
            _page([
              _like(id: 1, peerId: 10, peerName: 'Original'),
              _like(id: 2, peerId: 20, peerName: 'Kept'),
            ]),
          ],
        );
        final container = _containerWith(backend);

        final notifier = await _primeOutgoingLikes(container);

        notifier.upsertOutgoingLike(
          _like(id: 99, peerId: 10, peerName: 'Updated'),
        );
        notifier.upsertOutgoingLike(_like(id: 3, peerId: 30, peerName: 'New'));

        final items = _outgoingItems(container);
        expect(items.where((like) => like.peer.id == 10), hasLength(1));
        expect(
          items.singleWhere((like) => like.peer.id == 10).peer.fullName,
          'Updated',
        );
        expect(items.where((like) => like.peer.id == 30), hasLength(1));
        expect(
          items.map((like) => like.peer.id),
          containsAll(const [10, 20, 30]),
        );
      },
    );

    test('removeOptimistically removes only the matching peer id', () async {
      final backend = _ScriptedChatsBackend(
        outgoingPages: [
          _page([
            _like(id: 1, peerId: 10, peerName: 'Remove'),
            _like(id: 2, peerId: 20, peerName: 'Keep'),
          ]),
        ],
      );
      final container = _containerWith(backend);

      final notifier = await _primeOutgoingLikes(container);

      notifier.removeOptimistically(
        _like(id: 999, peerId: 10, peerName: 'Same peer'),
      );

      expect(_outgoingItems(container).map((like) => like.peer.id), const [20]);
    });
  });
}

ProviderContainer _containerWith(_ScriptedChatsBackend backend) {
  final container = ProviderContainer(
    overrides: [
      chatsRepositoryProvider.overrideWith(
        (ref) => _ScriptedChatsRepository(ref, backend),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<OutgoingLikesController> _primeOutgoingLikes(
  ProviderContainer container,
) async {
  final notifier = container.read(outgoingLikesListControllerProvider.notifier);
  await notifier.load();
  return notifier;
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

class _ScriptedChatsBackend {
  _ScriptedChatsBackend({required List<_LikesPage> outgoingPages})
    : _outgoingPages = [...outgoingPages];

  final List<_LikesPage> _outgoingPages;

  Future<_LikesPage> fetchOutgoingLikesPage({String? cursor}) async {
    if (_outgoingPages.isEmpty) {
      throw StateError('No outgoing likes page scripted for cursor $cursor');
    }
    return _outgoingPages.removeAt(0);
  }
}

class _ScriptedChatsRepository extends ChatsRepository {
  _ScriptedChatsRepository(super.ref, this.backend);

  final _ScriptedChatsBackend backend;

  @override
  Future<_LikesPage> fetchOutgoingLikesPage({String? cursor, int limit = 20}) {
    return backend.fetchOutgoingLikesPage(cursor: cursor);
  }
}
