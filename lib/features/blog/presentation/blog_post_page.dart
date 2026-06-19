import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../shared/presentation/flatmates_async_view.dart';
import '../../shared/presentation/flatmates_error_state.dart';
import '../../shared/presentation/flatmates_header.dart';
import '../../shared/presentation/flatmates_network_image.dart';
import '../../shared/presentation/flatmates_skeleton.dart';
import 'application/blog_controller.dart';
import 'domain/blog_post.dart';

/// Renders a single blog post.
///
/// Backed by [BlogPostController] when accessed via `/blog/post/:id` and
/// [BlogPreviewController] when accessed via `/blog/preview/:token` (an
/// unauthenticated share link). The caller picks the right one by
/// supplying either an `int postId` or a `String token`.
class BlogPostPage extends ConsumerWidget {
  const BlogPostPage.byId({super.key, required int postId})
      : postId = postId,
        token = null;

  const BlogPostPage.byToken({super.key, required String token})
      : token = token,
        postId = null;

  final int? postId;
  final String? token;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = postId != null
        ? ref.watch(blogPostControllerProvider(postId!))
        : ref.watch(blogPreviewControllerProvider(token!));
    final locale = AppLocalizations.of(context);

    return Scaffold(
      appBar: FlatmatesHeader.backTitle(title: locale.blogListTitle),
      body: FlatmatesAsyncView<BlogPost>(
        value: state,
        loading: const FlatmatesSkeleton.list(),
        onRetry: () {
          if (postId != null) {
            ref.read(blogPostControllerProvider(postId!).notifier).refresh();
          }
        },
        error: (e, _) => FlatmatesErrorState(
          message: locale.blogLoadFailed,
          onRetry: () {
            if (postId != null) {
              ref.read(blogPostControllerProvider(postId!).notifier).refresh();
            } else if (token != null) {
              ref.invalidate(blogPreviewControllerProvider(token!));
            }
          },
        ),
        data: (post) => _BlogPostBody(
          post: post,
          isPreview: token != null,
        ),
      ),
    );
  }
}

class _BlogPostBody extends ConsumerWidget {
  const _BlogPostBody({required this.post, required this.isPreview});

  final BlogPost post;
  final bool isPreview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screen,
          vertical: AppSpacing.lg,
        ),
        children: [
          if (isPreview)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _PreviewBanner(locale: locale),
            ),
          if (post.coverImageUrl != null && post.coverImageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: FlatmatesNetworkImage(
                  imageUrl: post.coverImageUrl!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            post.title.isEmpty ? locale.blogPostMetaTitleFallback : post.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              if (post.authorName != null && post.authorName!.isNotEmpty)
                Text(
                  post.authorName!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (post.authorName != null && post.authorName!.isNotEmpty)
                const SizedBox(width: AppSpacing.sm),
              if (post.publishedAt != null)
                Text(
                  DateFormat.yMMMd().format(post.publishedAt!),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppSemanticColors.textSecondaryFor(
                      theme.brightness,
                    ),
                  ),
                ),
              if (post.readingTimeMinutes != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '· ${post.readingTimeMinutes} min read',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppSemanticColors.textSecondaryFor(
                      theme.brightness,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (post.categories.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (final cat in post.categories)
                  Chip(
                    label: Text(cat.name),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          MarkdownBody(
            data: post.body,
            styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
              p: theme.textTheme.bodyLarge,
            ),
          ),
          if (post.sources.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Sources',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final source in post.sources)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text(source, style: theme.textTheme.bodySmall),
              ),
          ],
        ],
      ),
    );
  }
}

class _PreviewBanner extends StatelessWidget {
  const _PreviewBanner({required this.locale});

  final AppLocalizations locale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppSemanticColors.yellowSoftFor(theme.brightness),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.visibility_outlined,
            color: AppSemanticColors.yellowMid,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  locale.blogPreviewBanner,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  locale.blogPreviewBannerSubtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppSemanticColors.textSecondaryFor(
                      theme.brightness,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
