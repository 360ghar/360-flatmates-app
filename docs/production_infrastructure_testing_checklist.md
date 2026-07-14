# Production Infrastructure Testing Checklist

## Prerequisites

- [ ] Firebase project `flatmates-a5291` is active
- [ ] Android `google-services.json` is present at `android/app/`
- [ ] iOS `GoogleService-Info.plist` is present at `ios/Runner/`
- [ ] Supabase project is running and accessible
- [ ] Backend API is deployed and reachable
- [ ] Supabase Edge Function `send-notification` is deployed with env vars:
  - `FIREBASE_PROJECT_ID`
  - `FIREBASE_SERVICE_ACCOUNT_JSON`
  - `SUPABASE_URL`
  - `SUPABASE_SERVICE_ROLE_KEY`
- [ ] `app_config` table has rows for both `android` and `ios` platforms
- [ ] `device_tokens` table exists with RLS policies applied
- [ ] `flutter pub get` completes without errors
- [ ] `flutter analyze` is clean

---

## 1. Fresh Install

| Step | Android | iOS |
|------|---------|-----|
| Uninstall any existing app | [ ] | [ ] |
| Clean build (`flutter clean && flutter pub get`) | [ ] | [ ] |
| Install and launch app | [ ] | [ ] |
| App opens without crash | [ ] | [ ] |
| Splash → Login screen appears | [ ] | [ ] |
| No raw/technical errors shown | [ ] | [ ] |

---

## 2. Logged Out User

| Step | Expected | Android | iOS |
|------|----------|---------|-----|
| App launches to login | Login screen | [ ] | [ ] |
| No notification permission prompt yet | No dialog | [ ] | [ ] |
| App config fetch happens in background | No UI block | [ ] | [ ] |
| Offline banner shows when no internet | Red banner | [ ] | [ ] |

---

## 3. Logged In User

| Step | Expected | Android | iOS |
|------|----------|---------|-----|
| Login with valid OTP/password | Success → onboarding or home | [ ] | [ ] |
| Notification permission prompt appears | System dialog | [ ] | [ ] |
| FCM token sent to backend | 200 response | [ ] | [ ] |
| `device_tokens` table has new row | Verify in Supabase | [ ] | [ ] |
| Analytics `login` event fires | Firebase console | [ ] | [ ] |
| Analytics `app_open` event fires | Firebase console | [ ] | [ ] |

---

## 4. Notification Permission — Allowed

| Step | Expected | Android | iOS |
|------|----------|---------|-----|
| Permission granted | `authorized` status | [ ] | [ ] |
| Token registered to backend | `device_tokens` row | [ ] | [ ] |
| Foreground notifications show | Local notification | [ ] | [ ] |
| Background notifications show | System notification | [ ] | [ ] |
| Terminated notification opens app | App opens to correct screen | [ ] | [ ] |

---

## 5. Notification Permission — Denied

| Step | Expected | Android | iOS |
|------|----------|---------|-----|
| Permission denied | `denied` status logged | [ ] | [ ] |
| App continues normally | No crash | [ ] | [ ] |
| Permission not requested again | Single prompt only | [ ] | [ ] |
| User can enable in settings | OS settings path | [ ] | [ ] |
| No FCM token registered | No `device_tokens` row | [ ] | [ ] |

---

## 6. Foreground Notification

| Step | Expected | Android | iOS |
|------|----------|---------|-----|
| Send test notification while app is open | Local notification appears | [ ] | [ ] |
| Notification has correct title/body | Matches payload | [ ] | [ ] |
| Tap notification → navigates to correct screen | Deep link works | [ ] | [ ] |
| Analytics `notification_received` fires | Firebase console | [ ] | [ ] |

---

## 7. Background Notification

| Step | Expected | Android | iOS |
|------|----------|---------|-----|
| Send test notification while app is backgrounded | System notification appears | [ ] | [ ] |
| Notification has correct title/body | Matches payload | [ ] | [ ] |
| Tap notification → app opens to correct screen | Deep link works | [ ] | [ ] |
| Analytics `notification_opened` fires | Firebase console | [ ] | [ ] |

