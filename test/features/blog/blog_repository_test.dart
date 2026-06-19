import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flatmates_app/core/config/endpoints.dart';
import 'package:flatmates_app/core/network/api_client.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/features/blog/application/blog_controller.dart';
import 'package:flatmates_app/features/blog/data/blog_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('BlogApi', () {
    test('listPosts returns paged posts from cursor envelope', () async {
      final adapter = _CapturingAdapter(
        responseBody: jsonEncode({
          'items': [
            {
              'id': 1,
              'slug': 'hello',
              'title': 'Hello world',
              'body': '# hi',
              'status': 'published',
              'author_name': '360 Ghar',
              'reading_time_minutes': 3,
            },
            {
              'id': 2,
              'slug': 'second',
              'title': 'Second',
              'body': 'body',
              'status': 'draft',
              'author_name': '360 Ghar',
              'reading_time_minutes': 5,
            },
          ],
          'next_cursor': 'next-page',
          'has_more': true,
          'limit': 20,
        }),
      );
      final container = _containerWith(adapter);
      addTearDown(container.dispose);

      final page = await container.read(blogApiProvider).listPosts();
      expect(adapter.lastRequest?.path, FlatmatesEndpoints.blogPosts);
      expect(page.items, hasLength(2));
      expect(page.items.first.slug, 'hello');
      expect(page.items.first.status,
          BlogPostStatusDto.published);
      expect(page.nextCursor, 'next-page');
      expect(page.hasMore, isTrue);
    });

    test('listPosts accepts status filter', () async {
      final adapter = _CapturingAdapter(
        responseBody: jsonEncode({
          'items': <Map<String, dynamic>>[],
          'next_cursor': null,
          'has_more': false,
          'limit': 20,
        }),
      );
      final container = _containerWith(adapter);
      addTearDown(container.dispose);

      await container
          .read(blogApiProvider)
          .listPosts(status: 'draft', categoryId: 4);

      expect(adapter.lastRequest?.queryParameters['status'], 'draft');
      expect(adapter.lastRequest?.queryParameters['category_id'], 4);
    });

    test('getPreview fetches a token-based preview', () async {
      final adapter = _CapturingAdapter(
        responseBody: jsonEncode({
          'id': 11,
          'slug': 'preview-slug',
          'title': 'Preview',
          'body': 'preview body',
          'status': 'draft',
        }),
      );
      final container = _containerWith(adapter);
      addTearDown(container.dispose);

      final post = await container
          .read(blogApiProvider)
          .getPreview('preview-token');

      expect(adapter.lastRequest?.path,
          FlatmatesEndpoints.blogPostPreview('preview-token'));
      expect(adapter.lastRequest?.method, 'GET');
      expect(post.id, 11);
      expect(post.status, BlogPostStatusDto.draft);
    });

    test('mintPreviewToken POSTs and returns the token', () async {
      final adapter = _CapturingAdapter(
        responseBody: jsonEncode({'token': 'fresh-token'}),
      );
      final container = _containerWith(adapter);
      addTearDown(container.dispose);

      final token = await container
          .read(blogApiProvider)
          .mintPreviewToken(7);

      expect(adapter.lastRequest?.path,
          FlatmatesEndpoints.blogPostPreviewToken(7));
      expect(adapter.lastRequest?.method, 'POST');
      expect(token, 'fresh-token');
    });
  });

  group('BlogListController', () {
    test('load() fetches first page and exposes hasMore + nextCursor', () async {
      final adapter = _CapturingAdapter(
        responseBody: jsonEncode({
          'items': [
            {
              'id': 1,
              'slug': 'a',
              'title': 'A',
              'body': 'b',
              'status': 'published',
            },
          ],
          'next_cursor': 'page-2',
          'has_more': true,
          'limit': 20,
        }),
      );
      final container = _containerWith(adapter);
      addTearDown(container.dispose);

      final controller =
          container.read(blogListControllerProvider.notifier);
      await controller.load();
      // Settle
      await Future<void>.delayed(Duration.zero);

      final state = container.read(blogListControllerProvider);
      expect(state.hasValue, isTrue);
      final value = state.value!;
      expect(value.items, hasLength(1));
      expect(value.hasMore, isTrue);
      expect(value.nextCursor, 'page-2');
    });
  });
}

ProviderContainer _containerWith(HttpClientAdapter adapter) {
  final apiClient = ApiClient(
    baseUrl: 'https://api.test.example.com',
    tokenProvider: FakeAuthTokenProvider(),
  );
  apiClient.dio.httpClientAdapter = adapter;
  return ProviderContainer(
    overrides: [apiClientProvider.overrideWithValue(apiClient)],
  );
}

class _CapturingAdapter implements HttpClientAdapter {
  _CapturingAdapter({this.responseBody = '{}'});

  final String responseBody;
  RequestOptions? lastRequest;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      responseBody,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
