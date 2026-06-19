import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../chats/application/cursor_list_controller.dart';
import '../data/blog_api.dart';
import '../domain/blog_post.dart';

/// Cursor-paginated controller for blog posts. The public list endpoint
/// uses the standard `{ items, next_cursor, has_more, limit }` envelope.
class BlogListController extends CursorListController<BlogPost> {
  @override
  Future<
      ({
        List<BlogPost> items,
        String? nextCursor,
        bool hasMore,
      })> fetchPage({String? cursor}) async {
    final page = await ref.read(blogApiProvider).listPosts(cursor: cursor);
    return (
      items: page.items.map(BlogPost.fromDto).toList(),
      nextCursor: page.nextCursor,
      hasMore: page.hasMore,
    );
  }
}

final blogListControllerProvider = NotifierProvider<
    BlogListController, AsyncValue<CursorListState<BlogPost>>>(
  BlogListController.new,
);

/// Loads a single blog post by id. Used by the detail route when the
/// caller navigates directly to `/blog/post/:id`.
class BlogPostController
    extends AutoDisposeFamilyAsyncNotifier<BlogPost, int> {
  @override
  Future<BlogPost> build(int postId) async {
    final dto = await ref.read(blogApiProvider).getPost(postId);
    return BlogPost.fromDto(dto);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final dto = await ref.read(blogApiProvider).getPost(arg);
      return BlogPost.fromDto(dto);
    });
  }
}

final blogPostControllerProvider = NotifierProvider.autoDispose
    .family<BlogPostController, AsyncValue<BlogPost>, int>(
  BlogPostController.new,
);

/// Fetches a post via a public preview token. Used by the unauthenticated
/// `/blog/preview/:token` share-link route.
class BlogPreviewController
    extends AutoDisposeFamilyAsyncNotifier<BlogPost, String> {
  @override
  Future<BlogPost> build(String token) async {
    final dto = await ref.read(blogApiProvider).getPreview(token);
    return BlogPost.fromDto(dto);
  }
}

final blogPreviewControllerProvider = NotifierProvider.autoDispose
    .family<BlogPreviewController, AsyncValue<BlogPost>, String>(
  BlogPreviewController.new,
);

/// Admin-only: mint a fresh preview token for an existing post. Returns
/// the new token so the admin can share it. Guarded at the controller
/// level (no role check) — the backend rejects non-admins with 403.
class BlogPreviewTokenController
    extends FamilyAsyncNotifier<String?, int> {
  @override
  Future<String?> build(int postId) async {
    // Defer — never auto-mint a token on build.
    if (kDebugMode) {
      debugPrint(
        'BlogPreviewTokenController: build called for post $postId '
        '(call mintPreviewToken to issue a token)',
      );
    }
    return null;
  }

  Future<String> mintPreviewToken(int postId) async {
    state = const AsyncValue.loading();
    try {
      final token = await ref.read(blogApiProvider).mintPreviewToken(postId);
      state = AsyncValue.data(token);
      return token;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final blogPreviewTokenControllerProvider = NotifierProvider.family<
    BlogPreviewTokenController, AsyncValue<String?>, int>(
  BlogPreviewTokenController.new,
);
