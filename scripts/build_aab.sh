#!/bin/sh
# Builds the signed Play Store App Bundle (.aab) using configuration sourced
# from the environment (via scripts/load_env.sh or CI secrets).
#
# Usage:
#   . ./scripts/load_env.sh && ./scripts/verify_env.sh && ./scripts/build_aab.sh
#
# Required env vars: APP_ENV, API_BASE_URL, SUPABASE_URL,
#   SUPABASE_PUBLISHABLE_KEY, GOOGLE_WEB_CLIENT_ID
# Optional: GOOGLE_IOS_CLIENT_ID, ENABLE_DEBUG_LOGS (default false)
#
# Signing is handled separately by android/app/key.properties
# (local) or CI-provided keystore. This script only drives the build.

set -eu

: "${APP_ENV:?required: set APP_ENV (dev|staging|prod)}"
: "${API_BASE_URL:?required: set API_BASE_URL}"
: "${SUPABASE_URL:?required: set SUPABASE_URL}"
: "${SUPABASE_PUBLISHABLE_KEY:?required: set SUPABASE_PUBLISHABLE_KEY}"
: "${GOOGLE_WEB_CLIENT_ID:?required: set GOOGLE_WEB_CLIENT_ID}"

ENABLE_DEBUG_LOGS="${ENABLE_DEBUG_LOGS:-false}"
GOOGLE_IOS_CLIENT_ID="${GOOGLE_IOS_CLIENT_ID:-}"

OUT="build/app/outputs/bundle/release/app-release.aab"

echo "Building appbundle for environment: $APP_ENV"

flutter build appbundle --release \
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
