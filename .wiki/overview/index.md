# 360 FlatMates overview

360 FlatMates is a Flutter mobile client for flatmate-finding in India. It helps users find flats and flatmates through listing discovery, compatibility-based swiping, real-time chat, and visit scheduling. The app uses Flutter 3.41+, Supabase for authentication, and a FastAPI backend monolith for all business logic and storage.

## Tech stack

- **Language**: Dart 3.9+, Flutter 3.41+
- **State management**: Riverpod (NotifierProvider, AsyncNotifierProvider, FamilyNotifier, FutureProvider)
- **Routing**: GoRouter with StatefulShellRoute.indexedStack (7 branches, 5 visible tabs)
- **Backend**: FastAPI monolith at `../backend`
- **Auth**: Supabase (phone + password, OTP, Google, Apple)
- **Realtime**: SSE (Server-Sent Events) + Supabase realtime for chat
- **Push**: Firebase Cloud Messaging + local notifications
- **Maps**: flutter_map with OpenStreetMap tiles
- **Design system**: Material 3 with warm-editorial palette (terracotta accent, paper/ink scales)
- **Localization**: English (template) and Hindi via ARB files
- **Analytics**: Firebase Analytics + Crashlytics

## Repository structure

```
lib/
  main.dart                       # Entry point
  bootstrap.dart                  # DI setup, Supabase init, Firebase, ProviderScope
  app/
    app.dart                      # MaterialApp.router, offline banner, deep links
    app_shell.dart                # Mode-dependent bottom navigation
    router/app_router.dart        # GoRouter with 20+ routes
  core/                           # App-wide technical plumbing
    providers.dart                # Global provider graph
    config/                       # AppConfig, FlatmatesEndpoints, env loading
    network/                      # Dio client, auth interceptor, SSE, connectivity
    theme/                        # Material 3 theme, design tokens
    errors/                       # AppFailure sealed class, error presenter
    storage/                      # SharedPreferences, secure storage, image upload
    domain/                       # PagedState, OptimisticUpdate, typed enums
    analytics/                    # Firebase Analytics + Crashlytics wrapper
    notifications/                # FCM foreground/background handling
    compatibility/                # Client-side matching algorithm
    deep_links/                   # app_links parsing
    location/                     # Google Places + Nominatim search
    map/                          # flutter_map controller + tile layer
    utils/                        # ActionDebouncer, profanity filter
    widgets/                      # Cross-feature shared widgets
  features/                       # Feature modules with controllers, repos, pages
    auth/                         # Authentication (phone, OTP, Google, Apple)
    bootstrap/                    # Profile + catalog loading after auth
    onboarding/                   # Multi-step onboarding state machine
    discover/                     # Listing feed, search, filters, map
    swipe/                        # Tinder-like card deck
    chats/                        # Conversations + messages (Supabase realtime)
    listings/                     # Multi-step listing builder + management
    visits/                       # Schedule/confirm/reschedule visits
    notifications/                # Notification list
    profile/                      # Profile view/edit
    settings/                     # Theme, palette, locale, privacy
    shared/presentation/          # 18 Flatmates* reusable widgets
    location/                     # Location picker UI
    location_search/              # Location search page
    feedback/                     # Feedback form
  l10n/                           # Generated ARB localization
```

## Key principles

- **Real backend APIs only** — no mock repositories or fake payloads
- **Business logic in controllers** — widgets call controllers, not repositories
- **Feature-first structure** — each feature owns its controller, repo, models, pages
- **Riverpod for state** — Notifier subclasses, PagedState, OptimisticUpdate
- **Server-driven metadata** — catalogs endpoint drives product behavior
- **Design token constants** — no magic numbers, all tokens from AppSpacing/AppRadius/etc.
- **Light/dark/system theme** — persisted to SharedPreferences
- **English + Hindi** — ARB-based localization, synced for primary flows

## Cross-repo dependencies

- `../backend` — FastAPI monolith, source of truth for API contracts
- `../real-estate-admin-dashboard` — Admin dashboard for moderation workflows
