import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app_shell.dart';
import '../../features/auth/auth_controller.dart';
import '../../features/auth/presentation/enter_phone_page.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/otp_page.dart';
import '../../features/auth/presentation/signup_page.dart';
import '../../features/auth/presentation/splash_page.dart';
import '../../features/bootstrap/bootstrap_controller.dart';
import '../../features/chats/chat_thread_page.dart';
import '../../features/chats/chats_repository.dart';
import '../../features/chats/conversations_page.dart';
import '../../features/discover/discover_page.dart';
import '../../features/discover/flat_details_page.dart';
import '../../features/discover/map_view_page.dart';
import '../../features/listings/create_listing_page.dart';
import '../../features/listings/listing_under_review_page.dart';
import '../../features/notifications/notifications_page.dart';
import '../../features/onboarding/onboarding_page.dart';
import '../../features/profile/edit_profile_page.dart';
import '../../features/profile/help_safety_page.dart';
import '../../features/profile/profile_page.dart';
import '../../features/settings/settings_page.dart';
import '../../features/swipe/swipe_deck_page.dart';
import '../../features/visits/visits_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = RouterRefreshNotifier();
  ref.onDispose(refreshNotifier.dispose);
  ref.listen<AuthState>(authControllerProvider, (previous, next) {
    refreshNotifier.refresh();
  });
  ref.listen<AsyncValue<BootstrapData?>>(bootstrapControllerProvider, (
    previous,
    next,
  ) {
    refreshNotifier.refresh();
  });

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final bootstrap = ref.read(bootstrapControllerProvider);
      final location = state.uri.path;
      final isSplash = location == '/splash';
      final isAuthRoute =
          location == '/enter-phone' ||
          location == '/login' ||
          location == '/signup' ||
          location == '/otp';
      final isOnboarding = location == '/onboarding';
      final isDeepLink = location.startsWith('/chats/') ||
          location.startsWith('/flat-details/') ||
          location.startsWith('/listing-review/') ||
          location == '/visits' ||
          location == '/post' ||
          location == '/notifications' ||
          location == '/help-safety' ||
          location == '/map';

      if (auth.status == AuthStatus.checking) {
        return isSplash ? null : '/splash';
      }

      if (!auth.isLoggedIn) {
        return isAuthRoute ? null : '/enter-phone';
      }

      if (bootstrap.isLoading || bootstrap.valueOrNull == null) {
        return isSplash ? null : '/splash';
      }

      final profile = bootstrap.valueOrNull?.profile;
      if (profile != null && !profile.onboardingCompleted && !isOnboarding) {
        return '/onboarding';
      }

      if (isSplash || isAuthRoute) {
        return '/discover';
      }

      // Allow deep link paths through when user is authenticated
      if (isDeepLink) {
        return null;
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      GoRoute(
        path: '/enter-phone',
        builder: (context, state) => const EnterPhonePage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) =>
            LoginPage(phone: state.uri.queryParameters['phone']),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) =>
            SignupPage(phone: state.uri.queryParameters['phone']),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) =>
            OtpPage(phone: state.uri.queryParameters['phone'] ?? ''),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/flat-details/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => FlatDetailsPage(
          listingId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/map',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MapViewPage(),
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: '/help-safety',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const HelpSafetyPage(),
      ),
      GoRoute(
        path: '/listing-review/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => ListingUnderReviewPage(
          listingId: int.parse(state.pathParameters['id']!),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/discover',
                builder: (context, state) => const DiscoverPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/swipe',
                builder: (context, state) => const SwipeDeckPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chats',
                builder: (context, state) => const ConversationsPage(),
                routes: [
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => ChatThreadPage(
                      conversationId: int.parse(state.pathParameters['id']!),
                      conversation: state.extra as ConversationSummaryModel?,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/visits',
                builder: (context, state) => const VisitsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/post',
                builder: (context, state) => const CreateListingPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfilePage(),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => const EditProfilePage(),
                  ),
                  GoRoute(
                    path: 'settings',
                    builder: (context, state) => const SettingsPage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class RouterRefreshNotifier extends ChangeNotifier {
  void refresh() {
    notifyListeners();
  }
}
