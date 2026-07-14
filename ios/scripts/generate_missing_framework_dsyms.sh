#!/bin/sh
# Generate dSYMs for prebuilt vendor frameworks that ship without DWARF.
#
# Google Firebase Analytics / App Measurement / Ads On-Device Conversion (SPM
# binary xcframeworks) and objective_c (Dart FFI) are embedded as frameworks
# but do not include matching dSYMs. Xcode 16+ then reports "Upload Symbols
# Failed" on App Store Connect upload.
#
# IMPORTANT: Copying the dylib into a .dSYM bundle is NOT enough. Apple's
# symbol uploader requires a real Mach-O "dSYM companion file" (MH_DSYM).
# `dsymutil` produces that type and preserves LC_UUID even when the binary
# has no debug symbols (empty DWARF is fine for closed-source Google code).
#
# Expected Xcode env: ACTION, CONFIGURATION, DWARF_DSYM_FOLDER_PATH,
# TARGET_BUILD_DIR, WRAPPER_NAME, BUILT_PRODUCTS_DIR.

set -eu

# Only needed when producing an archive (or Release/Profile builds that
# may be archived later). Skip Debug to keep local iteration fast.
case "${ACTION:-}" in
  archive|install) ;;
  *)
    case "${CONFIGURATION:-}" in
      Release|Profile) ;;
      *)
        echo "note: generate_missing_framework_dsyms: skip (ACTION=${ACTION:-} CONFIGURATION=${CONFIGURATION:-})"
        exit 0
        ;;
    esac
    ;;
esac

if [ -z "${DWARF_DSYM_FOLDER_PATH:-}" ]; then
  echo "warning: DWARF_DSYM_FOLDER_PATH is empty; cannot create dSYMs"
  exit 0
fi

if ! command -v dsymutil >/dev/null 2>&1; then
  echo "error: dsymutil not found on PATH; cannot create vendor framework dSYMs"
  exit 0
fi

# Binary framework basenames (without .framework).
FRAMEWORK_NAMES="
FirebaseAnalytics
GoogleAppMeasurement
GoogleAppMeasurementIdentitySupport
GoogleAdsOnDeviceConversion
objective_c
"

is_dsym_companion() {
  # Real dSYMs report as "dSYM companion file"; raw dylib copies do not.
  file "$1" 2>/dev/null | grep -q "dSYM companion file"
}

find_framework_binary() {
  name="$1"

  # Prefer the binary already embedded in the app product.
  if [ -n "${TARGET_BUILD_DIR:-}" ] && [ -n "${WRAPPER_NAME:-}" ]; then
    candidate="${TARGET_BUILD_DIR}/${WRAPPER_NAME}/Frameworks/${name}.framework/${name}"
    if [ -f "$candidate" ]; then
      echo "$candidate"
      return 0
    fi
  fi

  if [ -n "${BUILT_PRODUCTS_DIR:-}" ]; then
    candidate="${BUILT_PRODUCTS_DIR}/${name}.framework/${name}"
    if [ -f "$candidate" ]; then
      echo "$candidate"
      return 0
    fi
    # Fallback search (SPM may nest products).
    binary=$(find "${BUILT_PRODUCTS_DIR}" -path "*/${name}.framework/${name}" -type f 2>/dev/null | head -n 1 || true)
    if [ -n "$binary" ] && [ -f "$binary" ]; then
      echo "$binary"
      return 0
    fi
  fi

  return 1
}

create_dsym() {
  name="$1"
  binary="$2"
  dsym_path="${DWARF_DSYM_FOLDER_PATH}/${name}.framework.dSYM"
  dwarf_file="${dsym_path}/Contents/Resources/DWARF/${name}"

  # Replace incomplete stubs (raw dylib copies) from older scripts.
  if [ -f "$dwarf_file" ] && is_dsym_companion "$dwarf_file"; then
    echo "note: valid dSYM already present for ${name}.framework — skip"
    return 0
  fi

  if [ -d "$dsym_path" ]; then
    echo "note: replacing incomplete dSYM for ${name}.framework"
    rm -rf "$dsym_path"
  fi

  # dsymutil emits MH_DSYM with the same LC_UUID as the binary.
  # Stripped Google binaries warn "no debug symbols" — that is expected.
  if ! dsymutil "$binary" -o "$dsym_path" 2>&1; then
    echo "warning: dsymutil failed for ${name}.framework"
    return 0
  fi

  if [ ! -f "$dwarf_file" ]; then
    echo "warning: dsymutil did not produce DWARF for ${name}.framework"
    return 0
  fi

  if ! is_dsym_companion "$dwarf_file"; then
    echo "warning: output for ${name}.framework is not a dSYM companion file"
    return 0
  fi

  uuid=$(dwarfdump --uuid "$dwarf_file" 2>/dev/null | awk '{print $2}' | head -n 1 || true)
  echo "note: created dSYM for ${name}.framework (uuid=${uuid:-unknown})"
}

created=0
missing=0

for name in $FRAMEWORK_NAMES; do
  [ -n "$name" ] || continue

  if binary=$(find_framework_binary "$name"); then
    create_dsym "$name" "$binary"
    created=$((created + 1))
  else
    echo "warning: could not find ${name}.framework binary for dSYM generation"
    missing=$((missing + 1))
  fi
done

echo "note: generate_missing_framework_dsyms done (processed=${created} missing=${missing})"
# Never fail the archive for a missing vendor binary.
exit 0
