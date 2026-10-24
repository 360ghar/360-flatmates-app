# AGENTS.md

## Repo Purpose

This repository contains the dedicated Flutter mobile client for 360 FlatMates. It is not a general-purpose 360 Ghar client and it must stay aligned to the backend monolith and the flatmates-specific app surface.

## Project Overview

Repo facts: 360 FlatMates is a Flutter mobile client for flatmate-finding in India. It uses Supabase for auth and a FastAPI backend monolith at `../backend` for all business logic, product data, and storage (Cloudinary).

- **Flutter:** 3.44.6 (pinned via FVM in `.fvmrc`; must be a Shorebird-supported
  version and must match the `--flutter-version` in both release workflows and
  `scripts/shorebird_release.sh` — see [docs/shorebird.md](docs/shorebird.md))
- **Dart SDK:** ^3.9.0
- **Riverpod:** `flutter_riverpod` ^2.6.1
- **App ID:** `com.the360ghar.flatmates360`
- **OTA:** Shorebird code push for Dart-only fixes ([docs/shorebird.md](docs/shorebird.md))

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
# Use the pinned Flutter (.fvmrc, 3.44.6): `fvm dart run ...` or put
# ~/fvm/versions/3.44.6/bin first in PATH. The global Flutter 3.47 fails with
# "Missing implementation of visitDotShorthandPropertyAccess" (docs/api_contract.md).
dart run build_runner build --delete-conflicting-outputs

# Backend contract: enums and fixtures (see docs/api_contract.md)
# contract_sync.sh runs both generators (tool/gen_enums.py, tool/api_fixtures.py)
# and fails if the committed files were stale. Run it alone: running the
# generators first would regenerate the stale files before it compares them.
# It imports the backend schemas only (no app start-up, no database).
bash scripts/contract_sync.sh
flutter test test/contract

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

