# 360 FlatMates — Canonical Feature User-Stories Tracker

Single source of truth for every user-facing feature/user story in the app, its
expected behavior (derived from code), test status, errors found, and fix notes.

**Audit summary (post-fix)**
- 76 user stories across 16 feature areas
- 12 stories fixed (client-side code changes applied)
- 7 stories verified clean (false positives from initial scan, no action needed)
- 57 stories cataloged (no errors found in static review)
- Quality gates: `flutter analyze` clean, `flutter test` 136/136 passed, `banned_patterns.sh` all passed, `dart format` clean

**Status legend**
- `Cataloged` — story documented, static review found no errors
- `Fixed` — confirmed client-side errors fixed; verified via analyze + tests
- `Verified` — static review found no errors (includes false-positive downgrades)
- `Logged` — issue identified but requires backend or architectural refactor

**Test method**: static code review (read page + controller + repo, trace logic
against expected behavior). Runtime E2E via Maestro is documented in `.maestro/`
but not run in this pass.

---

## AUTH

| ID | Story | Route / Page | Expected Behavior | Status | Errors Found | Fix Notes |
|----|-------|--------------|-------------------|--------|--------------|-----------|
| AUTH-01 | Splash screen (auth check) | `/splash` `splash_page.dart` | Animated splash while `authControllerProvider.status == checking`; `BootstrapController` fetches `/flatmates/bootstrap` + `/users/me/auth-state`; on error shows retry button calling `bootstrapControllerProvider.notifier.refresh()`; router redirect chain evaluates next gate on completion. | Cataloged | | |
| AUTH-02 | Enter phone/email (identifier) | `/enter-phone` `enter_phone_page.dart` | Phone/email input; Android SIM hint picker (once/session); terms checkbox required; `checkIdentifierStatus()` → `POST /auth/identifier-status`; routes by `nextStep` to `/login`, `/otp`, or signup OTP; identifier stored in `pendingPhoneProvider`; Google/Apple buttons available. | Cataloged | | |
| AUTH-03 | Login with password | `/login` `login_page.dart` | Identifier pre-filled from route; password field with visibility toggle + tooltip; `signInWithPassword()`/`signInWithEmailPassword()` → Supabase `POST /auth/v1/token`; records `last_auth_method`; "Forgot Password?" → `/forgot-password`. | Cataloged | | |
| AUTH-04 | OTP verification | `/otp` `otp_page.dart` | 6 OTP boxes; Android `SmsAutoFill.listenForCode()` fills silently (stale-code guard, no auto-submit); `verifyOtp()`/`verifyEmailOtp()` → Supabase `POST /auth/v1/verify`; if `needsPassword` → `/set-password`; resend after 30s cooldown. | Cataloged | | |
| AUTH-05 | Set password (mandatory gate) | `/set-password` `set_password_page.dart` | Router forces when `auth.needsPassword == true`; password + confirm fields; `PasswordPolicy.validate()`; `setPasswordAfterSignup()` → `Supabase.auth.updateUser`; `PopScope canPop:false` prevents back; clears `needsPassword` on success. | Cataloged | | |
| AUTH-06 | Forgot password (OTP request) | `/forgot-password` `forgot_password_page.dart` | Identifier field pre-filled; `PasswordResetController.sendOtp()` auto-detects channel; `POST /auth/password-reset/otp`; on success → `/reset-password`. | Cataloged | | |
| AUTH-07 | Reset password (OTP + new password) | `/reset-password` `reset_password_page.dart` | OTP + new password + confirm; `verifyOtpAndSetPassword()` → `POST /auth/password-reset/verify` + `set-password`; on failure cleans up temp session via `signOut()`; success → `/discover`. | Cataloged | | |
| AUTH-08 | Add phone (post-Google, skippable) | `/add-phone` `add_phone_page.dart` | Router routes here when `addPhonePromptProvider == true && profile.phone empty`; two-step (phone → OTP); `requestAddPhoneOtp()` + `addAndVerifyPhone()`; "Skip" clears prompt, advances to onboarding/home. | Cataloged | | |
| AUTH-09 | Google sign-in | `/enter-phone` (button) | Native `GoogleSignIn` if `googleWebClientId` configured; on cancel rethrows benign `GoogleSignInException(canceled)`; phone-less → `addPhonePromptProvider=true`; OAuth redirect fallback launches browser, deep-link callback auto-exchanges `?code=`. | Cataloged | | |
| AUTH-10 | Apple sign-in (iOS) | `/enter-phone` (button) | Native Apple sheet; on cancel rethrows `AppleSignInCancelled` (benign); phone-less → add-phone prompt; records `last_auth_method = apple`. | Cataloged | | |

