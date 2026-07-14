import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/core/network/api_client.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/features/chats/application/cursor_list_controller.dart';
import 'package:flatmates_app/features/chats/chats_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../helpers/test_helpers.dart';

class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this.handler);
  final Response<dynamic> Function(RequestOptions) handler;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final response = handler(options);
    return ResponseBody.fromString(
      jsonEncode(response.data),
      response.statusCode ?? 200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }
}

ProviderContainer _containerWithAdapter(
  Response<dynamic> Function(RequestOptions) handler,
) {
  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(fakeAppConfig()),
      authTokenProviderProvider.overrideWithValue(FakeAuthTokenProvider()),
      apiClientProvider.overrideWithValue(
        ApiClient(
          baseUrl: 'https://api.test.example.com',
          tokenProvider: FakeAuthTokenProvider(),
        )..dio.httpClientAdapter = _ScriptedAdapter(handler),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

OutgoingLikeModel _peerLike(int peerId, {int id = -1}) {
  return OutgoingLikeModel(
    id: id,
    targetType: 'user',
    peer: ChatPeer(id: peerId, fullName: 'Peer $peerId'),
    createdAt: DateTime(2025, 5, 15),
  );
}

void main() {
  group('OutgoingLikesController optimistic liked peers', () {
    test(
      'upsertOutgoingLike replaces by peer id without duplicating',
      () async {
        final container = _containerWithAdapter((options) {
          return Response<dynamic>(
            data: {'items': [], 'next_cursor': null, 'has_more': false},
            statusCode: 200,
            requestOptions: options,
          );
        });

        // Prime the controller so it has an initial empty page.
        container.read(outgoingLikesListControllerProvider);
        await Future<void>.delayed(Duration.zero);

        final notifier = container.read(
          outgoingLikesListControllerProvider.notifier,
        );

        // Insert peer 1.
        notifier.upsertOutgoingLike(_peerLike(1));
        var state = container
            .read(outgoingLikesListControllerProvider)
            .valueOrNull!;
        expect(state.items.length, 1);
        expect(state.items.first.peer!.id, 1);

        // Insert peer 2.
        notifier.upsertOutgoingLike(_peerLike(2, id: -2));
        state = container
            .read(outgoingLikesListControllerProvider)
            .valueOrNull!;
        expect(state.items.length, 2);

        // Re-insert peer 1 — should replace, not duplicate.
        notifier.upsertOutgoingLike(_peerLike(1, id: -3));
        state = container
            .read(outgoingLikesListControllerProvider)
            .valueOrNull!;
        expect(state.items.length, 2);
        final peerIds = state.items.map((e) => e.peer!.id).toSet();
        expect(peerIds, {1, 2});
      },
    );

    test('removeOptimistically removes only the matching peer id', () async {
      final container = _containerWithAdapter((options) {
        return Response<dynamic>(
          data: {'items': [], 'next_cursor': null, 'has_more': false},
          statusCode: 200,
          requestOptions: options,
        );
      });

      container.read(outgoingLikesListControllerProvider);
      await Future<void>.delayed(Duration.zero);

      final notifier = container.read(
        outgoingLikesListControllerProvider.notifier,
      );

      notifier.upsertOutgoingLike(_peerLike(1));
      notifier.upsertOutgoingLike(_peerLike(2, id: -2));
      notifier.upsertOutgoingLike(_peerLike(3, id: -3));

      var state = container
          .read(outgoingLikesListControllerProvider)
          .valueOrNull!;
      expect(state.items.length, 3);

      // Remove peer 2 only.
      notifier.removeOptimistically(_peerLike(2, id: -2));
      state = container.read(outgoingLikesListControllerProvider).valueOrNull!;
      expect(state.items.length, 2);
      final peerIds = state.items.map((e) => e.peer!.id).toSet();
      expect(peerIds, {1, 3});
    });

    test(
      'pending optimistic like survives loadMore and a later refresh',
      () async {
        // Page 1: empty server list. Page 2: also empty. Then a refresh
        // (first page again) — the optimistic like must survive all of it.
        final pages = <Map<String, dynamic>>[
          {'items': [], 'next_cursor': 'c1', 'has_more': true},
          {'items': [], 'next_cursor': null, 'has_more': false},
          {'items': [], 'next_cursor': null, 'has_more': false},
        ];
        var callIndex = 0;
        final container = _containerWithAdapter((options) {
          final page =
              pages[callIndex < pages.length ? callIndex : pages.length - 1];
          callIndex++;
          return Response<dynamic>(
            data: page,
            statusCode: 200,
            requestOptions: options,
          );
        });

        container.read(outgoingLikesListControllerProvider);
        await Future<void>.delayed(Duration.zero);

        final notifier = container.read(
          outgoingLikesListControllerProvider.notifier,
        );

        // Add an optimistic like for peer 5.
        notifier.upsertOutgoingLike(_peerLike(5, id: -5));
        var state = container
            .read(outgoingLikesListControllerProvider)
            .valueOrNull!;
        expect(state.items.any((e) => e.peer!.id == 5), isTrue);

        // loadMore — the optimistic like must survive.
        await notifier.loadMore();
        state = container
            .read(outgoingLikesListControllerProvider)
            .valueOrNull!;
        expect(state.items.any((e) => e.peer!.id == 5), isTrue);

        // refresh — the optimistic like must survive.
        await notifier.refresh();
        state = container
            .read(outgoingLikesListControllerProvider)
            .valueOrNull!;
        expect(state.items.any((e) => e.peer!.id == 5), isTrue);
      },
    );
  });
}
