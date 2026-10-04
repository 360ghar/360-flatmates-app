# Maestro E2E CI

How the Maestro suite runs in GitHub Actions, what it needs, and what it does not cover.

Workflow: `.github/workflows/maestro.yml` (job `maestro_test`). Triggers: pull requests
targeting `main` / `develop`, plus `workflow_dispatch`. Runner `ubuntu-22.04`, Flutter from
`.fvmrc` (3.44.6), Maestro CLI pinned to `cli-2.6.1` with checksum verification, Android
emulator API 33 (`google_apis`, x86_64, pixel_6, KVM enabled). It installs the debug APK and
runs `maestro test .maestro/e2e.yaml --format junit --output maestro-report.xml`, then
uploads `maestro-report` as an artifact.

## Required repository secrets

| Secret | Purpose |
|---|---|
| `API_BASE_URL` | `--dart-define`; backend base URL. Must be a seeded **non-production** environment — the flows mutate state. |
| `SUPABASE_URL` | `--dart-define`; Supabase project URL. |
| `SUPABASE_PUBLISHABLE_KEY` | `--dart-define`; Supabase publishable key. |
| `MAESTRO_PHONE` | Phone number of the seeded, already-onboarded `room_poster` account (E.164), passed to Maestro as `${MAESTRO_PHONE}`. |
| `MAESTRO_PASSWORD` | Password for that account, passed as `${MAESTRO_PASSWORD}`. |

The first three names are the same secrets the release workflows already use
(`android-release.yml`, `ios-release.yml`, `shorebird-patch.yml`); `MAESTRO_PHONE` and
`MAESTRO_PASSWORD` are Maestro-specific and must be created separately.

A preflight step runs before the Flutter and Maestro installs and fails the job with
`::error::Missing required repository secret(s): <names>` when any of the five is empty, so a
missing secret reads as a configuration error instead of a login assertion failure later.

## App config comes from `--dart-define`

The debug APK is built with:

```bash
flutter build apk --debug \
  --dart-define=APP_ENV=ci \
  --dart-define=API_BASE_URL="$API_BASE_URL" \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_PUBLISHABLE_KEY="$SUPABASE_PUBLISHABLE_KEY"
```

`AppConfig.fromEnvironment()` (`lib/core/config/app_config.dart`) prefers
`String.fromEnvironment` over `dotenv`, and throws when `API_BASE_URL` / `SUPABASE_URL` /
`SUPABASE_PUBLISHABLE_KEY` are empty; `bootstrap.dart` then renders `_ConfigErrorApp`, so no
flow can reach the login screen. CI still writes a one-line `.env` stub (`APP_ENV=ci`) only
because `.env` is declared as an asset in `pubspec.yaml` and the file must exist for the
build — it is not the config source in CI. Local runs keep using a real `.env` (or the same
`--dart-define` flags).

## Seeded backend prerequisites

From the header of `.maestro/e2e.yaml`, the target `API_BASE_URL` must have:

- a seeded, already-onboarded `room_poster` account matching `MAESTRO_PHONE` / `MAESTRO_PASSWORD`
- at least 3 discover listings
- at least 1 existing conversation (chat + schedule-visit flows)
- at least 1 visit (visit actions)

The flows mutate state (like, message, schedule/reschedule/cancel visit, create listing,
block/report/unmatch), which is why the target must not be production. The backend must also
be reachable from GitHub-hosted runners.

## Local run

```bash
export MAESTRO_PHONE='+91XXXXXXXXXX'
export MAESTRO_PASSWORD='<password>'
maestro test .maestro/e2e.yaml
```

Build/run the app locally against the same seeded backend (`.env` or `--dart-define`).

## Coverage gap

`.maestro/` holds 82 YAML files: 81 feature flows plus `_shared/login.yaml`, a helper that
several flows include (it does run indirectly). `.maestro/e2e.yaml` invokes only 20 top-level
flows, so the other 61 feature flows never execute in CI — including all 10 onboarding flows,
all 3 map flows, and 4 of the 11 flows edited by the Paper Diorama PR
(`auth/02_login_email`, `auth/03_signup_otp`, `auth/04_forgot_password`, `auth/05_set_password`).
A green Maestro job therefore does not mean the suite is green — expanding `e2e.yaml` (or
adding a second scheduled workflow for the remaining folders) is a follow-up, not part of the
current fix.

## Current blockers to a green run

1. `MAESTRO_PHONE` and `MAESTRO_PASSWORD` repository secrets do not exist yet — the user
   creates them.
2. The seeded non-production backend must be reachable from CI at the `API_BASE_URL` secret's
   value, with the seed data listed above.
