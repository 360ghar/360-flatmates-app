# 360 FlatMates — Canonical User Stories

> **Source of truth** for every user-facing behavior in the app.
> Each row is a testable user story with its expected behavior, linked Maestro flow, and Flutter test.
> Status: `PASS` | `FAIL` | `PENDING` | `N/A` (native-only)

---

## AUTH

| ID | User Story | Expected Behavior | Maestro Flow | Flutter Test | Status |
|----|-----------|-------------------|--------------|-------------|--------|
| AUTH-01 | User enters phone number and continues | Phone input accepts 10-digit Indian numbers, normalizes to +91, terms checkbox gates CTA, routes to login or OTP | auth/01_login_phone | unit/auth/auth_controller_test | PASS |
| AUTH-02 | User enters email and continues | Email detected via @, routes to login or OTP | auth/01_login_phone | unit/auth/auth_controller_test | PASS |
| AUTH-03 | User logs in with phone + password | Pre-filled phone, password field, visibility toggle, submit → bootstrap → discover | auth/01_login_phone | widget/auth/login_page_test | PASS |
| AUTH-04 | User signs up via OTP | Enter phone → OTP screen → enter 6-digit code → set-password → discover | auth/03_signup_otp | widget/auth/otp_page_test | PASS |
| AUTH-05 | User requests forgot password | Enter phone/email → send OTP → reset-password page | auth/04_forgot_password | widget/auth/forgot_password_page_test | PASS |
| AUTH-06 | User resets password via OTP | Enter OTP + new password → submit → discover | auth/04_forgot_password | widget/auth/reset_password_page_test | PASS |
| AUTH-07 | User sets mandatory password after OTP | Set-password page shown, cannot skip (PopScope), password policy validation, confirm match | auth/05_set_password | widget/auth/set_password_page_test | PASS |
| AUTH-08 | User skips post-social add-phone | Add-phone page shown after Google/Apple sign-in, skip button proceeds to app | auth/06_add_phone | widget/auth/add_phone_page_test | PASS |
| AUTH-09 | User logs out | Profile → logout button → confirmation dialog → enter-phone screen | auth/07_logout | widget/auth/splash_page_test | PASS |
| AUTH-10 | Splash page handles auth check | Shows spinner during auth check, routes to enter-phone or discover | N/A | widget/auth/splash_page_test | PASS |
| AUTH-11 | Invalid credentials show error | Wrong password → error message displayed, not crashed | auth/01_login_phone | unit/auth/auth_controller_test | PASS |
| AUTH-12 | OTP resend with countdown | Resend button disabled for 30s, then enabled | auth/03_signup_otp | widget/auth/otp_page_test | PASS |
| AUTH-13 | Terms checkbox gates continue | Continue CTA disabled until terms accepted | auth/01_login_phone | widget/auth/enter_phone_page_test | PASS |

## ONBOARDING

| ID | User Story | Expected Behavior | Maestro Flow | Flutter Test | Status |
|----|-----------|-------------------|--------------|-------------|--------|
| ONB-01 | User navigates splash carousel | 4 pages with next/skip/get-started, progress dots | onboarding/01_splash_carousel | widget/onboarding/onboarding_page_test | PASS |
| ONB-02 | User selects mode (co-hunter) | 3 mode options, select → continue → location page | onboarding/02_mode_selection | widget/onboarding/mode_selection_page_test | PASS |
| ONB-03 | User selects mode (room-poster) | Selecting room_poster shows Post tab instead of Explore | onboarding/02_mode_selection | widget/onboarding/mode_selection_page_test | PASS |
| ONB-04 | User selects location | Popular cities list, search, use current location, select → basic info | onboarding/03_location_selection | widget/onboarding/location_selection_page_test | PASS |
| ONB-05 | User enters basic info | Name, age (18-100), profession, city, locality — next disabled until valid | onboarding/04_basic_info | widget/onboarding/basic_info_page_test | PASS |
| ONB-06 | User skips profile photo | Skip button proceeds to lifestyle quiz | onboarding/05_profile_photo | widget/onboarding/profile_photo_page_test | PASS |
| ONB-07 | User answers lifestyle quiz | Catalog-driven questions, all must be answered to proceed | onboarding/06_lifestyle_quiz | widget/onboarding/lifestyle_quiz_page_test | PASS |
| ONB-08 | User sets budget and timeline | Budget range slider (5k-100k), timeline chips, min <= max validation | onboarding/07_budget_timeline | widget/onboarding/budget_timeline_page_test | PASS |
| ONB-09 | User sets preferences | Catalog-driven preference chips, select → next | onboarding/08_preferences | widget/onboarding/preferences_page_test | PASS |
| ONB-10 | User selects non-negotiables | Multi-select deal-breakers, submit → onboarding complete → discover | onboarding/09_non_negotiables | widget/onboarding/non_negotiables_page_test | PASS |
| ONB-11 | Onboarding completion banner shows | Banner in app shell when onboarding incomplete, tap CTA → resume | onboarding/10_completion_banner | widget/onboarding/onboarding_page_test | PASS |
| ONB-12 | Draft persistence restores progress | Saved draft restored on app relaunch, "Welcome back" message | N/A | unit/onboarding/onboarding_controller_test | PASS |
| ONB-13 | System back navigates onboarding steps | Back gesture steps backwards, stops at mode selection | N/A | unit/onboarding/onboarding_controller_test | PASS |

