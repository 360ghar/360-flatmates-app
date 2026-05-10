---
name: qa-flatmates
description: >
  QA tests for the 360 FlatMates Flutter mobile app. Tests authentication, onboarding,
  discovery, swiping, chat, listing creation, visits, profile/settings, and notifications
  via iOS Simulator streamed through serve-sim. Supports 3 user modes (Room Poster,
  Co-Hunter, Open to Both) plus new-user signup flow.
---

# QA — 360 FlatMates Flutter App

## Testing Target

**This project does NOT use preview deployments.** All QA runs test against a local dev environment:

1. **iOS Simulator** must be booted before testing
2. **serve-sim** must be running at `http://localhost:3200` to stream the simulator to browser
3. **Flutter app** must be running on the simulator (`flutter run`)
4. **FastAPI backend** must be running at `http://127.0.0.1:3600/api/v1`
5. Access the app via browser at `http://localhost:3200` using agent-browser

**Startup sequence:**
```bash
# 1. Boot iOS Simulator (if not already)
open -a Simulator

# 2. Start serve-sim (background)
npx serve-sim &

# 3. Run the Flutter app
flutter run

# 4. Wait for serve-sim to be ready
curl -s -o /dev/null -w "%{http_code}" http://localhost:3200
```

**If the app or serve-sim is not running**, report ALL tests as BLOCKED: "iOS Simulator stream not available at localhost:3200. Start serve-sim and flutter run before QA." Do NOT fall back to any remote environment.

## Authentication

**Method:** Supabase phone + password (or OTP)

**Test credentials are provided via environment variables:**
- `QA_ROOM_POSTER_PHONE` / `QA_ROOM_POSTER_PASSWORD`
- `QA_CO_HUNTER_PHONE` / `QA_CO_HUNTER_PASSWORD`
- `QA_OPEN_TO_BOTH_PHONE` / `QA_OPEN_TO_BOTH_PASSWORD`

**Login flow in the app:**
1. Navigate to `/enter-phone`
2. Enter phone number
3. Tap "Login" to go to password page, or tap "Send OTP" for OTP flow
4. Enter password or OTP
5. On success, redirected to `/discover` (or `/onboarding` if incomplete)

**In CI/automated runs:** Credentials come from GitHub secrets mapped to env vars. The agent does NOT need to log in interactively -- it fills the phone/password fields via agent-browser.

## App-Specific Notes

- The app uses **Material 3** with primary color `#5B4BCF`
- Navigation is mode-dependent: Room Poster sees Home|Post|Swipe|Likes&Chat|Profile; Co-Hunter/Open to Both sees Home|Explore|Swipe|Likes&Chat|Profile
- The app supports **light, dark, and system** theme modes
- **English and Hindi** localization are supported
- serve-sim streams at 60fps -- interactions (taps, swipes) are forwarded to the simulator
- Some animations (swipe deck, compatibility ring) may take 300-600ms -- wait for them
- The app uses `Key` values on interactive widgets for Maestro stability -- these also help agent-browser targeting

## Menu of Test Flows

The orchestrator picks only the flows relevant to the current diff. Each flow is labeled with the code areas it covers.

---

### Flow 1: Authentication (Phone Login + Signup)

**Covers:** `lib/features/auth/**`, `lib/core/network/interceptors/auth_interceptor.dart`, `lib/core/storage/auth_token_storage.dart`

**Steps:**
1. Navigate to `/enter-phone` (or launch app while logged out)
2. Enter test phone number in the phone input field
3. Tap "Login" button
4. On the login page, enter password
5. Verify redirect to `/discover` (or `/onboarding` if not completed)
6. Capture snapshot showing the discover feed or onboarding screen

**Per-persona variations:**
- Room Poster: Login with `QA_ROOM_POSTER_PHONE` credentials
- Co-Hunter: Login with `QA_CO_HUNTER_PHONE` credentials
- Open to Both: Login with `QA_OPEN_TO_BOTH_PHONE` credentials

**New user signup variation:**
1. Navigate to `/enter-phone`
2. Enter a new phone number
3. Tap "Sign Up" to go to signup page
4. Fill in full name, phone, password
5. Verify redirect to `/onboarding` (onboarding not completed)

**OTP login variation:**
1. Enter phone number
2. Tap "Send OTP"
3. Enter OTP code (requires access to SMS or test OTP from Supabase)
4. Verify redirect to `/discover`

**Success criteria:** Authenticated user sees the discover feed (or onboarding if incomplete).

**Negative test:** Enter wrong password -> verify error message displayed (not a crash).

---

### Flow 2: Onboarding (Mode Selection -> Profile Complete)

**Covers:** `lib/features/onboarding/**`, `lib/features/bootstrap/**`

