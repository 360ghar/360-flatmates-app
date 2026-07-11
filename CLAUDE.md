# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

360 FlatMates — a Flutter mobile client for flatmate-finding in India. Uses Supabase for auth and a FastAPI backend monolith at `../backend` for all business logic, product data, and storage (Cloudinary).

- **Flutter:** 3.41.9 (pinned via FVM in `.fvmrc`)
- **Dart SDK:** ^3.9.0
- **Riverpod:** `flutter_riverpod` ^2.6.1
- **App ID:** `com.the360ghar.flatmates`

## Commands

```bash
# Setup
cp .env.example .env          # then fill in SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, API_BASE_URL, GOOGLE_PLACES_API_KEY
flutter pub get

# VS Code format-on-save (auto-applies dart format on every save)
# Config lives in .vscode/settings.json — works for VS Code, Cursor, Windsurf, etc.
# IntelliJ/Android Studio: Settings → Tools → Actions on Save → Reformat code.
#   Shared code style at .idea/codeStyles/ — IntelliJ will auto-detect it.

# Run
flutter run

# iOS Simulator browser preview (run BEFORE flutter run, requires macOS + Xcode)
npx serve-sim                  # → http://localhost:3200 — stream simulator to browser for agent testing

# Code generation (run after changing freezed/json_serializable models)
dart run build_runner build --delete-conflicting-outputs

# Quality (run before every commit)
dart format .
flutter analyze
flutter test
bash scripts/banned_patterns.sh

# Auto-fix lint issues (prefer_const_constructors, avoid_redundant_argument_values, etc.)
dart fix --apply lib/

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
    app_shell.dart              → mode-dependent bottom nav (5 shell branches)
    router/app_router.dart      → GoRouter with auth/bootstrap redirects + deep links
  core/                         → app-wide plumbing only (no feature logic)
    providers.dart              → global Riverpod provider graph (app config, prefs, secure store, Dio, …)
    providers/                  → MutableNotifier / AutoDisposeMutableNotifier helpers
    config/                     → AppConfig, FlatmatesEndpoints, constants, env loader
    network/                    → Dio client, auth/error interceptors, connectivity, realtime/SSE
    location/                   → GooglePlacesService, Nominatim, location helpers
    map/                        → TileLayerFactory (OSM light / CARTO dark), map controller
    notifications/              → Firebase Messaging (foreground + background)
    storage/                    → SharedPreferences, secure storage, image upload
    theme/                      → Material 3 theme (Airbnb Rausch), design token constants
    compatibility/              → client-side matching algorithm (6 weighted dimensions)
    deep_links/                 → DeepLinkService (app_links, cold+warm start)
    domain/                     → PagedState<T>, OptimisticUpdate, typed enums
    errors/                     → AppFailure sealed class, ErrorPresenter, l10n bridge
    analytics/                  → AnalyticsEvents + AnalyticsProps constants
    utils/                      → ActionDebouncer, etc.
  features/                     → each feature owns its controller, repo, models, pages
    auth/                       → Supabase auth (phone/email + password, OTP, social) [data/domain/presentation]
    bootstrap/                  → loads /flatmates/bootstrap (profile + catalogs + counts)
    onboarding/                 → multi-step state machine with draft persistence
    discover/                   → listing feed + map + search filters
    swipe/                      → Tinder-like card deck with deal-breaker filtering
    chats/                      → conversations + messages (Supabase realtime + optimistic send)
    listings/                   → multi-step listing builder + manage
    visits/                     → schedule/confirm/reschedule visits (under /profile/visits)
    notifications/              → notification list + route resolver
    profile/                    → profile view/edit
    settings/                   → theme/locale + server-driven notification & privacy settings
    feedback/                   → bug/feature feedback form
    location_search/            → location search page
    shared/presentation/        → Flatmates* reusable widgets, barrel-exported via components.dart
```

### State management — Riverpod

**Controllers / app state**