---

## 8. Terminated Notification

| Step | Expected | Android | iOS |
|------|----------|---------|-----|
| Force-close the app | App not in recents | [ ] | [ ] |
| Send test notification | System notification appears | [ ] | [ ] |
| Tap notification → app launches | Cold start | [ ] | [ ] |
| App navigates to correct screen after bootstrap | Deep link consumed | [ ] | [ ] |
| No crash on malformed payload | Graceful handling | [ ] | [ ] |

---

## 9. Notification Deep Link

| Step | Expected | Android | iOS |
|------|----------|---------|-----|
| Notification with `route` in data | Navigates to route | [ ] | [ ] |
| Notification without `route` | Opens app normally | [ ] | [ ] |
| Invalid/malformed `route` | No crash, safe fallback | [ ] | [ ] |
| Deep link when not logged in | Redirects to login, then continues | [ ] | [ ] |
| External deep link (`the360ghar.com/flatmates/...`) | App opens if installed | [ ] | [ ] |

---

## 10. Force Update (Old Version)

| Step | Expected | Android | iOS |
|------|----------|---------|-----|
| Set `minimum_required_version` > app version in `app_config` | — | [ ] | [ ] |
| Launch app | Force update screen shown | [ ] | [ ] |
| Screen is non-dismissible | `PopScope(canPop: false)` | [ ] | [ ] |
| Update button opens store | Play Store / App Store | [ ] | [ ] |
| Analytics `force_update_shown` fires | Firebase console | [ ] | [ ] |

---

## 11. Optional Update

| Step | Expected | Android | iOS |
|------|----------|---------|-----|
| Set `latest_version` > app version, `minimum` <= app version | — | [ ] | [ ] |
| Launch app | Optional update dialog shown | [ ] | [ ] |
| "Later" dismisses dialog | Dialog closes | [ ] | [ ] |
| Dismissed version not shown again | No repeat prompt | [ ] | [ ] |
| "Update now" opens store | Play Store / App Store | [ ] | [ ] |
| Analytics `optional_update_shown` fires | Firebase console | [ ] | [ ] |

---

## 12. Maintenance Mode

> **Not implemented in the Flutter client (v1.0.x).** Force/optional update
> screens cover version gating. A dedicated maintenance-mode screen requires a
> backend flag + client screen — track as a follow-up before claiming this
> checklist item. Leave unchecked until shipped.

| Step | Expected | Android | iOS |
|------|----------|---------|-----|
| Maintenance mode screen | Deferred — not in app yet | N/A | N/A |

---

## 13. No Internet

| Step | Expected | Android | iOS |
|------|----------|---------|-----|
| Turn off network | — | [ ] | [ ] |
| Launch app | Offline banner shown | [ ] | [ ] |
| App config fetch fails gracefully | No crash | [ ] | [ ] |
| App continues with cached/local state | Usable | [ ] | [ ] |
| Turn network back on | Banner disappears | [ ] | [ ] |
| App config re-fetched | Config applied | [ ] | [ ] |

---

## 14. Supabase Session Restore

| Step | Expected | Android | iOS |
|------|----------|---------|-----|
| Login, close app, reopen | Session restored | [ ] | [ ] |
| No re-login required | Auto-authenticated | [ ] | [ ] |
| FCM token re-registered | `device_tokens` updated | [ ] | [ ] |
| Notification service re-initialized | Foreground messages work | [ ] | [ ] |
| SSE reconnected | Real-time events work | [ ] | [ ] |

---

## 15. FCM Token Refresh

| Step | Expected | Android | iOS |
|------|----------|---------|-----|
| Token refreshes (simulate or wait) | `onTokenRefresh` fires | [ ] | [ ] |
| New token sent to backend | `device_tokens` updated | [ ] | [ ] |
| Old token still works until replaced | No gap in delivery | [ ] | [ ] |
| Logout clears token | `device_tokens` deleted | [ ] | [ ] |

---

## 16. Android Physical Device

