# 360 FlatMates design system: Paper Diorama

This file is identical in `360-flatmates-web` and `360-flatmates`. Change both in the same PR.

The UI is a cut-paper diorama of an Indian neighbourhood. Screens are built from stacked paper
layers: a sky at the back, sections in the middle, cards and sheets in front. Light comes from the
top-left, so every layer casts a small, tight shadow down and to the right onto the layer behind it.

Rules:
1. Depth comes from paper layers and directional shadows, never from glows or blurred blooms.
2. The scene art (hills, town, tree, sun) is the signature. Use it in headers, auth, onboarding,
   empty, error and offline states. Do not use it as decoration inside dense content.
3. Content is always visible. Motion moves things that are already on screen.
4. Usability wins over style: WCAG AA text contrast, tap targets of 44 px (web) / 48 dp (Flutter),
   reduce-motion respected, 60 fps on mid-range phones.

## 1. Colour tokens

Light is day. Dark is night on pine-black (never blue-charcoal). Every text pair below passes WCAG
AA (4.5:1) on every paper layer. The contrast tests enforce this:
`src/styles/__tests__/contrast.test.ts` (web) and `test/core/theme/contrast_test.dart` (Flutter).

### Paper layers and ink
| Token | Light | Dark | Use |
|---|---|---|---|
| `sky` | `#E4EBE3` | `#121814` | Layer 0. Page background. |
| `paper-1` | `#EDF1EA` | `#19211C` | Layer 1. Sections, bands, nav rail. |
| `paper-2` | `#FDFCFA` | `#222A24` | Layer 2. Cards, sheets, inputs. |
| `paper-3` | `#FFFFFF` | `#2A332C` | Layer 3. Popovers, raised cards, toasts. |
| `ink` | `#23201C` | `#F1EDE6` | Headings, primary text. |
| `ink-2` | `#4A443D` | `#CBC4B9` | Body text. |
| `ink-3` | `#6B6359` | `#A39C91` | Muted text, captions, placeholders. |
| `edge` | `#23201C` at 10 % | `#F1EDE6` at 10 % | Self-coloured paper lip (1 px top/side stroke). |

### Brand
| Token | Light | Dark | Use |
|---|---|---|---|
| `clay` | `#A94A2B` | `#E27E5A` | Primary. Main actions, active nav, links. |
| `clay-press` | `#8C3B20` | `#C9694A` | Pressed primary. |
| `clay-soft` | `#F2DACF` | `#3A2A23` | Selected fills, primary tint. |
| `on-clay` | `#FFFFFF` | `#1A120E` | Text on `clay`. |
| `pine` | `#2E5B48` | `#86B9A0` | Secondary. Success, verified, secondary actions. |
| `pine-soft` | `#D3E2D8` | `#22352C` | Secondary fills. |
| `on-pine` | `#FFFFFF` | `#1A120E` | Text on `pine`. |
| `marigold` | `#E0A034` | `#E8B458` | Accent. Sun, stars, rating, lit windows. Never body text on paper. |
| `danger` | `#B3261E` | `#F2A097` | Errors, destructive actions. |
| `danger-soft` | `#F6DAD7` | `#3B2220` | Error fills. |
| `warning-ink` | `#7E5208` | `#E8B458` | Warning text. |
| `warning-soft` | `#F7E8C8` | `#352B19` | Warning fills. |

### Scene layers (art only)
| Token | Light | Dark |
|---|---|---|
| `scene-hill-far` | `#C3D5C8` | `#1D2A22` |
| `scene-hill-near` | `#93B39F` | `#26392E` |
| `scene-town-far` | `#DDB3A0` | `#3A2A23` |
| `scene-town` | `#A94A2B` | `#8A4128` |
| `scene-window` | `#F6EBD9` | `#E8B458` (lit at night) |
| `scene-tree` | `#2E5B48` | `#3F6F58` |
| `scene-sun` | `#E0A034` | `#E8B458` |
| `scene-cloud` | `#FFFFFF` | `#2A332C` |

## 2. Typography

- Display: **Gambarino** (Fontshare, ITF Free Font License, one weight: Regular 400). Self-hosted:
  `public/fonts/Gambarino-Regular.woff2` (web), `assets/fonts/Gambarino-Regular.ttf` (Flutter).
  Never synthesise bold or italic (`font-synthesis: none`). Emphasis = size and colour, not weight.
- Body and UI: the platform font. Web: `system-ui, -apple-system, "Segoe UI", Roboto, sans-serif`.
  Flutter: the default (SF Pro on iOS, Roboto on Android).
- Numbers in data (price, dates, counts): body font with tabular figures.

| Role | Font | Size / line height | Weight |
|---|---|---|---|
| `display` | Gambarino | 40 / 44 | 400 |
| `h1` | Gambarino | 32 / 38 | 400 |
| `h2` | Gambarino | 26 / 32 | 400 |
| `h3` | Gambarino | 21 / 26 | 400 |
| `title` | Body | 17 / 22 | 600 |
| `body` | Body | 16 / 24 | 400 |
| `body-sm` | Body | 14 / 20 | 400 |
| `label` | Body | 14 / 18 | 600 |
| `caption` | Body | 13 / 18 | 400 |

Headlines stay on one or two lines. No uppercase tracked "eyebrow" labels.

## 3. Spacing, radius, size

