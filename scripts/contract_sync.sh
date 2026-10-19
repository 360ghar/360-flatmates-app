#!/bin/bash
# Regenerates the backend contract files (wire enums and API fixtures) and fails when the
# files on disk were stale, so a backend change is noticed before the app tests run.
#
# Needs the backend checkout (default ../../360ghar/360ghar-backend, or set BACKEND_DIR),
# `uv`, and `dart` (use the pinned SDK: PATH="$HOME/fvm/versions/3.44.6/bin:$PATH").
# CI does not run it: the backend repo is not part of the CI checkout.
#
# Usage: bash scripts/contract_sync.sh
#
# The check compares the files before and after the run (not `git diff`), so it also
# works on a tree with uncommitted changes. Commit the regenerated files when it fails.

set -euo pipefail
cd "$(dirname "$0")/.."

BACKEND="${BACKEND_DIR:-../../360ghar/360ghar-backend}"
SNAP="$(mktemp -d)"
trap 'rm -rf "$SNAP"' EXIT

cp lib/core/domain/wire_enums.dart "$SNAP/wire_enums.dart"
cp -R test/fixtures/api "$SNAP/api"

python3 tool/gen_enums.py
uv run --project "$BACKEND" python tool/api_fixtures.py
dart format lib/core/domain/wire_enums.dart

STALE=0
diff -q "$SNAP/wire_enums.dart" lib/core/domain/wire_enums.dart || STALE=1
diff -rq "$SNAP/api" test/fixtures/api || STALE=1

if [ "$STALE" -ne 0 ]; then
  echo "FAIL: the contract files were stale and are now regenerated. Review and commit them."
  exit 1
fi
echo "OK: lib/core/domain/wire_enums.dart and test/fixtures/api are current."