**Steps:**
1. Start from `/onboarding` (after fresh signup or with onboarding incomplete)
2. Mode Selection: Tap one of the 3 mode cards (Room Poster / Co-Hunter / Open to Both), tap Continue
3. Location Selection: Search or select a city, tap Continue
4. Basic Info: Enter name, age, profession
5. Profile Photo: Upload or skip
6. Lifestyle Quiz: Answer lifestyle questions
7. Budget/Timeline: Set budget range and move-in timeline
8. Preferences: Set preferences (gender, food, pets, smoking)
9. Non-Negotiables: Set deal-breakers
10. Submit onboarding
11. Verify redirect to `/discover` and profile is complete

**Per-persona variations:**
- Test each mode selection to verify correct bottom nav tabs appear after completion

**Success criteria:** After completing onboarding, user lands on discover feed with correct bottom nav for their mode.

**Negative test:** Try to skip required fields -> verify Continue button is disabled.

---

### Flow 3: Discover Feed

**Covers:** `lib/features/discover/**`, `lib/core/compatibility/**`

**Steps:**
1. Navigate to `/discover` (Home tab)
2. Verify greeting shows user name ("Hi, [Name]!")
3. Verify listing cards are displayed in horizontal scroll
4. Tap a listing card to navigate to flat details
5. Use the search bar to search by location/landmark
6. Apply filter chips (Nearby, 1BHK, Furnished, Budget+)
7. Navigate to search filters page for advanced filters
8. Apply filters and verify results update

**Success criteria:** Listing cards load with images, prices, titles. Search and filters work.

---

### Flow 4: Flat Details

**Covers:** `lib/features/discover/flat_details_page.dart`, `lib/features/shared/presentation/**`

**Steps:**
1. From discover feed, tap a listing card
2. Verify image carousel loads
3. Verify title, price (₹/month), location displayed
4. Verify icon row (beds, furnishing, WiFi, etc.)
5. Verify "About this Flat" section
6. Verify availability grid (Available from, Posted on)
7. Tap "Shortlist" -> verify heart icon toggles
8. Tap "Contact" -> verify navigation to chat
9. Verify compatibility ring/score is displayed
10. Tap back -> return to discover feed

**Success criteria:** All listing details render correctly. Shortlist and Contact buttons work.

---

### Flow 5: Swipe Deck

**Covers:** `lib/features/swipe/**`

**Steps:**
1. Navigate to `/swipe` tab
2. Verify profile cards load in a deck
3. Swipe right (like) on a card
4. Verify card animates away and next card appears
5. Swipe left (pass) on a card
6. Verify card animates away
7. If match occurs, verify celebration animation
8. Continue until deck is empty or a few swipes

**Success criteria:** Cards respond to swipes. Like/pass animations work. Match celebration triggers when applicable.

---

### Flow 6: Chat

**Covers:** `lib/features/chats/**`

**Steps:**
1. Navigate to `/chats` tab (Likes & Chat)
2. Verify conversations list loads with avatars, names, last message preview
3. Tap a conversation to open chat thread
4. Type a message in the input field
5. Tap send
6. Verify message appears as sent bubble (primary color, right-aligned)
7. Wait for potential reply
8. Verify property card is shown at top of chat if applicable
9. Tap "View Listing" button if present -> verify navigation to flat details
10. Go back to conversations list

**Success criteria:** Messages send and appear correctly. Conversation list loads.

**Negative test:** Send empty message -> verify send button is disabled or message is not sent.

---

### Flow 7: Post Listing

**Covers:** `lib/features/listings/**`

**Steps:**
1. For Room Poster: Tap "Post" tab -> Tap "New Listing"
   For other modes: Navigate to `/post/new`
2. Step 1: Fill flat details (dropdown for BHK, title, location, rent, room type, furnishing)
3. Tap "Next"
4. Step 2: Add photos (or skip)
5. Tap "Next"
6. Step 3+: Fill preferences (gender, allowed flatmates, food habits, pets, smoking, move-in timeline)
7. Tap "Next"
8. Review page: Verify all details are correct
9. Tap "Publish Listing"
10. Verify redirect to "Listing Under Review" page
11. Verify review page shows: confirmation message, "What happens next" steps, property preview card
12. Tap "Go to Home Feed" -> verify return to discover

**Per-persona variations:**
- Room Poster: Post tab is directly accessible in bottom nav
- Co-Hunter / Open to Both: Navigate via profile or route

**Success criteria:** Listing is published and shows "Under Review" confirmation.

**Negative test:** Try to publish with required fields empty -> verify Next button is disabled or validation error appears.

---

### Flow 8: Visits

**Covers:** `lib/features/visits/**`

**Steps:**
1. Navigate to `/visits` tab
2. Verify visits list (upcoming, past, pending)
3. From a chat thread, tap "Schedule Visit"
4. Select a date on the calendar
5. Select a time slot (Morning/Afternoon/Evening)
6. Add an optional note
7. Tap "Send Request"
8. Verify confirmation
9. Go back to visits page -> verify new visit appears

**Success criteria:** Visit request is sent and appears in visits list.

---

### Flow 9: Profile & Settings

