#!/bin/sh
# Verifies that all required runtime config variables are present in the
# environment (set via scripts/load_env.sh or directly exported).
#
# Usage:
#   . ./scripts/load_env.sh && ./scripts/verify_env.sh
#
# Exit code is non-zero when any required variable is missing.

set -u

REQUIRED="APP_ENV API_BASE_URL SUPABASE_URL SUPABASE_PUBLISHABLE_KEY GOOGLE_WEB_CLIENT_ID"

OPTIONAL="GOOGLE_IOS_CLIENT_ID ENABLE_DEBUG_LOGS"

missing=0

echo "Verifying required environment variables..."
for var in $REQUIRED; do
  eval "val=\"\${$var:-}\""
  if [ -z "$val" ]; then
    echo "  MISSING: $var"
    missing=$((missing + 1))
  else
    echo "  OK:      $var"
  fi
done

echo ""
echo "Optional variables:"
for var in $OPTIONAL; do
  eval "val=\"\${$var:-}\""
  if [ -z "$val" ]; then
    echo "  empty:   $var (optional)"
  else
    echo "  set:     $var"
  fi
done

if [ "$missing" -gt 0 ]; then
  echo ""
  echo "verify_env: $missing required variable(s) missing." >&2
  exit 1
fi

echo ""
echo "verify_env: all required variables present."
exit 0
