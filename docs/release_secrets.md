# Release secrets & build defines

Release CI **must not** rely on a committed `.env`. Config is injected with
`--dart-define` from GitHub Secrets / Variables.

## Required repository secrets

| Secret | Used by | Purpose |
|--------|---------|---------|
| `API_BASE_URL` | Android + iOS release | Backend base URL including `/api/v1` |
| `SUPABASE_URL` | Android + iOS release | Supabase project URL |
| `SUPABASE_PUBLISHABLE_KEY` | Android + iOS release | Supabase anon/publishable key |
| `GOOGLE_WEB_CLIENT_ID` | Android + iOS release | Google Sign-In web client (optional empty) |
| `GOOGLE_IOS_CLIENT_ID` | Android + iOS release | Google Sign-In iOS client (optional empty) |
| `ANDROID_KEYSTORE_BASE64` | Android release | Base64-encoded upload keystore |
| `ANDROID_STORE_PASSWORD` | Android release | Keystore password |
| `ANDROID_KEY_PASSWORD` | Android release | Key password |
| `ANDROID_KEY_ALIAS` | Android release | Key alias |
| `PLAY_STORE_SERVICE_ACCOUNT_JSON` | Android release | Play Console service account |
| `IOS_DIST_CERTIFICATE_BASE64` | iOS release | Distribution cert (p12) |
| `IOS_CERTIFICATE_PASSWORD` | iOS release | p12 password |
| `IOS_PROVISIONING_PROFILE_BASE64` | iOS release | App Store profile |
| `IOS_KEYCHAIN_PASSWORD` | iOS release | Temporary CI keychain |
| `ASC_KEY_ID` / `ASC_ISSUER_ID` / `ASC_KEY_CONTENT` | iOS deliver | App Store Connect API key |

## Variables

| Variable | Purpose |
|----------|---------|
| `APP_STORE_ID` | Numeric App Store ID for force-update deep links |

## Local release dry-run

### Android

```bash
flutter build appbundle --release \
  --obfuscate --split-debug-info=build/symbols \
  --dart-define=APP_ENV=prod \
  --dart-define=API_BASE_URL=https://api.example.com/api/v1 \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=... \
  --dart-define=ENABLE_DEBUG_LOGS=false
```

### iOS

```bash
flutter build ipa --release \
  --dart-define=APP_ENV=prod \
  --dart-define=API_BASE_URL=https://api.example.com/api/v1 \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=... \
  --dart-define=ENABLE_DEBUG_LOGS=false
```

Or open `ios/Runner.xcworkspace` in Xcode → **Product → Archive** (Release).

#### Firebase / Google dSYMs (Upload Symbols Failed)

Firebase Analytics is integrated via **Swift Package Manager** binary
frameworks (`FirebaseAnalytics`, `GoogleAppMeasurement`,
`GoogleAppMeasurementIdentitySupport`, `GoogleAdsOnDeviceConversion`). Those
prebuilt binaries do not ship dSYMs, so Xcode 16+ reports **Upload Symbols
Failed** for them unless stubs are generated.

Build phases on the `Runner` target (order matters):

1. **Generate missing vendor framework dSYMs** →
   `ios/scripts/generate_missing_framework_dsyms.sh`  
   Runs `dsymutil` on each vendor framework binary so the archive gets a real
   Mach-O **dSYM companion** (`MH_DSYM`) with a matching `LC_UUID`.  
   A plain `cp` of the dylib is **not** enough — Apple’s uploader ignores
   those and still reports Upload Symbols Failed.
2. **[Crashlytics] Upload dSYMs** →
   `ios/scripts/upload_crashlytics_symbols.sh`  
   Uploads app/Flutter dSYMs to Crashlytics (SPM checkout of
   `firebase-ios-sdk`, with CocoaPods fallback).

After archiving, confirm dSYMs exist **and** are companion files:

```bash
ARCHIVE=path/to/Runner.xcarchive

ls "$ARCHIVE/dSYMs"
# Expect among others:
#   Runner.app.dSYM
#   FirebaseAnalytics.framework.dSYM
#   GoogleAppMeasurement.framework.dSYM
#   GoogleAppMeasurementIdentitySupport.framework.dSYM
#   GoogleAdsOnDeviceConversion.framework.dSYM
#   objective_c.framework.dSYM

# Must say "dSYM companion file", NOT "dynamically linked shared library"
file "$ARCHIVE/dSYMs/FirebaseAnalytics.framework.dSYM/Contents/Resources/DWARF/FirebaseAnalytics"

# UUIDs must match the embedded framework
dwarfdump --uuid "$ARCHIVE/Products/Applications/Runner.app/Frameworks/FirebaseAnalytics.framework/FirebaseAnalytics"
dwarfdump --uuid "$ARCHIVE/dSYMs/FirebaseAnalytics.framework.dSYM"
```

These dSYMs satisfy App Store Connect validation only (empty DWARF for
closed-source Google code is expected). Crash symbolication for *your* app
still relies on `Runner.app.dSYM` (+ Flutter symbols) uploaded by the
Crashlytics phase.

**If Organizer still shows Upload Symbols Failed:** bump `CFBundleVersion`
(`pubspec.yaml` build number), clean archive again, and re-upload. Do not
re-use an archive that was built with the old `cp`-based stubs.

## Play track

Android CI publishes to the **internal** track. Promote to production from
Play Console after QA.
