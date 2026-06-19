import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../chats/application/cursor_list_controller.dart';
import '../../shared/presentation/flatmates_async_view.dart';
import '../../shared/presentation/flatmates_card.dart';
import '../../shared/presentation/flatmates_empty_state.dart';
import '../../shared/presentation/flatmates_header.dart';
import '../../shared/presentation/flatmates_network_image.dart';
import '../../shared/presentation/flatmates_skeleton.dart';
import 'application/blog_controller.dart';
import 'domain/blog_post.dart';

/// Public blog index. Cursor-paginated via the cursor controller; tap a
/// card to navigate to `/blog/post/:id`.
class BlogListPage extends ConsumerStatefulWidget {
  const BlogListPage({super.key});

  @override
  ConsumerState<BlogListPage> createState() => _BlogListPageState();
}

class _BlogListPageState extends ConsumerState<BlogListPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(blogListControllerProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 240) {
      Future.microtask(() {
        if (!mounted) return;
        ref.read(blogListControllerProvider.notifier).loadMore();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final state = ref.watch(blogListControllerProvider);
    return Scaffold(
      appBar: FlatmatesHeader.backTitle(title: locale.blogListTitle),
      body: FlatmatesAsyncView<CursorListState<BlogPost>>(
        value: state,
        isEmpty: (s) => s.items.isEmpty,
        loading: const FlatmatesSkeleton.list(),
        empty: FlatmatesEmptyState(
          title: locale.blogEmpty,
          icon: Icons.article_outlined,
        ),
        onRetry: () => ref.read(blogListControllerProvider.notifier).refresh(),
        data: (s) => RefreshIndicator(
          onRefresh: () =>
              ref.read(blogListControllerProvider.notifier).refresh(),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screen,
              vertical: AppSpacing.md,
            ),
            itemCount: s.items.length + (s.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= s.items.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Center(
                    child: s.isLoadingMore
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : TextButton.icon(
                            onPressed: () => ref
                                .read(blogListControllerProvider.notifier)
                                .loadMore(),
                            icon: const Icon(Icons.expand_more_rounded),
                            label: Text(locale.loadMoreCta),
                          ),
                  ),
                );
              }
              final post = s.items[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _BlogCard(
                  post: post,
                  locale: locale,
                  onTap: () => context.push('/blog/post/${post.id}'),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BlogCard extends StatelessWidget {
  const _BlogCard({
    required this.post,
    required this.locale,
    required this.onTap,
  });

  final BlogPost post;
  final AppLocalizations locale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FlatmatesCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (post.coverImageUrl != null && post.coverImageUrl!.isNotEmpty)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: FlatmatesNetworkImage(
                imageUrl: post.coverImageUrl!,
                fit: BoxFit.cover,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _StatusBadge(status: post.status, locale: locale),
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
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  post.title.isEmpty ? locale.blogPostMetaTitleFallback : post.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (post.excerpt != null && post.excerpt!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    post.excerpt!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppSemanticColors.textSecondaryFor(
                        theme.brightness,
                      ),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.locale});

  final BlogPostStatus status;
  final AppLocalizations locale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = switch (status) {
      BlogPostStatus.draft => locale.blogPostStatusDraft,
      BlogPostStatus.published => locale.blogPostStatusPublished,
      BlogPostStatus.scheduled => locale.blogPostStatusScheduled,
      BlogPostStatus.archived => locale.blogPostStatusArchived,
      BlogPostStatus.unknown => '',
    };
    if (label.isEmpty) return const SizedBox.shrink();
    final color = switch (status) {
      BlogPostStatus.published => AppSemanticColors.greenMid,
      BlogPostStatus.scheduled => AppSemanticColors.blueMid,
      BlogPostStatus.archived => AppSemanticColors.textSecondaryFor(
          theme.brightness,
        ),
      _ => AppSemanticColors.yellowMid,
    };
    final bg = switch (status) {
      BlogPostStatus.published => AppSemanticColors.greenSoftFor(
          theme.brightness,
        ),
      BlogPostStatus.scheduled => AppSemanticColors.blueSoftFor(
          theme.brightness,
        ),
      _ => AppSemanticColors.yellowSoftFor(theme.brightness),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
