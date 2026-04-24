import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/gen/app_localizations.dart';
import '../features/notifications/notifications_repository.dart';

class AppShell extends ConsumerWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final notifications = ref.watch(notificationsProvider);
    final unreadCount = notifications.valueOrNull
            ?.where((n) => !n.isRead)
            .length ??
        0;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            key: const Key('notifications_bell'),
            onPressed: () => context.push('/notifications'),
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text('$unreadCount'),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
        ],
      ),
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        height: 76,
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: navigationShell.goBranch,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        backgroundColor: theme.colorScheme.surface,
        destinations: [
          NavigationDestination(
            key: const Key('nav_home_tab'),
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: locale.navHome,
          ),
          NavigationDestination(
            key: const Key('nav_swipe_tab'),
            icon: const Icon(Icons.swap_horiz_rounded),
            selectedIcon: const Icon(Icons.swap_horiz_rounded),
            label: locale.navSwipe,
          ),
          NavigationDestination(
            key: const Key('nav_likes_chat_tab'),
            icon: const Icon(Icons.favorite_border_rounded),
            selectedIcon: const Icon(Icons.favorite_rounded),
            label: locale.navLikesChat,
          ),
          NavigationDestination(
            key: const Key('nav_visits_tab'),
            icon: const Icon(Icons.calendar_today_outlined),
            selectedIcon: const Icon(Icons.calendar_today_rounded),
            label: locale.navSchedule,
          ),
          NavigationDestination(
            key: const Key('nav_post_tab'),
            icon: const Icon(Icons.add_home_outlined),
            selectedIcon: const Icon(Icons.add_home_rounded),
            label: locale.navPost,
          ),
          NavigationDestination(
            key: const Key('nav_profile_tab'),
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person_rounded),
            label: locale.navProfile,
          ),
        ],
      ),
    );
  }
}
