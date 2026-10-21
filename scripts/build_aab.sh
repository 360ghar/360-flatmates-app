#!/bin/sh
# Builds a signed App Bundle (.aab) with plain `flutter build`, using
# configuration sourced from the environment (via scripts/load_env.sh or CI
# secrets). The bundle has no Shorebird engine and can NEVER receive an OTA
# patch, so it is not a store artifact: store builds use
# scripts/shorebird_release.sh or the v* tag workflows. The script refuses to
# run unless ALLOW_PLAIN_BUNDLE=1 is set, for local or QA bundles only.
#
# Usage:
#   . ./scripts/load_env.sh && ./scripts/verify_env.sh && \
#     ALLOW_PLAIN_BUNDLE=1 ./scripts/build_aab.sh
#
# Required env vars: APP_ENV, API_BASE_URL, SUPABASE_URL,
#   SUPABASE_PUBLISHABLE_KEY, GOOGLE_WEB_CLIENT_ID
# Optional: GOOGLE_IOS_CLIENT_ID, ENABLE_DEBUG_LOGS (default false)
#
# Signing is handled separately by android/app/key.properties
# (local) or CI-provided keystore. This script only drives the build.
#
# Runs through the pinned Flutter from .fvmrc via fvm when it is on PATH, so the
# bundle matches the version used by the release and OTA-patch builds. A plain
# `flutter build` artifact has no Shorebird engine and can never be patched.

set -eu

if [ "${ALLOW_PLAIN_BUNDLE:-}" != "1" ]; then
  echo "build_aab: refusing to build a plain-Flutter bundle: it can never receive a Shorebird patch." >&2
  echo "build_aab: use scripts/shorebird_release.sh for store builds, or set ALLOW_PLAIN_BUNDLE=1 for a local or QA bundle." >&2
  exit 1
fi

: "${APP_ENV:?required: set APP_ENV (dev|staging|prod)}"
: "${API_BASE_URL:?required: set API_BASE_URL}"
: "${SUPABASE_URL:?required: set SUPABASE_URL}"
: "${SUPABASE_PUBLISHABLE_KEY:?required: set SUPABASE_PUBLISHABLE_KEY}"
: "${GOOGLE_WEB_CLIENT_ID:?required: set GOOGLE_WEB_CLIENT_ID}"

ENABLE_DEBUG_LOGS="${ENABLE_DEBUG_LOGS:-false}"
GOOGLE_IOS_CLIENT_ID="${GOOGLE_IOS_CLIENT_ID:-}"

OUT="build/app/outputs/bundle/release/app-release.aab"

if command -v fvm >/dev/null 2>&1; then
  FLUTTER="fvm flutter"
else
  FLUTTER="flutter"
  echo "build_aab: fvm not found on PATH; using the plain flutter SDK (its version may not match .fvmrc)." >&2
fi

echo "Building appbundle for environment: $APP_ENV"

# shellcheck disable=SC2086  # intentional word-splitting: FLUTTER may be "fvm flutter"
$FLUTTER build appbundle --release \
  --dart-define=APP_ENV="$APP_ENV" \
  --dart-define=API_BASE_URL="$API_BASE_URL" \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_PUBLISHABLE_KEY="$SUPABASE_PUBLISHABLE_KEY" \
  --dart-define=GOOGLE_WEB_CLIENT_ID="$GOOGLE_WEB_CLIENT_ID" \
  --dart-define=GOOGLE_IOS_CLIENT_ID="$GOOGLE_IOS_CLIENT_ID" \
  --dart-define=ENABLE_DEBUG_LOGS="$ENABLE_DEBUG_LOGS"

if [ ! -f "$OUT" ]; then
  echo "build_aab: expected output not found: $OUT" >&2
  exit 1
fi

echo ""
echo "build_aab: done -> $OUT"
