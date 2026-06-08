# 360 FlatMates Technical Specification

## Product Alignment

360 FlatMates is implemented as a new Flutter mobile client backed by the existing 360 Ghar FastAPI monolith. The mobile app uses Supabase directly for authentication and uses the FastAPI backend as the application system of record for flatmate profile data, listings, swipes, conversations, and visits.

The product source remains `docs/prd.md`, but the implementation architecture in this document replaces the older Firebase and Firestore assumptions.

## Backend Reuse Strategy

The backend reuses existing shared platform entities wherever possible.

- `users` is the primary flatmate profile record.
- `properties` is the flatmate room and PG listing record.
- `user_swipes` is extended to support both property swipes and person swipes.
- `visits` is extended to support flatmate meet requests without introducing a second visit resource.
- Existing Supabase bearer-token auth, Cloudinary upload infrastructure, notification infrastructure, and websocket infrastructure remain part of the monolith.

The only new persistence layer introduced is the reusable social layer that did not already exist in the monolith.

- `user_matches`
- `user_conversations`
- `user_messages`
- `user_blocks`
- `user_reports`
- `app_catalogs`

These tables are generic shared primitives rather than FlatMates-only clones, so they can serve additional peer-to-peer use cases later.

## Data Model Extensions

The `users` table now stores flatmate-specific search and lifecycle fields directly.

- Mode
- Profile status
- Onboarding completion
- Bio
- Budget range
- Move-in timeline
- City and locality
- The six compatibility dimensions from the PRD
- Last active timestamp

The `users.preferences` JSON document remains the long-tail storage area for flatmate-specific metadata that should not be promoted to first-class columns yet.

The `properties` table continues to represent room listings. Flatmate listings are identified through the existing `property_type` and `purpose` values already present in the backend.

Flatmate listing creation uses the existing `/api/v1/properties` contract with the room photos submitted as `image_urls` plus `main_image_url`. The backend persists those URLs into `property_images` so the mobile app and admin review queue can show the full photo set instead of only the cover image.

On create and update, flatmate listings run best-effort Google Maps geocoding when coordinates are missing and `GOOGLE_MAPS_API_KEY` is configured. The backend stores both latitude/longitude and the PostGIS `location` point for map and future nearby-essential features.

The `user_swipes` table now supports both listing and profile actions.

- Listing swipe uses `target_type=property` and `property_id`
- Profile swipe uses `target_type=user` and `target_user_id`
- `swipe_action` preserves pass, like, and super-like
- `context_property_id` allows person-to-person actions to retain listing context
- Profile super-likes are server-capped through a daily usage ledger so the V1 3-per-day limit is enforced beyond the mobile SharedPreferences UI counter.

The `visits` table now supports two contexts.

- `property_tour` for existing real-estate visits
- `flatmate_meet` for in-chat flatmate meet requests

Flatmate visits also carry the counterparty user and optional conversation and match linkage so the existing visits resource can support both product surfaces.

## API Surface

The backend now exposes a dedicated FlatMates app surface under `/api/v1/flatmates`.

- `GET /flatmates/bootstrap`
- `GET /flatmates/catalogs`
- `GET /flatmates/profile`
- `PUT /flatmates/profile`
- `POST /flatmates/swipes`
- `GET /flatmates/likes`
- `POST /flatmates/profile-views`
- `GET /flatmates/conversations`
- `GET /flatmates/conversations/{id}/messages`
- `POST /flatmates/conversations/{id}/messages`
- `GET /flatmates/matches`
- `POST /flatmates/blocks`
- `POST /flatmates/reports`
- `POST /flatmates/listings/{listing_id}/society-tags/votes`

The existing `/api/v1/visits` resource is extended rather than duplicated. It now accepts and returns the flatmate visit context fields alongside the original property-tour behavior.

The Flutter app currently reuses the existing `/api/v1/properties` endpoint for room discovery, filtered to flatmate inventory. Move-in timeline chips use the backend `move_in` query parameter (`immediate`, `this_month`, `next_month`, with `flexible` treated as no availability filter) and retain the same client-side window check for already-loaded feed and map data. The swipe deck passes the same `move_in` value to `/api/v1/flatmates/profiles` for profile timeline filtering.

Admin moderation uses `/api/v1/flatmates/moderation/listings` and `/api/v1/flatmates/moderation/prescreen/{listing_id}`. New and resubmitted room listings are pre-screened by a deterministic backend classifier that stores `ai_prescreen_result`, `ai_prescreen_flags`, and `ai_prescreen_reason` in `listing_preferences` before human review.

On first approval, a flatmate listing receives a 24-hour launch boost marker in `listing_preferences` (`approval_boost_granted_at`, `boosted_until`, `boost_reason`) and the approval notification tells the Room Poster the listing is live and boosted.

Flatmate user reports are stored in `user_reports`. Once a profile has 3 distinct active reports, the backend pauses that user's Flatmates profile and removes it from discoverable profile results pending admin review.