- Spacing scale (px/dp): `4 8 12 16 20 24 32 40 56 72`.
- Page gutter: 16 (phone), 24 (tablet), 32 (desktop). Content max width 1200.
- Radius: `cut-sm 6`, `cut-md 12`, `cut-lg 18`, `cut-xl 28`, `full`.
  Cards use a hand-cut uneven radius: `12 14 11 13` (top-left, top-right, bottom-right, bottom-left).
- Tap target: 44 px (web), 48 dp (Flutter). Control height: 48.

## 4. Elevation (paper layers)

Light source: top-left. Shadows are tight, offset down-right, tinted with `ink`. No symmetric blur.

| Level | Shadow | Use |
|---|---|---|
| `e0` | none | Flat on its layer |
| `e1` | `0 1px 0 edge` + `0 1px 2px ink/8%` | Inputs, chips, list rows |
| `e2` | `0 1px 0 edge` + `1px 3px 4px -2px ink/14%` | Cards, buttons |
| `e3` | `0 1px 0 edge` + `2px 6px 8px -4px ink/18%` | Sheets, popovers, lifted cards |

Dark mode uses the same geometry with black at 40 / 50 / 60 %.

Scene layers each cast `drop-shadow(1px 2px 1.5px)` in `ink/22%` (light) or black 50 % (dark).

## 5. Paper details

- **Grain**: a fine noise texture at 4 % opacity on paper surfaces, painted behind content. Never
  over text.
- **Torn edge**: one generated tile (`tornEdgeTile`), repeated along an edge. Used where a scene
  meets content, on bottom-sheet tops and on section breaks. Depth 10 px.
- **Scallop edge**: semicircles of radius 6 along an edge. Used on toasts and the offline strip.
- **Clear the cut**: any element with a torn or scallop edge gets padding larger than the edge depth
  on that side.

## 6. Scene art

Generated by `360-flatmates-web/scripts/generate-paper-art.py` into:
- `src/components/paper/art.ts` (web, SVG path data)
- `lib/features/shared/presentation/paper/paper_art.dart` (Flutter, op-codes)

Never edit the generated files. Change the script and rerun it.

| Shape | Layer order | Token |
|---|---|---|
| `sun` | 1 | `scene-sun` |
| `cloudA`, `cloudB` | 2 | `scene-cloud` |
| `hillsFar` | 3 | `scene-hill-far` |
| `townFar` | 4 | `scene-town-far` |
| `hillsNear` | 5 | `scene-hill-near` |
| `townWindows` | 6 | `scene-window` |
| `townNear` | 7 | `scene-town` |
| `tree` | 8 | `scene-tree` |

Compact scene (320 x 200) for empty states: `miniSun`, `miniHillsFar`, `miniHillsNear`, plus one prop.

| Prop | Token | Used for |
|---|---|---|
| `house` | `clay` | No listings, no visits |
| `chat` | `pine` | No conversations |
| `heart` | `clay` | No likes / matches |
| `magnifier` | `pine` | No search results |
| `bell` | `marigold` | No notifications |
| `rainCloud` | `ink-3` | Error, offline, not found |

## 7. Motion

| Token | Value |
|---|---|
| `fast` | 120 ms |
| `base` | 200 ms |
| `slow` | 320 ms |
| `layer-stagger` | 40 ms |
| `paper-out` | `cubic-bezier(0.2, 0.7, 0.2, 1)` |
| `paper-settle` | `cubic-bezier(0.3, 1.3, 0.5, 1)` |

- **Entrance**: layers rise 12 px into place, staggered 40 ms, back layers first. Opacity starts at 1.
- **Press** (buttons, chips): scale 0.98 and shadow `e2` → `e1`. Buttons never move on hover; hover
  only shifts colour.
- **Lift** (cards on hover, web only): shadow `e2` → `e3`, translate up 1 px.
- **Parallax**: scene layers move at different rates while the page scrolls (far layers slowest).
  Transform only.
- **Reduce motion**: no parallax, no entrance movement, no press scale. State changes are instant.

## 8. Components

| Component | Rule |
|---|---|
| Button, primary | `clay` fill, `on-clay` label, `cut-md` radius, `e2`, 48 high. |
| Button, secondary | `pine-soft` fill, `ink` label. Not an outline button. |
| Button, quiet | No fill, `clay` label, underline on hover (static, not animated). |
| Card | `paper-2`, uneven radius, `e2`, grain. |
| Input | `paper-2`, `cut-md`, `e1`, 48 high. Focus: 2 px `clay` stroke. Error: 2 px `danger` + message below. |
| Chip | `paper-2` + `e1`; selected = `clay-soft` fill + `ink` label. |
| Bottom sheet | `paper-2`, torn top edge, `e3`. |
| Toast | `paper-3`, scallop left edge, `e3`. Error toast: `danger` icon + text. |
| Nav (mobile) | Paper tab strip on `paper-1`. Active tab rises one layer (`paper-2` + `e2`) with `clay` icon and label. |
| Nav (desktop) | Sidebar on `paper-1`; active item = `paper-2` + `e2`. |
| Skeleton | Bones in `paper-1` on `paper-2`. Slow tone pulse (no shimmer highlight). Same layout as the loaded view. |
| Empty state | Compact scene + prop, `h3` title, one `body` line, one primary action. |
| Error state | `rainCloud` scene, human message (never raw error text), Retry button. |
| Offline | Scallop-edged strip in the page flow (pushes content down), `warning-soft`. |

## 9. Icons

Five nav icons are custom filled paper shapes. Utility icons use lucide (web) or Material (Flutter)
at one stroke weight (1.75 px web) with no container tile behind them.
