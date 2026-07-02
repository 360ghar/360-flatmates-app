import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_motion.dart';
import '../../core/deep_links/deep_link_service.dart';
import '../../core/providers.dart';
import '../../core/storage/app_preferences.dart';
import '../app_shell.dart';
import '../../features/auth/auth_controller.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../features/auth/presentation/add_phone_page.dart';
import '../../features/auth/presentation/enter_phone_page.dart';
import '../../features/auth/presentation/forgot_password_page.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/otp_page.dart';
import '../../features/auth/presentation/reset_password_page.dart';
import '../../features/auth/presentation/set_password_page.dart';
import '../../features/auth/presentation/splash_page.dart';
import '../../features/bootstrap/bootstrap_controller.dart';
import '../../features/chats/chat_thread_page.dart';
import '../../features/chats/chats_repository.dart';
import '../../features/chats/presentation/chat_peer_profile_page.dart';
import '../../features/chats/conversations_page.dart';
import '../../features/discover/discover_page.dart';
import '../../features/discover/presentation/browse_listings_page.dart';
import '../../features/discover/change_location_page.dart';
import '../../features/location_search/location_search_page.dart';
import '../../features/discover/flat_details_page.dart';
import '../../features/discover/map_view_page.dart';
import '../../features/feedback/domain/feedback_model.dart';
import '../../features/feedback/presentation/feedback_form_page.dart';
import '../../features/listings/create_listing_page.dart';
import '../../features/listings/listing_under_review_page.dart';
import '../../features/listings/manage_listing_page.dart' as listings;
import '../../features/listings/post_hub_page.dart';
import '../../features/notifications/notifications_page.dart';
import '../../features/onboarding/onboarding_controller.dart';
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
import '../../features/settings/privacy_security_page.dart';
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
    if (!next.isLoggedIn) {
      ref.read(flatmatesOnboardingCompletedOverrideProvider.notifier).state =
          false;
      unawaited(
        ref
            .read(appPreferencesProvider)
            .remove(PrefKeys.flatmatesOnboardingCompletedUserId),
      );
    }
    if (previous?.status != next.status ||
        previous?.authStage != next.authStage ||
        previous?.needsPassword != next.needsPassword ||
        previous?.sessionAuthenticated != next.sessionAuthenticated) {
      refreshNotifier.refresh();
    }
  });
  ref.listen<AsyncValue<BootstrapData?>>(bootstrapControllerProvider, (
    previous,
    next,
  ) {
    final nextData = next.valueOrNull;
    if (nextData != null && next.hasValue && !next.isLoading) {
      refreshNotifier.refresh();
    }
  });
  // Re-evaluate the redirect chain when the post-Google add-phone prompt
  // toggles (set after a phone-less Google sign-in, cleared on add/skip).
  ref.listen<bool>(addPhonePromptProvider, (previous, next) {
    if (previous != next) {
      refreshNotifier.refresh();
    }
  });
  ref.listen<bool>(flatmatesOnboardingCompletedOverrideProvider, (
    previous,
    next,
  ) {
    if (previous != next) {
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
          location == '/otp' ||
          location == '/forgot-password' ||
          location == '/reset-password';
      final isAddPhone = location == '/add-phone';
      final isSetPassword = location == '/set-password';
      final isOnboarding = location == '/onboarding';
      final isDeepLink =
          location.startsWith('/chats/') ||
          location.startsWith('/flat-details/') ||
          location.startsWith('/user-profile/') ||
          location.startsWith('/flatmates/listing/') ||
          location.startsWith('/flatmates/chat/') ||
          location.startsWith('/listing-review/') ||
          location.startsWith('/manage-listings') ||
          location == '/notifications' ||
          location == '/notification-settings' ||
          location == '/schedule-visit' ||
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
        return isAuthRoute ? null : '/enter-phone';
      }

      // Requirement 6: mandatory set-password after an OTP verify or backend
      // password_setup gate. Gate everything until it's completed.
      if (auth.needsPassword || auth.authStage == AuthStage.passwordSetup) {
        return isSetPassword ? null : '/set-password';
      }
      if (isSetPassword) {
        // Password set — leave the gate and continue the redirect chain.
        return '/splash';
      }

      if (bootstrap.isLoading) {
        return isSplash ? null : '/splash';
      }

      if (bootstrap.hasError || bootstrap.valueOrNull == null) {
        return isSplash ? null : '/splash';
      }

      final bootstrapData = bootstrap.valueOrNull!;
      final profile = bootstrapData.profile;
      final completedOverrideUserId = ref
          .read(appPreferencesProvider)
          .getString(PrefKeys.flatmatesOnboardingCompletedUserId);
      final hasCompletedOnboardingLocally =
          ref.read(flatmatesOnboardingCompletedOverrideProvider) ||
          completedOverrideUserId == profile.id.toString();
      final isAppReady = authenticatedAppReady(
        authStage: auth.authStage,
        hasCompletedOnboardingLocally: hasCompletedOnboardingLocally,
      );

      if (auth.authStage == AuthStage.unknown) {
        return isSplash ? null : '/splash';
      }

      if (auth.authStage == AuthStage.identifierVerification) {
        if (!auth.sessionAuthenticated) {
          return isAuthRoute ? null : '/enter-phone';
        }
        final localRedirect = authenticatedIdentifierVerificationRedirect(
          location: location,
          isAuthRoute: isAuthRoute,
          isSplash: isSplash,
          profile: profile,
          hasCompletedOnboardingLocally: hasCompletedOnboardingLocally,
        );
        if (localRedirect != null) return localRedirect;
      }

      // ── PROFILE_COMPLETION gate ──────────────────────────────────────────
      // Enforced from the backend-computed auth stage. If mandatory profile
      // fields are missing, route to the edit-profile page to collect them.
      // Skip this gate while the user is already on the edit-profile page.
      final isProfileEdit = location == '/profile/edit';
      if (auth.authStage == AuthStage.profileCompletion && !isProfileEdit) {
        return '/profile/edit';
      }

      if (auth.authStage == AuthStage.appOnboarding &&
          !hasCompletedOnboardingLocally &&
          !isOnboarding) {
        return '/onboarding';
      }

      if (isAppReady && isOnboarding) {
        return '/discover';
      }

      // Post-Google add-phone is skippable and sits after the required backend
      // gates so it does not disturb the auth-stage state machine.
      final wantsAddPhone = ref.read(addPhonePromptProvider);
      final hasPhone = (profile.phone ?? '').trim().isNotEmpty;
      if (isAppReady && wantsAddPhone && !hasPhone) {
        return isAddPhone ? null : '/add-phone';
      }
      if (isAddPhone) {
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
        builder: (context, state) => LoginPage(
          phone: state.uri.queryParameters['phone'],
          email: state.uri.queryParameters['email'],
        ),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) => OtpPage(
          phone: state.uri.queryParameters['phone'] ?? '',
          email: state.uri.queryParameters['email'],
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => ForgotPasswordPage(
          phone: state.uri.queryParameters['phone'],
          email: state.uri.queryParameters['email'],
        ),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => ResetPasswordPage(
          phone: state.uri.queryParameters['phone'],
          email: state.uri.queryParameters['email'],
        ),
      ),
      GoRoute(
        path: '/set-password',
        builder: (context, state) => const SetPasswordPage(),
      ),
      GoRoute(
        path: '/add-phone',
        builder: (context, state) => const AddPhonePage(),
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
        path: '/user-profile/:userId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final userId = int.tryParse(state.pathParameters['userId'] ?? '');
          if (userId == null) {
            final locale = AppLocalizations.of(context);
            return Scaffold(body: Center(child: Text(locale.errorUnknown)));
          }
          return ChatPeerProfilePage(
            userId: userId,
            conversation: state.extra is ConversationSummaryModel
                ? state.extra as ConversationSummaryModel
                : null,
          );
        },
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
        path: '/privacy-security',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PrivacySecurityPage(),
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
                builder: (context, state) => const ModeTab2Switcher(),
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
                builder: (context, state) {
                  final tab = state.uri.queryParameters['tab'];
                  return ConversationsPage(
                    initialTab: const {'chats', 'likes', 'liked'}.contains(tab)
                        ? tab!
                        : 'chats',
                  );
                },
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

@visibleForTesting
bool authenticatedAppReady({
  required AuthStage authStage,
  required bool hasCompletedOnboardingLocally,
}) {
  return authStage == AuthStage.active || hasCompletedOnboardingLocally;
}

@visibleForTesting
String? authenticatedIdentifierVerificationRedirect({
  required String location,
  required bool isAuthRoute,
  required bool isSplash,
  required FlatmatesProfileModel profile,
  required bool hasCompletedOnboardingLocally,
}) {
  // Frontend-only fallback for a stale backend verification mirror: Supabase
  // has already issued a valid session, but /auth-state still reports
  // identifier_verification. Continue with local bootstrap gates instead of
  // bouncing the user back to login.
  final isProfileEdit = location == '/profile/edit';
  final isOnboarding = location == '/onboarding';
  if ((profile.fullName ?? '').trim().isEmpty) {
    return isProfileEdit ? null : '/profile/edit';
  }
  if (!profile.onboardingCompleted && !hasCompletedOnboardingLocally) {
    return isOnboarding ? null : '/onboarding';
  }
  if (isSplash || isAuthRoute || isOnboarding) {
    return '/discover';
  }
  return null;
}

/// Mode lookup for the `/tab2` shell branch.
///
/// Extracted from the widget so the production widget ([ModeTab2Switcher])
/// can be tested without standing up the full bootstrap chain.
final tab2ModeProvider = Provider<String?>((ref) {
  return ref.watch(
    bootstrapControllerProvider.select((v) => v.valueOrNull?.profile.mode),
  );
});

/// Stable wrapper for the `/tab2` shell branch.
///
/// The slot in the parent `IndexedStack` always has the same runtime type
/// ([ModeTab2Switcher]). The internal `build()` picks which child to show
/// based on the current mode. This keeps the wrapper's Element (and its
/// SemanticsNode) alive across mode flips, so the Semantics tree is mutated
/// in place rather than torn down + rebuilt — which is what previously
/// triggered the `!semantics.parentDataDirty` assertion in
/// `rendering/object.dart`.
///
/// Children are returned *without* `ValueKey`s. The author had previously
/// added keys to force a clean State rebuild on mode flip, but the
/// `ValueKey` swap is exactly what made the SemanticsNode detach/attach
/// race the parent-data flush.
class ModeTab2Switcher extends ConsumerStatefulWidget {
  const ModeTab2Switcher({super.key});

  @override
  ConsumerState<ModeTab2Switcher> createState() => _ModeTab2SwitcherState();
}

class _ModeTab2SwitcherState extends ConsumerState<ModeTab2Switcher> {
  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(tab2ModeProvider);
    if (mode == 'room_poster') {
      return const PostHubPage();
    }
    return const MapViewPage();
  }
}