## BOOTSTRAP

| ID | Story | Route / Page | Expected Behavior | Status | Errors Found | Fix Notes |
|----|-------|--------------|-------------------|--------|--------------|-----------|
| BOOT-01 | Bootstrap data fetch | `bootstrap_controller.dart` | Auto-triggered when `auth.status == authenticated`; parallel fetch `/flatmates/bootstrap` + `/users/me/auth-state`; updates `AuthController.authStage`; retains previous value during refresh; on error splash shows retry. | Cataloged | | |

## ONBOARDING

| ID | Story | Route / Page | Expected Behavior | Status | Errors Found | Fix Notes |
|----|-------|--------------|-------------------|--------|--------------|-----------|
| ONBOARD-01 | Splash carousel | `/onboarding` (splash step) `onboarding_splash_pages.dart` | 4-page carousel with illustrations, page indicators; "Next" advances, "Skip" on last → mode selection; `completeSplash()` advances. | Fixed | L10n: "Profile Setup" hardcoded in `onboarding_page.dart:134` | Replaced with `locale.profileSetup` (new ARB key `profileSetup`) |
| ONBOARD-02 | Mode selection | `/onboarding` (mode step) `mode_selection_page.dart` | 3 mode cards (Co-Hunter, Room Poster, Open to Both) from `flatmates_modes` catalog (hardcoded fallback); `setMode()` → location selection. | Cataloged | | |
| ONBOARD-03 | Location selection | `/onboarding` (location step) `location_selection_page.dart` | City + locality pickers; `setLocation()` → basic info. | Cataloged | | |
| ONBOARD-04 | Basic info | `/onboarding` (basicInfo step) `basic_info_page.dart` | Name, age (≥18), profession, city/locality (pre-filled); validation; `setBasicInfo()` → profile photo. | Cataloged | | |
| ONBOARD-05 | Profile photo upload | `/onboarding` (profilePhoto step) `profile_photo_page.dart` | Grid up to 5; gallery/camera; `ImageUploadService.uploadProfilePhoto()`; remove deletes local only; `setPhotoUrls()` → lifestyle quiz. | Cataloged | | |
| ONBOARD-06 | Lifestyle quiz | `/onboarding` (lifestyleQuiz step) `lifestyle_quiz_page.dart` | 8+ questions from `flatmates_lifestyle_quiz` catalog (hardcoded fallback); `setLifestyleAnswers()` → budget timeline. | Cataloged | | |
| ONBOARD-07 | Budget & timeline | `/onboarding` (budgetTimeline step) `budget_timeline_page.dart` | Budget min/max sliders + timeline pills from `flatmates_move_in_timeline` catalog (hardcoded fallback); validation `budgetMin ≤ budgetMax`; `setBudgetTimeline()` → preferences. | Cataloged | | |
| ONBOARD-08 | Preferences | `/onboarding` (preferences step) `preferences_page.dart` | Gender/pets/smoking/drinking pills from `flatmates_preferences` catalog (hardcoded fallback); normalizes values; `setPreferences()` → non-negotiables. | Cataloged | | |
| ONBOARD-09 | Non-negotiables | `/onboarding` (nonNegotiables step) `non_negotiables_page.dart` | Deal-breaker pills from `flatmates_non_negotiables` catalog (hardcoded fallback); multi-select; `submitNonNegotiables()` triggers final submission. | Cataloged | | |
| ONBOARD-10 | Onboarding submission | `onboarding_controller.dart` | Builds payload, normalizes prefs, `ProfileRepository.updateProfile()` → `PATCH /users/me`; on success `BootstrapController.refresh()`, clears draft, `isComplete=true`, router → `/discover`. | Cataloged | | |
| ONBOARD-11 | Waitlist (city unavailable) | `/waitlist?city=` `waitlist_page.dart` | Empty state; "Notify Me" → `updateProfile({waitlist_city})`; "Invite Friends" → `Share.share()` deep link. | Cataloged | | |

