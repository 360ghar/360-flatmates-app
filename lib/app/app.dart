import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/notifications/notification_service.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/auth_controller.dart';
import '../features/bootstrap/bootstrap_controller.dart';
import '../features/settings/settings_controller.dart';
import '../l10n/gen/app_localizations.dart';
import 'router/app_router.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  // Local notifications are initialized in bootstrap() before runApp().
  // NotificationService.initialize() is called after auth login (see ref.listen below).

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    final router = ref.watch(appRouterProvider);

    ref.listen<AuthState>(authControllerProvider, (_, next) {
      final bootstrap = ref.read(bootstrapControllerProvider.notifier);
      if (next.isLoggedIn) {
        bootstrap.load();
        ref.read(notificationServiceProvider).initialize();
        _navigateFromPendingNotification(router);
      } else {
        ref.read(notificationServiceProvider).dispose();
        bootstrap.clear();
      }
    });

    return MaterialApp.router(
      title: '360 FlatMates',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(
        brightness: Brightness.light,
        palette: settings.palette,
      ),
      darkTheme: AppTheme.build(
        brightness: Brightness.dark,
        palette: settings.palette,
      ),
      themeMode: settings.themeMode,
      locale: settings.locale,
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }

  void _navigateFromPendingNotification(GoRouter router) {
    final route = NotificationService.consumePendingRoute();
    if (route != null && route.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        router.push(route);
      });
    }
  }
}
