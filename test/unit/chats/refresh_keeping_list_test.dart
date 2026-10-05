import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/core/network/api_client.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/features/chats/application/cursor_list_controller.dart';

import '../../helpers/test_helpers.dart';

class _Item {
  const _Item(this.id);
  final int id;
}

/// Scripted cursor controller: `addPage` queues one response per `fetchPage`
/// call, `failNext` makes the next call throw.
class _ScriptedListController extends CursorListController<_Item> {
  final List<({List<_Item> items, String? nextCursor, bool hasMore})> _pages =
      [];
  bool failNext = false;
  int fetchCount = 0;

  void addPage(List<_Item> items, {bool hasMore = false}) {
    _pages.add((items: items, nextCursor: null, hasMore: hasMore));
  }

  @override
  Future<({List<_Item> items, String? nextCursor, bool hasMore})> fetchPage({
    String? cursor,
  }) async {
    fetchCount++;
    if (failNext) {
      failNext = false;
      throw StateError('offline');
    }
    return _pages.removeAt(0);
  }

  @override
  bool matchesItem(_Item a, _Item b) => a.id == b.id;
}

final _listProvider =
    NotifierProvider<
      _ScriptedListController,
      AsyncValue<CursorListState<_Item>>
    >(_ScriptedListController.new);

/// Calls the primitive from a controller method — the way production code
/// does (a [Ref] used outside of a provider's `build`).
class _RefreshDriverController extends Notifier<int> {
  @override
  int build() => 0;

  Future<void> refreshList() => refreshKeepingList(ref, _listProvider);
}

final _refreshDriverProvider = NotifierProvider<_RefreshDriverController, int>(
  _RefreshDriverController.new,
);

/// A provider that is deliberately never read: the primitive must skip it.
final _neverReadProvider =
    NotifierProvider<
      _ScriptedListController,
      AsyncValue<CursorListState<_Item>>
    >(_ScriptedListController.new);

class _DeadListDriverController extends Notifier<int> {
  @override
  int build() => 0;

  Future<void> refreshList() => refreshKeepingList(ref, _neverReadProvider);
}

final _refreshDeadDriverProvider =
    NotifierProvider<_DeadListDriverController, int>(
      _DeadListDriverController.new,
    );

class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this._handler);

  final Response<dynamic> Function(RequestOptions) _handler;
  final List<RequestOptions> requests = [];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final response = _handler(options);
    return ResponseBody.fromString(
      jsonEncode(response.data),
      response.statusCode ?? 200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }
}

/// Refreshes the three chat lists the way `App._refetchAfterReconnect` does.
class _ChatsRefreshDriverController extends Notifier<int> {
  @override
  int build() => 0;

  Future<void> refresh() => refreshChatListControllers(ref);
}

final _refreshChatsDriverProvider =
    NotifierProvider<_ChatsRefreshDriverController, int>(
      _ChatsRefreshDriverController.new,
    );

void main() {
  group('refreshKeepingList', () {
    test('replaces the rows when the refresh succeeds', () async {
      final controller = _ScriptedListController()
        ..addPage(const [_Item(1)])
        ..addPage(const [_Item(2)]);
      final container = ProviderContainer(
        overrides: [_listProvider.overrideWith(() => controller)],
      );
      addTearDown(container.dispose);

      container.read(_listProvider);
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(_listProvider).valueOrNull!.items.map((i) => i.id),
        [1],
      );

      await container.read(_refreshDriverProvider.notifier).refreshList();

      final state = container.read(_listProvider);
      expect(state.valueOrNull!.items.map((i) => i.id), [2]);
      expect(state.valueOrNull!.hasError, isFalse);
      expect(controller.fetchCount, 2);
    });

    test(
      'keeps the rendered rows (and surfaces the error) on failure',
      () async {
        final controller = _ScriptedListController()..addPage(const [_Item(1)]);
        final container = ProviderContainer(
          overrides: [_listProvider.overrideWith(() => controller)],
        );
        addTearDown(container.dispose);

        container.read(_listProvider);
        await Future<void>.delayed(Duration.zero);
        expect(
          container.read(_listProvider).valueOrNull!.items.map((i) => i.id),
          [1],
        );

        controller.failNext = true;
        await container.read(_refreshDriverProvider.notifier).refreshList();

        final state = container.read(_listProvider);
        // Still data (no error screen / blank spinner) …
        expect(state, isA<AsyncData<CursorListState<_Item>>>());
        expect(state.valueOrNull!.items.map((i) => i.id), [1]);
        // … with the failure attached so the UI can show a banner.
        expect(state.valueOrNull!.hasError, isTrue);
      },
    );

    test('skips a provider that was never read (first read fetches)', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(_refreshDeadDriverProvider.notifier).refreshList();

      expect(container.exists(_neverReadProvider), isFalse);
    });
  });

  group('refreshChatListControllers', () {
    test('keeps the loaded chat lists when the refetch fails', () async {
      var fail = false;
      final adapter = _ScriptedAdapter((options) {
        if (fail) {
          return Response<dynamic>(
            data: {'detail': 'boom'},
            statusCode: 500,
            requestOptions: options,
          );
        }
        if (options.path == '/flatmates/conversations') {
          return Response<dynamic>(
            data: {
              'items': [
                {
                  'id': 1,
                  'peer': {'id': 2, 'full_name': 'Priya'},
                },
              ],
              'next_cursor': null,
              'has_more': false,
            },
            statusCode: 200,
            requestOptions: options,
          );
        }
        return Response<dynamic>(
          data: {'items': [], 'next_cursor': null, 'has_more': false},
          statusCode: 200,
          requestOptions: options,
        );
      });
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(fakeAppConfig()),
          authTokenProviderProvider.overrideWithValue(FakeAuthTokenProvider()),
          apiClientProvider.overrideWithValue(
            ApiClient(
              baseUrl: 'https://api.test.example.com',
              tokenProvider: FakeAuthTokenProvider(),
            )..dio.httpClientAdapter = adapter,
          ),
        ],
      );
      addTearDown(container.dispose);

      // Initial load of all three lists (each starts with one conversation).
      await container
          .read(conversationsListControllerProvider.notifier)
          .refresh();
      await container
          .read(incomingLikesListControllerProvider.notifier)
          .refresh();
      await container
          .read(outgoingLikesListControllerProvider.notifier)
          .refresh();

      expect(
        container.read(conversationsListControllerProvider).valueOrNull!.items,
        hasLength(1),
      );

      fail = true;
      await container.read(_refreshChatsDriverProvider.notifier).refresh();

      final conversations = container
          .read(conversationsListControllerProvider)
          .valueOrNull!;
      expect(
        conversations.items,
        hasLength(1),
        reason: 'the row stays on screen after a failed refresh',
      );
      expect(conversations.hasError, isTrue);
      for (final state in [
        container.read(incomingLikesListControllerProvider).valueOrNull!,
        container.read(outgoingLikesListControllerProvider).valueOrNull!,
      ]) {
        expect(state.hasError, isTrue);
      }
    });
  });
}