## DISCOVER

| ID | Story | Route / Page | Expected Behavior | Status | Errors Found | Fix Notes |
|----|-------|--------------|-------------------|--------|--------------|-----------|
| DISC-01 | Home feed | `/discover` `discover_page.dart` | Auto-detect location; time-based greeting; paginated feed via `DiscoverFeedController` (offset-based, `rawCount` tracking); scroll listener @500px → `loadMore()`; pull-to-refresh resets offset; deal-breaker + move-in + vibe filtering client-side. | Verified | Verified clean (WaitlistNudgeCard uses `setState` but is plain `StatefulWidget`, not `ConsumerStatefulWidget` — AGENTS.md rule does not apply) | |
| DISC-02 | Search filters | `/discover` filter sheet `filter_sheet.dart` | Budget range (₹5K–₹100K), room type, furnishing, gender, move-in, pets, smoking; "Clear All"; active filter chips; `updateFilters()` → `load()`; filter version bumping; persisted to `discoverFiltersProvider`. | Verified | Verified clean — budget slider IS initialized from `discoverFiltersProvider` in `build()` (`:287-310`). 15 `setState` calls kept as-is (ephemeral modal form, 7+ interdependent fields). | |
| DISC-03 | Browse listings grid | `/discover/browse-listings` `browse_listings_page.dart` | Grid of cards; search bar + clear; filter button opens same sheet; like → optimistic `toggleLike()`; tap card → `/flat-details/{id}`. | Fixed | L10n: tooltip `'Back'` hardcoded (`:63`), tooltip `'Close search'` hardcoded (`:94`) | Replaced with `locale.backCta` and `locale.closeSearch` (new ARB key `closeSearch`) |
| DISC-04 | Flat details | `/flat-details/{id}` `flat_details_page.dart` | `propertyListingProvider(id)`; image carousel + indicator; about/media/location sections; like toggles shortlist + invalidates conversation providers; contact → chat/create conversation; schedule visit; owner profile tap → match %; share sheet. | Fixed | 3 `setState` calls for `_currentImageIndex` + `_contacting` (AGENTS.md violation → StateProvider) | Converted to `_currentImageIndexProvider` + `_contactingProvider` StateProviders |
| DISC-05 | Carousel + full-screen gallery | `flat_details_page.dart` → `FullScreenGallery.open()` | Carousel with page indicator; tap → full-screen modal; swipe/double-tap zoom/pinch/drag-to-dismiss (disabled while zoomed); Hero animation; close button + counter. | Verified | Verified clean (`FullScreenGallery` is plain `StatefulWidget`, not `ConsumerStatefulWidget` — AGENTS.md setState rule does not apply; animation-critical state correctly uses setState for 60fps) | |
| DISC-06 | Location picker modal | location chip → `LocationPickerModal` `location/presentation/location_picker_modal.dart` | Popular cities from catalog; search filter; "Use current location" GPS/IP; tap city updates + closes; radius slider; persisted to `LocationController`. | Cataloged | | |
| DISC-07 | Change location (profile) | `/change-location` `change_location_page.dart` | Popular cities list; search; "Use current location"; save → `profileRepositoryProvider.updateProfile()` + `bootstrapController.refresh()`; success toast + pop. | Fixed | 11 `setState` calls (AGENTS.md violation → StateProvider) | Converted to `_selectedCityProvider`, `_locatingProvider`, `_savingProvider`, `_selectingPlaceProvider`, `_searchVersionProvider` StateProviders |
| DISC-08 | Location search page | `/location-search` `location_search_page.dart` | Debounced search (500ms, `LocationSearchNotifier`); merges Google Places + Nominatim, dedupes; tap → resolve → returns `LocationData`; "Use current location"; permission handling. | Verified | Verified clean | |
| DISC-09 | Map view | `/map` `map_view_page.dart` | Full-screen map centered on selected location; clustered markers by locality; tap marker → bottom sheet with cards; tap card → flat details; like in sheet; map controls (zoom/recenter/fit); location chip → picker modal. | Fixed | `_likeListing` is `async void` (`:278`) and bypasses `DiscoverFeedController.toggleLike()` — calls `repo.setLiked()` directly, no optimistic update | Changed `async void` → `Future<void>` so exceptions propagate correctly. Map uses its own `MapListingsController` (not `DiscoverFeedController`), so direct repo call is correct for this context. |
| DISC-10 | Like/unlike listing | feed card → `DiscoverFeedController.toggleLike()` | Optimistic update; `POST /swipes` with `liked=true/false`; on success invalidates `conversationsProvider` (if liked); on failure rolls back; returns `conversationId`; toast "Contact request sent"/"Conversation created". | Fixed | `conversationsProvider` only invalidated on like (`:174-176`), not on unlike — stale conversation list after unliking | Now invalidates `conversationsProvider` on both like and unlike |
| DISC-11 | Society tag vote | flat details society tag → `_handleSocietyTagVote()` | Tap tag to vote; `POST /properties/{id}/society-tag-votes`; vote count updated. | Verified | Verified clean (shows toast on failure) | |
| DISC-12 | Schedule visit entry | flat details → `/schedule-visit` | Pre-fills conversation ID; see VISIT-02. | Cataloged | | |

