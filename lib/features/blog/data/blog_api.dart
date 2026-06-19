import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/endpoints.dart';
import '../../../core/providers.dart';
import '../../../core/utils/paged_envelope.dart';
import 'blog_post_dto.dart';

/// Thin wrapper around the blog REST surface.
///
/// Endpoints exercised:
/// - `GET /blog/posts` — public + admin (filterable by status, category)
/// - `GET /blog/posts/preview/{token}` — public preview for unpublished posts
/// - `POST /blog/posts/{id}/preview-token` — admin-only token mint
class BlogApi {
  const BlogApi(this._ref);

  final Ref _ref;

  /// Public + admin post listing. The backend uses cursor pagination; the
  /// wire envelope is `{ items, next_cursor, has_more, limit }`.
  Future<
      ({
        List<BlogPostDto> items,
        String? nextCursor,
        bool hasMore,
      })> listPosts({
    String? cursor,
    int limit = 20,
    String? status,
    int? categoryId,
  }) async {
    final queryParameters = <String, dynamic>{'limit': limit};
    if (cursor != null && cursor.isNotEmpty) {
      queryParameters['cursor'] = cursor;
    }
    if (status != null && status.isNotEmpty) {
      queryParameters['status'] = status;
    }
    if (categoryId != null) {
      queryParameters['category_id'] = categoryId;
    }
    final response = await _ref.read(apiClientProvider).get(
          FlatmatesEndpoints.blogPosts,
          queryParameters: queryParameters,
        );
    final data = Map<String, dynamic>.from(response.data as Map? ?? const {});
    return parsePagedEnvelope(data, BlogPostDto.fromJson, label: 'blogPosts');
  }

  /// Fetch a single post by id. Used when the post is known by id (e.g.
  /// admin views) and the slug-based listing doesn't include it.
  Future<BlogPostDto> getPost(int id) async {
    final response = await _ref
        .read(apiClientProvider)
        .get(FlatmatesEndpoints.blogPost(id));
    final data = Map<String, dynamic>.from(response.data as Map? ?? const {});
    return BlogPostDto.fromJson(data);
  }

  /// Public preview fetch by token. Used by the unauthenticated
  /// `/blog/preview/{token}` share-link flow.
  Future<BlogPostDto> getPreview(String token) async {
    final response = await _ref
        .read(apiClientProvider)
        .get(FlatmatesEndpoints.blogPostPreview(token));
    final data = Map<String, dynamic>.from(response.data as Map? ?? const {});
    return BlogPostDto.fromPreviewJson(data);
  }

  /// Admin-only: mint a fresh preview token for an existing post. Returns
  /// the new token so the admin can share it.
  Future<String> mintPreviewToken(int postId) async {
    final response = await _ref.read(apiClientProvider).post(
          FlatmatesEndpoints.blogPostPreviewToken(postId),
        );
    final data = Map<String, dynamic>.from(response.data as Map? ?? const {});
    final token = data['token'] as String?;
    if (token == null || token.isEmpty) {
      throw StateError(
        'Preview token missing from ${FlatmatesEndpoints.blogPostPreviewToken(postId)}',
      );
    }
    return token;
  }
}

final blogApiProvider = Provider<BlogApi>((ref) => BlogApi(ref));