# Shorebird OTA (code push) — see docs/shorebird.md for the full runbook.
# Anything that ships MUST be built by Shorebird: a plain `flutter build`
# artifact has no Shorebird engine and can never be patched.
. ./scripts/load_env.sh && ./scripts/verify_env.sh
./scripts/shorebird_release.sh android --dry-run    # validate, upload nothing
./scripts/shorebird_release.sh android|ios          # cut a patchable release
./scripts/shorebird_patch.sh android 1.0.9+18       # OTA patch -> staging track
shorebird preview --platform=android --track=staging
# Both scripts source scripts/shorebird_env_stub.sh, which swaps your real .env
# for the one-line CI stub during the build and restores it afterwards.
```

## Core Rules

- Use real backend APIs only. Do not introduce mock repositories, fake payloads, or hardcoded business catalogs.
- Keep the app mobile-first and maintain parity between iOS and Android.
- Treat `../backend` as the source of truth for product data contracts.
- Keep business metadata server-driven through `/api/v1/flatmates/catalogs` whenever the data affects product behavior.
- **Store artifacts must be built by Shorebird, never plain `flutter build`.** A `flutter build` artifact has no Shorebird engine and can never receive an OTA patch. Use `scripts/shorebird_release.sh` or the `v*` tag workflows. The Flutter version in `.fvmrc` must stay Shorebird-supported and identical to the `--flutter-version` in both release workflows and `scripts/shorebird_release.sh`. See [docs/shorebird.md](docs/shorebird.md).
- **Do not add assets or native code in a patch-only fix.** Assets, native code, plugin natives and the Flutter version cannot be shipped over the air; they require a full release.
- **Keep the `--dart-define` set identical between a release and its patches, per platform.** `APP_STORE_ID` is iOS-only (Android carries 7 defines, iOS 8). Change `android-release.yml`, `ios-release.yml`, `shorebird-patch.yml` and `scripts/shorebird_{release,patch}.sh` together, or the patched app boots into `_ConfigErrorApp`.
- **`.env` is a bundled Flutter asset, so its bytes are diffed by Shorebird.** Release and patch builds must both use the identical one-line `APP_ENV=prod` stub — CI writes it inline, local scripts via `scripts/shorebird_env_stub.sh`. Never let a real `.env` reach a shipped build; config goes in through `--dart-define`.

## Architecture Boundaries

- `lib/core` is for app-wide technical plumbing only.
- `lib/features` owns product behavior and presentation.
- Avoid leaking feature logic into `core`.
- Do not add another state-management library.
- Keep GoRouter as the routing layer.
- `scripts/banned_patterns.sh` enforces architecture guardrails: ratchets on raw `BorderRadius.circular(<n>)` and `Color(0x…)` outside `core/theme` (count may only go down; raw colours are at 0), no light-only `AppSemanticColors.accent/error/success/warning/info/primary/onPrimary` in `lib/features` or `lib/app` (use `*For(brightness)`), no `error.toString()` in pages, no `apiClientProvider` in pages (use a repository), no `Supabase.instance` in pages, no raw `Image.network` in features, page files under 500 lines.
- **When a page hits the 500-line cap, extract rather than trim.** Move a cohesive, low-coupling chunk into the feature's `presentation/widgets/` — pure helpers and data classes belong there just as much as widgets do (`listing_catalog_options.dart`, `edit_profile_form_state.dart`). Move the code **verbatim**; do not rewrite it in the same pass, so the diff stays reviewable. Only files named `*_page.dart` are subject to the cap, but the `EdgeInsets.all(<int>)` and `Image.network` bans apply to every file under `lib/features/`. There is no per-feature barrel: import extracted files directly. If the same helper exists in two features, promote it to `lib/features/shared/presentation/` (see `lifestyle_labels.dart`) instead of copying it. A page file fails the check at `-gt 500`; exactly 500 passes. `components.dart` is shared-only and does not export `profile_sections.dart`. Another worked example: `buildEditProfileTabHandlers` in `edit_profile_form_state.dart`.
- **Never declare Xcode script-phase `inputPaths`/`outputPaths` that resolve inside the target's own product directory** — `${DWARF_DSYM_FOLDER_PATH}`, `${BUILT_PRODUCTS_DIR}`, `${TARGET_BUILD_DIR}/${WRAPPER_NAME}`. It creates `Cycle inside Runner`, which breaks every iOS build including archives and `shorebird release ios`. Use `alwaysOutOfDate = 1` and let the script resolve paths at runtime. Preserve the order of the two custom dSYM phases in the Runner target.
- **Business logic goes in controllers, not widgets.** Widgets call `ref.read(controllerProvider.notifier).method()` instead of calling repositories directly. Repository calls in widget files are banned — use `application/` layer controllers. Examples: `FeedbackController`, `ChatActionsController`, `SwipeDeckController`, `ManageListingsActionsController`, `NotificationsActionsController`, `EditProfileActionsController`, `VisitsActionsController`, `BlockedUsersListController.unblock`, `AuthController.changePassword`.

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
    theme/                      → Material 3 Paper Diorama theme, tokens, PaperTheme extension
    compatibility/              → client-side matching algorithm (6 weighted dimensions)
    deep_links/                 → DeepLinkService (app_links, cold+warm start)
    domain/                     → typed enums
    errors/                     → AppFailure sealed class, ErrorPresenter, l10n bridge
    analytics/                  → AnalyticsEvents + AnalyticsProps constants
    utils/                      → ActionDebouncer, etc.
  features/                     → each feature owns its controller, repo, models, pages
    auth/                       → Supabase auth (phone/email + password, OTP, social) [data/domain/presentation]
    bootstrap/                  → loads /flatmates/bootstrap (profile + catalogs + counts)
    onboarding/                 → multi-step state machine with draft persistence
    discover/                   → listing feed + map + search filters
    swipe/                      → Tinder-like card deck with deal-breaker filtering
    chats/                      → conversations + messages (REST pages, Broadcast refetch, optimistic send)
    listings/                   → multi-step listing builder + manage
    visits/                     → schedule/confirm/reschedule visits (under /profile/visits)
    notifications/              → notification list + route resolver
    profile/                    → profile view/edit
    settings/                   → theme/locale + server-driven notification & privacy settings
    feedback/                   → bug/feature feedback form
    location_search/            → location search page
    shared/presentation/        → Flatmates* reusable widgets, barrel-exported via components.dart
```

### Routing — GoRouter

