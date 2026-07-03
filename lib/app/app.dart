import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/analytics/analytics_service.dart';
import '../core/app_config/app_config_service.dart';
import '../core/app_config/force_update_page.dart';
import '../core/app_config/optional_update_dialog.dart';
import '../core/deep_links/deep_link_service.dart';
import '../core/errors/app_failure.dart';
import '../core/network/connectivity_monitor.dart';
import '../core/network/flatmates_realtime_providers.dart';
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
  bool _appConfigChecked = false;

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
      _checkAppConfig();
      ref.read(analyticsServiceProvider).logAppOpen();
    });
  }

  @override
  void dispose() {
    _deepLinkService?.dispose();
    super.dispose();
  }

  Future<void> _checkAppConfig() async {
    if (_appConfigChecked) return;

    final configService = ref.read(appConfigServiceProvider);
    final analytics = ref.read(analyticsServiceProvider);
    final result = await configService.checkForUpdates();

    if (!mounted || result == null) {
      // Version check failed — let the app continue normally.
      _appConfigChecked = true;
      return;
    }

    final status = await configService.resolveUpdateStatus(result);

    if (!mounted) {
      _appConfigChecked = true;
      return;
    }

    switch (status) {
      case AppUpdateStatus.forceUpdate:
        final downloadUrl = result.downloadUrl;
        if (downloadUrl == null || downloadUrl.isEmpty) {
          _appConfigChecked = true;
          return;
        }
        unawaited(analytics.logForceUpdateShown());
        unawaited(
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => ForceUpdatePage(updateUrl: downloadUrl),
            ),
            (_) => false,
          ),
        );
      case AppUpdateStatus.optionalUpdate:
        final downloadUrl = result.downloadUrl;
        if (downloadUrl == null || downloadUrl.isEmpty) {
          _appConfigChecked = true;
          return;
        }
        unawaited(analytics.logOptionalUpdateShown());
        unawaited(
          OptionalUpdateDialog.show(
            context,
            updateUrl: downloadUrl,
            message: result.releaseNotes ?? '',
            onDismiss: () {
              final version = result.latestVersion;
              if (version != null) {
                configService.dismissOptionalUpdate(version);
              }
            },
          ),
        );
      case AppUpdateStatus.upToDate:
        break;
    }

    _appConfigChecked = true;
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    final router = ref.watch(appRouterProvider);
    final bootstrapState = ref.watch(bootstrapControllerProvider);

    // Activate Supabase Broadcast event stream and provider invalidation router.
    ref.watch(flatmatesRealtimeEventRouterProvider);

    ref.listen<AsyncValue<BootstrapData?>>(bootstrapControllerProvider, (
      _,
      next,
    ) {
      final error = next.asError?.error;
      if (error is AuthExpiredFailure) {
        unawaited(
          ref
              .read(authControllerProvider.notifier)
              .signOut()
              .catchError((_) {}),
        );
      }
      final realtimeConfig = next.valueOrNull?.realtime;
      if (realtimeConfig != null) {
        final tokenProvider = ref.read(authTokenProviderProvider);
        ref
            .read(flatmatesRealtimeServiceProvider)
            .connect(
              channel: realtimeConfig.channel,
              private: realtimeConfig.private,
              events: realtimeConfig.events,
              tokenRefresher: () => tokenProvider.getAccessToken(),
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

    // React only to the login/logout *transition*, not to every auth-state
    // emission. Bootstrap fetches /users/me/auth-state and calls
    // updateGateStage(), which re-emits AuthState — so an unguarded listener
    // here would re-refresh bootstrap on every fetch and loop infinitely
    // (each cycle also re-firing logLogin, notification init, and realtime connect).
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      final wasLoggedIn = previous?.isLoggedIn ?? false;
      final isLoggedIn = next.isLoggedIn;
      if (isLoggedIn == wasLoggedIn) return;

      if (isLoggedIn) {
        ref.read(analyticsServiceProvider).logLogin();
        ref.read(bootstrapControllerProvider.notifier).refresh();
        ref.read(notificationServiceProvider).initialize();
      } else {
        ref.read(notificationServiceProvider).dispose();
        unawaited(ref.read(flatmatesRealtimeServiceProvider).disconnect());
        ref.read(bootstrapControllerProvider.notifier).clear();
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
      final analytics = ref.read(analyticsServiceProvider);
      analytics.logNotificationOpened();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        router.go(route);
      });
    }
  }
}