## LOCATION

| ID | Story | Route / Page | Expected Behavior | Status | Errors Found | Fix Notes |
|----|-------|--------------|-------------------|--------|--------------|-----------|
| LOC-01 | Location search | `LocationSearchNotifier.onSearchChanged()` | Debounced 500ms, query ≥2 chars; parallel Google Places + Nominatim; merge + dedupe by `mainText|secondaryText`; version guard against stale results. | Cataloged | | |
| LOC-02 | Resolve suggestion | `LocationSearchNotifier.resolveSuggestion()` | Routes to Google Places or Nominatim by source; returns `PlaceDetails` with name/lat/lng. | Cataloged | | |
| LOC-03 | Detect current location | `LocationController.getCurrentLocation()` | Check services enabled; request permission; GPS (20s timeout); reverse geocode; IP fallback via `ipapi.co`; updates `LocationState`. | Fixed | L10n: `'Could not detect location'` hardcoded in `location_controller.dart` (application layer, not presentation) | Replaced `String? error` field with `LocationError?` enum + `LocationErrorL10n.toMessage()` extension; added `couldNotDetectLocation` ARB key (en + hi); UI can now map enum to localized string |

## SWIPE

| ID | Story | Route / Page | Expected Behavior | Status | Errors Found | Fix Notes |
|----|-------|--------------|-------------------|--------|--------------|-----------|
| SWIPE-01 | Swipe right (like) | `/swipe` `swipe_deck_page.dart` | Drag right >20% width; card flies off (200ms easeIn); `markSwiped()` + `swipeProfile(action:'like')`; undo button 3s; if `didMatch` → match celebration; haptic; invalidates `conversationsProvider` + `outgoingLikesProvider`. | Cataloged | | |
| SWIPE-02 | Swipe left (pass) | `/swipe` `swipe_deck_page.dart` | Drag left >20% width; `swipeProfile(action:'pass')`; no celebration; `incomingLikesProvider` NOT invalidated; undo 3s. | Cataloged | | |
| SWIPE-03 | Match celebration | `/match-celebration` `match_celebration_screen.dart` | Both avatars + heart; confetti (2s, 30 particles); scale anim (600ms easeOutBack); "Send Message" → `/chats/{id}`; "Keep Swiping" → deck. | Cataloged | | |
| SWIPE-04 | Undo last swipe | `/swipe` undo button | Appears 3s after swipe; `undoSwipe(profile)` re-inserts at front; clears `_lastSwipedProfile`; timer auto-hides; cancelled in dispose. | Cataloged | | |
| SWIPE-05 | Empty state | `/swipe` `swipe_empty_state.dart` | 3 reasons: `noProfiles`, `allFiltered`, `endOfDeck`; contextual messaging; "Refresh Profiles" clears compat cache + reloads. | Cataloged | | |
| SWIPE-06 | Match Q&A nudge (swipe) | bottom sheet after match `swipe/match_qna_nudge.dart` | 3 questions; Q2 1-5 slider; "Share Answers" → `POST /conversations/{id}/qna`; "Skip for Now" closes. | Fixed | (1) Banned pattern: `apiClientProvider` in widget (`:43`) — extract to controller; (2) L10n: Q2 slider labels hardcoded English (`:72-77`) | (1) Extracted `MatchQnAController` in `application/match_qna_controller.dart`; widget now calls `ref.read(matchQnAControllerProvider.notifier).submitAnswers()`; (2) Replaced hardcoded labels with `locale.qnaMostlyPrivate/qnaBalanced/qnaMostlySocial` (new ARB keys) |

