import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/errors/app_failure.dart';
import '../../core/errors/l10n_bridge.dart';
import '../../core/theme/app_semantic_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../shared/presentation/flatmates_async_view.dart';
import '../shared/presentation/flatmates_empty_state.dart';
import '../shared/presentation/flatmates_header.dart';
import '../shared/presentation/flatmates_skeleton.dart';
import '../shared/presentation/flatmates_toast.dart';
import '../shared/presentation/flatmates_ui.dart';
import 'notifications_repository.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
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
                ref.invalidate(notificationsProvider);
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
            // Scrollable content
            Expanded(
              child: FlatmatesAsyncView<List<NotificationModel>>(
                value: notifications,
                loading: const FlatmatesSkeleton.notificationList(),
                empty: FlatmatesEmptyState(
                  title: locale.notificationEmpty,
                  subtitle: locale.notificationsEmptySubtitle,
                  icon: Icons.notifications_none_rounded,
                ),
                onRetry: () => ref.invalidate(notificationsProvider),
                data: (items) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(notificationsProvider);
                      await ref.read(notificationsProvider.future);
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final notification = items[index];
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
                          onTap: () => _handleTap(context, ref, notification),
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

  void _handleTap(
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
        ref.invalidate(notificationsProvider);
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

    final route = notification.route;
    if (route != null && route.startsWith('/')) {
      context.push(route);
      return;
    }

    String? resolvedRoute;
    switch (notification.type) {
      case 'new_match':
      case 'flatmate_new_match':
      case 'new_message':
      case 'flatmate_new_message':
        if (notification.referenceId != null) {
          resolvedRoute = '/chats/${notification.referenceId}';
        }
        break;
      case 'listing_approved':
      case 'flatmate_listing_approved':
        if (notification.referenceId != null) {
          resolvedRoute = '/flat-details/${notification.referenceId}';
        } else {
          resolvedRoute = '/post';
        }
        break;
      case 'visit_scheduled':
      case 'flatmate_visit_scheduled':
      case 'visit_confirmed':
      case 'flatmate_visit_confirmed':
        resolvedRoute = '/visits';
        break;
    }

    if (resolvedRoute != null) {
      if (resolvedRoute.startsWith('/chats/') ||
          resolvedRoute.startsWith('/flat-details/')) {
        context.push(resolvedRoute);
      } else {
        context.go(resolvedRoute);
      }
    } else if (context.mounted) {
      FlatmatesToast.info(context, locale.notificationNoAction);
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
