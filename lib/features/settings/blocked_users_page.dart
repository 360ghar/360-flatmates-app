import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_failure.dart';
import '../../core/errors/l10n_bridge.dart';
import '../../core/theme/app_semantic_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../chats/application/cursor_list_controller.dart';
import '../shared/presentation/components.dart';
import 'data/blocked_user_model.dart';
import 'data/blocked_users_list_controller.dart';

class BlockedUsersPage extends ConsumerStatefulWidget {
  const BlockedUsersPage({super.key});

  @override
  ConsumerState<BlockedUsersPage> createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends ConsumerState<BlockedUsersPage> {
  /// Users with an unblock in flight (their button is disabled).
  final _unblocking = <int>{};

  BlockedUsersListController get _controller =>
      ref.read(blockedUsersListControllerProvider.notifier);

  Future<void> _confirmAndUnblock(int blockedUserId) async {
    final locale = AppLocalizations.of(context);
    final confirmed = await FlatmatesDialog.confirm(
      context,
      title: locale.unblockCta,
      cancelLabel: locale.cancelCta,
      confirmLabel: locale.unblockCta,
      cancelKey: const Key('unblock_dialog_cancel'),
      confirmKey: const Key('unblock_dialog_confirm'),
    );
    if (!confirmed || !mounted) return;

    setState(() => _unblocking.add(blockedUserId));
    try {
      await _controller.unblock(blockedUserId);
      if (!mounted) return;
      FlatmatesToast.success(context, locale.userUnblocked);
    } catch (e) {
      debugPrint(
        'BlockedUsersPage: unblock failed for user $blockedUserId: $e',
      );
      if (!mounted) return;
      final msg = e is AppFailure
          ? e.userMessage(locale.toUserMessageL10n())
          : locale.unblockFailed;
      FlatmatesToast.error(context, msg);
    } finally {
      if (mounted) setState(() => _unblocking.remove(blockedUserId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final blockedUsers = ref.watch(blockedUsersListControllerProvider);

    return FlatmatesScreen(
      appBar: FlatmatesHeader.backTitle(title: locale.blockedUsersLabel),
      body: RefreshIndicator(
        onRefresh: _controller.refresh,
        child: FlatmatesAsyncView<CursorListState<BlockedUser>>(
          value: blockedUsers,
          onRetry: _controller.refresh,
          loading: const Padding(
            padding: EdgeInsets.all(AppSpacing.screen),
            child: FlatmatesSkeleton.list(),
          ),
          error: (_, _) => FlatmatesErrorState(
            message: locale.couldNotLoadBlockedUsers,
            onRetry: _controller.refresh,
          ),
          isEmpty: (state) => state.items.isEmpty,
          // A scroll view, so pull to refresh works on the empty state too.
          empty: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              FlatmatesEmptyState(
                title: locale.noBlockedUsers,
                subtitle: locale.blockedUsersAppearHere,
                icon: Icons.person_off_rounded,
              ),
            ],
          ),
          data: (state) => ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.screen),
            itemCount: state.items.length + (state.hasMore ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              if (index >= state.items.length) {
                return Center(
                  child: state.isLoadingMore
                      ? const Padding(
                          padding: EdgeInsets.all(AppSpacing.md),
                          child: SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : FlatmatesButton.tertiary(
                          label: locale.loadMoreCta,
                          icon: Icons.expand_more_rounded,
                          onPressed: _controller.loadMore,
                        ),
                );
              }
              final user = state.items[index];
              return _BlockedUserRow(
                user: user,
                onUnblock: _unblocking.contains(user.blockedUserId)
                    ? null
                    : () => _confirmAndUnblock(user.blockedUserId),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BlockedUserRow extends StatelessWidget {
  const _BlockedUserRow({required this.user, required this.onUnblock});

  final BlockedUser user;
  final VoidCallback? onUnblock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    final identity = Row(
      children: [
        FlatmatesAvatar(name: user.name, imageUrl: user.imageUrl, size: 40),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (user.location != null) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  user.location!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppSemanticColors.textSecondaryFor(theme.brightness),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
    final unblock = FlatmatesButton.tertiary(
      key: ValueKey('unblock_${user.blockedUserId}'),
      label: locale.unblockCta,
      onPressed: onUnblock,
    );
    // At large text sizes the button moves under the name so the name keeps
    // the full row width.
    final large = MediaQuery.textScalerOf(context).scale(1) >= 1.5;

    return FlatmatesCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
      ),
      child: large
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [identity, unblock],
            )
          : Row(
              children: [
                Expanded(child: identity),
                unblock,
              ],
            ),
    );
  }
}