Flatmate room listings with expired `available_from` dates are automatically paused through the backend listing read paths and flagged in `listing_preferences` for Room Poster review. Owner pause/resume uses the same property update API with `listing_preferences.moderation_status`, so the Flutter Manage Listing action remains aligned with the backend moderation contract.

Data-only interaction capture is also live for V2 recommendation and community-insight upgrades. The mobile swipe deck records expanded-profile view duration through `POST /api/v1/flatmates/profile-views`, and society tag feedback uses `POST /api/v1/flatmates/listings/{listing_id}/society-tags/votes` to maintain per-tag up/down counts, current-user votes, and 3-downvote dispute markers in `listing_preferences`.

## Chat and Match Behavior

Chat is implemented as a generic two-user conversation layer.

- Profile swipes remain person-to-person
- Reciprocal positive profile swipes create `user_matches`
- Incoming positive profile swipes are exposed through `GET /flatmates/likes`; once the current user taps Match, the app records the reciprocal `POST /flatmates/swipes` action and opens the resulting conversation with the Q&A nudge.
- Listing likes do not wait for reciprocity and directly create or reuse a conversation with the listing owner
- Only one active conversation is maintained per user pair
- Repeated listing interest from the same pair reuses the existing conversation and updates its listing context
- Flatmate visit scheduling creates a real `/api/v1/visits` row with `visit_context=flatmate_meet`, `conversation_id`, and `counterparty_user_id`, then sends a structured `visit_request` chat message with visit metadata so the chat thread can render the request card and confirm/reschedule actions from live visit status.

This satisfies the product requirement that flatmate conversations be built on a reusable chat primitive instead of a dedicated FlatMates-only chat schema.

## Catalog Strategy

Business catalogs are served from the backend through `app_catalogs`. Seeded V1 catalogs include:

- Flatmate modes
- Move-in timelines
- Onboarding quiz dimensions
- Vibe tags
- Report reasons

This removes the need for the Flutter app to hardcode business metadata.

## Flutter Architecture

The Flutter application starts from a clean mobile-only scaffold and uses:

- Riverpod for dependency injection and state
- GoRouter for navigation
- Dio for FastAPI communication
- Supabase Flutter for auth
- Shared preferences for theme, palette, and locale persistence
- Secure storage for token persistence
- ARB-based localization for English and Hindi

The app shell currently includes:

- Authentication
- Bootstrap loading
- Discover
- Chats
- Visits
- Profile and settings

Theming supports light, dark, and system modes along with multiple palette presets. Localization currently supports English and Hindi only.

## Current Delivery State

This implementation establishes the platform foundation, the first usable product loop, and the core feature surface:

- Password and OTP auth
- Backend bootstrap
- Full onboarding flow (splash screens, mode selection, basic info, **skippable** photo step with name-initials avatar fallback, lifestyle quiz, budget/timeline, non-negotiables)
- Compatibility engine (6-dimension scoring with animated ring)
- Swipe deck (collapsed/expanded cards, action bar, user-to-user swipes)
- Match celebration screen with Q&A nudge, answer storage, and chat-thread answer display
- Flatmate profile editing
- Listing discovery through real property APIs
- Listing-like to chat creation
- Two-user conversations with Supabase Realtime (primary) and SSE-driven refetch fallback when realtime is unavailable, photo sharing, icebreaker chips, read receipts, and report/block/unmatch
- Flatmate visit request, confirmation, reschedule, and cancellation
- 8-step listing builder (location, society, room, photos, flat, costs, about, review)
- Manage listing page with status badges, share, and boost
- Map view with clustered pins and filter bar
- Home feed with vibe and move-in filter chips, city counter, and Picked for You
- Backend AI pre-screening for review completeness, suspicious rent, missing photos, and spam/inappropriate content keywords
- Repeat-report auto-pause for Flatmates profiles after 3 active reports
- Expired move-in auto-pause for Room Poster listings, with owner pause/resume using backend moderation status
- Data-only profile view duration tracking for future smart recommendations
- Data-only society tag vote counts and community-dispute markers
- First-approval 24-hour boost marker and notification
- Listing geocoding with latitude/longitude and PostGIS point storage
- WhatsApp share card via share_plus
- Waitlist mode for low-density cities
- Privacy settings (hide last name, hide exact location)
- Push notification service (FCM token management)
- 401 auth interceptor with token refresh retry
- Image upload service (camera/gallery + Cloudinary via backend API)
- Video tour upload and playback with client-side size and duration enforcement
- Theme, palette, and locale switching
- EN + HI localization (150+ strings)

## Immediate Follow-On Work

The next backend and mobile milestones should focus on:

- Pagination on listings, conversations, and messages
- Seed data for complete end-to-end QA scenarios
- Google Calendar sync for confirmed visits
- Maestro end-to-end test flow
- App store metadata (icons, screenshots, copy)
- Analytics and crash reporting (Firebase Analytics / Sentry)
- Broader seed data coverage for QA and Maestro
