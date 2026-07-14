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
import '../core/network/sse_providers.dart';
import '../core/providers.dart';
import '../core/notifications/notification_service.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/auth_controller.dart';
import '../features/bootstrap/bootstrap_controller.dart';
import '../features/notifications/notification_route_resolver.dart';
import '../features/onboarding/onboarding_controller.dart';
import '../features/settings/settings_controller.dart';
import '../l10n/gen/app_localizations.dart';
import 'router/app_router.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> with WidgetsBindingObserver {
  DeepLinkService? _deepLinkService;
  bool _appConfigChecked = false;

  // Local notifications are initialized in bootstrap() before runApp().
  // NotificationService.initialize() is called after auth login (see ref.listen below).

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    WidgetsBinding.instance.removeObserver(this);
    _deepLinkService?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final bootstrap = ref.read(bootstrapControllerProvider).valueOrNull;
    if (bootstrap == null) return;
    final router = ref.read(appRouterProvider);
    _navigateFromPendingNotification(router);
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
        _presentWithRootNavigator((navContext) {
          unawaited(
            Navigator.of(navContext).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => ForceUpdatePage(updateUrl: downloadUrl),
              ),
              (_) => false,
            ),
          );
        });
      case AppUpdateStatus.optionalUpdate:
        final downloadUrl = result.downloadUrl;
        if (downloadUrl == null || downloadUrl.isEmpty) {
          _appConfigChecked = true;
          return;
        }
        unawaited(analytics.logOptionalUpdateShown());
        _presentWithRootNavigator((navContext) {
          unawaited(
            OptionalUpdateDialog.show(
              navContext,
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
        });
      case AppUpdateStatus.upToDate:
        break;
    }

    _appConfigChecked = true;
  }

  /// _AppState sits above [MaterialApp.router] — use the GoRouter root
  /// navigator so dialogs/pages have a valid [Navigator] ancestor.
  void _presentWithRootNavigator(
    void Function(BuildContext navContext) present,
  ) {
    void tryPresent([int attemptsLeft = 5]) {
      if (!mounted) return;
      final navContext = rootNavigatorKey.currentContext;
      if (navContext != null) {
        present(navContext);
        return;
      }
      if (attemptsLeft <= 0) {
        debugPrint('App._presentWithRootNavigator: root navigator unavailable');
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        tryPresent(attemptsLeft - 1);
      });
    }

    tryPresent();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    final router = ref.watch(appRouterProvider);
    final bootstrapState = ref.watch(bootstrapControllerProvider);

    // Activate Realtime event stream and provider invalidation router.
    ref.watch(flatmatesRealtimeEventRouterProvider);

    // Gate Realtime on device connectivity so DNS/host-lookup failures while
    // offline do not thrash reconnects (and resume cleanly when online).
    ref.listen<AsyncValue<bool>>(connectivityProvider, (previous, next) {
      final online = next.valueOrNull;
      if (online == null) return;
      final service = ref.read(flatmatesRealtimeServiceProvider);
      service.setNetworkAvailable(online);
      if (online && ref.read(authControllerProvider).isLoggedIn) {
        _connectRealtimeIfReady();
      }
    });

    ref.listen<AsyncValue<BootstrapData?>>(bootstrapControllerProvider, (
      _,
      next,
    ) {
      final error = next.asError?.error;
      if (error is AuthExpiredFailure) {
        unawaited(
          ref.read(authControllerProvider.notifier).signOut().catchError((
            Object error,
            StackTrace stackTrace,
          ) {
            debugPrint('App.bootstrap auth-expired signOut failed: $error');
          }),
        );
      }

      // Connect Realtime once bootstrap has a profile id (channel name source).
      final data = next.valueOrNull;
      if (data != null && ref.read(authControllerProvider).isLoggedIn) {
        _connectRealtimeIfReady();
      }

      // Cold-start / late push deep-link: consume pending route whenever
      // bootstrap becomes ready (not a permanent one-shot).
      if (data != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigateFromPendingNotification(router);
        });
      }
    });

    // Handle notification deep links once bootstrap data is present.
    // Always attempt consume — no permanent one-shot flag so subsequent
    // warm taps (when build re-runs) can still navigate.
    if (bootstrapState is AsyncData && bootstrapState.value != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateFromPendingNotification(router);
      });
    }

    // React only to the login/logout *transition*, not to every auth-state
    // emission. Bootstrap fetches /users/me/auth-state and calls
    // updateGateStage(), which re-emits AuthState — so an unguarded listener
    // here would re-refresh bootstrap on every fetch and loop infinitely
    // (each cycle also re-firing logLogin, notification init, and Realtime).
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      final wasLoggedIn = previous?.isLoggedIn ?? false;
      final isLoggedIn = next.isLoggedIn;
      final completedPasswordGate =
          wasLoggedIn &&
          isLoggedIn &&
          (previous?.needsPassword ?? false) &&
          !next.needsPassword;

      if (completedPasswordGate) {
        _refreshBootstrapAfterAuth('password-gate');
      } else if (isLoggedIn == wasLoggedIn &&
          isLoggedIn &&
          _bootstrapNeedsRefresh()) {
        _refreshBootstrapAfterAuth('auth-resume');
      }

      if (isLoggedIn == wasLoggedIn) return;

      if (isLoggedIn) {
        _logLoginSafely();
        _initializeNotificationsSafely();
        // Realtime needs the numeric profile id from bootstrap — connect
        // when bootstrap data is already present, otherwise bootstrap listener
        // above will connect once profile id is available.
        _connectRealtimeIfReady();
      } else {
        ref.read(notificationServiceProvider).dispose();
        ref.read(flatmatesRealtimeServiceProvider).disconnect();
        ref.read(pendingPhoneProvider.notifier).set(null);
        ref.read(addPhonePromptProvider.notifier).set(false);
        unawaited(_clearOnboardingDraftThenInvalidate());
        ref.read(bootstrapControllerProvider.notifier).clear();
      }
    });

    return MaterialApp.router(
      title: '360 FlatMates',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(brightness: Brightness.light),
      darkTheme: AppTheme.build(brightness: Brightness.dark),
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

  bool _bootstrapNeedsRefresh() {
    final bootstrap = ref.read(bootstrapControllerProvider);
    final auth = ref.read(authControllerProvider);
    return !bootstrap.isLoading &&
        (bootstrap.valueOrNull == null ||
            bootstrap.hasError ||
            auth.authStage == AuthStage.unknown);
  }

  void _refreshBootstrapAfterAuth(String source) {
    if (ref.read(bootstrapControllerProvider).isLoading) {
      return;
    }
    unawaited(
      ref.read(bootstrapControllerProvider.notifier).refresh().catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        debugPrint('App.$source bootstrap refresh failed: $error');
      }),
    );
  }

  void _logLoginSafely() {
    try {
      unawaited(
        ref.read(analyticsServiceProvider).logLogin().catchError((
          Object error,
          StackTrace stackTrace,
        ) {
          debugPrint('App.login analytics failed: $error');
        }),
      );
    } catch (error) {
      debugPrint('App.login analytics failed: $error');
    }
  }

  void _initializeNotificationsSafely() {
    try {
      unawaited(
        ref.read(notificationServiceProvider).initialize().catchError((
          Object error,
          StackTrace stackTrace,
        ) {
          debugPrint('App.login notification init failed: $error');
        }),
      );
    } catch (error) {
      debugPrint('App.login notification init failed: $error');
    }
  }

  void _connectRealtimeIfReady() {
    try {
      final bootstrap = ref.read(bootstrapControllerProvider).valueOrNull;
      final profileId = bootstrap?.profile.id;
      if (profileId == null || profileId <= 0) return;

      final realtime =
          bootstrap?.realtime ??
          FlatmatesRealtimeConfig.fallbackForUser(profileId);
      if (realtime.channel.isEmpty) return;

      final online = ref.read(connectivityProvider).valueOrNull ?? true;
      final service = ref.read(flatmatesRealtimeServiceProvider);
      service.setNetworkAvailable(online);

      final tokenProvider = ref.read(authTokenProviderProvider);
      service.connect(
        channelName: realtime.channel,
        tokenRefresher: () => tokenProvider.getAccessToken(),
        privateChannel: realtime.privateChannel,
        events: realtime.events.isNotEmpty ? realtime.events : null,
      );
    } catch (error) {
      debugPrint('App.login Realtime connect failed: $error');
    }
  }

  Future<void> _clearOnboardingDraftThenInvalidate() async {
    try {
      await ref.read(onboardingDraftStorageProvider).clear();
      if (!mounted) return;
      ref.invalidate(onboardingControllerProvider);
    } catch (error) {
      debugPrint('App.logout clear onboarding draft failed: $error');
    }
  }

  void _navigateFromPendingNotification(GoRouter router) {
    final rawRoute = NotificationService.consumePendingRoute();
    if (rawRoute == null || rawRoute.isEmpty) return;

    final route = resolveNotificationDeepLink(rawRoute);
    if (route == null || route.isEmpty) return;

    final analytics = ref.read(analyticsServiceProvider);
    analytics.logNotificationOpened();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      router.go(route);
    });
  }
}