- `StatefulShellRoute.indexedStack` with **5 branches**: `/discover` (nested browse), `/tab2` (mode-dependent Explore/Map or Post hub), `/swipe`, `/chats` (nested thread), `/profile` (nested edit/settings/visits)
- Bottom nav has 5 shape-stable slots; slot 2 swaps by mode: Room Poster sees Home|Post|Swipe|Likes&Chat|Profile; Co-Hunter/Open to Both sees Home|Explore|Swipe|Likes&Chat|Profile
- Full-screen routes (`parentNavigatorKey`): `/post/new`, `/manage-listings`, `/listing-review/:id`, `/search-filters`, `/schedule-visit`, `/change-password`, `/blocked-users`, `/flat-details`, `/complete-profile`, `/location-search`, `/change-location`, …
- Soft onboarding / profile-completion gate: core feature routes can redirect to `/complete-profile` when mandatory fields are missing; not a hard block on every path
- Auth redirect chain: checking → `/splash`, unauthenticated → `/enter-phone`, onboarding incomplete → `/onboarding`
- Router refreshes on `authControllerProvider`, `bootstrapControllerProvider`, and auth routing signals (`addPhonePromptProvider`, onboarding override)
- Deep links: `/flatmates/listing/{id}` → flat details, `/flatmates/chat/{id}` → chat thread (`app_links`). Remap legacy/push paths via `notification_route_resolver.dart` (`/post` → `/post/new`, `/visits` → `/profile/visits`)

### Map and location

- `TileLayerFactory` — light OSM / dark CARTO basemaps; bump `styleVersion` when tile URLs change
- `GooglePlacesService` — autocomplete + place details; gate UI on `GooglePlacesService.isConfigured` (`GOOGLE_PLACES_API_KEY`)

### Deep linking

- `DeepLinkService` (`core/deep_links/deep_link_service.dart`) parses incoming HTTP deep links via `app_links`
- Supported paths: `/flatmates/listing/{id}` → flat details, `/flatmates/chat/{id}` → chat thread
- Handles cold start (initial link) and warm start (stream listener)

### Connectivity / Offline

- `connectivityProvider` (`StreamProvider<bool>` via `connectivity_plus`) monitors network state
- `OfflineBanner` wraps the app in `MaterialApp.builder` and shows an in-flow strip that pushes content down (not an overlay)
- Coming back online invalidates the conversation, likes, notification and visit lists (`_refetchAfterReconnect` in `app.dart`)

### Updates: store releases vs OTA patches

Two independent mechanisms, both surfaced from `lib/core/app_config/`:

- **Server-driven store updates** — `AppConfigService.checkForUpdates()` posts to
  `/versions/check` and drives `ForceUpdatePage` / `OptionalUpdateDialog`. Tells
  the user to download a new build.
- **Shorebird OTA patches** — Dart-only fixes shipped without store review.
  Downloads are handled entirely by Shorebird (`auto_update: true`);
  `PatchService` is **read-only** and never downloads or applies anything. It
  feeds the Crashlytics `shorebird_patch_number` key (set in
  `AnalyticsService.create()` before `runApp`, so first-frame crashes stay
  attributable), the Settings → About version line, and a one-off
  restart-required SnackBar. Everything no-ops when
  `ShorebirdUpdater.isAvailable` is false (debug, `flutter run`, non-Shorebird
  builds).

Assets, native code, plugin natives and the Flutter version **cannot** be
patched — those need a `v*` tag release. Full runbook and gotchas:
[docs/shorebird.md](docs/shorebird.md).

Two invariants that silently break patching if violated:

- **dart-define parity.** A patch must be built with the *same* define set as the
  release it targets, per platform. `APP_STORE_ID` is **iOS-only** (it drives the
  force-update deep link); Android carries 7 defines, iOS 8. The four places that
  must agree are `android-release.yml`, `ios-release.yml`, `shorebird-patch.yml`,
  and `scripts/shorebird_{release,patch}.sh`. A mismatch ships a broken config —
  `AppConfig` throws on an empty `API_BASE_URL` and the app boots into
  `_ConfigErrorApp`.
- **`.env` is a bundled asset**, so its bytes are part of what Shorebird diffs.
  Release and patch builds both write the identical one-line `APP_ENV=prod` stub
  (CI inline, locally via `scripts/shorebird_env_stub.sh`). This also stops a real
  `.env` with secrets being shipped inside the app.

### Auth flow