- `NotifierProvider` / `AsyncNotifierProvider` for controllers with explicit state and named methods (`DiscoverFeedController`, `MessagesController`, `AuthController`, `BootstrapController`, `OnboardingController`, `SettingsController`, …)
- `FamilyNotifier` for parameterized controllers (`MessagesController` per conversation)
- `Provider` for repositories and services (injected via `ref.watch`)
- `FutureProvider` / `FutureProvider.family` for one-shot async data
- `StreamProvider` for streams (`connectivityProvider`)
- `PagedState<T>` for paginated data; `OptimisticUpdate.perform<T>()` for optimistic writes with rollback
- Three providers overridden at `ProviderScope` root: `appConfigProvider`, `appPreferencesProvider`, `secureStoreProvider`
- After write operations, **invalidate** the relevant provider rather than manually syncing widget state

**State tiers (required)**

| Kind | Prefer | Write API |
|------|--------|-----------|
| **Shared / product state** (filters, auth routing signals, map selection, cross-widget flags) | `Notifier` / `AsyncNotifier`, or `MutableNotifier` / `AutoDisposeMutableNotifier` in `core/providers/mutable_notifier.dart` | `ref.read(provider.notifier).set(value)` or `.update(fn)` |
| **Multi-field form / page UI** | One page-level `Notifier` with a single state object when practical | Named methods on the notifier |
| **True ephemeral UI** (password visibility, carousel index, OTP text, one-shot spinner, emoji picker open) | **`setState` on `State` / `ConsumerState`** when the value never leaves the widget | `setState(() => …)` — guard with `if (!mounted) return` after `await` |

**`StateProvider`**

- Still available on Riverpod 2 for remaining/legacy call sites.
- **Do not add new shared/product `StateProvider`s** — use `MutableNotifier` (or a full `Notifier`).
- On a future Riverpod 3 upgrade, `StateProvider` moves to `package:flutter_riverpod/legacy.dart` (discouraged, not removed). Migrating shared providers now avoids that tax.
- Some multi-field form pages still use page-local `StateProvider`s; convert on touch toward `setState` (ephemeral) or a single form `Notifier` (complex forms).

**Examples of shared state on `MutableNotifier`**

- `pendingPhoneProvider`, `addPhonePromptProvider` (`auth_controller.dart`)
- `flatmatesOnboardingCompletedOverrideProvider` (`onboarding_controller.dart`)
- `discoverFiltersProvider`, `selectedPropertyProvider` (`discover_repository.dart`)
- `mapProgrammaticScrollProvider` (map bottom sheet)

```dart
// Shared simple value
final flagProvider =
    NotifierProvider<MutableNotifier<bool>, bool>(() => MutableNotifier(false));
ref.watch(flagProvider);
ref.read(flagProvider.notifier).set(true);

// Route-scoped autoDispose
final selectedProvider = NotifierProvider.autoDispose<
  AutoDisposeMutableNotifier<MyType?>,
  MyType?
>(() => AutoDisposeMutableNotifier(null));
```

**Read / write rules**

- **Read** state with `ref.watch()` in `build()`; **write** with `ref.read(provider.notifier)` methods in callbacks.
- Never use `ref.read()` to read state in `build()`.
- Never mutate providers while the widget tree is building (including in `initState` for first-frame setup — use `addPostFrameCallback` / `Future.microtask` if a write is required). AutoDispose providers that rebuild to their initial value on remount often need no reset write.
- When converting ephemeral flags to `setState`, callbacks invoked from async helpers (e.g. upload `finally`) must check `mounted` before `setState`.

### Routing — GoRouter

- `StatefulShellRoute.indexedStack` with **5 branches**: `/discover` (nested browse), `/tab2` (mode-dependent Explore/Map or Post hub), `/swipe`, `/chats` (nested thread), `/profile` (nested edit/settings/visits)
- Bottom nav has 5 shape-stable slots; slot 2 swaps by mode: Room Poster sees Home|Post|Swipe|Likes&Chat|Profile; Co-Hunter/Open to Both sees Home|Explore|Swipe|Likes&Chat|Profile
- Full-screen routes (`parentNavigatorKey`): `/post/new`, `/manage-listings`, `/listing-review/:id`, `/search-filters`, `/schedule-visit`, `/change-password`, `/blocked-users`, `/flat-details`, `/complete-profile`, `/location-search`, `/change-location`, …
- Soft onboarding / profile-completion gate: core feature routes can redirect to `/complete-profile` when mandatory fields are missing; not a hard block on every path
- Auth redirect chain: checking → `/splash`, unauthenticated → `/enter-phone`, onboarding incomplete → `/onboarding`
- Router refreshes on `authControllerProvider`, `bootstrapControllerProvider`, and auth routing signals (`addPhonePromptProvider`, onboarding override)
- Deep links: `/flatmates/listing/{id}` → flat details, `/flatmates/chat/{id}` → chat thread (`app_links`). Remap legacy/push paths via `notification_route_resolver.dart` (`/post` → `/post/new`, `/visits` → `/profile/visits`)

