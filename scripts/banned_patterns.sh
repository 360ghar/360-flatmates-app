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
RADIUS_BASELINE=0
COLOR_BASELINE=0

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

# Light-only status colours fail contrast in dark mode (clay on dark paper is
# about 1.2:1). Use the brightness-aware AppSemanticColors.*For(brightness).
#
# Every token below is a light-only constant in
# lib/core/theme/app_semantic_colors.dart whose value has a brightness-aware
# counterpart, so a raw reference inside a feature or app widget is always the
# wrong choice. Most counterparts are named `*For(brightness)`; the rest are
# named by semantics:
#   accent, primary, coralMid, purpleMid, pinkMid, orangeMid -> clayFor()
#   blueMid, tealMid, greenMid                               -> pineFor()
#   onPrimary                                                -> onClayFor()
#   error, coralInk                                          -> dangerFor()
#   success, info                                            -> pineFor()
#   warning                                                  -> warningInkFor()
#   ink, textPrimary                                         -> textPrimaryFor()
#   body, ink2, mutedText, textSecondary                     -> textSecondaryFor()
#   muted, ink3, textTertiary                                -> textTertiaryFor()
#   canvas, card, surface, surfaceCard                       -> surfaceFor()
#   paper, sky, scaffold                                     -> paperFor()/skyFor()
#   secondarySurface, surfaceSoft, surfaceDim, lavenderBg    -> secondarySurfaceFor()
#   surfaceStrong, peerBubbleBg                              -> paperDeepFor()/disabledSurfaceFor()
#   successBg, infoBg, successSoft                           -> successSoftFor()
#   errorBg, errorSoft, dangerSoft                           -> errorSoftFor()
#   warningBg, warningSoft, warningSoftBg                    -> warningSoftFor()
#   accentSoft, primarySoft/Container/Light, primaryDisabled -> coralSoftFor()
#   primaryActive                                            -> clayPressFor()
#   blueInk, tealInk                                         -> greenInkFor()
#   purpleInk, pinkInk, orangeInk                            -> clayInkFor()
#   starRating                                               -> marigoldFor()
#   compatHigh, mapMarkerProperty, swipeCardFallbackMid      -> pineFor()
#   compatLow                                                -> dangerFor()
#   mapMarkerRoom                                            -> clayFor()
#   mapMarkerCluster                                         -> textPrimaryFor()
#   swipeCardFallbackEnd                                     -> greenInkFor()
#
# Deliberately absent: light-only constants with no brightness-aware
# counterpart — mutedSoft (ink4), hairlineSoft (paper4, line2, lineLow,
# outlineVariant), borderStrong, errorHover, yellowMid (compatMedium),
# yellowInk, swipeCardFallbackStart — plus frostOverlayLight (paired with
# frostOverlayDark by an explicit brightness ternary) and scrim/onScrim, which
# never invert (DESIGN.md §1).
LIGHT_ONLY_TOKENS='accent|accentSoft'
LIGHT_ONLY_TOKENS+='|primary|primaryActive|primaryDisabled|primarySoft|primaryContainer|primaryLight|onPrimary'
LIGHT_ONLY_TOKENS+='|sky|paper|paper1|paper2|paper3|paperDeep|canvas|scaffold'
LIGHT_ONLY_TOKENS+='|surface|surfaceSoft|surfaceStrong|surfaceCard|card|surfaceDim|secondarySurface|disabledSurface|lavenderBg|peerBubbleBg'
LIGHT_ONLY_TOKENS+='|ink|body|muted|ink2|ink3|mutedText|textPrimary|textSecondary|textTertiary'
LIGHT_ONLY_TOKENS+='|clay|clayPress|claySoft|onClay|pine|pineSoft|onPine|marigold|danger|dangerSoft|warningInk|warningSoft|warningSoftBg'
LIGHT_ONLY_TOKENS+='|coralSoft|coralMid|coralInk|clayInk|greenInk'
LIGHT_ONLY_TOKENS+='|success|successSoft|successBg|successTextDark|error|errorSoft|errorBg|warning|warningBg|info|infoBg'
LIGHT_ONLY_TOKENS+='|hairline|blueSoft|blueMid|blueInk|tealSoft|tealMid|tealInk|greenSoft|greenMid'
LIGHT_ONLY_TOKENS+='|purpleSoft|purpleMid|purpleInk|pinkSoft|pinkMid|pinkInk|orangeSoft|orangeMid|orangeInk|yellowSoft'
LIGHT_ONLY_TOKENS+='|starRating|compatHigh|compatLow|mapMarkerRoom|mapMarkerProperty|mapMarkerCluster'
LIGHT_ONLY_TOKENS+='|swipeCardFallbackMid|swipeCardFallbackEnd'

# Deliberate exemption: the share poster renders a PNG for export, so it must
# keep the fixed light palette instead of following the viewer's theme.
LIGHT_ONLY_EXEMPT='lib/features/discover/share_listing_card.dart'

echo -n "  light-only accent/status colours in features and app... "
HITS=$(grep -rEn "AppSemanticColors\.($LIGHT_ONLY_TOKENS)([^A-Za-z0-9]|$)" lib/features lib/app --include='*.dart' | grep -v "^$LIGHT_ONLY_EXEMPT:" || true)
COUNT=$(printf '%s\n' "$HITS" | grep -c . || true)
if [ "$COUNT" -gt 0 ]; then
  echo "FAIL ($COUNT; use AppSemanticColors.*For(brightness))"
  echo "$HITS"
  ERRORS=$((ERRORS + 1))
else
  echo "OK"
fi

if [ "$ERRORS" -gt 0 ]; then
  echo ""
  echo "Found $ERRORS banned pattern(s). Fix before merging."
  exit 1
fi

echo ""
echo "All checks passed!"