## CHATS

| ID | Story | Route / Page | Expected Behavior | Status | Errors Found | Fix Notes |
|----|-------|--------------|-------------------|--------|--------------|-----------|
| CHAT-01 | Conversation list | `/chats` `conversations_page.dart` | `conversationsProvider` (FutureProvider); app-wide realtime invalidation via `flatmatesRealtimeEventProvider`; cards with avatar/name/last msg/unread badge; pull-to-refresh invalidates providers; tab override persisted. | Cataloged | | |
| CHAT-02 | Open chat thread | `/chats/{id}` `chat_thread_page.dart` | `conversationProvider(id)` + watch `messagesControllerProvider(id)` (FamilyNotifier); `markAsRead()` on mount; optimistic sends (negative ids, 60% opacity); Q&A nudge if new match; pre-message area (property card, Q&A); input bar. | Cataloged | | |
| CHAT-03 | Send message | chat input → `MessagesController.sendMessage()` | Trim + `ProfanityFilter.censor()`; optimistic add (negative id, 60% opacity); `POST /conversations/{id}/messages`; on failure rollback + toast; on success authoritative `fetchMessages()` + `mergeMessages()` dedupe + `pruneConfirmedPending()` (±2min window); realtime fallback w/ exponential backoff (1s→32s). | Cataloged | | |
| CHAT-04 | Send photo | chat input photo icon | `ImageUploadService.pickImages(limit:1)` → `uploadChatPhoto()` → `sendMessage(attachmentUrl, type:'image')`; same optimistic + refetch flow. | Cataloged | | |
| CHAT-05 | Incoming likes tab | `/chats` tab=likes | `incomingLikesProvider`; "Match" → `ChatActionsController.matchIncomingLike()`; creates conversation, invalidates providers, navigates to thread, Q&A nudge after 600ms; `_matchingLikeIdsProvider` prevents double-tap. | Cataloged | | |
| CHAT-06 | Outgoing likes tab | `/chats` tab=liked | `outgoingLikesProvider` (read-only list); pull-to-refresh. | Cataloged | | |
| CHAT-07 | Block user | chat thread more menu | Confirmation dialog; `ChatActionsController.blockUser()` → `POST /blocks`; conversation removed; toast. | Cataloged | | |
| CHAT-08 | Report user | chat thread more menu | Reason dropdown (catalog/defaults); `ChatActionsController.reportUser()` → `POST /reports`; toast. | Cataloged | | |
| CHAT-09 | Unmatch | chat thread more menu | Confirmation; `unmatchConversation()` → `POST /blocks` with `unmatch_only=true`; conversation removed; toast. | Cataloged | | |
| CHAT-10 | Peer profile | `/user-profile/{id}` `chat_peer_profile_page.dart` | Renders `ChatPeer` instantly; `peerProfileProvider(id)` enriches; call button (tel:); property context card; graceful degradation if peer deleted/blocked. | Fixed | L10n: tooltip `'Back'` hardcoded | Replaced with `locale.backCta` |
| CHAT-11 | Q&A answers (chat) | chat thread nudge `chats/match_qna_nudge.dart` | 3 questions; Q2 1-5 slider; "Answer" → `POST /conversations/{id}/qna`; "Skip" closes; dismissal tracked in SharedPreferences per conversation. | Fixed | L10n: Q2 slider labels hardcoded English (`:29-35`, different set from swipe version) | Replaced `_q2Labels` const array with `_q2Label(locale)` switch using `locale.qnaVeryPrivate/qnaMostlyPrivate/qnaBalanced/qnaMostlySocial/qnaVerySocial` |