**Covers:** `lib/features/profile/**`, `lib/features/settings/**`

**Steps:**
1. Navigate to `/profile` tab
2. Verify avatar, name, role badge, location displayed
3. Tap "Edit Profile" (pencil icon on avatar) -> verify edit page opens
4. Go back
5. Tap settings gear icon -> verify settings page opens
6. Test theme switching (Light/Dark/System)
7. Test palette switching if available
8. Navigate to "Change Password" -> verify page loads
9. Navigate to "Blocked Users" -> verify page loads (may be empty)
10. Navigate to "Help & Support" -> verify page loads
11. Go back to profile

**Success criteria:** Profile displays correctly. Settings pages load. Theme switching works.

**Negative test:** Enter wrong current password in change password -> verify error message.

---

### Flow 10: Notifications

**Covers:** `lib/features/notifications/**`

**Steps:**
1. Navigate to `/notifications` (via bell icon in header or route)
2. Verify notification cards load
3. Verify each card shows: icon, title, description, timestamp
4. Verify unread dot indicator on unread notifications
5. Tap "Mark all as read" if available
6. Tap a notification -> verify it navigates to relevant content
7. Go back

**Success criteria:** Notifications list loads with correct card layout. Unread indicators work.

---

### Flow 11: Mode-Dependent Bottom Nav (Multi-Persona)

**Covers:** `lib/app/app_shell.dart`, `lib/app/router/app_router.dart`

**This flow verifies that the 3 user modes show different bottom nav tabs.**

**Steps per persona:**

**Room Poster:**
1. Login as room_poster
2. Verify bottom nav shows: Home, Post, Swipe, Likes & Chat, Profile
3. Verify "Post" tab is visible and navigates to `/post`
4. Verify "Explore" (map) tab is NOT visible

**Co-Hunter:**
1. Login as co_hunter
2. Verify bottom nav shows: Home, Explore, Swipe, Likes & Chat, Profile
3. Verify "Explore" tab is visible and navigates to `/map`
4. Verify "Post" tab is NOT visible (unless accessed via route)

**Open to Both:**
1. Login as open_to_both
2. Verify bottom nav shows: Home, Explore, Swipe, Likes & Chat, Profile
3. Verify "Explore" tab is visible and navigates to `/map`
4. Verify user can also access `/post/new` via route

**Success criteria:** Each mode shows the correct bottom nav tab configuration per DESIGN.md.

---

### Flow 12: Map View

**Covers:** `lib/features/discover/map_view_page.dart`

**Steps:**
1. Navigate to `/map` (Explore tab for Co-Hunter/Open to Both)
2. Verify Google Maps loads with property markers
3. Tap a marker -> verify listing preview card appears
4. Tap the preview card -> navigate to flat details
5. Go back to map

**Success criteria:** Map loads with markers. Tapping markers shows listing previews.

---

## Cleanup

After test runs that create data:

```bash
# Delete test listings (if listing IDs are known)
curl -X DELETE http://127.0.0.1:3600/api/v1/properties/{id} \
  -H "Authorization: Bearer $TOKEN"

# Delete test conversations
curl -X DELETE http://127.0.0.1:3600/api/v1/flatmates/conversations/{id} \
  -H "Authorization: Bearer $TOKEN"

# Delete test visits
curl -X DELETE http://127.0.0.1:3600/api/v1/visits/{id} \
  -H "Authorization: Bearer $TOKEN"
```

For test users created during signup: these can remain as they have low impact. If cleanup is needed, use the backend admin endpoints.

## Known Failure Modes

1. **iOS Simulator not booted.** `flutter run` will fail if no simulator is booted. Always check `xcrun simctl list devices | grep Booted` before running the app. Boot with `open -a Simulator`.

2. **serve-sim not running.** The browser stream at `http://localhost:3200` will be unreachable. Start with `npx serve-sim` before flutter run. serve-sim requires Node.js.

3. **Backend not running.** API calls will fail with connection refused. Start the FastAPI backend from `../backend` with `uvicorn app.main:app --reload --port 8000` or the project's start command.

4. **Supabase session expiry.** Long QA runs may hit token expiry. If auth fails mid-run, re-login or restart the app. Supabase access tokens have a 1-hour default TTL.

5. **OTP timing.** Supabase OTP codes expire after 60 seconds by default. For OTP login tests, request a fresh OTP and enter it quickly. In local dev, the Supabase project may have a test OTP feature enabled.

6. **Flutter hot reload.** If the app was started with `flutter run`, hot reload/restart may change the app state unexpectedly during QA. Avoid triggering hot reload during test runs.

7. **serve-sim latency.** The browser stream adds ~50-100ms latency. Wait for UI transitions to complete before capturing snapshots. Animations (swipe, compatibility ring) take 300-600ms.

8. **Google Maps API key.** Map-related tests will fail if `GOOGLE_MAPS_API_KEY` is not set in `.env`. Verify the env var is present before testing map flows.