## NAVIGATION

| ID | User Story | Expected Behavior | Maestro Flow | Flutter Test | Status |
|----|-----------|-------------------|--------------|-------------|--------|
| NAV-01 | Co-hunter sees 5 tabs | Home, Explore, Swipe, Likes&Chat, Profile | navigation/01_tabs_co_hunter | widget/app/app_shell_test | PASS |
| NAV-02 | Room-poster sees 5 tabs | Home, Post, Swipe, Likes&Chat, Profile | navigation/02_tabs_room_poster | widget/app/app_shell_test | PASS |
| NAV-03 | User switches between tabs | Each tab navigates to its branch, content loads | navigation/01_tabs_co_hunter | widget/app/app_shell_test | PASS |
| NAV-04 | Deep link to listing opens flat details | /flatmates/listing/{id} → flat-details page | navigation/03_deep_link_listing | widget/app/app_router_test | PASS |
| NAV-05 | Deep link to chat opens thread | /flatmates/chat/{id} → chat thread page | navigation/04_deep_link_chat | widget/app/app_router_test | PASS |
| NAV-06 | Auth redirect chain works | Unauthenticated → enter-phone, authenticated → discover | N/A | widget/app/app_router_test | PASS |
| NAV-07 | Onboarding soft gate blocks swipe/post/chats | Blocked routes redirect to /onboarding, allowed routes pass | N/A | widget/app/app_router_test | PASS |

## DISCOVER

| ID | User Story | Expected Behavior | Maestro Flow | Flutter Test | Status |
|----|-----------|-------------------|--------------|-------------|--------|
| DIS-01 | Home feed loads with greeting | Greeting with first name, location chip, search bar, picked-for-you grid | discover/01_home_feed | widget/discover/discover_page_test | PASS |
| DIS-02 | User scrolls home feed | Feed scrolls up/down, cards animate in | discover/01_home_feed | widget/discover/discover_page_test | PASS |
| DIS-03 | User opens flat details from feed | Tap card → flat-details page with carousel, contact button | discover/03_flat_details | widget/discover/flat_details_page_test | PASS |
| DIS-04 | User opens browse listings | "See all" → browse-listings page with search and filter | discover/02_browse_listings | widget/discover/browse_listings_page_test | PASS |
| DIS-05 | User searches in browse listings | Search bar expands, debounced query, results update | discover/02_browse_listings | widget/discover/browse_listings_page_test | PASS |
| DIS-06 | User applies search filters | Filter sheet opens, apply room type + furnishing, show results | discover/06_search_filters | widget/discover/filter_sheet_test | PASS |
| DIS-07 | User clears all filters | Clear button resets all filters | discover/07_search_filters_clear | widget/discover/filter_sheet_test | PASS |
| DIS-08 | User likes a listing from feed | Heart toggle, optimistic update, toast on success/failure | discover/08_like_listing | unit/discover/discover_feed_controller_test | PASS |
| DIS-09 | User likes from flat details | Shortlist button toggles like state | discover/03_flat_details | widget/discover/flat_details_page_test | PASS |
| DIS-10 | User shares a listing | Share button → share sheet with link | discover/05_flat_details_share | widget/discover/flat_details_page_test | PASS |
| DIS-11 | User changes location | Location chip → change-location page → save → feed updates | discover/09_change_location | widget/discover/discover_page_test | PASS |
| DIS-12 | Image carousel in flat details | Swipe through images, dots indicator, back button | discover/04_flat_details_carousel | widget/discover/flat_details_page_test | PASS |
| DIS-13 | Full-screen gallery | Tap image → full-screen gallery, swipe, double-tap zoom, close | discover/04_flat_details_carousel | widget/discover/full_screen_gallery_test | PASS |
| DIS-14 | Empty feed state | No listings → empty state with icon and message | N/A | widget/discover/discover_page_test | PASS |
| DIS-15 | Feed error state with retry | Network error → error state with retry button | N/A | widget/discover/discover_page_test | PASS |
| DIS-16 | Contact button on flat details | Contact → ensures liked → navigates to chat | discover/03_flat_details | widget/discover/flat_details_page_test | PASS |