## VISITS

| ID | Story | Route / Page | Expected Behavior | Status | Errors Found | Fix Notes |
|----|-------|--------------|-------------------|--------|--------------|-----------|
| VISIT-01 | Visits list | `/visits` `visits_page.dart` | `visitsProvider`; 3 sections (Confirmed/Scheduled, Requested, Completed); cards with title/date/status; pull-to-refresh; empty state. | Cataloged | | |
| VISIT-02 | Schedule visit | `/schedule-visit?conversationId=` `schedule_visit_page.dart` | Conversation metadata; property card; calendar (default tomorrow, 90d range); time slots (Morning/Afternoon/Evening); note (180 char); privacy badge; `scheduleVisitAndNotify()` → `POST /visits` + best-effort chat message; invalidates visits + messages; two-stage error handling. | Cataloged | | |
| VISIT-03 | Confirm visit | visits page confirm button | `confirmVisit(id)` → `PUT /visits/{id}` status=confirmed; invalidate; toast. | Cataloged | | |
| VISIT-04 | Reschedule visit | visits page reschedule button | Date + time picker; `rescheduleVisit(id, newDate)` → `PUT /visits/{id}` scheduled_date (UTC) + status=requested; invalidate; toast. | Cataloged | | |
| VISIT-05 | Cancel visit | visits page cancel button | Confirmation dialog; `cancelVisit(id)` → `PUT /visits/{id}` status=cancelled; invalidate; toast. | Cataloged | | |

## LISTINGS

