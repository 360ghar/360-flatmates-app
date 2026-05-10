# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

360 FlatMates — a Flutter mobile client for flatmate-finding in India. Uses Supabase for auth/storage and a FastAPI backend monolith at `../backend` for all business logic and product data.

- **Flutter:** 3.35.2 (pinned via FVM in `.fvmrc`)
- **Dart SDK:** ^3.11.0
- **App ID:** `com.the360ghar.flatmates`

## Commands

```bash
# Setup
cp .env.example .env          # then fill in SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, API_BASE_URL, GOOGLE_MAPS_API_KEY
flutter pub get

# Run
flutter run

# iOS Simulator browser preview (run BEFORE flutter run, requires macOS + Xcode)
npx serve-sim                  # → http://localhost:3200 — stream simulator to browser for agent testing

# Code generation (run after changing freezed/json_serializable models)
dart run build_runner build --delete-conflicting-outputs

# Quality
flutter analyze
flutter test
bash scripts/banned_patterns.sh

# Localization (auto-generated on build, but can be triggered manually)
flutter gen-l10n

# CI (.github/workflows/quality.yml): dart format --set-exit-if-changed, flutter analyze --fatal-infos, flutter gen-l10n, flutter test

# Maestro E2E (requires MAESTRO_PHONE, MAESTRO_PASSWORD, etc. env vars)
maestro test .maestro/flatmates_e2e.yaml
maestro test maestro/e2e.yaml
```

## Architecture

### Feature-first structure under `lib/`

```
lib/
  main.dart                     → entry point
  bootstrap.dart                → DI setup, Supabase init, Firebase, ProviderScope with 3 overrides
  app/
    app.dart                    → MaterialApp.router + OfflineBanner in Stack, DeepLinkService init
    app_shell.dart              → mode-dependent bottom nav (5 visible tabs from 7 branches)
    router/app_router.dart      → GoRouter with auth/bootstrap redirects + deep links
  core/                         → app-wide plumbing only (no feature logic)
    providers.dart              → global Riverpod provider graph (7 providers)
    config/                     → AppConfig, FlatmatesEndpoints, constants, env loader
    network/                    → Dio client, auth/error interceptors, connectivity monitor
    notifications/              → Firebase Messaging (foreground + background)
    storage/                    → SharedPreferences, secure storage, image upload
    theme/                      → Material 3 theme, palette switching, design token constants
    compatibility/              → client-side matching algorithm (6 weighted dimensions)
    deep_links/                 → DeepLinkService (app_links, cold+warm start)
    domain/                     → PagedState<T>, OptimisticUpdate, typed enums
    errors/                     → AppFailure sealed class, ErrorPresenter, l10n bridge
    analytics/                  → AnalyticsEvents + AnalyticsProps constants
    utils/                      → ActionDebouncer
  features/                     → each feature owns its controller, repo, models, pages
    auth/                       → Supabase auth (phone+password, OTP) [data/domain/presentation]
    bootstrap/                  → loads /flatmates/bootstrap (profile + catalogs + counts) [domain]
    onboarding/                 → multi-step state machine with draft persistence [domain]
    discover/                   → listing feed + map + search filters [application/data/domain/presentation+widgets]
    swipe/                      → Tinder-like card deck with deal-breaker filtering [presentation+widgets]
    chats/                      → conversations + messages (polling + optimistic send) [application/domain/presentation+widgets]
    listings/                   → multi-step listing builder + manage [application/domain/presentation+widgets]
    visits/                     → schedule/confirm/reschedule visits
    notifications/              → notification list
    profile/                    → profile view/edit
    settings/                   → theme, palette, locale, privacy, blocked users, change password [data/domain]
    shared/presentation/        → 18 Flatmates* reusable widgets, barrel-exported via components.dart
```

### State management — Riverpod

- `NotifierProvider` / `AsyncNotifierProvider` for controllers with explicit state and named methods (`DiscoverFeedController`, `ListingDraftController`, `MessagesController`, `AuthController`, `BootstrapController`, `OnboardingController`, `SettingsController`)
- `FamilyNotifier` for parameterized controllers (`MessagesController` per conversation)
- `Provider` for repositories and services (injected via `ref.watch`)
- `FutureProvider` / `FutureProvider.family` for one-shot async data (swipe profiles, conversations, notifications, visits)
- `StreamProvider` for streams (`connectivityProvider`)
- `PagedState<T>` for paginated data with initial/refresh/load-more loading states
- `OptimisticUpdate.perform<T>()` for optimistic UI writes with rollback on failure
- Three providers overridden at `ProviderScope` root: `appConfigProvider`, `appPreferencesProvider`, `secureStoreProvider`
- After write operations, **invalidate** the relevant provider rather than manually syncing widget state