## MAP

| ID | User Story | Expected Behavior | Maestro Flow | Flutter Test | Status |
|----|-----------|-------------------|--------------|-------------|--------|
| MAP-01 | Map view loads with markers | Map renders, listing markers visible, bottom sheet carousel | map/01_map_view | widget/discover/map_view_page_test | PASS |
| MAP-02 | User taps marker → card selected | Marker tap selects corresponding card in carousel | map/02_map_carousel | widget/discover/map_view_page_test | PASS |
| MAP-03 | User taps card → flat details | Card tap navigates to flat-details page | map/02_map_carousel | widget/discover/map_view_page_test | PASS |
| MAP-04 | User likes from map card | Like button on map carousel card | map/02_map_carousel | unit/discover/map_listings_controller_test | PASS |
| MAP-05 | Map filter applies | Filter button opens filter sheet, results update on map | map/03_map_filter | widget/discover/map_view_page_test | PASS |
| MAP-06 | Map empty state | No listings in area → overlay with message | N/A | widget/discover/map_view_page_test | PASS |

## SWIPE

| ID | User Story | Expected Behavior | Maestro Flow | Flutter Test | Status |
|----|-----------|-------------------|--------------|-------------|--------|
| SWP-01 | Swipe deck loads profiles | Card stack visible, foreground card opaque, next/third preloaded | swipe/01_swipe_deck_load | widget/swipe/swipe_deck_page_test | PASS |
| SWP-02 | User swipes right (like) | Card flies right, next card promotes, haptic feedback | swipe/02_swipe_like | widget/swipe/swipe_card_stack_test | PASS |
| SWP-03 | User swipes left (pass) | Card flies left, next card promotes | swipe/03_swipe_pass | widget/swipe/swipe_card_stack_test | PASS |
| SWP-04 | User undoes last swipe | Undo button restores last card (only if not persisted) | swipe/04_swipe_undo | unit/swipe/swipe_deck_controller_test | PASS |
| SWP-05 | Action bar buttons work | Skip/like buttons trigger same as swipe gestures | swipe/05_swipe_action_buttons | widget/swipe/swipe_action_bar_test | PASS |
| SWP-06 | End of deck empty state | All profiles seen → "You've seen everyone" message | swipe/06_swipe_empty_state | widget/swipe/swipe_deck_page_test | PASS |
| SWP-07 | Match celebration shows | Like → match → celebration screen with both photos | swipe/07_match_celebration | widget/swipe/match_celebration_test | PASS |
| SWP-08 | Match → open chat | "Send message" button → chat thread | swipe/07_match_celebration | widget/swipe/match_celebration_test | PASS |
| SWP-09 | Match → keep swiping | "Keep swiping" button → closes celebration, next card | swipe/07_match_celebration | widget/swipe/match_celebration_test | PASS |
| SWP-10 | Swipe filter opens | Filter button → filter sheet, filters shared with discover | swipe/08_swipe_filter | widget/swipe/swipe_deck_page_test | PASS |
| SWP-11 | Deal-breaker filtering | Non-negotiables filter out incompatible profiles | N/A | unit/swipe/swipe_deal_breaker_test | PASS |
| SWP-12 | Profile view tracking | Duration and scroll depth recorded on card view | N/A | unit/swipe/swipe_repository_test | PASS |

## CHATS

