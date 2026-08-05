#!/bin/sh
# Builds a Shorebird-enabled store release. This REPLACES `flutter build` for
# anything that ships: a binary from plain `flutter build` contains no Shorebird
# engine and can never receive an over-the-air patch.
#
# Usage:
#   . ./scripts/load_env.sh && ./scripts/verify_env.sh
#   ./scripts/shorebird_release.sh android
#   ./scripts/shorebird_release.sh ios --dry-run
#
# Required env vars: APP_ENV, API_BASE_URL, SUPABASE_URL,
#   SUPABASE_PUBLISHABLE_KEY, GOOGLE_WEB_CLIENT_ID
# Optional: GOOGLE_IOS_CLIENT_ID, APP_STORE_ID, ENABLE_DEBUG_LOGS (default false)
#
# The release version comes from `version:` in pubspec.yaml — `--release-version`
# is rejected here. Re-running for a version that already has an active release
# on the same platform exits 70; bump pubspec instead.
#
# Signing is handled as usual by android/app/key.properties (Android) or the
# login keychain (iOS). Shorebird does not manage signing.

set -eu

PLATFORM="${1:-}"
if [ "$PLATFORM" != 'android' ] && [ "$PLATFORM" != 'ios' ]; then
  echo "usage: $0 <android|ios> [extra shorebird args...]" >&2
  exit 64
fi
shift

: "${APP_ENV:?required: set APP_ENV (dev|staging|prod)}"
: "${API_BASE_URL:?required: set API_BASE_URL}"
: "${SUPABASE_URL:?required: set SUPABASE_URL}"
: "${SUPABASE_PUBLISHABLE_KEY:?required: set SUPABASE_PUBLISHABLE_KEY}"
: "${GOOGLE_WEB_CLIENT_ID:?required: set GOOGLE_WEB_CLIENT_ID}"

ENABLE_DEBUG_LOGS="${ENABLE_DEBUG_LOGS:-false}"
GOOGLE_IOS_CLIENT_ID="${GOOGLE_IOS_CLIENT_ID:-}"
APP_STORE_ID="${APP_STORE_ID:-}"

# Must match .fvmrc and BOTH release workflows. Shorebird ignores the local /
# FVM Flutter entirely and manages its own pinned cache, so this has to be
# passed explicitly or it silently builds with Shorebird's default version.
# Every platform of one release version must share this revision.
FLUTTER_VERSION='3.44.6'

# Android only: also emits the .apk alongside the .aab in one invocation.
#
# APP_STORE_ID drives the iOS force-update deep link and is passed ONLY on iOS,
# matching ios-release.yml (android-release.yml omits it). The define set here
# must stay identical to the workflow for the same platform, or a release cut
# locally and a patch built in CI would not be built from the same inputs.
if [ "$PLATFORM" = 'android' ]; then
  set -- --artifact=apk "$@"
else
  set -- --dart-define=APP_STORE_ID="$APP_STORE_ID" "$@"
fi

# Build against the same one-line .env stub CI uses. This keeps a locally-cut
# release byte-comparable with patches built in CI, and stops a developer's real
# .env (with secrets) from being bundled into a shipped app.
# See scripts/shorebird_env_stub.sh.
. "$(dirname "$0")/shorebird_env_stub.sh"
shorebird_stub_env

echo "Shorebird release: $PLATFORM (env: $APP_ENV, flutter: $FLUTTER_VERSION)"

# Flags Shorebird understands are passed natively — it must know the release is
# obfuscated so it uploads the obfuscation map that future patches rebuild
# against. Only Flutter flags it does not model go after the `--`.
# --no-tree-shake-icons keeps the MaterialIcons asset byte-stable so a later
# Dart-only patch that touches an icon does not trip the asset-diff check.
shorebird release "$PLATFORM" \
  --flutter-version="$FLUTTER_VERSION" \
  --obfuscate \
  --split-debug-info=build/symbols \
  --dart-define=APP_ENV="$APP_ENV" \
  --dart-define=API_BASE_URL="$API_BASE_URL" \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_PUBLISHABLE_KEY="$SUPABASE_PUBLISHABLE_KEY" \
  --dart-define=GOOGLE_WEB_CLIENT_ID="$GOOGLE_WEB_CLIENT_ID" \
  --dart-define=GOOGLE_IOS_CLIENT_ID="$GOOGLE_IOS_CLIENT_ID" \
  --dart-define=ENABLE_DEBUG_LOGS="$ENABLE_DEBUG_LOGS" \
  "$@" \
  -- \
  --no-tree-shake-icons

echo ""
echo "shorebird_release: done. Verify on a device with:"
echo "  shorebird preview --platform=$PLATFORM"