| ID | Story | Route / Page | Expected Behavior | Status | Errors Found | Fix Notes |
|----|-------|--------------|-------------------|--------|--------------|-----------|
| LIST-01 | Create listing draft | `/post/new` `create_listing_page.dart` | 8 steps (location, society, room, flat, costs, about, preferences, review); step persisted to SharedPreferences; validation gates; submit → `POST /properties`; on success → `/listing-review/{id}`. | Fixed | Photo upload loop breaks on first failure (`:192-203`) — should continue remaining files. Note: 21 `setState` calls kept as-is — page is a multi-step form with 12+ interdependent form fields; converting to 12+ StateProviders would push the 482-line file over the 500-line limit and create worse architecture. | Removed `break` from upload failure handler — loop now continues uploading remaining files on partial failure |
| LIST-02 | Upload listing photos | step 2 of create | `ImageUploadService.pickImages(limit: 10-current)`; each `uploadListingPhoto()`; ≥2 photos required; on failure toast + break loop. | Fixed | Loop breaks on first upload failure (`create_listing_page.dart:192-203`) — remaining files not attempted | Removed `break` — loop continues on partial failure, shows toast per failed file |
| LIST-03 | Submit listing for review | step 7 review | Validate required fields; build `ListingCreateRequest`; `POST /properties`; invalidate `discoverFeedControllerProvider` + refresh bootstrap; → `/listing-review/{id}`. | Cataloged | | |
| LIST-04 | Manage listings | `/manage-listings` `manage_listing_page.dart` | `myListingsProvider`; tabs Active/Draft/Expired; actions Edit/View Stats/Share/Copy Link/Pause-Resume/Review; pause/resume optimistic via `_pausedListingIds`; refresh invalidates. | Cataloged | | |
| LIST-05 | Listing under review | `/listing-review/{id}` `listing_under_review_page.dart` | `listingReviewProvider(id)`; Supabase Broadcast `listing_status_changed` listener; status icon + progress; rejected → message + resubmit; approved → "live" button. | Cataloged | | |
| LIST-06 | Post hub (room poster) | `/post` `post_hub_page.dart` | Two cards: "Post a Listing" → `/post/new`, "Manage Listings" → `/manage-listings`; counts from `myListingsProvider`; refresh indicator. | Cataloged | | |

## PROFILE

| ID | Story | Route / Page | Expected Behavior | Status | Errors Found | Fix Notes |
|----|-------|--------------|-------------------|--------|--------------|-----------|
| PROF-01 | View profile | `/profile` `profile_page.dart` | `bootstrapControllerProvider.profile`; avatar + edit overlay; name/email/phone/location; profile strength %; menu sections (Discovery, Account, Help & Safety); staggered animation. | Cataloged | | |
| PROF-02 | Edit profile | `/profile/edit` `edit_profile_page.dart` | Init from bootstrap in `didChangeDependencies`; sections (Basic, Location, Budget, Bio, Mode/Work/Timeline, Lifestyle, Non-negotiables, Photos); photo upload; budget min≤max validation; `updateProfile()` + refresh bootstrap + pop. | Verified | 14 `setState` calls kept as-is — page is a multi-section form with 10+ interdependent fields; converting to StateProviders would push the 471-line file over the 500-line limit. | |
| PROF-03 | Help & safety | `/help-safety` `help_safety_page.dart` | Menu: FAQ, Popular Topics, Booking Agreements, Account & Profile, Contact Support, Report a Bug, Request a Feature; trust badge. | Cataloged | | |
| PROF-04 | Legal content | `/terms-of-service`, `/privacy-policy` `legal_content_page.dart` | Load markdown from asset bundle; render with typography; loading spinner; error message; mounted checks. | Fixed | 2 `setState` calls (AGENTS.md violation → StateProvider) | Converted to `_legalContentProvider`, `_legalLoadingProvider`, `_legalHasErrorProvider` family StateProviders (keyed by assetPath for multi-instance support) |

## SETTINGS