| ID | User Story | Expected Behavior | Maestro Flow | Flutter Test | Status |
|----|-----------|-------------------|--------------|-------------|--------|
| CHT-01 | Conversations hub shows 3 tabs | Chats, Likes You, You Liked tabs | chats/01_conversations_tabs | widget/chats/conversations_page_test | PASS |
| CHT-02 | User switches between chat tabs | Tab switch loads correct list | chats/01_conversations_tabs | widget/chats/conversations_page_test | PASS |
| CHT-03 | User opens a conversation | Tap conversation card → chat thread with messages | chats/02_open_chat | widget/chats/chat_thread_page_test | PASS |
| CHT-04 | User sends a text message | Type in input → send → message appears optimistically | chats/03_send_message | unit/chats/messages_controller_test | PASS |
| CHT-05 | User toggles emoji picker | Emoji button → emoji picker shows → select emoji → inserted | chats/04_emoji_picker | widget/chats/chat_input_bar_test | PASS |
| CHT-06 | User views peer profile from chat | Tap peer header → peer profile page with compatibility | chats/05_peer_profile | widget/chats/chat_peer_profile_page_test | PASS |
| CHT-07 | User blocks peer from chat | More menu → block → confirmation → back to conversations | chats/06_block_user | unit/chats/chat_actions_controller_test | PASS |
| CHT-08 | User reports peer from chat | More menu → report → reason → submit | chats/07_report_user | unit/chats/chat_actions_controller_test | PASS |
| CHT-09 | User unmatches conversation | More menu → unmatch → confirmation → back to conversations | chats/08_unmatch | unit/chats/chat_actions_controller_test | PASS |
| CHT-10 | Q&A nudge sheet shows after match | New match → Q&A nudge bottom sheet with icebreaker questions | chats/09_qna_nudge | unit/chats/chat_actions_controller_test | PASS |
| CHT-11 | User matches incoming like | Likes You tab → match button → creates conversation → chat | chats/10_match_incoming_like | unit/chats/chat_actions_controller_test | PASS |
| CHT-12 | Messages load via realtime | Supabase realtime updates message list | N/A | unit/chats/messages_controller_test | PASS |
| CHT-13 | Load older messages (pagination) | Scroll to top → loads older messages via keyset pagination | N/A | unit/chats/messages_controller_test | PASS |
| CHT-14 | Empty conversations state | No conversations → empty state with icon | N/A | widget/chats/conversations_page_test | PASS |
| CHT-15 | Mark conversation as read | Opening thread marks messages as read | N/A | unit/chats/messages_controller_test | PASS |

## VISITS

| ID | User Story | Expected Behavior | Maestro Flow | Flutter Test | Status |
|----|-----------|-------------------|--------------|-------------|--------|
| VIS-01 | User views visits list | Profile → Visits → list with Confirmed/Requested/Past sections | visits/01_visits_list | widget/visits/visits_page_test | PASS |
| VIS-02 | User schedules a visit from chat | Chat header → schedule visit → date picker → time slot → note → send | visits/02_schedule_visit | widget/visits/schedule_visit_page_test | PASS |
| VIS-03 | User confirms a visit | Visit card → confirm chip → status updates | visits/03_confirm_visit | unit/visits/visits_actions_controller_test | PASS |
| VIS-04 | User cancels a visit | Visit card → cancel → confirmation dialog → status updates | visits/04_cancel_visit | unit/visits/visits_actions_controller_test | PASS |
| VIS-05 | User reschedules a visit | Confirmed visit → reschedule → date/time picker → new time | visits/05_reschedule_visit | unit/visits/visits_actions_controller_test | PASS |
| VIS-06 | Empty visits state | No visits → "No visits scheduled yet" with calendar icon | N/A | widget/visits/visits_page_test | PASS |
| VIS-07 | Past date rejected | Date picker rejects dates before today | N/A | widget/visits/schedule_visit_page_test | PASS |

## LISTINGS

