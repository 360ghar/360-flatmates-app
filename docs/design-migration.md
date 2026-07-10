# Design Migration: Airbnb System

> Canonical visual system for 360 FlatMates. Source of truth: [DESIGN.md](../DESIGN.md).

## Overview

The app adopts Airbnb’s marketplace design language:

- **Primary:** Rausch `#FF385C` (single brand voltage — no multi-palette)
- **Canvas:** pure white `#FFFFFF`
- **Ink:** `#222222` (never pure black)
- **Type:** Inter (open-source substitute for Airbnb Cereal VF)
- **Shape:** soft radii (buttons 8, cards 14, pills full)
- **Elevation:** one shadow tier only
- **Dark mode:** derived neutrals (product requirement; not on Airbnb public web)

## Token map (implementation)

| Area | File |
|---|---|
| Colors | `lib/core/theme/app_semantic_colors.dart` |
| Spacing | `lib/core/theme/app_spacing.dart` |
| Radius | `lib/core/theme/app_radius.dart` |
| Shadows | `lib/core/theme/app_shadows.dart` |
| Typography | `lib/core/theme/app_typography.dart` |
| ThemeData | `lib/core/theme/app_theme.dart` |

Legacy aliases (`accent` → `primary`, `paper` → `surfaceSoft`, `ink2` → `body`, `line` → `hairline`) remain so feature call sites migrate gradually.

## Product decisions

1. **Rausch only** — palette switcher removed from Settings.
2. **Light / dark / system** retained; light is design-system truth.
3. Shared `Flatmates*` components and high-traffic discover chrome restyled first.

## Verification

```bash
dart format .
flutter analyze --fatal-infos
bash scripts/banned_patterns.sh
flutter test
```