### Routing — GoRouter

- `StatefulShellRoute.indexedStack` with 7 branches: `/discover`, `/map`, `/swipe`, `/chats`, `/post`, `/visits`, `/profile`
- Mode-dependent bottom nav shows 5 of 7 tabs: Room Poster sees Home|Post|Swipe|Likes&Chat|Profile; Co-Hunter/Open to Both sees Home|Explore|Swipe|Likes&Chat|Profile
- Additional full-screen routes (using `parentNavigatorKey`): `/search-filters`, `/schedule-visit`, `/change-password`, `/blocked-users`, `/flat-details`, `/chat-thread`
- Auth redirect chain: checking → `/splash`, unauthenticated → `/enter-phone`, onboarding incomplete → `/onboarding`
- Router refreshes on `authControllerProvider` and `bootstrapControllerProvider` changes
- Deep links: `/flatmates/listing/{id}` → flat details, `/flatmates/chat/{id}` → chat thread (via `app_links`)

### Error handling

- `AppFailure` sealed class hierarchy in `core/errors/`: `NetworkFailure`, `AuthExpiredFailure`, `ServerFailure`, `PermissionFailure`, `NotFoundFailure`, `ValidationFailure`, `RateLimitFailure`, `ConflictFailure`, `UploadFailure`, `UnknownFailure`
- `ErrorPresenter.fromDio()` maps `DioException` → typed `AppFailure` subclass (including field-level 422 parsing)
- `UserMessageL10n` bridge decouples `AppFailure.userMessage()` from generated l10n
- `FlatmatesAsyncView` renders `AsyncValue<T>` into loading/data/empty/error states using `AppFailure.userMessage()`
- **Banned in pages:** `error.toString()` (enforced by `scripts/banned_patterns.sh`)

### Networking

- Shared `Dio` client from `core/network/api_client.dart` — all authenticated requests go through this
- `AuthInterceptor` attaches Bearer token; handles 401 with request queue to prevent token-refresh race conditions
- `ErrorInterceptor` maps DioException types to user-friendly messages
- `FlatmatesEndpoints` (`core/config/endpoints.dart`) centralizes all API path constants
- Backend paths are relative to `AppConfig.apiBaseUrl` (set via `.env` or `--dart-define`)

### Deep linking

- `DeepLinkService` (`core/deep_links/deep_link_service.dart`) parses incoming HTTP deep links via `app_links`
- Supported paths: `/flatmates/listing/{id}` → flat details, `/flatmates/chat/{id}` → chat thread
- Handles cold start (initial link) and warm start (stream listener)

### Connectivity / Offline

- `connectivityProvider` (`StreamProvider<bool>` via `connectivity_plus`) monitors network state
- `OfflineBanner` shown as a Stack overlay above `MaterialApp.router` when offline

### Auth flow

1. Phone input → password login or OTP via Supabase
2. After auth, `GET /users/me` validates user exists in backend
3. `BootstrapController` fetches `/flatmates/bootstrap` for profile + catalogs
4. If `onboardingCompleted == false`, router redirects to onboarding flow
5. Missing env vars show `_ConfigErrorApp`; missing Firebase config sets `NotificationService.messagingEnabled = false`

### Theme and localization

- Material 3 via `ColorScheme.fromSeed()` with 3 palettes: electric indigo (default), ember coral, monsoon teal
- Google Fonts: Sora (headlines), Plus Jakarta Sans (body)
- Design token constant files in `core/theme/`: `AppSpacing`, `AppRadius`, `AppShadows`, `AppMotion`, `AppTypography`, `AppSemanticColors`, `AppGradients` — barrel-exported via `theme.dart`
- Light/dark/system theme modes, persisted to SharedPreferences (defaults: **Light mode**, **English** locale)
- ARB-based l10n: English (`app_en.arb`, template) and Hindi (`app_hi.arb`), generated to `lib/l10n/gen/`

### Design system

