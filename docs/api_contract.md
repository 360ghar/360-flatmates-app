# API contract

The backend is the source of the contract. The app follows it in code and proves it in tests.

## Rules the app follows

1. Read errors only from `{"error": {"code", "message", "details"}}`. A 422 lists field errors in `details.fields[]` (`field`, `msg`, `type`). Branch on `code`, not on `message`. A 5xx never shows backend text.
2. Read every list as a CursorPage (`items`, `next_cursor`, `has_more`, `limit`, `total`). Send `limit` 100 or less. A read that needs all rows follows `next_cursor`.
3. Send only declared query keys and body keys. An unknown key is a 422. A PATCH body holds only the keys that changed. An explicit `null` clears a field.
4. Send and read enum values exactly as the backend sends them (`lib/core/domain/wire_enums.dart`). A value this build does not know is `null`. It never becomes a real member.
5. Platform is `ios` or `android` (never the Dart name `iOS`). `build_number` is an integer. Date-only fields are `YYYY-MM-DD`. Datetimes are UTC with `Z`.
6. A peer phone is never in a peer payload. The app reads it from `GET /flatmates/matches/{match_id}/contact`, and only for an open match. An owner contact number is shown to the owner only.
7. A visit counterparty is a name and an avatar (`PublicUserRef`). Cancel uses `POST /visits/{id}/cancel` with a reason. Reschedule uses `POST /visits/{id}/reschedule`.
8. A content edit (title, rent, description, photos) puts a live listing back in review. An availability toggle does not. The app shows the review state.
9. Push data has `type_key` and `route` at the top level. The Android channel is `flatmates_messages`.
10. Chat has no table stream. The open thread reads REST pages and refetches on a Broadcast event.
11. The client sends `message_type` `text` or `image` only. A visit request is a `text` message with `visit_id` in its metadata.
12. Every store follows three rules. It has a schema version (a store of another version is dropped, never read). It belongs to the signed-in account (another account never reads it). Sign-out removes it. `Cache-Control: no-store` responses are never written to disk. The owner listings cache is in memory only. The onboarding draft carries `v` and the account id (`OnboardingDraftStorage`). On sign-out `clearAccountScopedState` (`lib/app/account_scope.dart`) removes the account keys of `AppPreferences` (`PrefKeys.isAccountKey`) and invalidates every list and detail provider, so the next account reads its own rows. Theme, language and the last sign-in method belong to the device and stay.
13. Profile writes send declared keys only. `PUT /flatmates/profile` takes no `email` and no `phone`: the edit form shows both read-only.
14. A backend error `code` the app has copy for (`PROFILE_NOT_FOUND`, `MATCH_NOT_FOUND`, `PROFILE_STATUS_LOCKED`, `LISTING_NOT_FOUND`, `LISTING_STATUS_CONFLICT`, `BLOCK_NOT_FOUND`, `VISIT_CONFLICT`, `VISIT_NOT_CANCELLABLE`, `VISIT_NOT_RESCHEDULABLE`, `USER_INACTIVE`) shows the English or Hindi copy of the app (`UserMessageL10n.codeMessages`). Any other 4xx code shows the backend message (English only). A 5xx never shows the backend text: it can leak internals, so the app shows its own server copy.
15. A chat, notification or visit list row with no readable `created_at` is skipped (and logged). A property listing row is kept with `created_at` null. The app never dates a row at the current time or at the epoch. A UTC timestamp is converted to local time only to display it (the details page, the header, the visit banner and the `matched on` date of the schedule page).
16. Read `listing_preferences` through the public allowlist only (`PUBLIC_LISTING_PREFERENCE_KEYS` in the backend `app/services/visibility.py`). The server removes every other key for every viewer except an admin, the owner included. The app does not read `moderation_reason`, `auto_paused_*`, `society_tag_vote_counts` or `society_tag_user_votes`.
    - A rejected listing shows the generic guidance (`rejectionDetailText`) and the edit-and-resubmit action. The moderator reason is not available to the owner.
    - `expired` comes from `expires_at` only. An auto-paused listing reads as `paused`, and Resume answers 409 `LISTING_STATUS_CONFLICT` (shown with its own copy).
    - The vibe tags on the details page come from `society_vibe_tags` (public). The vote counts and the viewer vote come from the `SocietyTagVoteOut` that `POST /flatmates/listings/{id}/society-tags/votes` answers (`SocietyTagVote`). Before a vote the chip has no count.
    - The listing form still sends keys the server drops (see the handoff open items).
17. An enum the contract declares inline (`IdentifierStatusResponse.channel` and `next_step`) is parsed to a nullable member. A value this build does not know is `null` and is logged. The auth flow reads the channel from what the user typed and sends an unknown next step to OTP.

## Enums

`tool/gen_enums.py` writes `lib/core/domain/wire_enums.dart` from the backend `docs/openapi.json`.
Add the enum name to `ENUMS` in the script, then run it again. The script writes code that `dart format` leaves unchanged (it wraps the `kWireEnumValues` entries at 80 columns), so `dart format --output=none --set-exit-if-changed lib test` passes with the pinned SDK.

```bash
python3 tool/gen_enums.py
```

## Fixtures and tests

`tool/api_fixtures.py` validates sample data through the backend response models and writes `test/fixtures/api/*.json`. It also writes the request body contracts (`requests.json`), the query keys of every operation (`operations.json`), push data, deep links and enums.

```bash
uv run --project ../../360ghar/360ghar-backend python tool/api_fixtures.py
flutter test test/contract
```

- `test/contract/contract_test.dart` parses every response with the app models.
- `test/contract/requests_test.dart` runs the app repositories and checks each body and query against the contract.
- `test/contract/errors_test.dart` checks the error mapping for each status.
- `test/contract/enums_test.dart` fails when `wire_enums.dart` is stale.
- `test/contract/push_and_links_test.dart` checks push data and deep links.

Run the fixture script again after each backend contract change. `scripts/contract_sync.sh` runs `tool/gen_enums.py` and `tool/api_fixtures.py`, formats `wire_enums.dart`, and exits 1 when `lib/core/domain/wire_enums.dart` or `test/fixtures/api` was stale (it compares the files before and after the run). It needs the backend checkout and `uv`; CI does not run it. Commit the regenerated files when it fails.

```bash
export PATH="$HOME/fvm/versions/3.44.6/bin:$PATH"
bash scripts/contract_sync.sh
```

## Generated models

The freezed and json files under `lib/` are committed. Run the generator with the Flutter version the repo pins (`.fvmrc`, 3.44.6). The pin does not change `pubspec.lock`.

```bash
export PATH="$HOME/fvm/versions/3.44.6/bin:$PATH"   # or `fvm flutter` / `fvm dart`
dart run build_runner build --delete-conflicting-outputs
```

With a newer global Flutter (3.47), analyzer 7.x fails with `Missing implementation of visitDotShorthandPropertyAccess` on any library that links the Flutter widgets. Use the pinned SDK for `build_runner`. `flutter analyze` and `flutter test` run with either.