### Error handling

- `AppFailure` sealed class hierarchy in `core/errors/`: `NetworkFailure`, `AuthExpiredFailure`, `ServerFailure`, `PermissionFailure`, `NotFoundFailure`, `ValidationFailure`, `RateLimitFailure`, `ConflictFailure`, `UploadFailure`, `UnknownFailure`
- `ErrorPresenter.fromDio()` maps `DioException` → typed `AppFailure` subclass (including field-level 422 parsing)
- `UserMessageL10n` bridge decouples `AppFailure.userMessage()` from generated l10n
- `FlatmatesAsyncView` renders `AsyncValue<T>` into loading/data/empty/error states using `AppFailure.userMessage()`
- **Banned in pages:** `error.toString()` (enforced by `scripts/banned_patterns.sh`)
- **No empty catch blocks.** Every `catch` must at minimum log via `debugPrint('ClassName.methodName: $e')`. In fire-and-forget contexts, use `unawaited()`.

### Networking

- Shared `Dio` client from `core/network/api_client.dart` — all authenticated requests go through this
- `AuthInterceptor` attaches Bearer token; handles 401 with request queue to prevent token-refresh race conditions
- `ErrorInterceptor` maps DioException types to user-friendly messages
- `FlatmatesEndpoints` (`core/config/endpoints.dart`) centralizes all API path constants
- Backend paths are relative to `AppConfig.apiBaseUrl` (set via `.env` or `--dart-define`)

### Map and location

- `TileLayerFactory` — light OSM / dark CARTO basemaps; bump `styleVersion` when tile URLs change
- `GooglePlacesService` — autocomplete + place details; gate UI on `GooglePlacesService.isConfigured` (`GOOGLE_PLACES_API_KEY`)

### Deep linking

- `DeepLinkService` (`core/deep_links/deep_link_service.dart`) parses incoming HTTP deep links via `app_links`
- Supported paths: `/flatmates/listing/{id}` → flat details, `/flatmates/chat/{id}` → chat thread
- Handles cold start (initial link) and warm start (stream listener)

### Connectivity / Offline

- `connectivityProvider` (`StreamProvider<bool>` via `connectivity_plus`) monitors network state
- `OfflineBanner` shown as a Stack overlay above `MaterialApp.router` when offline

### Auth flow

1. Identifier input (phone or email) → password login or OTP via Supabase
2. After auth, `GET /users/me` validates user exists in backend
3. `BootstrapController` fetches `/flatmates/bootstrap` for profile + catalogs
4. If `onboardingCompleted == false`, router redirects to onboarding; missing mandatory profile fields → `/complete-profile`
5. Missing env vars show `_ConfigErrorApp`; missing Firebase config sets `NotificationService.messagingEnabled = false`
6. Account deletion: `DeleteAccountPage` → `AuthController.deleteAccount()` → `DELETE /users/me`, then best-effort Supabase sign-out + token clear → `/enter-phone`
7. Phone held between auth steps via `pendingPhoneProvider` (`MutableNotifier`); post-social “add phone” prompt via `addPhonePromptProvider`

### Theme and localization

