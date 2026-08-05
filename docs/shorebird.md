# Shorebird OTA (code push) runbook

Shorebird ships Dart-only fixes straight to installed apps — no store review, no
new build number. A patch is typically a few hundred KB and takes effect on the
user's next cold start.

This is separate from the server-driven update prompts in
`lib/core/app_config/`. Those tell a user to go download a new build; a patch
actually fixes the running app.

---

## The one rule that governs everything

**A binary built with plain `flutter build` can never be patched.** It has no
Shorebird engine inside it. Every store artifact must come from
`shorebird release`, which is why `android-release.yml` and `ios-release.yml`
call Shorebird instead of `flutter build`.

Anything already published before this was wired up is permanently unpatchable.

## What a patch can and cannot change

| Change | Patchable? |
|---|---|
| Dart code — logic, UI, copy, most pub packages | **Yes** |
| Assets (`assets/`, `.env`, fonts, the icon font) | No |
| Native code — Kotlin, Swift, Gradle, Podfile, plugin natives | No |
| Adding or upgrading a plugin with native code | No |
| Flutter or engine version | No |

Anything in the "No" column needs a full `v*` release.

---

## Prerequisites (once per machine)

```bash
curl --proto '=https' --tlsv1.2 \
  https://raw.githubusercontent.com/shorebirdtech/install/main/install.sh -sSf | bash
shorebird doctor
shorebird login          # opens a browser
```

CI authenticates with the `SHOREBIRD_TOKEN` repo secret — see
[release_secrets.md](release_secrets.md).

## One-time project setup

Already done if `shorebird.yaml` exists at the repo root. If it does not:

```bash
shorebird init
```

> **Do not push a `v*` tag until `shorebird.yaml` is committed.** The release
> workflows now call `shorebird release`, which cannot run without an `app_id`,
> so tagging first fails the job mid-release.

Then verify all three of the following and commit them together — the app cannot
resolve patches at runtime without the first two:

1. **`shorebird.yaml`** at the repo root, holding `app_id`. The `app_id` is *not*
   a secret; it is committed deliberately and only lets a client fetch patches.
2. **`shorebird.yaml` listed under `flutter: assets:` in `pubspec.yaml`** — `init`
   adds this automatically. Without it the updater cannot read the app id.
3. **`<uses-permission android:name="android.permission.INTERNET"/>`** in
   `android/app/src/main/AndroidManifest.xml` — already present in this repo, so
   `init` should be a no-op here.

Add `auto_update: false` to `shorebird.yaml` only if you want to take over
download scheduling in Dart. The app currently relies on the default
(`true`) and `PatchService` stays read-only.

### Flutter version

Pinned to **3.44.6** in `.fvmrc`, both release workflows, and
`scripts/shorebird_release.sh`. Shorebird ignores your local and FVM Flutter
entirely and manages its own pinned cache, so the version must be passed
explicitly or it silently builds with Shorebird's own default.

Two constraints worth remembering:

- Every platform of one release version must share a single Flutter revision, so
  the Android and iOS jobs must pass the same `--flutter-version`.
- A patch cannot choose a version — it always inherits the release's revision.

Check support for a version before changing the pin:

```bash
shorebird flutter versions list
# or, without installing anything:
git ls-remote --heads https://github.com/shorebirdtech/flutter.git \
  'refs/heads/flutter_release/3.44.6'   # empty output => unsupported
```

If you change the pin, change it in all four places at once.

---

## Shipping a release

Releases are cut by tagging, exactly as before:

```bash
git tag v1.0.10 && git push origin v1.0.10
```

`android-release.yml` and `ios-release.yml` then run `shorebird release`, upload
to Play (internal track) and App Store Connect, and register the release with
Shorebird so it can be patched later.

Locally:

```bash
. ./scripts/load_env.sh && ./scripts/verify_env.sh
./scripts/shorebird_release.sh android --dry-run
./scripts/shorebird_release.sh android
shorebird preview --platform=android      # install it on a device
```

Notes:

- The release version comes from `version:` in `pubspec.yaml`;
  `--release-version` is rejected on `shorebird release`.
- Re-running a release for a version that already has an active release on the
  same platform exits **70**. Bump `pubspec.yaml` instead.
- Android emits both the `.aab` (uploaded to Play and to Shorebird) and the
  `.apk` (local/QA only) from one invocation.
- **Never let a store console change the version code or build number.** Patch
  targeting keys off the exact release version, so an auto-increment silently
  breaks every future patch for that release.

