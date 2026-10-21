# iPhone Duo (foldable iPhone)

How 360 FlatMates adapts to Apple's foldable iPhone, and what is still open.

Apple's iPhone Duo is the first foldable iPhone: a 5.4" cover display and a 7.6"
inner display, with the app resizing **live** when the device is folded or
unfolded. Apps built with the iOS 27 SDK resize dynamically; apps built with
the iOS 27.1 SDK additionally get vertical system bars.

This document is the reference for the geometry, the breakpoint mapping, the
safe-area rules, and the release boundary. It is the source of truth for
"correct on Duo" — there was no written definition before it.

---

## 1. Display geometry

Four poses, in logical points, measured on the iOS 27.1 iPhone Duo simulator:

| Pose | Points | AppBreakpoints bucket | Shell chrome |
|------|--------|----------------------|--------------|
| Folded portrait | 466 × 678 | compact | bottom bar |
| Folded landscape | 678 × 466 | medium | bottom bar |
| Open / half-open portrait | 669 × 951 | medium | bottom bar |
| Open / half-open landscape | 951 × 669 | expanded | navigation rail |

The hinge angle does **not** change the size class: half-open and fully open
report identical dimensions and identical size classes. Size classes alone
therefore cannot tell you how far the device is open.

### Safe area — the important part

> **Corrected.** An earlier revision of this document claimed an **84 pt
> right-edge** inset and no top inset, on the theory that the Duo moves its
> status bar and camera to the right edge. **That was wrong.** It came from the
> research pass rather than from the device, and it sent the inset work at the
> right edge while the real inset sat on top. The measurements below are taken
> from the running app.

Safe area is **top 82 pt and bottom 34 pt**, with **no right inset**. Measured
on the booted iOS 27.1 Duo simulator, open portrait, from the running app's own
widget tree — the `MediaQueryData` the framework received from the platform:

```text
size: Size(669.0, 951.0), devicePixelRatio: 3.0,
padding: EdgeInsets(0.0, 82.0, 0.0, 34.0)
```

`EdgeInsets(left, top, right, bottom)`. Three independent checks agree:

- the platform reports a zero right inset, and no Dart code hardcodes 82 or 84
  anywhere in `lib/`;
- Apple's own Settings app on the same simulator draws the same horizontal
  top-right status bar the app does — there are no vertical right-edge system
  bars to make room for;
- the app's own applied padding resolves to `EdgeInsets(16, 16, 16, 58)`, which
  is `screen + 0` on both sides and `lg + 34` on the bottom, i.e. it found the
  34 pt bottom inset and nothing on the right.

So the Duo is an ordinary notched phone as far as insets go. The risk is the
**top**: `SafeArea` handles it, and `PaperSceneHeader` consumes it explicitly
(`EdgeInsets.only(top: MediaQuery.paddingOf(context).top)`), so a page that passes
`useSafeArea: false` and hand-rolls only a bottom inset is the one to check.

Only [open portrait] was measurable. `simctl` exposes no fold control
(`screenConfig geometry` accepts only each panel's native mode, so the other
three poses are rejected as `No mode found`), and the pose toggle otherwise
needs the DeviceHub toolbar. Treat the folded and landscape insets as
unverified.

---

## 2. Breakpoints

`lib/core/theme/app_breakpoints.dart` is the single definition. The existing
Material boundaries (`medium = 600`, `expanded = 900`) already classify every
Duo pose correctly — 669 lands in medium, 951 in expanded — so no boundary
value needed to change. What changed is that the boundaries now *do* something
on more surfaces.

| Helper | Behaviour |
|--------|-----------|
| `cardGridColumns(width)` | 2 / 3 / 4 listing cards |
| `profileGridColumns(width)` | 2 / 3 / 4 profile cards (Likes grid) |
| `lifestyleColumns(width)` | 2 or 4 (there is no 3) |
| `contentMaxWidth(width)` | 720 below `wide`, `double.infinity` at/above |
| `chatBubbleMaxWidth(width)` | `min(width * 0.75, 560)` |
| `isMedium` / `isExpanded` | boolean gates |
| `readingColumn` | the 720 constant, for a hard cap |

`profileGridColumns` and `cardGridColumns` are deliberately separate functions
with identical bodies today. The listing feed and the profile grid are free to
diverge; do not collapse them.

### The reading column

`FlatmatesScreen` centres every page body in a column capped at
`contentMaxWidth(width)`. This is the one change that fixes the majority of
screens: without it, text runs the full 951 pt.

It applies to both the scrollable and non-scrollable paths, sets **width
only** (never height), and is a no-op whenever the available width already fits within the 720 dp cap
(the 951 dp open-landscape pose is capped) — at 466, 669 and 678 dp
the rendering is pixel-identical to before.

### The navigation rail

