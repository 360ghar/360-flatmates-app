# UX Audit Backlog — cleared 2026-07-11

All items from the 12-lane audit and deferred list are **fixed**. Nothing intentionally left open.

## Fixed in Wave 2a + full backlog sweep

| Area | Fixes |
|------|--------|
| Visits | Wire statuses, reschedule API, chat actions, dual invalidate |
| Discover | Browse line limit, broaden cursor, home error UI, filter clear search, browse debounce |
| Flat details | Society tag votes, family providers, schedule guard |
| Auth | needsPassword durable prefs, terms default false, forgot-password E.164, soft gate `/tab2` |
| Onboarding | Profile completion gate, waitlist prefs storage, coming-soon→waitlist, upload failure toast, welcome-back flag, dead move-in UI |
| Chats | Photo send, QnA numeric Q2, unmatch toast, send/read guards, catalog report reasons |
| Swipe | Undo only until persist, hasSwiped preserve, like-only incoming, fling commit |
| Map | Like toggle + feed sync |
| Settings | Remote privacy + notification settings, foreground notif filter, logout confirm, unblock confirm |
| Listings | Payload fields, photo batch, under-review live UI, pause controller, boost removed, dead draft deleted |
| Notifications | Actions controller, SSE list invalidate |
| Shared | Reduced motion empty/error/screen, legal titles l10n, legal error retry |
| Profile | Mode/work_style null-safe, privacy display masking |
| Feedback | AppFailure messages |
| Location | Search versioning, picker GPS timeout + settings |

## Verification

- `bash scripts/banned_patterns.sh` — pass
- `flutter analyze` — clean
- `dart format` applied
- Run `flutter test` before merge