1. Identifier input (phone or email) → password login or OTP via Supabase
2. After auth, `GET /users/me` validates user exists in backend
3. `BootstrapController` fetches `/flatmates/bootstrap` for profile + catalogs
4. If `onboardingCompleted == false`, router redirects to onboarding; missing mandatory profile fields → `/complete-profile`
5. Missing env vars show `_ConfigErrorApp`; missing Firebase config sets `NotificationService.messagingEnabled = false`
6. Account deletion: `DeleteAccountPage` → `AuthController.deleteAccount()` → `DELETE /users/me`, then best-effort Supabase sign-out + token clear → `/enter-phone`
7. Phone held between auth steps via `pendingPhoneProvider` (`MutableNotifier`); post-social “add phone” prompt via `addPhonePromptProvider`
8. The Supabase session (access + refresh token) is stored in the keychain / keystore by `SecureSessionStorage` (`core/storage/secure_session_storage.dart`), passed to `Supabase.initialize`. It migrates an existing SharedPreferences session on first run, and falls back to SharedPreferences whenever the keychain is unusable — at initialization, when a migration's keychain write fails, or when a later session write fails. A `…-store` marker records which store is authoritative: `secure` means the keychain copy is read and any plaintext duplicate is dropped unread; `prefs` means the plaintext copy is authoritative and is re-migrated once the keychain works again. A secure read failure while the marker says `secure` is treated as "no session", and "not persisted" is logged only when both stores refuse the write. Storage writes are serialized. Sign-out writes a persistent invalidation marker before deleting both credential copies; the marker is the single source of truth (delete wins), and session reads and migration honor it until a new session is persisted successfully.
9. `AuthController` also listens to Supabase `signedOut` events, so a server-side sign-out routes to login without waiting for a failed request.

### Key patterns

- Shared component library: `Flatmates*` widgets in `features/shared/presentation/` barrel-exported via `components.dart`. Key widgets: `FlatmatesScreen`, `FlatmatesAsyncView`, `FlatmatesNetworkImage`, `FlatmatesCard`, `FlatmatesChip`, `FlatmatesSkeleton`, `FlatmatesErrorState`, `FlatmatesEmptyState`, `FlatmatesChromeIconButton`, `FlatmatesLocationChip`. Shell chrome uses solid surfaces + hairline borders (no `BackdropFilter` frost). Two shared files in the same folder are deliberately **not** in the barrel and are imported directly: `profile_sections.dart` (`LifestyleCell`, `LifestyleGrid`, `PreferencesCard`, `SectionHeader`) and `lifestyle_labels.dart` (localized lifestyle dimension names, values and icons — the single source shared by the chat peer profile and the discover owner sheet).
- Image uploads go through the backend API (Cloudinary) via `ImageUploadService`.
- Compatibility scoring runs client-side in `core/compatibility/` with 6 weighted dimensions.
- Chat reads `GET /flatmates/conversations/{id}/messages` (CursorPage, `cursor` for older pages). There is no table stream on `public.messages`: the open thread refetches when Realtime Broadcast on `flatmates:user:{id}` delivers `new_message` or `conversation_updated`. `MessagesController` merges refetched rows with optimistic pending sends and refetches after a successful POST.
- **Check `mounted` before using `context` or `setState` after `await`.**

## Code Generation

- Freezed and json_serializable are used for domain models. After modifying freezed-annotated models, run `dart run build_runner build --delete-conflicting-outputs`.
- Generated files (`.freezed.dart`, `.g.dart`) are committed to the repo.

## Riverpod Guidance

- Prefer Riverpod providers over singleton services.
- For complex state with named methods, prefer `Notifier`/`AsyncNotifier`/`FamilyNotifier` subclasses over raw `FutureProvider`.
- Use `PagedState<T>` for paginated data and `OptimisticUpdate.perform<T>()` for optimistic writes with rollback.
- Invalidate feature providers after write operations instead of manually syncing widget trees.
- Avoid global mutable state outside provider-controlled objects.
- **Use `ref.watch()` in `build()` to read state; `ref.read()` in callbacks to write.** Never use `ref.read()` to read state inside `build()` — it creates non-reactive snapshots. Never mutate state inside `build()` — move mutations to event handlers.

**Controllers / app state**

- `NotifierProvider` / `AsyncNotifierProvider` for controllers with explicit state and named methods (`DiscoverFeedController`, `MessagesController`, `AuthController`, `BootstrapController`, `OnboardingController`, `SettingsController`, …)
- `FamilyNotifier` for parameterized controllers (`MessagesController` per conversation)
- `Provider` for repositories and services (injected via `ref.watch`)
- `FutureProvider` / `FutureProvider.family` for one-shot async data
- `StreamProvider` for streams (`connectivityProvider`)
- Three providers overridden at `ProviderScope` root: `appConfigProvider`, `appPreferencesProvider`, `secureStoreProvider`

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

