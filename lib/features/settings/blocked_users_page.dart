import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_failure.dart';
import '../../core/errors/l10n_bridge.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../chats/application/cursor_list_controller.dart';
import '../shared/presentation/flatmates_card.dart';
import '../shared/presentation/flatmates_empty_state.dart';
import '../shared/presentation/flatmates_error_state.dart';
import '../shared/presentation/flatmates_header.dart';
import '../shared/presentation/flatmates_skeleton.dart';
import '../shared/presentation/flatmates_toast.dart';
import '../shared/presentation/flatmates_ui.dart';
import 'data/blocked_users_list_controller.dart';
import 'data/blocked_users_repository.dart';

class BlockedUsersPage extends ConsumerWidget {
  const BlockedUsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = AppLocalizations.of(context);
    final blockedUsers = ref.watch(blockedUsersListControllerProvider);
    final unblockingIds = ref.watch(_unblockingIdsProvider);

    return Scaffold(
      appBar: FlatmatesHeader.backTitle(title: locale.blockedUsersLabel),
      body: blockedUsers.when(
        data: (state) {
          if (state.items.isEmpty) {
            return FlatmatesEmptyState(
              title: locale.noBlockedUsers,
              subtitle: locale.blockedUsersAppearHere,
              icon: Icons.person_off_rounded,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.xl),
            itemCount: state.items.length + (state.hasMore ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              if (index >= state.items.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Center(
                    child: state.isLoadingMore
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : TextButton.icon(
                            onPressed: () => ref
                                .read(
                                  blockedUsersListControllerProvider.notifier,
                                )
                                .loadMore(),
                            icon: const Icon(Icons.expand_more_rounded),
                            label: Text(locale.loadMoreCta),
                          ),
                  ),
                );
              }
              final user = state.items[index];
              final isUnblocking = unblockingIds.contains(user.blockedUserId);
              return FlatmatesCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    FlatmatesAvatar(
                      name: user.name,
                      imageUrl: user.imageUrl,
                      size: 40,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          if (user.location != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              user.location!,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: AppSemanticColors.textSecondaryFor(
                                      Theme.of(context).brightness,
                                    ),
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    FlatmatesButton.secondary(
                      label: locale.unblockCta,
                      destructive: true,
                      height: 36,
                      onPressed: isUnblocking
                          ? null
                          : () async {
                              ref
                                  .read(_unblockingIdsProvider.notifier)
                                  .state = {
                                ...ref.read(_unblockingIdsProvider),
                                user.blockedUserId,
                              };
                              try {
                                await ref
                                    .read(blockedUsersRepositoryProvider)
                                    .unblockUser(user.blockedUserId);
                                ref.invalidate(
                                  blockedUsersListControllerProvider,
                                );
                                if (!context.mounted) return;
                                FlatmatesToast.success(
                                  context,
                                  locale.userUnblocked,
                                );
                              } catch (e) {
                                debugPrint(
                                  'BlockedUsersPage: unblock failed for user ${user.blockedUserId}: $e',
                                );
                                if (!context.mounted) return;
                                final msg = e is AppFailure
                                    ? e.userMessage(locale.toUserMessageL10n())
                                    : locale.unblockFailed;
                                FlatmatesToast.error(context, msg);
                              } finally {
                                ref
                                    .read(_unblockingIdsProvider.notifier)
                                    .state = {
                                  ...ref.read(_unblockingIdsProvider),
                                }..remove(user.blockedUserId);
                              }
                            },
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const FlatmatesSkeleton.list(),
        error: (error, _) => FlatmatesErrorState(
          message: locale.couldNotLoadBlockedUsers,
          onRetry: () => ref
              .read(blockedUsersListControllerProvider.notifier)
              .refresh(),
        ),
      ),
    );
  }
}

final _unblockingIdsProvider = StateProvider<Set<int>>((ref) => {});
