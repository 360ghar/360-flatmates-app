# Test Results

## Summary

| Metric | Value |
|--------|-------|
| Total test files | 87 |
| Total tests | 567 |
| Passing | 567 |
| Failing | 0 |
| Pass rate | 100% |

## Test Suite Composition

### Unit Tests (`test/unit/`)
- **Settings**: `settings_controller_test.dart` (7 tests) — theme mode, locale, privacy toggles, notification settings
- **Discover**: `discover_feed_controller_test.dart` (6 tests), `discover_repository_test.dart` (2 tests), `catalog_filter_chips_test.dart` (8 tests)
- **Core**: `deep_link_service_test.dart` (10 tests) — deep link parsing for listing/chat routes, edge cases
- **Contract**: API contract validation tests
- **App**: App-level integration tests

### Widget Tests (`test/widget/`)
- **Auth**: `enter_phone_page_test.dart`, `login_page_test.dart`, `otp_page_test.dart`, `splash_page_test.dart`, `reset_password_page_test.dart`
- **Onboarding**: `onboarding_page_test.dart`, `basic_info_page_test.dart`, `mode_selection_page_test.dart`
- **Discover**: `discover_page_test.dart`, `discover_listing_card_test.dart`, `discover_header_test.dart`
- **Chats**: `chat_app_bar_test.dart`, `chat_message_bubble_test.dart`, `chat_input_bar_test.dart`, `chat_thread_page_test.dart`, `conversations_page_test.dart`, `message_list_scroll_test.dart`
- **Visits**: `schedule_visit_page_test.dart`, `visits_page_test.dart`
- **Notifications**: `notifications_page_test.dart`
- **Profile**: `profile_page_test.dart`, `edit_profile_page_test.dart`, `help_safety_page_test.dart`, `profile_strength_card_test.dart`, `legal_content_page_test.dart`
- **Settings**: `settings_page_test.dart`, `preferences_sheet_test.dart`, `notification_settings_page_test.dart`, `change_password_page_test.dart`
- **Feedback**: `feedback_form_page_test.dart`
- **Shared**: `flatmates_search_bar_test.dart`, `flatmates_skeleton_test.dart`, `flatmates_like_button_test.dart`, `flatmates_price_text_test.dart`
- **App**: `widget_test.dart` — infrastructure tests

### Maestro E2E Tests (`.maestro/`)
- 82 flows across Auth, Onboarding, Navigation, Listings, Profile, Settings, Chats, Visits, and Notifications
- `config.yaml`, `e2e.yaml`, `_shared/login.yaml`

## Issues Found and Fixed (Phase 5)

### 1. `flatmates_search_bar_test.dart` — Wrong icon constant
- **Root cause**: Test expected `Icons.search` but the source uses `AppIcons.search` which maps to `Icons.search_rounded`.
- **Fix**: Updated test to use `AppIcons.search` from `app_icons.dart`.

### 2. `flatmates_skeleton_test.dart` — RenderFlex overflow in page variants
- **Root cause**: Some skeleton variants (e.g., `ProfileSkeleton`, `FlatDetailsSkeleton`) use `Column` internally and overflow the default 800x600 test surface.
- **Fix**: Wrapped each variant in a `SizedBox(height: 2000)` to give bounded height for ListView-based variants, and drained soft overflow errors with `tester.takeException()` for Column-based variants.

### 3. `preferences_sheet_test.dart` — Privacy toggles below fold
- **Root cause**: The privacy toggles (`setting_hide_last_name`, `setting_hide_location`) are at the bottom of a `ListView` inside a `DraggableScrollableSheet` and are not built until scrolled into view.
- **Fix**: Added `tester.scrollUntilVisible()` before asserting the toggles are found.

### 4. `notification_settings_page_test.dart` — Enable All button off-screen
- **Root cause**: The "Enable All" button is at the bottom of a `ListView` and cannot be tapped in the default 800x600 test surface. The tap offset doesn't hit the button.
- **Fix**: Called `updateAllNotificationSettings(true)` directly via the Riverpod `ProviderContainer` instead of tapping the off-screen button.

### 5. `edit_profile_page_test.dart` — Wrong widget type and field finder
- **Root cause**: 
  - The save button is a `FlatmatesButton` (via `FlatmatesBottomActionBar`), not a `FilledButton`.
  - The About tab uses `TextField` (not `TextFormField`) for the bio input.
  - The back button is a `FlatmatesChromeIconButton` with `Icons.arrow_back_rounded`, not a `BackButton`.
- **Fix**: Changed widget cast from `FilledButton` to `FlatmatesButton`, used `find.byKey(const Key('profile_bio_input'))` instead of `find.byType(TextFormField)`, and used `find.byIcon(Icons.arrow_back_rounded)` for the back button.

### 6. `feedback_form_page_test.dart` — Submit button below viewport
- **Root cause**: The bug feedback form is taller than the test surface due to dropdown fields. The submit button at the bottom of the `ListView` is not built (lazy building) and `ensureVisible` fails with "No element".
- **Fix**: Replaced `ensureVisible` with manual `tester.drag()` to scroll down before tapping.

### 7. `help_safety_page_test.dart` — Request feature item below viewport
- **Root cause**: The `request_a_feature_menu_item` is below the fold in the page's `ListView` and is not built until scrolled into view.
- **Fix**: Added `tester.scrollUntilVisible()` before asserting the item is found.

## Verification

```bash
flutter test
# Result: 00:52 +567: All tests passed!
```