- Write shared simple values with `.set` / `.update`, not `.notifier.state =`.
- Never mutate providers while the widget tree is building (including in `initState` for first-frame setup — use `addPostFrameCallback` / `Future.microtask` if a write is required). AutoDispose providers that rebuild to their initial value on remount often need no reset write.
- When converting ephemeral flags to `setState`, callbacks invoked from async helpers (e.g. upload `finally`) must check `mounted` before `setState`.

- Prefer `AsyncValue.value` / `valueOrNull` as supported by the current Riverpod version.

## Error Handling

- Use `AppFailure` (sealed class hierarchy in `core/errors/`) and `FlatmatesAsyncView` for error display in pages.
- Never use `error.toString()` in presentation code (banned in pages) — enforced by `scripts/banned_patterns.sh`.
- `AppFailure` sealed class hierarchy in `core/errors/`: `NetworkFailure`, `AuthExpiredFailure`, `ServerFailure`, `PermissionFailure`, `NotFoundFailure`, `ValidationFailure`, `RateLimitFailure`, `ConflictFailure`, `UploadFailure`, `UnknownFailure`
- `ErrorPresenter.fromDio()` maps `DioException` → typed `AppFailure` subclass (including field-level 422 parsing)
- `UserMessageL10n` bridge decouples `AppFailure.userMessage()` from generated l10n
- `FlatmatesAsyncView` renders `AsyncValue<T>` into loading/data/empty/error states using `AppFailure.userMessage()`. A failed refresh keeps the loaded data on screen (`skipError`); the error view is only for a load that never produced data
- **Never use empty catch blocks.** Every `catch` must at minimum log via `debugPrint('ClassName.methodName: $e')`. Empty `catch (_) {}` silently swallows errors and makes debugging impossible. Exceptions:
  - `catch (_) { return null; }` is acceptable for fire-and-forget lookups with no side effects.
  - `catch (_) { /* comment */ }` must include `debugPrint` alongside the comment.
- In analytics/crashlytics fire-and-forget contexts, wrap with `unawaited()` instead of empty catches.

## Networking Guidance

- All authenticated requests must flow through the shared auth interceptor.
- Do not bypass the shared client for ad hoc HTTP calls.
- Shared `Dio` client from `core/network/api_client.dart` — all authenticated requests go through this
- `AuthInterceptor` attaches Bearer token; handles 401 with request queue to prevent token-refresh race conditions
- `ApiClient` maps every `DioException` to a typed `AppFailure` via `ErrorPresenter.fromDio` (there is no separate error interceptor). 5xx and upload failures always show localized copy, never backend text.
- On a server 401 the interceptor passes the rejected token to `getAccessToken(rejectedToken:)`, which forces a refresh; queued requests retry individually.
- Backend paths are relative to `AppConfig.apiBaseUrl` (set via `.env` or `--dart-define`)
- Use `FlatmatesEndpoints` from `core/config/endpoints.dart` for API paths. Do not hardcode or duplicate backend paths.

## UI Guidance