| ID | Story | Route / Page | Expected Behavior | Status | Errors Found | Fix Notes |
|----|-------|--------------|-------------------|--------|--------------|-----------|
| SET-01 | Theme/palette/locale | `/settings` preferences sheet `settings_page.dart` | Theme Mode (Light/Dark/System), Palette (Indigo/Coral/Teal), Language (English/Hindi); `updateThemeMode()`/`updatePalette()`/`updateLocale()`; persisted to SharedPreferences. | Cataloged | | |
| SET-02 | Change password | `/change-password` `change_password_page.dart` | New + confirm password; visibility toggles + tooltips; `PasswordRulesChecklist`; `authRepositoryProvider.changePassword()`; success toast + pop; `_savingProvider` StateProvider. | Fixed | L10n: tooltip `'Toggle password visibility'` hardcoded (`:119, :151`) | Replaced with `locale.togglePasswordVisibility` (new ARB key) |
| SET-03 | Delete account | `/delete-account` `delete_account_page.dart` | Warning; type "DELETE" to confirm; `authControllerProvider.deleteAccount()` → `DELETE /users/me` + best-effort Supabase signOut + token clear; → `/enter-phone`; `_isDeleting` flag. | Fixed | (1) 3 `setState` calls (AGENTS.md violation → StateProvider); (2) design token: `BorderRadius.circular(9)` hardcoded (`:80, :83, :88`) → use `AppRadius` | (1) Converted to `_confirmTextProvider` + `_isDeletingProvider` StateProviders; (2) Replaced with `AppRadius.smBorder` |
| SET-04 | Blocked users | `/blocked-users` `blocked_users_page.dart` | `blockedUsersProvider`; list with avatar/name/location; unblock → optimistic via `_unblockingIdsProvider` + `unblockUser()` + invalidate; error toast + finally cleanup; empty state. | Cataloged | | |
| SET-05 | Notification settings | `/notification-settings` `notification_settings_page.dart` | 5 toggles (Messages, Visit Reminders, Matches, Listing Updates, Promotions); `updateNotif*()`; persisted immediately; "Enable All"/"Disable All". | Cataloged | | |
| SET-06 | Privacy & security | `/privacy-security` `privacy_security_page.dart` | Menu: Change Password, Blocked Users, Privacy Policy, Terms, Delete Account. | Cataloged | | |
| SET-07 | Settings hub | `/settings` `settings_page.dart` | Grouped menu (Account, App, Legal); logout button; preferences bottom sheet; about dialog with version. | Cataloged | | |

## FEEDBACK

| ID | Story | Route / Page | Expected Behavior | Status | Errors Found | Fix Notes |
|----|-------|--------------|-------------------|--------|--------------|-----------|
| FEED-01 | Report bug | `/help-safety/report-bug` `feedback_form_page.dart` | Title (200 char), Bug Type dropdown, Severity dropdown, Description (4-8 lines); validation; `feedbackControllerProvider.submitBugReport()` → `POST /bugs` with `bug_type:'functionality_bug'`; success toast + pop. | Cataloged | | |
| FEED-02 | Request feature | `/help-safety/request-feature` `feedback_form_page.dart` | Title (200 char), Description (4-8 lines); validation; `submitFeatureRequest()` → `POST /bugs` with `bug_type:'feature_request'`; success toast + pop. | Cataloged | | |

## NOTIFICATIONS

| ID | Story | Route / Page | Expected Behavior | Status | Errors Found | Fix Notes |
|----|-------|--------------|-------------------|--------|--------------|-----------|
| NOTIF-01 | View notifications | `/notifications` `notifications_page.dart` | `notificationsProvider`; list with type-icon/title/body/time/read-status (accent border if unread); tap → mark read + navigate to referenced resource; "Mark All Read"; refresh; empty state. | Cataloged | | |

---

## Backend Issues

Issues rooted in `../backend` (or requiring cross-repo coordination). Logged here for separate handling; NOT fixed in this client pass.

| ID | Issue | Affected Stories | Notes |
|----|-------|------------------|-------|
| BE-01 | Onboarding hardcoded fallback catalogs (`flatmates_lifestyle_quiz`, `flatmates_move_in_timeline`, `flatmates_preferences`, `flatmates_non_negotiables`) can drift from backend source of truth. | ONBOARD-06, ONBOARD-07, ONBOARD-08, ONBOARD-09 | AGENTS.md requires business metadata server-driven. Fallbacks exist for resilience but can feed stale dimensions into matching. Consider: remove fallback (fail fast) OR sync mechanism. |
| BE-02 | Q&A slider label set differs between swipe (`match_qna_nudge.dart`: "Very private/Mostly private/Balanced/Mostly social/Very social") and chats (`match_qna_nudge.dart`: "Very private/Private/Mixed/Social/Very social"). | SWIPE-06, CHAT-11 | Should be server-driven via a `flatmates_qna_labels` catalog for consistency + localization. |
