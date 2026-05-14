import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/deep_links/deep_link_service.dart';
import '../core/errors/app_failure.dart';
import '../core/network/connectivity_monitor.dart';
import '../core/network/sse_providers.dart';
import '../core/providers.dart';
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
  DeepLinkService? _deepLinkService;
  bool _hasNavigatedFromNotification = false;

  // Local notifications are initialized in bootstrap() before runApp().
  // NotificationService.initialize() is called after auth login (see ref.listen below).

  @override
  void initState() {
    super.initState();
    // Deep link service is initialized after the first frame so that
    // GoRouter is available via the provider.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final router = ref.read(appRouterProvider);
      _deepLinkService = DeepLinkService(router: router)..init();
    });
  }

  @override
  void dispose() {
    _deepLinkService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    final router = ref.watch(appRouterProvider);
    final bootstrapState = ref.watch(bootstrapControllerProvider);

    // Activate SSE event stream and provider invalidation router.
    ref.watch(sseEventRouterProvider);

    ref.listen<AsyncValue<BootstrapData?>>(bootstrapControllerProvider, (
      _,
      next,
    ) {
      final error = next.asError?.error;
      if (error is AuthExpiredFailure) {
        unawaited(
          ref.read(authControllerProvider.notifier).signOut().catchError((_) {}),
        );
      }
    });

    // Handle notification deep links on bootstrap completion
    if (bootstrapState is AsyncData &&
        bootstrapState.value != null &&
        !_hasNavigatedFromNotification) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateFromPendingNotification(router);
      });
    }

    ref.listen<AuthState>(authControllerProvider, (_, next) {
      final bootstrap = ref.read(bootstrapControllerProvider.notifier);
      if (next.isLoggedIn) {
        bootstrap.load();
        ref.read(notificationServiceProvider).initialize();
        // Connect SSE stream with a token refresher callback so reconnects
        // always use a fresh JWT.
        final config = ref.read(appConfigProvider);
        final tokenProvider = ref.read(authTokenProviderProvider);
        ref
            .read(sseServiceProvider)
            .connect(config.apiBaseUrl, () => tokenProvider.getAccessToken());
      } else {
        ref.read(notificationServiceProvider).dispose();
        ref.read(sseServiceProvider).disconnect();
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
      builder: (context, child) {
        return Stack(
          children: [child ?? const SizedBox.shrink(), const OfflineBanner()],
        );
      },
    );
  }

  void _navigateFromPendingNotification(GoRouter router) {
    final route = NotificationService.consumePendingRoute();
    if (route != null && route.isNotEmpty) {
      _hasNavigatedFromNotification = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        router.go(route);
      });
    }
  }
}
