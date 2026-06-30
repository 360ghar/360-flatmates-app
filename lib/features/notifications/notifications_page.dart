import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/errors/app_failure.dart';
import '../../core/errors/l10n_bridge.dart';
import '../../core/theme/app_semantic_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../chats/application/cursor_list_controller.dart';
import '../shared/presentation/flatmates_async_view.dart';
import '../shared/presentation/flatmates_empty_state.dart';
import '../shared/presentation/flatmates_header.dart';
import '../shared/presentation/flatmates_skeleton.dart';
import '../shared/presentation/flatmates_toast.dart';
import '../shared/presentation/flatmates_ui.dart';
import 'notifications_list_controller.dart';
import 'notifications_repository.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Prime the cursor controller so the first paint already has data.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(notificationsListControllerProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Triggers an older-page load when the user scrolls near the bottom of
  /// the list. Backed by cursor pagination in
  /// [NotificationsListController].
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 240) {
      Future.microtask(() {
        if (!mounted) return;
        ref.read(notificationsListControllerProvider.notifier).loadMore();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationsState = ref.watch(notificationsListControllerProvider);
    final locale = AppLocalizations.of(context);

    return Scaffold(
      appBar: FlatmatesHeader.backTitle(
        title: locale.notificationsTitle,
        actions: [
          IconButton(
            key: const Key('notification_mark_all_read'),
            onPressed: () async {
              try {
                await ref.read(notificationsRepositoryProvider).markAllAsRead();
                ref.invalidate(notificationsListControllerProvider);
              } catch (e) {
                if (context.mounted) {
                  final msg = e is AppFailure
                      ? e.userMessage(locale.toUserMessageL10n())
                      : locale.errorUnknown;
                  FlatmatesToast.error(context, msg);
                }
              }
            },
            icon: const Icon(Icons.check_circle_outline),
            tooltip: locale.markAllRead,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: FlatmatesAsyncView<CursorListState<NotificationModel>>(
                value: notificationsState,
                loading: const FlatmatesSkeleton.notificationList(),
                isEmpty: (state) => state.items.isEmpty,
                empty: FlatmatesEmptyState(
                  title: locale.notificationEmpty,
                  subtitle: locale.notificationsEmptySubtitle,
                  icon: Icons.notifications_none_rounded,
                ),
                onRetry: () => ref
                    .read(notificationsListControllerProvider.notifier)
                    .refresh(),
                data: (state) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      await ref
                          .read(notificationsListControllerProvider.notifier)
                          .refresh();
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      itemCount: state.items.length + (state.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= state.items.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.lg,
                            ),
                            child: Center(
                              child: state.isLoadingMore
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : TextButton.icon(
                                      onPressed: () => ref
                                          .read(
                                            notificationsListControllerProvider
                                                .notifier,
                                          )
                                          .loadMore(),
                                      icon: const Icon(
                                        Icons.expand_more_rounded,
                                      ),
                                      label: Text(locale.loadMoreCta),
                                    ),
                            ),
                          );
                        }
                        final notification = state.items[index];
                        return FlatmatesNotificationCard(
                          title: notification.title,
                          body: notification.body,
                          time: _formatTime(notification.createdAt, locale),
                          icon: _iconForType(notification.type),
                          iconBgColor: _iconBackgroundForType(
                            notification.type,
                          ),
                          iconColor: _iconColorForType(notification.type),
                          isRead: notification.isRead,
                          onTap: () =>
                              unawaited(_handleTap(context, ref, notification)),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleTap(
    BuildContext context,
    WidgetRef ref,
    NotificationModel notification,
  ) async {
    final locale = AppLocalizations.of(context);
    if (!notification.isRead) {
      try {
        await ref
            .read(notificationsRepositoryProvider)
            .markAsRead(notification.id);
        ref.invalidate(notificationsListControllerProvider);
      } catch (e) {
        if (context.mounted) {
          final msg = e is AppFailure
              ? e.userMessage(locale.toUserMessageL10n())
              : locale.errorUnknown;
          FlatmatesToast.error(context, msg);
        }
      }
    }

    if (!context.mounted) return;

    final resolvedRoute = _resolveNotificationRoute(notification);

    if (resolvedRoute != null) {
      if (resolvedRoute.startsWith('/chats/') ||
          resolvedRoute.startsWith('/flat-details/')) {
        unawaited(context.push(resolvedRoute));
      } else {
        context.go(resolvedRoute);
      }
    } else if (context.mounted) {
      FlatmatesToast.info(context, locale.notificationNoAction);
    }
  }

  String? _resolveNotificationRoute(NotificationModel notification) {
    final explicitRoute = notification.route;
    if (explicitRoute != null && explicitRoute.startsWith('/')) {
      final uri = Uri.tryParse(explicitRoute);
      if (uri == null) return null;
      final path = uri.path;
      final query = uri.hasQuery ? '?${uri.query}' : '';
      if (path == '/post') return '/post/new$query';
      if (path == '/visits' || path.startsWith('/visits/')) {
        return '/profile/visits$query';
      }
      return explicitRoute;
    }

    switch (notification.type) {
      case 'new_match':
      case 'flatmate_new_match':
      case 'new_message':
      case 'flatmate_new_message':
        if (notification.referenceId != null) {
          return '/chats/${notification.referenceId}';
        }
        return null;
      case 'listing_approved':
      case 'flatmate_listing_approved':
        if (notification.referenceId != null) {
          return '/flat-details/${notification.referenceId}';
        }
        return '/post/new';
      case 'visit_scheduled':
      case 'flatmate_visit_scheduled':
      case 'visit_confirmed':
      case 'flatmate_visit_confirmed':
        return '/profile/visits';
      default:
        return null;
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'new_match':
      case 'flatmate_new_match':
        return Icons.favorite_rounded;
      case 'new_message':
      case 'flatmate_new_message':
        return Icons.chat_bubble_outline;
      case 'listing_approved':
      case 'flatmate_listing_approved':
        return Icons.verified_outlined;
      case 'visit_scheduled':
      case 'flatmate_visit_scheduled':
        return Icons.notifications_outlined;
      case 'visit_confirmed':
      case 'flatmate_visit_confirmed':
        return Icons.calendar_month;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _iconBackgroundForType(String type) {
    switch (type) {
      case 'new_match':
      case 'flatmate_new_match':
        return AppSemanticColors.pinkSoft;
      case 'new_message':
      case 'flatmate_new_message':
        return AppSemanticColors.blueSoft;
      case 'listing_approved':
      case 'flatmate_listing_approved':
        return AppSemanticColors.greenSoft;
      case 'visit_scheduled':
      case 'flatmate_visit_scheduled':
        return AppSemanticColors.yellowSoft;
      case 'visit_confirmed':
      case 'flatmate_visit_confirmed':
        return AppSemanticColors.tealSoft;
      default:
        return AppSemanticColors.coralSoft;
    }
  }

  Color _iconColorForType(String type) {
    switch (type) {
      case 'new_match':
      case 'flatmate_new_match':
        return AppSemanticColors.pinkMid;
      case 'new_message':
      case 'flatmate_new_message':
        return AppSemanticColors.blueMid;
      case 'listing_approved':
      case 'flatmate_listing_approved':
        return AppSemanticColors.greenMid;
      case 'visit_scheduled':
      case 'flatmate_visit_scheduled':
        return AppSemanticColors.yellowMid;
      case 'visit_confirmed':
      case 'flatmate_visit_confirmed':
        return AppSemanticColors.tealMid;
      default:
        return AppSemanticColors.accent;
    }
  }

  String _formatTime(DateTime dateTime, AppLocalizations locale) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays == 0) {
      return DateFormat.jm().format(dateTime);
    } else if (diff.inDays == 1) {
      return locale.yesterdayLabel;
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ${locale.daysAgoLabel}';
    } else {
      return DateFormat.MMMd().format(dateTime);
    }
  }
}