- Material 3 with single Airbnb Rausch primary (`#FF385C`), white canvas, ink `#222222`
- Google Fonts: Inter (open-source substitute for Airbnb Cereal VF)
- Design token constant files in `core/theme/`: `AppSpacing`, `AppRadius`, `AppShadows`, `AppMotion`, `AppTypography`, `AppSemanticColors` — barrel-exported via `theme.dart`
- Light/dark/system theme modes, persisted to SharedPreferences (defaults: **Light mode**, **English** locale)
- ARB-based l10n: English (`app_en.arb`, template) and Hindi (`app_hi.arb`), generated to `lib/l10n/gen/`

### Design system

The canonical design tokens, component specifications, and screen-by-screen
implementation targets are documented in [DESIGN.md](DESIGN.md). All UI work
should reference DESIGN.md as the source of truth for colors, typography,
spacing, border radii, component behavior, and per-screen layout specs.

### Key patterns

- Freezed + json_serializable for domain models. Run `dart run build_runner build --delete-conflicting-outputs` after changes.
- DTO pattern: when backend JSON doesn't map cleanly to domain models, use a DTO class in the feature's `data/` layer (e.g., `PropertyListingDto` → `PropertyListing`).
- Shared component library: `Flatmates*` widgets in `features/shared/presentation/` barrel-exported via `components.dart`. Key widgets: `FlatmatesScreen`, `FlatmatesAsyncView`, `FlatmatesNetworkImage`, `FlatmatesCard`, `FlatmatesChip`, `FlatmatesSkeleton`, `FlatmatesErrorState`, `FlatmatesEmptyState`, `FlatmatesChromeIconButton`, `FlatmatesLocationChip`. Shell chrome uses solid surfaces + hairline borders (no `BackdropFilter` frost).
- Animation patterns: use `AppMotion` tokens for all durations/curves. Press feedback via `Listener` + `AnimatedScale` (0.97). Do not use `GestureDetector` to detect presses when wrapping interactive children — use `Listener` instead.
- `FlatmatesEndpoints` centralizes all API path constants — no hardcoded backend paths.
- Image uploads go through the backend API (Cloudinary) via `ImageUploadService`.
- Compatibility scoring runs client-side in `core/compatibility/` with 6 weighted dimensions.
- Chat uses Supabase realtime for the open thread; app-wide events use Realtime Broadcast on `flatmates:user:{id}`. `MessagesController` merges live arrivals with optimistic pending sends and refetches after successful POST.
- Banned patterns (`scripts/banned_patterns.sh`): no `error.toString()` in pages, no `apiClientProvider` in pages, no `Supabase.instance` in pages, no raw `Image.network` in features, page files under 500 lines.
- **Business logic in controllers, not widgets.** Examples: `FeedbackController`, `ChatActionsController`, `SwipeDeckController`, `ManageListingsActionsController`, `NotificationsActionsController`.
- **Local UI state:** ephemeral → `setState` (with `mounted` checks after async); shared/product → `Notifier` / `MutableNotifier`. Do not reintroduce shared `StateProvider`s.
- **Always use `const` constructors** where possible. Run `dart fix --apply lib/` periodically.
- **Add `tooltip` to all `IconButton` widgets** for accessibility.
- **No empty catch blocks.** Every `catch` must log via `debugPrint`. Use `unawaited()` for fire-and-forget futures.
- **Check `mounted` before using `context` or `setState` after `await`.**

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
- Maintain light/dark/system theme support with a single Rausch brand primary.
- Keep English and Hindi localization in sync for primary flows.
- Use meaningful `Key` values on interactive widgets for Maestro stability.
- Update `docs/` when API surface, architecture, theme/localization strategy, auth flow, or Maestro assumptions change.
- **Ephemeral UI → `setState`; shared state → `Notifier` / `MutableNotifier`.** Avoid new shared `StateProvider`s. Write shared simple values with `.set` / `.update`, not `.notifier.state =`.
- **Controllers over direct repository calls** in widgets. Create `application/` layer controllers.
- **`debugPrint` over empty catch blocks.** Never use `catch (_) {}` without logging.
- **`const` constructors everywhere.** Run `dart fix --apply lib/` to auto-fix.
- **`tooltip` on every `IconButton`** for accessibility.
- **Never mutate providers during build / `initState` first frame** without deferral; prefer autoDispose initial values over reset writes.
- **`mounted` before `setState` / `context` after `await`.**