- Maintain support for light, dark, and system theme modes (default: Light).
- Use the single clay brand primary from DESIGN.md (Paper Diorama). Do not reintroduce multi-palette switching.
- Keep English and Hindi localization coverage in sync for all primary user flows (default: English).
- Use meaningful string keys (`Key('login_submit_button')`) on major interactive widgets. Maestro's `id:` reads only `Semantics.identifier`, never Flutter keys: only the `Flatmates*` components that call `withTestId` expose their string key as the identifier — `FlatmatesButton`, `FlatmatesMenuItem`, `FlatmatesCard`, `FlatmatesChip`, `FlatmatesChromeIconButton`, `FlatmatesSegmentedControl` segments and the `FlatmatesBottomActionBar` toggle. Every other widget, including shared components that only accept a `Key` such as `FlatmatesLocationChip` and `FlatmatesLikeButton`, needs `withTestId(key, child)` (`lib/features/shared/presentation/test_id.dart`).
- All visual tokens (colors, radii, spacing, typography, shadows, components) must match [DESIGN.md](DESIGN.md). Do not introduce values that contradict the design system.
- Use design token constant files from `core/theme/` (AppSpacing, AppRadius, AppShadows, AppMotion, AppTypography, AppSemanticColors) barrel-exported via `theme.dart`. Do not use magic numbers.
- Use `Flatmates*` shared components from `features/shared/presentation/` instead of duplicating Scaffold/SafeArea/ListView/async-state patterns.
- Use `FlatmatesNetworkImage` instead of raw `Image.network` — enforced by `scripts/banned_patterns.sh`.
- Use `AppMotion` for all animation durations and curves. Do not hard-code durations or `Curves`. Use `Listener` (not `GestureDetector`) for press-detection when wrapping interactive children (InkWell, FilledButton, OutlinedButton) to avoid gesture arena conflicts. Press feedback uses `Listener` + `AnimatedScale` (`AppMotion.pressScale`, 0.98) with shadow e2 → e1.
- Shell chrome (bottom nav, bottom sheets, bottom action bars) uses solid canvas/surface colors with hairline borders — no frosted-glass `BackdropFilter`, no multi-palette switching.
- **Always use `const` constructors** for widgets that don't change (SizedBox, Padding, Icon, Text, etc.). This enables widget reuse and reduces GC pressure.
- **Add `tooltip` to every `IconButton`** for accessibility (screen readers). Common tooltips: `'Toggle password visibility'`, `'Back'`, `'Call'`, `'More options'`, `'Search'`, `'Like'`.
- **Avoid heavy computations in `build()`.** Extract `List.generate()`, `.map().toList()`, and `for` loops to private methods or pre-compute in providers. `build()` runs 60fps during animations — every allocation matters.
- **Use `AppLocalizations.of(context)` for all user-facing strings.** Hardcoded English strings block localization to Hindi and other target languages. Add new keys to `lib/l10n/arb/app_en.arb` and `app_hi.arb` when introducing new strings.

### Theme and localization

