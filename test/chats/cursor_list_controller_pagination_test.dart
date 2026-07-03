import 'package:flatmates_app/features/chats/application/cursor_list_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A plain model with no `==`/`hashCode`/`toString` override.
///
/// Before the matchesItem fix, `CursorListController.matchesItem` defaulted to
/// `a.toString() == b.toString()`. For a class like this every instance shares
/// the default `"Instance of '_PlainItem'"` string, so `loadMore()` treated
/// every page-2 item as a duplicate of a rendered item and appended nothing —
/// silently breaking pagination for Visits/Notifications/BlockedUsers/MyListings.
/// This model locks that regression.
class _PlainItem {
  const _PlainItem(this.id);
  final int id;
}

typedef _PlainPage = ({
  List<_PlainItem> items,
  String? nextCursor,
  bool hasMore,
});

final _scriptedPagesProvider = Provider<List<_PlainPage>>(
  (ref) => throw UnimplementedError('override _scriptedPagesProvider in tests'),
);

class _PlainListController extends CursorListController<_PlainItem> {
  @override
  Future<_PlainPage> fetchPage({String? cursor}) async {
    final pages = ref.read(_scriptedPagesProvider);
    if (pages.isEmpty) {
      throw StateError('no scripted page for cursor $cursor');
    }
    return pages.removeAt(0);
  }

  @override
  bool matchesItem(_PlainItem a, _PlainItem b) => a.id == b.id;
}

final _plainListControllerProvider =
    NotifierProvider<
      _PlainListController,
      AsyncValue<CursorListState<_PlainItem>>
    >(_PlainListController.new);

void main() {
  test(
    'loadMore appends new items for a plain (no-value-equality) model',
    () async {
      final pages = <_PlainPage>[
        (
          items: const [_PlainItem(1), _PlainItem(2)],
          nextCursor: 'c2',
          hasMore: true,
        ),
        (
          items: const [_PlainItem(3), _PlainItem(4)],
          nextCursor: null,
          hasMore: false,
        ),
      ];
      final container = ProviderContainer(
        overrides: [_scriptedPagesProvider.overrideWithValue(pages)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(_plainListControllerProvider.notifier);
      await notifier.load();
      expect(
        container
            .read(_plainListControllerProvider)
            .requireValue
            .items
            .map((i) => i.id),
        [1, 2],
      );

      await notifier.loadMore();
      // Before the fix this stayed [1, 2] — every page-2 item was deduped away
      // because the default matchesItem considered any two _PlainItem equal.
      expect(
        container
            .read(_plainListControllerProvider)
            .requireValue
            .items
            .map((i) => i.id),
        [1, 2, 3, 4],
      );
    },
  );
}
