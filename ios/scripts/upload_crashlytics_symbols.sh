#!/bin/sh
# Upload dSYMs to Firebase Crashlytics (SPM- and CocoaPods-aware).
#
# FlutterFire on this project uses Swift Package Manager for Firebase, so
# Pods/FirebaseCrashlytics is usually absent. Fall back to the SPM checkout
# under DerivedData SourcePackages.
#
# Expected Xcode env: BUILD_DIR, PODS_ROOT (optional), SCRIPT_INPUT_FILE_* via
# the Run Script input paths.

set -eu

# Crashlytics run is most useful for Release/Profile/archive; skip Debug.
case "${CONFIGURATION:-}" in
  Release|Profile) ;;
  *)
    if [ "${ACTION:-}" != "archive" ] && [ "${ACTION:-}" != "install" ]; then
      echo "note: upload_crashlytics_symbols: skip (CONFIGURATION=${CONFIGURATION:-} ACTION=${ACTION:-})"
      exit 0
    fi
    ;;
esac

DERIVED_DATA_PATH="${BUILD_DIR%/Build/*}"
RUN_SCRIPT=""

if [ -n "${PODS_ROOT:-}" ] && [ -x "${PODS_ROOT}/FirebaseCrashlytics/run" ]; then
  RUN_SCRIPT="${PODS_ROOT}/FirebaseCrashlytics/run"
elif [ -x "${DERIVED_DATA_PATH}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run" ]; then
  RUN_SCRIPT="${DERIVED_DATA_PATH}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run"
else
  # Broader search (Xcode sometimes nests Build differently).
  CANDIDATE=$(find "${DERIVED_DATA_PATH}/SourcePackages/checkouts" \
    -path "*/firebase-ios-sdk/Crashlytics/run" \
    -type f 2>/dev/null | head -n 1 || true)
  if [ -n "$CANDIDATE" ] && [ -x "$CANDIDATE" ]; then
    RUN_SCRIPT="$CANDIDATE"
  fi
fi

if [ -z "$RUN_SCRIPT" ]; then
  echo "warning: Firebase Crashlytics run script not found; skipping dSYM upload"
  echo "warning: looked under PODS_ROOT and ${DERIVED_DATA_PATH}/SourcePackages/checkouts"
  exit 0
fi

echo "note: uploading dSYMs via ${RUN_SCRIPT}"
# Crashlytics `run` uses Xcode env vars (DWARF_DSYM_FOLDER_PATH, etc.).
exec "$RUN_SCRIPT"