| Step | Expected | Status |
|------|----------|--------|
| App installs via APK/Play Store | — | [ ] |
| POST_NOTIFICATIONS permission works | Android 13+ | [ ] |
| Firebase initializes | No errors in logcat | [ ] |
| All notification states work | Foreground/background/terminated | [ ] |
| Deep links work | App links + custom scheme | [ ] |
| Crashlytics reports errors | Firebase console | [ ] |

---

## 17. iOS Physical Device

| Step | Expected | Status |
|------|----------|--------|
| App installs via TestFlight/App Store | — | [ ] |
| Notification permission works | iOS system dialog | [ ] |
| Firebase initializes | No errors in Xcode console | [ ] |
| All notification states work | Foreground/background/terminated | [ ] |
| Deep links work | Universal links + custom scheme | [ ] |
| Crashlytics reports errors | Firebase console | [ ] |
| Background fetch works | `UIBackgroundModes` configured | [ ] |

---

## 18. Crashlytics Verification

| Step | Expected | Android | iOS |
|------|----------|---------|-----|
| Force a crash (test crash) | Appears in Firebase console | [ ] | [ ] |
| Custom keys present | `app_version`, `platform`, `build_number` | [ ] | [ ] |
| User ID set after login | `setUserId` called | [ ] | [ ] |
| No sensitive data in crash reports | PII not logged | [ ] | [ ] |
| Config fetch errors logged | Non-fatal errors | [ ] | [ ] |

---

## 19. Analytics Verification

| Event | Trigger | Android | iOS |
|-------|---------|---------|-----|
| `app_open` | App launch | [ ] | [ ] |
| `auth_completed` | Login success | [ ] | [ ] |
| `onboarding_completed` | Onboarding finish | [ ] | [ ] |
| `user_signed_out` | Logout | [ ] | [ ] |
| `notification_received` | Foreground notification | [ ] | [ ] |
| `notification_opened` | Notification tap | [ ] | [ ] |
| `force_update_shown` | Force update screen | [ ] | [ ] |
| `optional_update_shown` | Optional update dialog | [ ] | [ ] |
| `maintenance_screen_shown` | Maintenance screen | [ ] | [ ] |

---

## 20. RLS Policy Verification

Run these SQL queries in Supabase SQL Editor to verify:

```sql
-- app_config: anyone can read
SELECT count(*) FROM app_config; -- Should return 2 rows without auth

-- device_tokens: user can only see own tokens
-- (Test with authenticated user session)
SELECT count(*) FROM device_tokens WHERE user_id = auth.uid();

-- device_tokens: user cannot see other users' tokens
-- (Test with different user session)
```

| Policy | Expected | Status |
|--------|----------|--------|
| `app_config_select_public` | Unauthenticated SELECT works | [ ] |
| `app_config_insert_admin` | Normal user INSERT fails | [ ] |
| `app_config_update_admin` | Normal user UPDATE fails | [ ] |
| `device_tokens_select_own` | User sees only own tokens | [ ] |
| `device_tokens_insert_own` | User can insert own token | [ ] |
| `device_tokens_select_service` | Service role can read all | [ ] |

---

## Sign-off

| Area | Tested By | Date | Status |
|------|-----------|------|--------|
| Android physical device | | | [ ] Pass / [ ] Fail |
| iOS physical device | | | [ ] Pass / [ ] Fail |
| Notifications (all states) | | | [ ] Pass / [ ] Fail |
| Force/optional update | | | [ ] Pass / [ ] Fail |
| Maintenance mode | | | [ ] Pass / [ ] Fail |
| Deep links | | | [ ] Pass / [ ] Fail |
| Crashlytics | | | [ ] Pass / [ ] Fail |
| Analytics | | | [ ] Pass / [ ] Fail |
| RLS policies | | | [ ] Pass / [ ] Fail |
| No internet handling | | | [ ] Pass / [ ] Fail |
| Session restore | | | [ ] Pass / [ ] Fail |
| FCM token lifecycle | | | [ ] Pass / [ ] Fail |
