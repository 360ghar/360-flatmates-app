#!/bin/sh
# Ships a Dart-only fix over the air to an existing Shorebird release.
#
# Usage:
#   . ./scripts/load_env.sh && ./scripts/verify_env.sh
#   ./scripts/shorebird_patch.sh android 1.0.9+18            # -> staging track
#   ./scripts/shorebird_patch.sh android 1.0.9+18 stable
#   ./scripts/shorebird_patch.sh ios 1.0.9+18 staging --dry-run
#
# Run from a branch cut off the release's `v*` tag with ONLY the Dart fix on top.
# Patching from main drags in unrelated asset/native/dependency changes.
#
# Cannot be patched: assets, native code, plugin native changes, Flutter version.
#
# Required env vars: same as scripts/shorebird_release.sh. The dart-define set
# below must stay identical to the release's, or the patch ships a broken config
# (AppConfig throws on an empty API_BASE_URL -> _ConfigErrorApp on launch).

set -eu

PLATFORM="${1:-}"
RELEASE_VERSION="${2:-}"
TRACK="${3:-staging}"
if [ "$PLATFORM" != 'android' ] && [ "$PLATFORM" != 'ios' ]; then
  echo "usage: $0 <android|ios> <release-version> [track] [extra args...]" >&2
  exit 64
fi
if [ -z "$RELEASE_VERSION" ]; then
  echo "usage: $0 $PLATFORM <release-version> [track]   e.g. 1.0.9+18" >&2
  exit 64
fi
[ $# -ge 3 ] && shift 3 || shift 2

: "${APP_ENV:?required: set APP_ENV (dev|staging|prod)}"
: "${API_BASE_URL:?required: set API_BASE_URL}"
: "${SUPABASE_URL:?required: set SUPABASE_URL}"
: "${SUPABASE_PUBLISHABLE_KEY:?required: set SUPABASE_PUBLISHABLE_KEY}"
: "${GOOGLE_WEB_CLIENT_ID:?required: set GOOGLE_WEB_CLIENT_ID}"

ENABLE_DEBUG_LOGS="${ENABLE_DEBUG_LOGS:-false}"
GOOGLE_IOS_CLIENT_ID="${GOOGLE_IOS_CLIENT_ID:-}"
APP_STORE_ID="${APP_STORE_ID:-}"

# APP_STORE_ID is an iOS-only define (see scripts/shorebird_release.sh). It must
# be present on exactly the platforms the release used, or the patch is built
# from a different define set than the release it targets.
if [ "$PLATFORM" = 'ios' ]; then
  set -- --dart-define=APP_STORE_ID="$APP_STORE_ID" "$@"
fi

# Build against the same one-line .env stub CI uses, so the patch's asset bundle
# matches the release's. See scripts/shorebird_env_stub.sh.
. "$(dirname "$0")/shorebird_env_stub.sh"
shorebird_stub_env

echo "Shorebird patch: $PLATFORM release $RELEASE_VERSION -> track '$TRACK'"

# --obfuscate is deliberately absent: Shorebird downloads the release's
# obfuscation map and applies it automatically, and passing the flag against a
# non-obfuscated release is fatal. There is no --flutter-version on patch — a
# patch always inherits the Flutter revision of the release it targets.
#
# No --allow-asset-diffs / --allow-native-diffs. If Shorebird reports a diff,
# read the report and understand it before overriding a real safety check.
shorebird patch "$PLATFORM" \
  --release-version="$RELEASE_VERSION" \
  --track="$TRACK" \
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
echo "shorebird_patch: done. Verify before promoting:"
echo "  shorebird preview --platform=$PLATFORM --track=$TRACK"
echo "  # then force-quit and relaunch — a patch applies on the SECOND launch"
echo "  shorebird patches list --release-version $RELEASE_VERSION"
