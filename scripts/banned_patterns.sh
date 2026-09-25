#!/bin/bash
# Checks for banned patterns in the codebase.
# Usage: bash scripts/banned_patterns.sh

set -e
ERRORS=0

echo "Checking for banned patterns..."

# 1. error.toString() in presentation files
echo -n "  error.toString() in presentation... "
COUNT=$(grep -r 'error\.toString()' lib/features/ --include='*_page.dart' --include='*_widget.dart' -l 2>/dev/null | wc -l)
if [ "$COUNT" -gt 0 ]; then
  echo "FAIL ($COUNT files)"
  grep -r 'error\.toString()' lib/features/ --include='*_page.dart' --include='*_widget.dart' -l
  ERRORS=$((ERRORS + 1))
else
  echo "OK"
fi

# 2. Direct apiClientProvider in page files
echo -n "  apiClientProvider in pages... "
COUNT=$(grep -r 'apiClientProvider' lib/features/ --include='*_page.dart' -l 2>/dev/null | wc -l)
if [ "$COUNT" -gt 0 ]; then
  echo "FAIL ($COUNT files)"
  grep -r 'apiClientProvider' lib/features/ --include='*_page.dart' -l
  ERRORS=$((ERRORS + 1))
else
  echo "OK"
fi

# 3. Supabase.instance in page files
echo -n "  Supabase.instance in pages... "
COUNT=$(grep -r 'Supabase\.instance' lib/features/ --include='*_page.dart' -l 2>/dev/null | wc -l)
if [ "$COUNT" -gt 0 ]; then
  echo "FAIL ($COUNT files)"
  grep -r 'Supabase\.instance' lib/features/ --include='*_page.dart' -l
  ERRORS=$((ERRORS + 1))
else
  echo "OK"
fi

# 4. Raw Image.network in feature files (should use FlatmatesNetworkImage)
echo -n "  Image.network in features... "
COUNT=$(grep -r 'Image\.network(' lib/features/ --include='*.dart' -l --exclude='flatmates_network_image.dart' 2>/dev/null | wc -l)
if [ "$COUNT" -gt 0 ]; then
  echo "FAIL ($COUNT files)"
  grep -r 'Image\.network(' lib/features/ --include='*.dart' --exclude='flatmates_network_image.dart' -l
  ERRORS=$((ERRORS + 1))
else
  echo "OK"
fi

# 5. Page files over 500 lines
echo -n "  Page files over 500 lines... "
LARGE_FILES=""
while IFS= read -r -d '' f; do
  LINES=$(wc -l < "$f")
  if [ "$LINES" -gt 500 ]; then
    LARGE_FILES="$LARGE_FILES $f ($LINES lines)"
  fi
done < <(find lib/features -name '*_page.dart' -print0)
if [ -n "$LARGE_FILES" ]; then
  echo "FAIL"
  echo "$LARGE_FILES"
  ERRORS=$((ERRORS + 1))
else
  echo "OK"
fi

# 6. Navigator.push in page files (should use GoRouter)
echo -n "  Navigator.push in pages... "
COUNT=$(grep -r 'Navigator\.push' lib/features/ --include='*_page.dart' -l 2>/dev/null | wc -l)
if [ "$COUNT" -gt 0 ]; then
  echo "FAIL ($COUNT files)"
  grep -r 'Navigator\.push' lib/features/ --include='*_page.dart' -l
  ERRORS=$((ERRORS + 1))
else
  echo "OK"
fi

# 7. Raw EdgeInsets.all(<digits>) in features (should use AppSpacing tokens)
echo -n "  Raw EdgeInsets.all(N) in features... "
HITS=$(grep -rEn 'EdgeInsets\.all\(\s*[0-9]+\s*\)' lib/features/ --include='*.dart' 2>/dev/null || true)
if [ -n "$HITS" ]; then
  COUNT=$(echo "$HITS" | wc -l | tr -d ' ')
  echo "FAIL ($COUNT occurrences)"
  echo "$HITS"
  ERRORS=$((ERRORS + 1))
else
  echo "OK"
fi

# Ratchets: raw radii and raw colours belong in lib/core/theme. Existing uses
# are grandfathered at the baseline below; the count may only go down.
# Lower the baseline when you remove one.
RADIUS_BASELINE=77
COLOR_BASELINE=11

echo -n "  raw BorderRadius.circular(<number>) outside theme... "
COUNT=$(grep -rE 'BorderRadius\.circular\([0-9.]+\)' lib --include='*.dart' | grep -v '^lib/core/theme/' | wc -l | tr -d ' ')
if [ "$COUNT" -gt "$RADIUS_BASELINE" ]; then
  echo "FAIL ($COUNT > baseline $RADIUS_BASELINE; use AppRadius)"
  ERRORS=$((ERRORS + 1))
else
  echo "OK ($COUNT)"
fi

echo -n "  raw Color(0x...) outside theme... "
COUNT=$(grep -r 'Color(0x' lib --include='*.dart' | grep -v '^lib/core/theme/\|paper_art.dart\|l10n/gen' | wc -l | tr -d ' ')
if [ "$COUNT" -gt "$COLOR_BASELINE" ]; then
  echo "FAIL ($COUNT > baseline $COLOR_BASELINE; use AppSemanticColors)"
  ERRORS=$((ERRORS + 1))
else
  echo "OK ($COUNT)"
fi

if [ "$ERRORS" -gt 0 ]; then
  echo ""
  echo "Found $ERRORS banned pattern(s). Fix before merging."
  exit 1
fi

echo ""
echo "All checks passed!"