- Paper Diorama design system (see DESIGN.md, identical in the web repo): clay primary `#A94A2B`, pine secondary, marigold accent, sky / paper-1..3 layers, directional paper shadows (`AppShadows.e1..e3`)
- Display type: Gambarino, bundled at `assets/fonts/` and registered under weights 400–800 in `pubspec.yaml` so a bold display style never fakes a bold. Body: platform font. No `google_fonts`.
- Paper primitives in `features/shared/presentation/paper/`: `PaperSurface`, `PaperEdgeBorder` (torn/scallop), `PaperScene` (layered neighbourhood; pass the page's `ScrollController` as `parallax`, as `enter_phone_page` and the onboarding pages do; off under reduce motion), `PaperSceneHeader`, `PaperIcon` (cut-paper icons, used for the five nav tabs). Scene art `paper_art.dart` is generated by `360-flatmates-web/scripts/generate-paper-art.py`; never edit it by hand.
- Motion: content is visible from the first frame (entrances rise, never fade from 0); new animations must check `AppMotion.reduceMotion`. Text scale is capped at 2x in `MaterialApp.builder`.
- Contrast: `test/core/theme/contrast_test.dart` asserts WCAG AA for every text/paper pair and for the status pill pairs (clay-ink / clay-soft, green-ink / pine-soft, danger / danger-soft, warning-ink / warning-soft). Goldens (macOS only) in `test/widget/shared/goldens/`.
- Large text: rows that put a name beside a time, badge or button stack at text scale 1.5 and above (conversation card, notification card, profile header, blocked user row); `FlatmatesSegmentedControl` wraps into rows when its widest label does not fit. Check new rows at 320 dp and 2x.
- Light/dark/system theme modes, persisted to SharedPreferences (defaults: **Light mode**, **English** locale)
- ARB-based l10n: English (`app_en.arb`, template) and Hindi (`app_hi.arb`), generated to `lib/l10n/gen/`

### Design system

The canonical design tokens, component specifications, and screen-by-screen implementation targets are documented in [DESIGN.md](DESIGN.md). All UI work should reference DESIGN.md as the source of truth for colors, typography, spacing, border radii, component behavior, and per-screen layout specs.

## DTO Pattern

- When backend JSON doesn't map cleanly to domain models, use a DTO class in the feature's `data/` layer to construct the domain model (e.g., `PropertyListingDto` → `PropertyListing`).
- Keep backend-specific parsing details in DTOs; keep domain models clean.

## Testing Guidance

- Keep `flutter analyze` clean.
- Keep at least one fast local Flutter test in the repo.
- Maintain a single end-to-end Maestro flow that exercises the real product loop.
- Update Maestro when route names, button labels, or login flow behavior changes.
- **Before committing, run `dart format .`** to ensure all files are properly formatted. The CI Quality Gates workflow will fail if any file is unformatted.
- **VS Code + forks:** `.vscode/settings.json` enables format-on-save for Dart files automatically.
- **Android Studio / IntelliJ:** Enable format-on-save manually at _Settings → Tools → Actions on Save → Reformat code_. A shared Dart code style (matching `dart format`) is provided at `.idea/codeStyles/`.
- After making changes, run `dart fix --dry-run lib/` to catch auto-fixable lint issues, then `dart fix --apply lib/` to apply them.

## Documentation Triggers

Update the docs in `docs/` when any of the following change:

- Backend API surface consumed by the app
- Repo architecture or folder layout
- Theme and localization strategy
- Auth bootstrap flow
- Maestro prerequisites or seeded-data assumptions
- Linting rules in `analysis_options.yaml`

## Analysis Options

The project uses `package:flutter_lints/flutter.yaml` with 23 additional strict rules in `analysis_options.yaml`. Key enabled rules:
- `use_build_context_synchronously` — catches `context` usage after `await` without `mounted` check
- `prefer_const_constructors` / `prefer_const_literals_to_create_immutables` — enforces widget reuse
- `unawaited_futures` — catches fire-and-forget async calls
- `avoid_print` — use `debugPrint()` instead of `print()`
- `avoid_dynamic`, `prefer_final_locals`, `prefer_single_quotes` — code quality

Run `dart fix --apply lib/` periodically to auto-fix `prefer_const_constructors` and `avoid_redundant_argument_values` issues.

## iOS Simulator Browser Preview

When running the app on an iOS Simulator, use [serve-sim](https://github.com/EvanBacon/serve-sim) to stream the simulator to the browser so AI agents can visually test without controlling the Simulator app directly:

```bash
# Start the stream BEFORE running the app
npx serve-sim                  # → http://localhost:3200
flutter run                    # then launch the app on the simulator
```

The agent can view and interact with the app at `http://localhost:3200`. Key capabilities: full 60fps MJPEG stream, gesture support (swipe-to-go-home, pinch-to-zoom with option key), keyboard forwarding, drag-and-drop media, simulator log forwarding to browser. Supports multiple booted simulators and background mode (`npx serve-sim --detach`). Requires macOS with Xcode command line tools.

## iOS build phases (Runner target)

Two custom shell-script phases run after `[CP] Embed Pods Frameworks`, in this
order — the order matters and is documented in
[docs/release_secrets.md](docs/release_secrets.md):

1. **Generate missing vendor framework dSYMs** (`ios/scripts/generate_missing_framework_dsyms.sh`) —
   Firebase ships as SPM binary frameworks with no dSYMs, which makes App Store
   Connect report "Upload Symbols Failed". This runs `dsymutil` to produce real
   dSYM companions. Gated to Release/Profile/archive.
2. **[Crashlytics] Upload dSYMs** (`ios/scripts/upload_crashlytics_symbols.sh`) —
   needs step 1 to have run.

**Never give either phase `inputPaths`/`outputPaths` that resolve inside the
target's own product directory** — `${DWARF_DSYM_FOLDER_PATH}` (which defaults to
`$(CONFIGURATION_BUILD_DIR)`, the directory containing `Runner.app`),
`${BUILT_PRODUCTS_DIR}`, or `${TARGET_BUILD_DIR}/${WRAPPER_NAME}`. Xcode expands a
declared directory input into a node depending on everything produced beneath it,
so the phase ends up depending on `Runner.app`, which depends on the phase:
`Cycle inside Runner; building could produce unreliable results`. That breaks
**every** iOS build including archives and `shorebird release ios`, and Xcode's
suggested "move the phase earlier" does not help because these phases declare no
outputs. This regressed once (commit `2fa149a`) and was fixed by emptying
`inputPaths`. Both phases carry `alwaysOutOfDate = 1` and discover their paths at
runtime, so declared inputs buy nothing.

## Cross-Repo Discipline

- `../backend` is the FastAPI monolith and the source of truth for API contracts. Implement new fields or endpoints there first.
- If a change requires new backend fields or endpoints, implement or coordinate that work in `../backend`.
- If moderation or review workflows are required, plan or implement them in `../real-estate-admin-dashboard`.
- Do not fork the contract locally in the Flutter app to avoid touching the backend.