| ID | User Story | Expected Behavior | Maestro Flow | Flutter Test | Status |
|----|-----------|-------------------|--------------|-------------|--------|
| LST-01 | Room-poster sees post hub | Post tab → hub with Post New Listing + Manage Listings cards | listings/01_post_hub | widget/listings/post_hub_page_test | PASS |
| LST-02 | User starts create listing | Post card → create listing → step 0: location form | listings/02_create_listing_step0 | widget/listings/create_listing_page_test | PASS |
| LST-03 | Create listing: flat/room/photos steps | Steps 1-3: flat details, room details, photo upload | listings/03_create_listing_steps1_3 | widget/listings/create_listing_page_test | PASS |
| LST-04 | Create listing: costs/about/society/publish | Steps 4-7: rent, about, society tags, review, publish | listings/04_create_listing_steps4_7 | widget/listings/create_listing_page_test | PASS |
| LST-05 | User manages listings | Manage card → tabbed view (Active/Drafts/Expired) | listings/05_manage_listings | widget/listings/manage_listing_page_test | PASS |
| LST-06 | User pauses a listing | Pause toggle → optimistic update, rollback on failure | listings/06_pause_listing | unit/listings/manage_listings_controller_test | PASS |
| LST-07 | Listing under review page | Under-review listing → review page with status | listings/07_listing_under_review | widget/listings/create_listing_page_test | PASS |
| LST-08 | Empty listings state | No listings → empty state with "Post a listing" CTA | N/A | widget/listings/manage_listing_page_test | PASS |
| LST-09 | Step validation prevents advance | Required fields missing → next button disabled | N/A | widget/listings/create_listing_page_test | PASS |

## PROFILE

| ID | User Story | Expected Behavior | Maestro Flow | Flutter Test | Status |
|----|-----------|-------------------|--------------|-------------|--------|
| PRO-01 | User views profile page | Avatar, name, email/phone, location, profile strength card, menu groups | profile/01_profile_view | widget/profile/profile_page_test | PASS |
| PRO-02 | User edits profile | Edit button → 4 tabs (Identity, Preferences, Lifestyle, About) | profile/02_edit_profile | widget/profile/edit_profile_page_test | PASS |
| PRO-03 | User saves profile edits | Save button → invalidates bootstrap → returns to profile | profile/02_edit_profile | widget/profile/edit_profile_page_test | PASS |
| PRO-04 | Profile strength card shows percentage | Card displays completion %, tap → edit profile | profile/03_profile_strength | widget/profile/profile_strength_card_test | PASS |
| PRO-05 | User views help & safety | Help menu item → topics list (FAQ, Popular, Bookings, Account, Contact) | profile/04_help_safety | widget/profile/help_safety_page_test | PASS |
| PRO-06 | User reports a bug | Help → report bug → feedback form → submit | profile/05_feedback_bug | widget/feedback/feedback_form_page_test | PASS |
| PRO-07 | User requests a feature | Help → request feature → feedback form → submit | profile/06_feedback_feature | widget/feedback/feedback_form_page_test | PASS |
| PRO-08 | Discard unsaved edits | Back with dirty form → discard confirmation dialog | N/A | widget/profile/edit_profile_page_test | PASS |
| PRO-09 | Budget validation in edit | Min budget > max budget → error toast | N/A | widget/profile/edit_profile_page_test | PASS |
| PRO-10 | Name masking with privacy setting | Hide last name → name shows first name only | N/A | widget/profile/profile_page_test | PASS |

## SETTINGS

| ID | User Story | Expected Behavior | Maestro Flow | Flutter Test | Status |
|----|-----------|-------------------|--------------|-------------|--------|
| SET-01 | User opens settings page | Account group, App group, Legal group, Logout button | settings/01_settings_page | widget/settings/settings_page_test | PASS |
| SET-02 | User switches theme to dark | Preferences sheet → dark option → theme changes | settings/02_preferences_theme | widget/settings/preferences_sheet_test | PASS |
| SET-03 | User switches theme to light | Preferences sheet → light option → theme changes | settings/02_preferences_theme | widget/settings/preferences_sheet_test | PASS |
| SET-04 | User switches language to Hindi | Preferences sheet → Hindi → UI strings update | settings/03_preferences_language | widget/settings/preferences_sheet_test | PASS |
| SET-05 | User toggles hide last name | Privacy toggle → name masked in profile | settings/04_preferences_privacy | unit/settings/settings_controller_test | PASS |
| SET-06 | User toggles hide location | Privacy toggle → location masked in profile | settings/04_preferences_privacy | unit/settings/settings_controller_test | PASS |
| SET-07 | User changes notification settings | 5 toggles, enable/disable all buttons | settings/05_notification_settings | widget/settings/notification_settings_page_test | PASS |
| SET-08 | User changes password | New password + confirm → policy validation → success toast | settings/06_change_password | widget/settings/change_password_page_test | PASS |
| SET-09 | User deletes account | Type DELETE → confirm dialog → account deleted → enter-phone | settings/07_delete_account | widget/settings/delete_account_page_test | PASS |
| SET-10 | User views blocked users | Blocked users list → unblock with confirmation | settings/08_blocked_users | widget/settings/blocked_users_page_test | PASS |
| SET-11 | User views privacy policy | Legal page renders markdown from assets | settings/09_legal_pages | widget/profile/legal_content_page_test | PASS |
| SET-12 | User views terms of service | Legal page renders markdown from assets | settings/09_legal_pages | widget/profile/legal_content_page_test | PASS |
| SET-13 | Empty blocked users state | No blocked users → empty state with icon | N/A | widget/settings/blocked_users_page_test | PASS |

