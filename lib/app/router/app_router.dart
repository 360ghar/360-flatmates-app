import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_motion.dart';
import '../../core/deep_links/deep_link_service.dart';
import '../app_shell.dart';
import '../../features/auth/auth_controller.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../features/auth/presentation/enter_phone_page.dart';
import '../../features/auth/presentation/forgot_password_page.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/otp_page.dart';
import '../../features/auth/presentation/reset_password_page.dart';
import '../../features/auth/presentation/signup_page.dart';
import '../../features/auth/presentation/splash_page.dart';
import '../../features/bootstrap/bootstrap_controller.dart';
import '../../features/chats/chat_thread_page.dart';
import '../../features/chats/chats_repository.dart';
import '../../features/chats/conversations_page.dart';
import '../../features/discover/discover_page.dart';
import '../../features/discover/presentation/browse_listings_page.dart';
import '../../features/discover/change_location_page.dart';
import '../../features/location_search/location_search_page.dart';
import '../../features/discover/flat_details_page.dart';
import '../../features/discover/map_view_page.dart';
import '../../features/discover/search_filters_page.dart';
import '../../features/feedback/domain/feedback_model.dart';
import '../../features/feedback/presentation/feedback_form_page.dart';
import '../../features/listings/create_listing_page.dart';
import '../../features/listings/listing_under_review_page.dart';
import '../../features/listings/manage_listing_page.dart' as listings;
import '../../features/notifications/notifications_page.dart';
import '../../features/onboarding/onboarding_page.dart';
import '../../features/onboarding/waitlist_page.dart';
import '../../features/profile/edit_profile_page.dart';
import '../../features/profile/help_safety_page.dart';
import '../../features/profile/profile_page.dart';
import '../../features/settings/settings_page.dart';
import '../../features/settings/blocked_users_page.dart';
import '../../features/settings/change_password_page.dart';
import '../../features/settings/delete_account_page.dart';
import '../../features/settings/notification_settings_page.dart';
import '../../features/shared/presentation/flatmates_bottom_sheet.dart';
import '../../features/swipe/swipe_deck_page.dart';
import '../../features/swipe/match_celebration_screen.dart';
import '../../features/swipe/match_qna_nudge.dart';
import '../../features/profile/legal_content_page.dart';
import '../../features/visits/schedule_visit_page.dart';
import '../../features/visits/visits_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = RouterRefreshNotifier();
  ref.onDispose(refreshNotifier.dispose);
  ref.listen<AuthState>(authControllerProvider, (previous, next) {
    if (previous?.status != next.status) {
      refreshNotifier.refresh();
    }
  });
  ref.listen<AsyncValue<BootstrapData?>>(bootstrapControllerProvider, (
    previous,
    next,
  ) {
    final prevData = previous?.valueOrNull;
    final nextData = next.valueOrNull;
    if (prevData == null && nextData != null) {
      refreshNotifier.refresh();
    }
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
          location == '/otp' ||
          location == '/forgot-password' ||
          location == '/reset-password';
      final isOnboarding = location == '/onboarding';
      final isDeepLink =
          location.startsWith('/chats/') ||
          location.startsWith('/flat-details/') ||
          location.startsWith('/flatmates/listing/') ||
          location.startsWith('/flatmates/chat/') ||
          location.startsWith('/listing-review/') ||
          location.startsWith('/manage-listings') ||
          location == '/notifications' ||
          location == '/notification-settings' ||
          location == '/schedule-visit' ||
          location == '/search-filters' ||
          location.startsWith('/help-safety') ||
          location == '/privacy-policy' ||
          location == '/terms-of-service' ||
          location == '/change-password' ||
          location == '/delete-account' ||
          location == '/blocked-users' ||
          location == '/match-celebration' ||
          location == '/waitlist' ||
          location == '/change-location' ||
          location == '/location-search' ||
          location == '/map';

      if (auth.status == AuthStatus.checking) {
        return isSplash ? null : '/splash';
      }

      if (!auth.isLoggedIn) {
        return isAuthRoute ? null : '/login';
      }

      if (bootstrap.isLoading) {
        return isSplash ? null : '/splash';
      }

      if (bootstrap.hasError || bootstrap.valueOrNull == null) {
        return isSplash ? null : '/splash';
      }

      final bootstrapData = bootstrap.valueOrNull!;
      final profile = bootstrapData.profile;

      if (!profile.onboardingCompleted && !isOnboarding) {
        return '/onboarding';
      }

      if (profile.onboardingCompleted && isOnboarding) {
        return '/discover';
      }

      final pendingDeepLink = DeepLinkService.consumePendingDeepLink();
      if (pendingDeepLink != null) {
        return pendingDeepLink;
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
        path: '/forgot-password',
        builder: (context, state) =>
            ForgotPasswordPage(phone: state.uri.queryParameters['phone']),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => const ResetPasswordPage(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/waitlist',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final city = state.uri.queryParameters['city'] ?? '';
          return WaitlistPage(city: city);
        },
      ),
      GoRoute(
        path: '/flat-details/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) {
            final locale = AppLocalizations.of(context);
            return Scaffold(body: Center(child: Text(locale.invalidListingId)));
          }
          return FlatDetailsPage(listingId: id);
        },
      ),
      GoRoute(
        path: '/flatmates/listing/:id',
        parentNavigatorKey: _rootNavigatorKey,
        redirect: (context, state) =>
            '/flat-details/${state.pathParameters['id']}',
      ),
      GoRoute(
        path: '/flatmates/chat/:id',
        parentNavigatorKey: _rootNavigatorKey,
        redirect: (context, state) => '/chats/${state.pathParameters['id']}',
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: '/notification-settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationSettingsPage(),
      ),
      GoRoute(
        path: '/change-location',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ChangeLocationPage(),
      ),
      GoRoute(
        path: '/location-search',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LocationSearchPage(),
      ),
      GoRoute(
        path: '/search-filters',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SearchFiltersPage(),
      ),
      GoRoute(
        path: '/map',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MapViewPage(),
      ),
      GoRoute(
        path: '/schedule-visit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => ScheduleVisitPage(
          conversation: state.extra is ConversationSummaryModel
              ? state.extra as ConversationSummaryModel
              : null,
          conversationId: int.tryParse(
            state.uri.queryParameters['conversationId'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/help-safety',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const HelpSafetyPage(),
        routes: [
          GoRoute(
            path: 'faq',
            builder: (context, state) =>
                const HelpSafetyTopicPage(topic: HelpSafetyTopic.faq),
          ),
          GoRoute(
            path: 'popular-topics',
            builder: (context, state) =>
                const HelpSafetyTopicPage(topic: HelpSafetyTopic.popularTopics),
          ),
          GoRoute(
            path: 'bookings',
            builder: (context, state) => const HelpSafetyTopicPage(
              topic: HelpSafetyTopic.bookingAgreements,
            ),
          ),
          GoRoute(
            path: 'account',
            builder: (context, state) => const HelpSafetyTopicPage(
              topic: HelpSafetyTopic.accountProfile,
            ),
          ),
          GoRoute(
            path: 'contact',
            builder: (context, state) =>
                const HelpSafetyTopicPage(topic: HelpSafetyTopic.contact),
          ),
          GoRoute(
            path: 'report-bug',
            builder: (context, state) =>
                const FeedbackFormPage(type: FeedbackType.bug),
          ),
          GoRoute(
            path: 'request-feature',
            builder: (context, state) =>
                const FeedbackFormPage(type: FeedbackType.feature),
          ),
        ],
      ),
      GoRoute(
        path: '/privacy-policy',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LegalContentPage(
          title: 'Privacy Policy',
          assetPath: 'assets/legal/privacy_policy.md',
        ),
      ),
      GoRoute(
        path: '/terms-of-service',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LegalContentPage(
          title: 'Terms of Service',
          assetPath: 'assets/legal/terms_of_service.md',
        ),
      ),
      GoRoute(
        path: '/change-password',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ChangePasswordPage(),
      ),
      GoRoute(
        path: '/delete-account',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DeleteAccountPage(),
      ),
      GoRoute(
        path: '/blocked-users',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const BlockedUsersPage(),
      ),
      GoRoute(
        path: '/match-celebration',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final conversationId = extra?['conversationId'] as int?;
          final userName = extra?['userName'] as String? ?? 'You';
          final userImageUrl = extra?['userImageUrl'] as String?;
          final peerName = extra?['peerName'] as String? ?? 'Flatmate';
          final peerImageUrl = extra?['peerImageUrl'] as String?;
          return MatchCelebrationScreen(
            userName: userName,
            userImageUrl: userImageUrl,
            peerName: peerName,
            peerImageUrl: peerImageUrl,
            onOpenChat: () {
              context.pop();
              if (conversationId != null) {
                context.push('/chats/$conversationId');
                final rootContext = _rootNavigatorKey.currentContext;
                if (rootContext != null) {
                  Future.delayed(AppMotion.matchCelebration, () {
                    if (rootContext.mounted) {
                      FlatmatesBottomSheet.show(
                        context: rootContext,
                        isScrollControlled: true,
                        builder: (_) =>
                            MatchQnANudgeSheet(conversationId: conversationId),
                      );
                    }
                  });
                }
              } else {
                context.go('/chats');
              }
            },
            onKeepSwiping: () => context.pop(),
          );
        },
      ),
      GoRoute(
        path: '/listing-review/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) {
            final locale = AppLocalizations.of(context);
            return Scaffold(body: Center(child: Text(locale.invalidListingId)));
          }
          return ListingUnderReviewPage(listingId: id);
        },
      ),
      GoRoute(
        path: '/post/new',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => CreateListingPage(
          listingId: int.tryParse(state.uri.queryParameters['listingId'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/manage-listings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const listings.ManageListingPage(),
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
                routes: [
                  GoRoute(
                    path: 'browse-listings',
                    builder: (context, state) => const BrowseListingsPage(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tab2',
                builder: (context, state) => const _ModeTab2Switcher(),
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
                    builder: (context, state) {
                      final id = int.tryParse(state.pathParameters['id'] ?? '');
                      if (id == null) {
                        final locale = AppLocalizations.of(context);
                        return Scaffold(
                          body: Center(
                            child: Text(locale.invalidConversationId),
                          ),
                        );
                      }
                      return ChatThreadPage(
                        conversationId: id,
                        conversation: state.extra is ConversationSummaryModel
                            ? state.extra as ConversationSummaryModel
                            : null,
                      );
                    },
                  ),
                ],
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
                  GoRoute(
                    path: 'visits',
                    builder: (context, state) => const VisitsPage(),
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

class _ModeTab2Switcher extends ConsumerWidget {
  const _ModeTab2Switcher();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(
      bootstrapControllerProvider.select((v) => v.valueOrNull?.profile.mode),
    );
    // Keyed by mode so the branch's State is rebuilt cleanly when the
    // user switches seeker_mode mid-session.
    if (mode == 'room_poster') {
      return const listings.ManageListingPage(
        key: ValueKey('tab2_room_poster'),
      );
    }
    return const MapViewPage(key: ValueKey('tab2_map'));
  }
}