The canonical design tokens, component specifications, and screen-by-screen
implementation targets are documented in [DESIGN.md](DESIGN.md). All UI work
should reference DESIGN.md as the source of truth for colors, typography,
spacing, border radii, component behavior, and per-screen layout specs.

### Key patterns

- Freezed + json_serializable for domain models (AuthState, BootstrapData, SettingsState, OnboardingState, ChatMessage, ConversationSummaryModel). Run `dart run build_runner build --delete-conflicting-outputs` after changes.
- DTO pattern: when backend JSON doesn't map cleanly to domain models, use a DTO class in the feature's `data/` layer (e.g., `PropertyListingDto` → `PropertyListing`).
- Shared component library: 18 `Flatmates*` widgets in `features/shared/presentation/` barrel-exported via `components.dart`. Key widgets: `FlatmatesScreen`, `FlatmatesAsyncView`, `FlatmatesNetworkImage`, `FlatmatesCard`, `FlatmatesChip`, `FlatmatesSkeleton`, `FlatmatesErrorState`, `FlatmatesEmptyState`. Components include premium polish: press scale feedback (`Listener` + `AnimatedScale`), focus glow (search bar), selection spring (chips), frosted-glass backdrop (bottom sheet/action bar/nav), animated entry (empty/error states), animated avatar ring, sliding indicator (segmented control), animated match ring (profile grid card), unread accent border (notification card). Skeleton variants: `.card()`, `.list()`, `.feed()`, `.profile()`.
- Animation patterns: use `AppMotion` tokens for all durations/curves. Press feedback via `Listener` + `AnimatedScale` (0.97). Staggered list animations via `StaggeredCardAppear` (discover feed) or `Future.delayed` pattern (profile menu groups). Frosted-glass via `BackdropFilter` + `AppSemanticColors.frostBlur`. Ring animations via `CustomPaint` inside `AnimatedBuilder`. Do not use `GestureDetector` to detect presses when wrapping interactive children — use `Listener` instead.
- Card theme: light mode elevation 1 (refined from 2). Dialog theme: 24px radius, elevation 4. Android page transitions: `FadeUpwardsPageTransitionsBuilder`. iOS: `CupertinoPageTransitionsBuilder`.
- `FlatmatesEndpoints` centralizes all API path constants — no hardcoded backend paths.
- Image uploads go to Supabase Storage via `ImageUploadService` (supports photos and video tours up to 50MB).
- Compatibility scoring runs client-side in `core/compatibility/` with 6 weighted dimensions.
- Chat uses `MessagesController` (FamilyNotifier with 5s polling + optimistic message sending), not raw FutureProvider.
- Banned patterns (enforced by `scripts/banned_patterns.sh`): no `error.toString()` in pages, no `apiClientProvider` in pages (use a repository), no `Supabase.instance` in pages, no raw `Image.network` in features (use `FlatmatesNetworkImage`), page files under 500 lines.

## iOS Simulator Browser Preview

[serve-sim](https://github.com/EvanBacon/serve-sim) streams the iOS Simulator's framebuffer to a browser at `http://localhost:3200`. Run `npx serve-sim` before `flutter run` so the agent can visually test the app without controlling the Simulator app directly. Supports 60fps stream, gestures, keyboard forwarding, and drag-and-drop media. Works with any booted simulator on macOS with Xcode.

## Cross-repo dependencies

- **`../backend`** — FastAPI monolith, source of truth for API contracts. If new fields/endpoints are needed, implement there first.
- **`../real-estate-admin-dashboard`** — admin dashboard for moderation workflows.
- Do not fork API contracts locally in the Flutter app.

## Rules from AGENTS.md

- Use real backend APIs only — no mock repositories, fake payloads, or hardcoded catalogs.
- Keep business metadata server-driven via `/api/v1/flatmates/catalogs`.
- `lib/core` is for technical plumbing only — don't leak feature logic there.
- Do not add another state-management library.
- Keep GoRouter as the routing layer.
- All authenticated requests must flow through the shared Dio client and auth interceptor.
- Maintain light/dark/system theme support and palette switching.
- Keep English and Hindi localization in sync for primary flows.
- Use meaningful `Key` values on interactive widgets for Maestro stability.
- Update `docs/` when API surface, architecture, theme/localization strategy, auth flow, or Maestro assumptions change.