## NOTIFICATIONS

| ID | User Story | Expected Behavior | Maestro Flow | Flutter Test | Status |
|----|-----------|-------------------|--------------|-------------|--------|
| NOT-01 | User views notifications list | Full-screen list, pull-to-refresh, auto-load more | notifications/01_notifications_list | widget/notifications/notifications_page_test | PASS |
| NOT-02 | User marks all as read | Mark all read button → all notifications marked read | notifications/02_mark_all_read | unit/notifications/notifications_actions_controller_test | PASS |
| NOT-03 | User taps a notification | Marks read, navigates to relevant page (chat/flat-details/visits) | notifications/03_tap_notification | widget/notifications/notifications_page_test | PASS |
| NOT-04 | Empty notifications state | No notifications → "No notifications yet" with bell icon | N/A | widget/notifications/notifications_page_test | PASS |

## BOOTSTRAP / CORE

| ID | User Story | Expected Behavior | Maestro Flow | Flutter Test | Status |
|----|-----------|-------------------|--------------|-------------|--------|
| BST-01 | Bootstrap loads on auth | Profile + catalogs + counts fetched after login | N/A | unit/bootstrap/bootstrap_controller_test | PASS |
| BST-02 | Bootstrap refresh retains value | Refresh keeps previous data during fetch (no flicker) | N/A | unit/bootstrap/bootstrap_controller_test | PASS |
| BST-03 | Bootstrap doesn't fetch when logged out | No API call when unauthenticated | N/A | unit/bootstrap/bootstrap_controller_test | PASS |
| BST-04 | Auth stage gates redirect | identifierVerification → enter-phone, profileCompletion → complete-profile, appOnboarding → onboarding | N/A | widget/app/app_router_test | PASS |
| BST-05 | Offline banner shows | No connectivity → OfflineBanner overlay above app | N/A | widget/app/app_shell_test | PASS |
| BST-06 | Compatibility scoring | 6-dimension weighted scoring produces correct percentages | N/A | unit/core/compatibility_test | PASS |
| BST-07 | Error handling maps DioException → AppFailure | Network/server/auth/permission/not-found/validation/rate-limit/conflict/upload | N/A | unit/core/app_failure_test | PASS |
| BST-08 | Deep link service parses paths | /flatmates/listing/{id} and /flatmates/chat/{id} parsed correctly | N/A | unit/core/deep_link_service_test | PASS |

---

## Summary Statistics

| Feature | Total Stories | PASS | FAIL | PENDING | N/A |
|---------|--------------|------|------|---------|-----|
| AUTH | 13 | 13 | 0 | 0 | 0 |
| ONBOARDING | 13 | 13 | 0 | 0 | 0 |
| NAVIGATION | 7 | 7 | 0 | 0 | 0 |
| DISCOVER | 16 | 16 | 0 | 0 | 0 |
| MAP | 6 | 6 | 0 | 0 | 0 |
| SWIPE | 12 | 12 | 0 | 0 | 0 |
| CHATS | 15 | 15 | 0 | 0 | 0 |
| VISITS | 7 | 7 | 0 | 0 | 0 |
| LISTINGS | 9 | 9 | 0 | 0 | 0 |
| PROFILE | 10 | 10 | 0 | 0 | 0 |
| SETTINGS | 13 | 13 | 0 | 0 | 0 |
| NOTIFICATIONS | 4 | 4 | 0 | 0 | 0 |
| BOOTSTRAP/CORE | 8 | 8 | 0 | 0 | 0 |
| **Total** | **133** | **133** | **0** | **0** | **0** |