At `isExpanded` the shell renders a `NavigationRail` instead of the bottom
`NavigationBar`. Same five destinations, same mode-dependent slot 2, same
icons and labels.

**The rail must keep the five Maestro identifiers** (`nav_home_tab`,
`nav_post_tab`/`nav_explore_tab`, `nav_swipe_tab`, `nav_inbox_tab`,
`nav_me_tab`). Maestro's `id:` reads `Semantics.identifier`, not Flutter keys,
so losing them breaks the 82 flows in `.maestro/`.

The wide body is a `Stack` with the page painted **first** and the rail over
it — not a `Row`. go_router wraps every inactive shell branch in an `Offstage`,
and an offstage node blocks the semantics of everything painted before it, so
a `Row` silently drops the rail's entire semantics subtree. This is documented
at `lib/app/app_shell.dart` and guarded by a test. Do not "simplify" it.

---

## 3. Flutter cannot see the hinge

`dart:ui` documents `MediaQuery.displayFeatures` as *populated only on
Android*. The iOS embedder does not populate it in Flutter 3.44.6, and the
proposal to do so ([flutter/flutter#192515](https://github.com/flutter/flutter/issues/192515))
is still open.

Consequences:

- There is **no fold-posture or hinge-angle awareness** in this app, and none
  is possible from pure Dart today.
- The app only ever observes "the window changed size", which is sufficient
  for everything in §2.
- Apple's `reservedRegions` / `UIHingeInteraction` APIs are reachable only
  through a native plugin. If fold-aware layout is ever needed, that is the
  route, and it is a **native** change (see §6).

A caution if that work is ever done: populating `displayFeatures` non-emptily
changes framework behaviour well beyond layout. `DisplayFeatureSubScreen`
confines dialogs, sheets and popup menus to one side of a division, and eleven
files under `packages/flutter/lib/src/` inherit that predicate.

---

## 4. Verification

Three layers, because each catches something the others cannot:

1. **Widget tests at real pose sizes.** `test/helpers/foldable_surfaces.dart`
   exposes the four poses and the real insets so tests do not re-type numbers.
2. **A live-resize test.** Nothing else in the repo changes the surface size
   *mid-test*, which is exactly what folding does. It asserts no exception
   across every pose transition — a `RenderFlex overflowed` fails it.
3. **Goldens at foldable width**, in addition to the 390 dp phone baseline.

### The CI gap — known and not fixed

The golden tests are guarded by `_skip = !Platform.isMacOS`, and
`.github/workflows/quality.yml` runs on `ubuntu-latest`. **No golden runs in
CI today**, including the pre-existing phone goldens. A foldable golden is
therefore developer-local protection only. Closing this needs a `macos-14`
job (the label is already used by the iOS release workflows).

Also note `flutter analyze` excludes `ios/**` and `android/**`
(`analysis_options.yaml`), so **no static check will ever catch a plist or
manifest regression**. That is why the native configuration below needs its
own verification step.

---

## 5. Rules for new UI

- **Use `FlatmatesScreen`.** It gives you `SafeArea` and the reading column.
  If you pass `useSafeArea: false`, you own **all four** insets. The one measured inset
  on this device is the **82 pt top** edge in open portrait; the folded and
  landscape poses are unverified, so do not assume that value there.
- **Do not size from the full viewport width** for anything that is content.
  `width * 0.75` on a 951 pt display is 713 pt of chat bubble.
- **Cap modals.** Sheets are capped at 640 and dialogs at 560 via
  `AppBreakpoints.sheetMaxWidth` / `dialogMaxWidth`. Material 3 already caps
  `showModalBottomSheet` at 640; the explicit cap makes the non-modal path
  deterministic rather than incidental.
- **A fixed height on a full-width child is a bug on a wide display.** A 160 dp
  photo in a 720 dp column is a 4.5:1 strip. Either derive the height from the
  width or bound it with an aspect ratio.
- **Check new rows at 466 dp and at 720 dp**, the same way the large-text rule
  says to check at 320 dp and 2x.
- Never edit `paper_art.dart` by hand — it is generated by
  `360-flatmates-web/scripts/generate-paper-art.py`.

### Known art constraint

The hero `PaperScene` layers are authored on a `Size(1200, 360)` canvas — a
3.33:1 canvas, far wider than any phone. `_ShapePainter` uses `BoxFit.cover`
anchored **bottom-right** so that on a narrow phone the crop keeps the sun and
the tree (both sit on the right of the canvas). This is why a wide viewport
shows *more* of the scene than a phone, not less. Changing the anchoring
silently breaks the phone rendering.

---

## 6. Release boundary — read before shipping

The work splits cleanly, and the split matters:

**Shippable as a Shorebird OTA patch (Dart only):** every breakpoint, the
reading column, the rail, per-feature layout, new Dart widgets, l10n strings.
Target the existing release (`1.0.9+18`) from a branch cut off its `v*` tag,
with the `--dart-define` set byte-identical per platform (Android 7, iOS 8 —
`APP_STORE_ID` is iOS-only).

**Requires a full `v*` release and store review:**

| Change | File |
|--------|------|
| `UIRequiresFullScreen` removal | `ios/Runner/Info.plist` |
| `UISupportedInterfaceOrientations~ipad` | `ios/Runner/Info.plist` |
| Device family / deployment target | `ios/Runner.xcodeproj/project.pbxproj` |
| Any new asset, font, or plugin with native code | `assets/`, `pubspec.yaml` |
| A Flutter SDK bump | `.fvmrc`, both release workflows, `scripts/shorebird_release.sh` |

`UIRequiresFullScreen` is deprecated by Apple
([TN3192](https://developer.apple.com/documentation/technotes/tn3192-migrating-your-app-from-the-deprecated-uirequiresfullscreen-key)),
and the key has been removed from `ios/Runner/Info.plist`.

**Measured on the iOS 27.1 Duo simulator: the key was inert on this device.**
With it set to `<true/>` and with it absent, the app filled both panels
edge-to-edge in folded portrait, unfolded portrait and unfolded landscape —
no letterboxing, no centring, no size change (black-bar scans returned zero
thickness on all eight captures). Removing it is therefore **hygiene, not a
fix**, and it is *not* the reason the app adapts. Do not expect a visual change
from it, and do not treat it as a blocker for anything else.

It is still a native change and **can never be delivered as an OTA patch** —
plan a store release for it, then patch layout corrections afterwards.

The Flutter version is pinned at 3.44.6 and must stay identical in `.fvmrc`,
`android-release.yml`, `ios-release.yml` and `scripts/shorebird_release.sh`.

---

## 7. Testing on the device

The iPhone Duo simulator is the only place to see the real thing.

```bash
xcrun simctl list devices | grep -i duo     # find the UDID
xcrun simctl boot <udid>
npx serve-sim                               # stream the simulator to a browser
fvm flutter run -d <udid>
```

Use the pinned Flutter: the global 3.47 fails on this repo with
`Missing implementation of visitDotShorthandPropertyAccess`.

Fold and unfold the device while the app is running and watch for overflow —
that transition is the failure mode the live-resize test exists to catch.

### Known local blocker: `flutter build ios --simulator` on Xcode 27

On a machine with Xcode 27, `flutter build ios --simulator --no-codesign` fails
with:

```
Exception: Binary .../Flutter.framework/Flutter does not contain architectures "arm64 x86_64".
```

The binary does contain both. Flutter 3.44.6's `thinFramework` runs
`lipo <file> -verify_arch arm64 x86_64` and checks only the exit code, and
Xcode 27's `lipo` rejects multiple architectures in that argument position
(`-verify_arch requires exactly one input file`), so the check fails
regardless. It reproduces on an untouched checkout — it is a pinned-Flutter
versus Xcode-27 toolchain mismatch, not a project problem.

Workaround, used for the simulator pass that produced the §1 numbers: generate
config with Flutter, then build with `xcodebuild` for one architecture.

```bash
flutter build ios --simulator --no-codesign --config-only
xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Debug \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  ARCHS=arm64 ONLY_ACTIVE_ARCH=NO \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO \
  -derivedDataPath /tmp/dd-duo build
```

### Changing the pose

There is **no `simctl` subcommand for the fold**. `xcrun simctl io <udid>
screenConfig geometry` only accepts each panel's native mode. The pose control
is the fold toggle in the DeviceHub toolbar
(`/Applications/Xcode.app/Contents/Applications/DeviceHub.app`), driven with
synthetic clicks; the toolbar reflows between sessions, so locate the icons by
pixel scan rather than by fixed coordinates.

Read back which panel is live from hardware, not the GUI:

```bash
xcrun simctl io <udid> enumerate          # LCD = cover 1398x2034, LCD-1 = inner 2007x2853
xcrun simctl io <udid> screenshot --display=LCD-1 out.png
```

Folded, only `LCD` is non-black; unfolded, only `LCD-1`. Relaunch the app after
each pose change — the click backgrounds it. Avoid
`xcrun simctl io screenConfig power off`: it can leave the simulator unable to
relaunch apps until the device is shut down and booted again.


---

## 8. Open items

- **CI does not run goldens** (§4). A `macos-14` job would close this.
- **No Maestro flow runs at a wide width.** The existing flows all execute on a
  single portrait `pixel_6` emulator, so the rail is covered by widget tests
  but not on-device.
- **`railWidth = 96`** is a judgement call, not a measurement. It fits
  `Explore` / `एक्सप्लोर` at the 1.3 text-scale cap with headroom; a longer
  locale wraps to a second line rather than clipping.
- **Hindi at wide widths** has not been eyeballed on a device.