---

## Shipping a patch

### 1. Branch off the release tag

Not off `main`. A patch built from `main` drags in unrelated asset, native and
dependency changes, which Shorebird will reject or turn into an enormous patch.

```bash
git checkout -b patch/1.0.9-fix-crash v1.0.9
# apply ONLY the Dart fix
```

### 2. Patch to the staging track

Via CI: **Actions → Shorebird Patch (OTA) → Run workflow**, pick the platform,
leave `release_version` blank to use `pubspec.yaml`, and keep `track: staging`.

Or locally:

```bash
./scripts/shorebird_patch.sh android 1.0.9+18 staging
```

### 3. Verify on a device

```bash
shorebird preview --platform=android --track=staging
```

Launch, **force-quit, and launch again** — a patch never applies to the running
isolate, so the fix only appears on the *second* launch. Confirm the patch number
in **Settings → About**.

### 4. Promote to stable

```bash
shorebird patches list --release-version 1.0.9+18
shorebird patches set-track --release-version 1.0.9+18 --patch-number 1 --track stable
```

### Rollback

Same command, pointing at the previous good patch number (or use the console's
Rollback action). Devices drop the bad patch on next startup and fall back to the
last good patch or the base release. Requires Flutter ≥ 3.27.4, and the
re-download counts against your monthly patch installs.

---

## Things that will bite you

**Diff warnings on the first patch.** Shorebird compares the patch build against
the release and refuses to proceed if assets or native code changed. On CI it
cannot prompt, so the job fails loudly — which is intended. Expect this at least
once: R8 / `shrinkResources` output and the native artifacts of
`firebase_*`, `supabase_flutter` and `flutter_map` are not always
byte-reproducible.

Diagnose it locally with `scripts/shorebird_patch.sh` and read the report before
reaching for `--allow-asset-diffs` / `--allow-native-diffs`. Those flags
suppress a real safety check; a genuinely mismatched patch can crash on launch.

**`.env` is a declared Flutter asset.** Its bytes are part of the bundle
Shorebird diffs. CI writes a one-line `APP_ENV=prod` stub in the release and
patch workflows, and both local scripts do the same via
`scripts/shorebird_env_stub.sh` — your real `.env` is swapped out for the build
and restored afterwards, including on failure. This keeps local and CI builds
byte-comparable, and stops a real `.env` (with secrets) being bundled into a
shipped app. If you ever call `shorebird release` or `shorebird patch` by hand,
do the same or you will get spurious asset diffs.

**dart-defines must match the release exactly.** They are baked into the binary.
A patch built with a different set ships a broken config: `AppConfig` throws on an
empty `API_BASE_URL` and the app boots into `_ConfigErrorApp`. The define list
lives in `scripts/shorebird_*.sh` and the workflow `env:` blocks — change all of
them together.

**Icon tree-shaking is disabled on purpose.** Both release and patch builds pass
`--no-tree-shake-icons`, because with tree-shaking on, a Dart-only fix that
references one new icon rewrites the `MaterialIcons` asset and trips the
asset-diff check. Costs roughly 1–1.5 MB of app size and buys patchability.

**Obfuscation is asymmetric.** Releases pass `--obfuscate`; patches must **not**.
Shorebird downloads the release's obfuscation map and applies it automatically,
and passing the flag against a non-obfuscated release is a fatal error.

**Free tier is 5,000 monthly patch *installs***, not patches. Rollbacks consume
installs too. Check the console before promoting anything to `stable` broadly.

**App size** grows by roughly 1.35–2 MB because Shorebird ships its own Flutter
engine build containing the patch runtime.

---

## Observability

The patch number is surfaced in three places, all read-only —
`lib/core/app_config/patch_service.dart` never downloads or applies anything,
since `auto_update: true` leaves that to Shorebird:

- **Crashlytics custom key `shorebird_patch_number`**, set in
  `AnalyticsService.create()` before `runApp` so a patch that crashes on the
  first frame is still attributable. `0` means "no patch, base release".
- **Settings → About** shows e.g. `1.0.9+18 (patch 3)`.
- **A one-off SnackBar** when a patch has downloaded but needs a restart, plus a
  `patch_ready_shown` analytics event. It has no action button: Flutter cannot
  restart itself, so a button there would do nothing.

All of it no-ops on debug builds, `flutter run`, and any non-Shorebird binary
(`ShorebirdUpdater.isAvailable` is false).
