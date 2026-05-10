# AGENTS.md

## Repo Purpose

This repository contains the dedicated Flutter mobile client for 360 FlatMates. It is not a general-purpose 360 Ghar client and it must stay aligned to the backend monolith and the flatmates-specific app surface.

## Core Rules

- Use real backend APIs only. Do not introduce mock repositories, fake payloads, or hardcoded business catalogs.
- Keep the app mobile-first and maintain parity between iOS and Android.
- Treat `../backend` as the source of truth for product data contracts.
- Keep business metadata server-driven through `/api/v1/flatmates/catalogs` whenever the data affects product behavior.

## Architecture Boundaries

- `lib/core` is for app-wide technical plumbing only.
- `lib/features` owns product behavior and presentation.
- Avoid leaking feature logic into `core`.
- Do not add another state-management library.
- Keep GoRouter as the routing layer.
- `scripts/banned_patterns.sh` enforces architecture guardrails: no `apiClientProvider` in page files (use a repository), no `Supabase.instance` in page files, no page files over 500 lines.

## Code Generation

- Freezed and json_serializable are used for domain models. After modifying freezed-annotated models, run `dart run build_runner build --delete-conflicting-outputs`.
- Generated files (`.freezed.dart`, `.g.dart`) are committed to the repo.

## Riverpod Guidance

- Prefer Riverpod providers over singleton services.
- For complex state with named methods, prefer `Notifier`/`AsyncNotifier`/`FamilyNotifier` subclasses over raw `FutureProvider`.
- Use `PagedState<T>` for paginated data and `OptimisticUpdate.perform<T>()` for optimistic writes with rollback.
- Invalidate feature providers after write operations instead of manually syncing widget trees.
- Avoid global mutable state outside provider-controlled objects.

## Error Handling

- Use `AppFailure` (sealed class hierarchy in `core/errors/`) and `FlatmatesAsyncView` for error display in pages.
- Never use `error.toString()` in presentation code — enforced by `scripts/banned_patterns.sh`.
- `ErrorPresenter.fromDio()` maps `DioException` → typed `AppFailure`.

## Networking Guidance

- Use the shared Dio client from `core`.
- All authenticated requests must flow through the shared auth interceptor.
- Do not bypass the shared client for ad hoc HTTP calls.
- Use `FlatmatesEndpoints` from `core/config/endpoints.dart` for API paths. Do not hardcode or duplicate backend paths.

## UI Guidance

- Maintain support for light, dark, and system theme modes (default: Light).
- Preserve palette switching as a first-class product capability.
- Keep English and Hindi localization coverage in sync for all primary user flows (default: English).
- Use meaningful keys on major interactive widgets so Maestro coverage can remain stable.
- All visual tokens (colors, radii, spacing, typography, shadows, components) must match [DESIGN.md](DESIGN.md). Do not introduce values that contradict the design system.
- Use design token constant files from `core/theme/` (AppSpacing, AppRadius, AppShadows, AppMotion, AppTypography, AppSemanticColors, AppGradients) barrel-exported via `theme.dart`. Do not use magic numbers.
- Use `Flatmates*` shared components from `features/shared/presentation/` instead of duplicating Scaffold/SafeArea/ListView/async-state patterns.
- Use `FlatmatesNetworkImage` instead of raw `Image.network` — enforced by `scripts/banned_patterns.sh`.
- Use `AppMotion` for all animation durations and curves. Do not hard-code durations or `Curves`. Use `Listener` (not `GestureDetector`) for press-detection when wrapping interactive children (InkWell, FilledButton, OutlinedButton) to avoid gesture arena conflicts.
- Frosted-glass overlays (bottom nav, bottom sheets, bottom action bars) use `BackdropFilter` with `AppSemanticColors.frostBlur` and semi-transparent surfaces. Apply `ClipRRect` before `BackdropFilter` to constrain blur bounds.

## DTO Pattern

- When backend JSON doesn't map cleanly to domain models, use a DTO class in the feature's `data/` layer to construct the domain model (e.g., `PropertyListingDto` → `PropertyListing`).
- Keep backend-specific parsing details in DTOs; keep domain models clean.

## Testing Guidance

- Keep `flutter analyze` clean.
- Keep at least one fast local Flutter test in the repo.
- Maintain a single end-to-end Maestro flow that exercises the real product loop.
- Update Maestro when route names, button labels, or login flow behavior changes.

## Documentation Triggers

Update the docs in `docs/` when any of the following change:

- Backend API surface consumed by the app
- Repo architecture or folder layout
- Theme and localization strategy
- Auth bootstrap flow
- Maestro prerequisites or seeded-data assumptions

## iOS Simulator Browser Preview

When running the app on an iOS Simulator, use [serve-sim](https://github.com/EvanBacon/serve-sim) to stream the simulator to the browser so AI agents can visually test without controlling the Simulator app directly:

```bash
# Start the stream BEFORE running the app
npx serve-sim                  # → http://localhost:3200
flutter run                    # then launch the app on the simulator
```

The agent can view and interact with the app at `http://localhost:3200`. Key capabilities: full 60fps MJPEG stream, gesture support (swipe-to-go-home, pinch-to-zoom with option key), keyboard forwarding, drag-and-drop media, simulator log forwarding to browser. Supports multiple booted simulators and background mode (`npx serve-sim --detach`). Requires macOS with Xcode command line tools.

## Cross-Repo Discipline

- If a change requires new backend fields or endpoints, implement or coordinate that work in `../backend`.
- If moderation or review workflows are required, plan or implement them in `../real-estate-admin-dashboard`.
- Do not fork the contract locally in the Flutter app to avoid touching the backend.
