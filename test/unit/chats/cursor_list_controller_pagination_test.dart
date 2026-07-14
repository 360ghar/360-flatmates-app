import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flatmates_app/features/chats/application/cursor_list_controller.dart';

/// Plain model with no `==`/`hashCode` override — exercises the
/// "no-value-equality" pagination path where `matchesItem` is the only
/// equality check.
class _PlainItem {
  const _PlainItem(this.id, this.label);
  final int id;
  final String label;
}

class _PlainListController extends CursorListController<_PlainItem> {
  final List<({List<_PlainItem> items, String? nextCursor, bool hasMore})>
  _pages = [];

  void addPage(
    List<_PlainItem> items, {
    String? nextCursor,
    bool hasMore = false,
  }) {
    _pages.add((items: items, nextCursor: nextCursor, hasMore: hasMore));
  }

  int _callIndex = 0;

  @override
  Future<({List<_PlainItem> items, String? nextCursor, bool hasMore})>
  fetchPage({String? cursor}) async {
    final page = _pages[_callIndex++];
    return page;
  }

  @override
  bool matchesItem(_PlainItem a, _PlainItem b) => a.id == b.id;
}

final _provider =
    NotifierProvider<
      _PlainListController,
      AsyncValue<CursorListState<_PlainItem>>
    >(_PlainListController.new);

void main() {
  test(
    'loadMore appends new items for a plain (no-value-equality) model',
    () async {
      final container = ProviderContainer(
        overrides: [
          _provider.overrideWith(() {
            final controller = _PlainListController();
            controller.addPage(
              const [_PlainItem(1, 'a'), _PlainItem(2, 'b')],
              nextCursor: 'cursor1',
              hasMore: true,
            );
            controller.addPage(const [_PlainItem(3, 'c'), _PlainItem(4, 'd')]);
            return controller;
          }),
        ],
      );
      addTearDown(container.dispose);

      // Trigger build + initial load.
      container.read(_provider);
      // Allow the microtask-driven load() to complete.
      await Future<void>.delayed(Duration.zero);

      final firstState = container.read(_provider).valueOrNull!;
      expect(firstState.items.map((e) => e.id), [1, 2]);

      // Load the second page.
      await container.read(_provider.notifier).loadMore();

      final secondState = container.read(_provider).valueOrNull!;
      expect(secondState.items.map((e) => e.id), [1, 2, 3, 4]);
      expect(secondState.hasMore, isFalse);
    },
  );
}
