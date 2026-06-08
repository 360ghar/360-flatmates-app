# Design Migration: Editorial Aesthetic Adoption

> This document lists every code change required to implement the warm editorial
> aesthetic (from JustHireMe) into the 360 FlatMates codebase. All token changes are
> derived from the updated DESIGN.md.

## Overview

The migration shifts from a cool modern Material 3 palette (electric indigo primary,
neutral grays, Sora/Plus Jakarta Sans) to a warm editorial palette (terracotta primary,
warm paper surfaces, Fraunces/Inter) with 8 categorical pastel colors and derived warm
dark mode.

**No architecture, state management, routing, or feature logic changes.** Only visual
tokens and their references in widgets/themes change.

**Total files requiring changes: 97**

---

## Global Find-and-Replace Patterns

These replacements apply across the entire codebase. Each is listed once here for
reference and cited per-file below.

| # | Old Pattern | New Pattern | Notes |
|---|-------------|-------------|-------|
| G1 | `colorScheme.primary` | `AppSemanticColors.accent` | CTAs, active icons, indicators |
| G2 | `colorScheme.onPrimary` | `Colors.white` | Text on terracotta buttons |
| G3 | `colorScheme.primaryContainer` | `AppSemanticColors.coralSoft` | Chip/container bg |
| G4 | `colorScheme.onSurface` | `AppSemanticColors.ink` | Headings, important text |
| G5 | `colorScheme.onSurfaceVariant` | `AppSemanticColors.ink2` | Body text, descriptions |
| G6 | `colorScheme.surface` | `AppSemanticColors.card` | White card/input surfaces |
| G7 | `colorScheme.surfaceContainerLow` | `AppSemanticColors.paper2` (light) / `AppSemanticColors.darkSurface` (dark) | Dark card bg, light secondary bg |
| G8 | `colorScheme.surfaceContainerHighest` | `AppSemanticColors.paper3` (light) / `AppSemanticColors.darkSurfaceElevated` (dark) | Skeleton, disabled fills |
| G9 | `colorScheme.outlineVariant` | `AppSemanticColors.line` | Borders, dividers |
| G10 | `colorScheme.error` | `AppSemanticColors.error` | Error/destructive states |
| G11 | `Colors.white` (as scaffold bg) | `AppSemanticColors.paper` | Warm off-white scaffold |
| G12 | `Colors.black` (as overlay/shadow) | `AppSemanticColors.ink` | Warm overlay tints |
| G13 | `0xFF10B981` | `0xFF5B8C44` | Success / compat high |
| G14 | `0xFFF59E0B` | `0xFFB57828` | Warning / compat medium |
| G15 | `0xFFEF4444` | `0xFFB4452C` | Error / compat low |
| G16 | `0xFF5B4BCF` | `0xFFC96442` | Primary → accent |
| G17 | `0xFFE8E4F6` | `0xFFF8D5C8` | Primary light → coral-soft |
| G18 | `0xFFDDD8F0` | `0xFFF8D5C8` | Primary container → coral-soft |
| G19 | `0xFF1A1A2E` | `0xFF1F1A14` | Text primary → ink |
| G20 | `0xFF6B7280` | `0xFF4A463E` | Text secondary → ink-2 |
| G21 | `0xFF9CA3AF` | `0xFF8A847A` | Text tertiary → ink-3 |
| G22 | `0xFFE5E7EB` | `rgba(31,26,20,0.08)` | Border → line |
| G23 | `0xFFF8F9FA` | `0xFFF4F3EE` | Surface dim → paper |
| G24 | `0xFF0F1321` | `0xFF1A1612` | Dark scaffold |
| G25 | `0xFF14192A` | `0xFF2A2520` | Dark nav bar |
| G26 | `GoogleFonts.sora(...)` | `GoogleFonts.fraunces(...)` | Display/headline font |
| G27 | `GoogleFonts.plusJakartaSans(...)` | `GoogleFonts.inter(...)` | Body font |
| G28 | `AppPalette.electricIndigo` (as default) | `AppPalette.inkOnPaper` | New default palette |
| G29 | `AppSemanticColors.frostBlur` | `3.0` (was `20.0`) | Reduced frost blur |

---

## 1. Theme Token Files (`lib/core/theme/`)

### 1.1 `app_semantic_colors.dart` — FULL REWRITE

This is the foundation file. Replace the entire color constant block.

**Token renames (old → new):**

| Old Token | Old Value | New Token | New Value |
|-----------|-----------|-----------|-----------|
| `success` | `Color(0xFF10B981)` | `success` | `Color(0xFF5B8C44)` |
| `error` | `Color(0xFFEF4444)` | `error` | `Color(0xFFB4452C)` |
| `warning` | `Color(0xFFF59E0B)` | `warning` | `Color(0xFFB57828)` |
| `successBg` | `Color(0xFFECFDF5)` | `successBg` | `Color(0xFFDCEAD4)` |
| `warningBg` | `Color(0xFFFEF3C7)` | `warningBg` | `Color(0xFFF5E8B8)` |
| `errorBg` | `Color(0xFFFEF2F2)` | `errorBg` | `Color(0xFFF8D5C8)` |
| `infoBg` | `Color(0xFFE8E4F6)` | `infoBg` | `Color(0xFFF8D5C8)` |
| `darkHeading` | `Color(0xFF1A1A2E)` | `ink` | `Color(0xFF1F1A14)` |
| `mutedText` | `Color(0xFF555555)` | `ink2` | `Color(0xFF4A463E)` |
| `lavenderBg` | `Color(0xFFF8F6FC)` | `paper` | `Color(0xFFF4F3EE)` |
| `peerBubbleBg` | `Color(0xFFF3F4F6)` | `paper3` | `Color(0xFFE4E1D7)` |
| `successTextDark` | `Color(0xFF065F46)` | `greenInk` | `Color(0xFF2D4A2E)` |
| `surface` | `Color(0xFFFFFFFF)` | `card` | `Color(0xFFFFFFFF)` (keep) |
| `surfaceDim` | `Color(0xFFF8F9FA)` | `paper` | `Color(0xFFF4F3EE)` |
| `textPrimary` | `Color(0xFF1A1A2E)` | `ink` | `Color(0xFF1F1A14)` |
| `textSecondary` | `Color(0xFF6B7280)` | `ink2` | `Color(0xFF4A463E)` |
| `textTertiary` | `Color(0xFF9CA3AF)` | `ink3` | `Color(0xFF8A847A)` |
| `border` | `Color(0xFFE5E7EB)` | `line` | `Color(0x141F1A14)` |
| `outlineVariant` | `Color(0xFFD1D5DB)` | `line2` | `Color(0x0A1F1A14)` |
| `primaryLight` | `Color(0xFFE8E4F6)` | `accentSoft` | `Color(0x1AC96442)` |
| `primaryContainer` | `Color(0xFFDDD8F0)` | `coralSoft` | `Color(0xFFF8D5C8)` |
| `darkScaffold` | `Color(0xFF0F1321)` | `darkScaffold` | `Color(0xFF1A1612)` |
| `darkNavBar` | `Color(0xFF14192A)` | `darkNavBar` | `Color(0xFF2A2520)` |
| `compatHigh` | `Color(0xFF10B981)` | `compatHigh` | `Color(0xFF5B8C44)` |
| `compatMedium` | `Color(0xFFF59E0B)` | `compatMedium` | `Color(0xFFB57828)` |
| `compatLow` | `Color(0xFFFF6B6B)` | `compatLow` | `Color(0xFFB4452C)` |
| `frostOverlayLight` | `Color(0x14FFFFFF)` | `frostOverlayLight` | `Color(0xE0F4F3EE)` |
| `frostOverlayDark` | `Color(0x14FFFFFF)` | `frostOverlayDark` | `Color(0xE01A1612)` |
| `frostBlur` | `20.0` | `frostBlur` | `3.0` |

**Add these new tokens:**

```dart
// Paper scale
static const Color paper = Color(0xFFF4F3EE);
static const Color paper2 = Color(0xFFEDEBE3);
static const Color paper3 = Color(0xFFE4E1D7);
static const Color paper4 = Color(0xFFD8D4C7);

// Ink scale
static const Color ink = Color(0xFF1F1A14);
static const Color ink2 = Color(0xFF4A463E);
static const Color ink3 = Color(0xFF8A847A);
static const Color ink4 = Color(0xFFB5AFA3);

// Semantic soft backgrounds
static const Color successSoft = Color(0x1E5B8C44);
static const Color errorSoft = Color(0x1AB4452C);
static const Color warningSoft = Color(0x1AB57828);

// Categorical pastel colors (soft / mid / ink)
static const Color blueSoft   = Color(0xFFE1EAF4);
static const Color blueMid    = Color(0xFF5B88B5);
static const Color blueInk    = Color(0xFF2A4868);
static const Color purpleSoft = Color(0xFFE7DDF1);
static const Color purpleMid  = Color(0xFF8B7BB8);
static const Color purpleInk  = Color(0xFF4A3E70);
static const Color greenSoft  = Color(0xFFDCEAD4);
static const Color greenMid   = Color(0xFF6A9068);
static const Color greenInk   = Color(0xFF2D4A2E);
static const Color yellowSoft = Color(0xFFF5E8B8);
static const Color yellowMid  = Color(0xFFC49840);
static const Color yellowInk  = Color(0xFF5C4318);
static const Color orangeSoft = Color(0xFFFCE0C8);
static const Color orangeMid  = Color(0xFFD17847);
static const Color orangeInk  = Color(0xFF5E3318);
static const Color tealSoft   = Color(0xFFCFE4DF);
static const Color tealMid    = Color(0xFF5A9DA8);
static const Color tealInk    = Color(0xFF1A4A52);
static const Color pinkSoft   = Color(0xFFF6DDE3);
static const Color pinkMid    = Color(0xFFC28098);
static const Color pinkInk    = Color(0xFF6B3548);
static const Color coralSoft  = Color(0xFFF8D5C8);
// coralMid = accent (#C96442), coralInk = orangeInk

// Accent
static const Color accent = Color(0xFFC96442);
static const Color accentSoft = Color(0x1AC96442);

// Dark mode warm palette
static const Color darkSurface = Color(0xFF2A2520);
static const Color darkSurfaceElevated = Color(0xFF342E28);
static const Color darkPaper2 = Color(0xFF252018);

// Dark semantic soft variants
static const Color successSoftDark = Color(0xFF1A3318);
static const Color errorSoftDark = Color(0xFF3A1A14);
static const Color warningSoftDark = Color(0xFF3A2E14);

// Dark categorical soft variants (darker for contrast)
static const Color blueSoftDark   = Color(0xFF1A2A3A);
static const Color purpleSoftDark = Color(0xFF2A1E3A);
static const Color greenSoftDark  = Color(0xFF1A2E1A);
static const Color yellowSoftDark = Color(0xFF3A3018);
static const Color orangeSoftDark = Color(0xFF3A2218);
static const Color tealSoftDark   = Color(0xFF183030);
static const Color pinkSoftDark   = Color(0xFF3A1A28);
static const Color coralSoftDark  = Color(0xFF3A2018);
```

**Legacy aliases at top of file — update to point to new names:**
```dart
const kDarkHeading = AppSemanticColors.ink;
const kMutedText = AppSemanticColors.ink2;
const kLavenderBg = AppSemanticColors.paper;
const kPeerBubbleBg = AppSemanticColors.paper3;
const kSuccessBg = AppSemanticColors.greenSoft;
const kSuccessTextDark = AppSemanticColors.greenInk;
```

---

### 1.2 `app_palette.dart`

- Add new enum value `inkOnPaper` as first (default) entry
- `inkOnPaper.seedColor` → `Color(0xFFC96442)`
- `inkOnPaper.storageValue` → `'ink_on_paper'`
- `inkOnPaper.label` → `'Ink on Paper'`
- Update `fromStorage` default fallback from `electricIndigo` to `inkOnPaper`

---

### 1.3 `app_typography.dart`

| Change | Old | New |
|--------|-----|-----|
| `displayWeight` | `FontWeight.w700` | `FontWeight.w400` |
| `h1Weight` | `FontWeight.w700` | `FontWeight.w400` |
| `h2Weight` | `FontWeight.w600` | `FontWeight.w400` |
| `h1LetterSpacing` | `-0.3` | `-0.035` |
| `h2LetterSpacing` | `-0.2` | `-0.025` |
| `h3LetterSpacing` | `-0.1` | `-0.012` |
| `displayHeight` | `1.2` | `1.05` |
| `h1Height` | `1.25` | `1.05` |
| `h2Height` | `1.3` | `1.1` |

**Add these new constants:**

```dart
// Font family names
static const String fontFamilyDisplay = 'Fraunces';
static const String fontFamilyBody = 'Inter';
static const String fontFamilyMono = 'JetBrains Mono';
static const String fontFamilySerif = 'Instrument Serif';

// Eyebrow style
static const double eyebrowSize = 10;
static const FontWeight eyebrowWeight = FontWeight.w600;
static const double eyebrowHeight = 1.4;
static const double eyebrowLetterSpacing = 0.16;

// Fraunces variable settings
static const String frauncesOpszDisplay = '"opsz" 144, "SOFT" 50, "WONK" 0';
static const String frauncesOpszH1 = '"opsz" 112, "SOFT" 40, "WONK" 0';
static const String frauncesOpszH2 = '"opsz" 96, "SOFT" 30, "WONK" 0';
```

---

### 1.4 `app_shadows.dart`

**Replace all shadow colors from cool black → warm ink, purple → terracotta:**

| Token | Old color | New color |
|-------|-----------|-----------|
| `card` | `Color(0x0F000000)` | `Color(0x0F1F1A14)` |
| `button` | `Color(0x2E5B4BCF)` | `Color(0x2EC96442)` |
| `floating` | `Color(0x1A000000)` | `Color(0x1A1F1A14)` |
| `modal` | `Color(0x1F000000)` | `Color(0x1F1F1A14)` |
| `subtleGlow` | `Color(0x145B4BCF)` | `Color(0x14C96442)` |
| `cardHover` | `Color(0x1A000000)` | `Color(0x1A1F1A14)` |
| `bottomBar` | `Color(0x0A000000)` | `Color(0x0A1F1A14)` |
| `inputFocusGlow(Color primary)` | `primary.withValues(alpha: 0.12)` | Accept `accent` param instead |
| `cardDark` | `Color(0x08000000)` | `Color(0x061F1A14)` |
| `floatingDark` | `Color(0x0F000000)` | `Color(0x0A1F1A14)` |
| `subtleGlowDark` | `Color(0x0A5B4BCF)` | `Color(0x0AC96442)` |
| `cardHoverDark` | `Color(0x0F000000)` | `Color(0x0A1F1A14)` |
| `bottomBarDark` | `Color(0x06000000)` | `Color(0x041F1A14)` |

**Add new 4-tier shadow scale:**
```dart
static const BoxShadow shadowXs = BoxShadow(color: Color(0x0A1F1A14), blurRadius: 2, offset: Offset(0, 1));
static const BoxShadow shadowMd = BoxShadow(color: Color(0x141F1A14), blurRadius: 18, offset: Offset(0, 6));
static const BoxShadow shadowLg = BoxShadow(color: Color(0x1F1F1A14), blurRadius: 60, offset: Offset(0, 18));
```

---

### 1.5 `app_radius.dart`

| Constant | Old | New |
|----------|-----|-----|
| `sm` | `10` | `9` |
| `md` | `12` | `10` |
| `sheet` | `24` | `8` |

---

### 1.6 `app_gradients.dart`

| Change | Old | New |
|--------|-----|-----|
| `successGradient` | `#ECFDF5` → `#D1FAE5` | `#DCEAD4` → `#C2DAB2` |
| `warningGradient` | `#FEF3C7` → `#FDE68A` | `#F5E8B8` → `#E8D5A0` |
| `errorGradient` | `#FEF2F2` → `#FECACA` | `#F8D5C8` → `#F0C0B0` |
| `surfaceGradient` light base | `AppSemanticColors.surface` / `.surfaceDim` | `AppSemanticColors.card` / `.paper` |
| `surfaceGradient` dark base | `AppSemanticColors.darkScaffold` | same (updated value) |
| `nudgeGradient` | `primary.withAlpha(0.08/0.03)` | `accent.withAlpha(0.08/0.03)` |
| `shimmerGradient` | neutral base/highlight | `paper2` / `card` / `paper2` |

**Add category gradients:**
```dart
static const LinearGradient blueCategoryGradient = LinearGradient(
  colors: [Color(0xFFE1EAF4), Color(0x00FFFFFF)],
  begin: Alignment.topLeft, end: Alignment.bottomRight,
);
// Add one per category: purple, green, yellow, orange, teal, pink
```

---

### 1.7 `app_theme.dart`

| Change | Old | New |
|--------|-----|-----|
| Display font | `GoogleFonts.sora(...)` | `GoogleFonts.fraunces(...)` |
| H1 font | `GoogleFonts.sora(...)` | `GoogleFonts.fraunces(...)` |
| H2 font | `GoogleFonts.sora(...)` | `GoogleFonts.fraunces(...)` |
| H3/headlineSmall | `GoogleFonts.sora(...)` | `GoogleFonts.sora(...)` — keep for H3 (Inter takes over body, Fraunces for display/H1/H2 only) |
| Body fonts | `GoogleFonts.plusJakartaSans(...)` | `GoogleFonts.inter(...)` |
| Label fonts | `GoogleFonts.plusJakartaSans(...)` | `GoogleFonts.inter(...)` |
| Caption | `GoogleFonts.plusJakartaSans(...)` | `GoogleFonts.inter(...)` |
| Scaffold bg (light) | `AppSemanticColors.surfaceDim` | `AppSemanticColors.paper` |
| Nav bar bg (light) | `scheme.surface` | `AppSemanticColors.paper.withAlpha(0.88)` |
| Nav bar bg (dark) | `AppSemanticColors.darkNavBar` | `AppSemanticColors.darkSurfaceElevated` |
| Nav indicator | `primary.withAlpha(0.14)` | same (palette seedColor is now terracotta) |
| Card bg (dark) | `scheme.surfaceContainerLow` | `AppSemanticColors.darkSurface` |
| Input fill (dark) | `scheme.surfaceContainerHighest.withAlpha(0.5)` | `AppSemanticColors.darkSurface.withAlpha(0.5)` |
| Button shape | `AppRadius.mdBorder` (12px) | `AppRadius.mdBorder` (10px after radius update) |
| Dialog shape | `AppRadius.sheetBorder` (24px) | `AppRadius.sheetBorder` (8px after radius update) |

**Also:** `GoogleFonts.fraunces()` needs `fontWeight: FontWeight.w400` (not w700). The
google_fonts package handles Fraunces optical sizing internally; explicit `fontVariationSettings`
are not directly supported but Fraunces renders well at w400 without them.

---

### 1.8 `app_motion.dart` — NO CHANGES

### 1.9 `app_spacing.dart` — NO CHANGES

---

## 2. Core Non-Theme Files

### 2.1 `lib/core/compatibility/compatibility_engine.dart`

Replace hardcoded compatibility score colors:
```dart
// OLD:
if (percentage >= 70) return const Color(0xFF10B981);
if (percentage >= 40) return const Color(0xFFF59E0B);
return const Color(0xFFEF4444);

// NEW:
if (percentage >= 70) return const Color(0xFF5B8C44);
if (percentage >= 40) return const Color(0xFFB57828);
return const Color(0xFFB4452C);
```

### 2.2 `lib/core/compatibility/compatibility_ring.dart`

No direct hardcoded colors — uses `compatibilityScoreColor()` from engine. The ring
background alpha `0.15` is fine. The text style `titleSmall` will inherit Fraunces via theme.

### 2.3 `lib/core/network/connectivity_monitor.dart`

Uses `Colors.white` for offline banner — change to `AppSemanticColors.ink` for text on
the offline banner, and banner bg from `colorScheme.error` → `AppSemanticColors.error`.

---

## 3. App Shell

### 3.1 `lib/app/app_shell.dart`

- Frost overlay for bottom nav: `Colors.white.withAlpha(...)` → `AppSemanticColors.paper.withAlpha(0.88)`
- Dark nav bg: `AppPalette` → already using `AppSemanticColors.darkNavBar` (value updates in token file)
- Active nav color: `colorScheme.primary` → derives from terracotta seed (auto)
- Inactive nav color: `AppSemanticColors.textSecondary` → `AppSemanticColors.ink3`

### 3.2 `lib/app/router/app_router.dart`

Uses `AppMotion.pageTransition` and `AppSpacing` — no changes needed.

---

## 4. Shared Components (`lib/features/shared/presentation/`)

### 4.1 `flatmates_ui.dart` (35KB, largest shared file)

This is the highest-impact component file. It contains avatar ring, menu item,
notification card, profile grid card, and many more inline widgets.

**Specific replacements (search patterns):**

| Line pattern | Replacement |
|-------------|-------------|
| `theme.colorScheme.primary` (22 occurrences) | `AppSemanticColors.accent` |
| `theme.colorScheme.primary.withValues(alpha: 0.95)` | `AppSemanticColors.accent.withValues(alpha: 0.95)` |
| `theme.colorScheme.primary.withValues(alpha: 0.72)` | `AppSemanticColors.accent.withValues(alpha: 0.72)` |
| `theme.colorScheme.primary.withValues(alpha: 0.18)` | `AppSemanticColors.accent.withValues(alpha: 0.18)` |
| `theme.colorScheme.primary.withValues(alpha: 0.1)` | `AppSemanticColors.accent.withValues(alpha: 0.1)` |
| `theme.colorScheme.primary.withValues(alpha: 0.08)` | `AppSemanticColors.accent.withValues(alpha: 0.08)` |
| `theme.colorScheme.primary.withValues(alpha: 0.15)` | `AppSemanticColors.accent.withValues(alpha: 0.15)` |
| `theme.colorScheme.primary.withAlpha(25)` | `AppSemanticColors.accent.withAlpha(25)` |
| `theme.colorScheme.primaryContainer` | `AppSemanticColors.coralSoft` |
| `theme.colorScheme.onSurface` | `AppSemanticColors.ink` |
| `theme.colorScheme.onSurfaceVariant` | `AppSemanticColors.ink2` |
| `surfaceContainerLow` (dark card bg) | `AppSemanticColors.darkSurface` |
| `surfaceContainerHighest` (disabled) | `AppSemanticColors.paper3` |
| `colorScheme.outlineVariant` | `AppSemanticColors.line` |

**Notification card icon containers:** Replace hardcoded tint backgrounds with categorical pastels:
- Booking confirmed: → `AppSemanticColors.tealSoft`, icon color `AppSemanticColors.tealMid`
- New message: → `AppSemanticColors.blueSoft`, icon color `AppSemanticColors.blueMid`
- Visit reminder: → `AppSemanticColors.yellowSoft`, icon color `AppSemanticColors.yellowMid`
- Listing approved: → `AppSemanticColors.greenSoft`, icon color `AppSemanticColors.greenMid`

**Avatar fallback gradient:** `primary → primary.withAlpha(0.72)` → `accent → accent.withAlpha(0.72)`

**Menu item icon containers:** Use categorical pastels based on context:
- My Bookings → `tealSoft`
- Shortlisted → `pinkSoft`
- My Chats → `blueSoft`
- Documents → `yellowSoft`
- Payment → `greenSoft`
- Settings → `purpleSoft`
- Help → `orangeSoft`
- Logout → `errorSoft`

### 4.2 `flatmates_card.dart`

| Pattern | Replacement |
|---------|-------------|
| `colorScheme.primary.withValues(alpha: 0.3)` (borderGlow) | `AppSemanticColors.accent.withValues(alpha: 0.3)` |
| `surfaceContainerLow` (dark bg) | `AppSemanticColors.darkSurface` |
| `colorScheme.outlineVariant` (border) | `AppSemanticColors.line` |

### 4.3 `flatmates_chip.dart`

| Pattern | Replacement |
|---------|-------------|
| `colorScheme.primaryContainer` (selected bg) | `AppSemanticColors.coralSoft` |
| `colorScheme.primary` (selected text) | `AppSemanticColors.accent` |
| `colorScheme.primary.withValues(alpha: 0.15)` (border) | `AppSemanticColors.accent.withValues(alpha: 0.15)` |
| `colorScheme.surface` (unselected bg) | `AppSemanticColors.paper2` |
| `colorScheme.onSurfaceVariant` (unselected text) | `AppSemanticColors.ink2` |
| `colorScheme.outlineVariant` (unselected border) | `AppSemanticColors.line` |
| `colorScheme.error` (danger variant) | `AppSemanticColors.error` |

### 4.4 `flatmates_search_bar.dart`

| Pattern | Replacement |
|---------|-------------|
| `AppShadows.inputFocusGlow(theme.colorScheme.primary)` | `AppShadows.inputFocusGlow(AppSemanticColors.accent)` |
| `theme.colorScheme.primary` (focus icon color) | `AppSemanticColors.accent` |
| `colorScheme.surface` (bg) | `AppSemanticColors.card` |
| `colorScheme.outlineVariant` (border) | `AppSemanticColors.line` |
| `colorScheme.onSurfaceVariant` (hint/placeholder) | `AppSemanticColors.ink3` |
| Border radius `20` | `9` |

### 4.5 `flatmates_bottom_action_bar.dart`

| Pattern | Replacement |
|---------|-------------|
| `Colors.white.withAlpha(...)` (frost light) | `AppSemanticColors.paper.withAlpha(0.92)` |
| `Color(0xFF14192A).withAlpha(...)` (frost dark) | `AppSemanticColors.darkScaffold.withAlpha(0.92)` |
| `AppSemanticColors.frostBlur` | value changes to `3.0` in token file |
| `surfaceContainerLow` (dark bg) | `AppSemanticColors.darkSurface` |
| `colorScheme.onSurface` (text) | `AppSemanticColors.ink` |
| `colorScheme.onSurfaceVariant` (text) | `AppSemanticColors.ink2` |

### 4.6 `flatmates_bottom_sheet.dart`

| Pattern | Replacement |
|---------|-------------|
| Same frost overlay as 4.5 | Same as 4.5 |
| `colorScheme.surface` (bg) | `AppSemanticColors.card` |
| `surfaceContainerLow` (dark bg) | `AppSemanticColors.darkSurface` |
| `colorScheme.onSurface` | `AppSemanticColors.ink` |
| `colorScheme.onSurfaceVariant` | `AppSemanticColors.ink2` |

### 4.7 `flatmates_segmented_control.dart`

| Pattern | Replacement |
|---------|-------------|
| `theme.colorScheme.primary` (active indicator) | `AppSemanticColors.accent` |
| `theme.colorScheme.primary` (active text/container) | `AppSemanticColors.accent` |
| `colorScheme.onSurfaceVariant` (inactive text) | `AppSemanticColors.ink2` |
| `surfaceContainerHighest` (inactive bg) | `AppSemanticColors.paper2` |
| `colorScheme.onSurface` (active text) | `Colors.white` (on terracotta) |

### 4.8 `flatmates_skeleton.dart`

| Pattern | Replacement |
|---------|-------------|
| `surfaceContainerLow` (shimmer base) | `AppSemanticColors.paper2` |
| `surfaceContainerHighest` (highlight) | `AppSemanticColors.card` |

### 4.9 `flatmates_empty_state.dart`

| Pattern | Replacement |
|---------|-------------|
| `theme.colorScheme.primary` (icon color default) | `AppSemanticColors.accent` |
| `colorScheme.onSurface` (text) | `AppSemanticColors.ink` |
| `colorScheme.onSurfaceVariant` (subtitle) | `AppSemanticColors.ink2` |

### 4.10 `flatmates_error_state.dart`

| Pattern | Replacement |
|---------|-------------|
| `colorScheme.error` (icon) | `AppSemanticColors.error` |
| `colorScheme.onSurface` (text) | `AppSemanticColors.ink` |
| `colorScheme.onSurfaceVariant` (subtitle) | `AppSemanticColors.ink2` |

### 4.11 `flatmates_header.dart`

| Pattern | Replacement |
|---------|-------------|
| Headline text style | Inherited from theme (Fraunces for headlineMedium) — no direct change |
| Back icon `colorScheme.onSurface` | `AppSemanticColors.ink` |
| Action icon `colorScheme.primary` | `AppSemanticColors.accent` |

### 4.12 `flatmates_screen.dart`

| Pattern | Replacement |
|---------|-------------|
| Scaffold background | Inherited from theme (paper) — no direct change needed |
| `AppSpacing.screen` padding | No change |

### 4.13 `flatmates_price_text.dart`

| Pattern | Replacement |
|---------|-------------|
| `colorScheme.primary` (currency symbol) | `AppSemanticColors.ink2` (was using primary for accent; now prices use ink) |
| `colorScheme.onSurface` (price digits) | `AppSemanticColors.ink` |

### 4.14 `flatmates_trust_badge.dart`

| Pattern | Replacement |
|---------|-------------|
| `theme.colorScheme.primary` (icon color) | `AppSemanticColors.accent` |
| `colorScheme.primary` (fallback icon color) | `AppSemanticColors.accent` |
| `AppSemanticColors.primaryLight` (bg) | `AppSemanticColors.coralSoft` |

### 4.15 `flatmates_profile_mini_card.dart`

| Pattern | Replacement |
|---------|-------------|
| Avatar gradient `primary → primary.withAlpha(0.72)` | `accent → accent.withAlpha(0.72)` |
| `colorScheme.onSurface` (name) | `AppSemanticColors.ink` |
| `colorScheme.onSurfaceVariant` (subtitle) | `AppSemanticColors.ink3` |
| `colorScheme.outlineVariant` (border) | `AppSemanticColors.line` |

### 4.16 `flatmates_listing_mini_card.dart`

| Pattern | Replacement |
|---------|-------------|
| `colorScheme.primary` (price) | `AppSemanticColors.accent` |
| `colorScheme.onSurface` (title) | `AppSemanticColors.ink` |
| `colorScheme.onSurfaceVariant` (subtitle) | `AppSemanticColors.ink2` |
| `colorScheme.outlineVariant` (border) | `AppSemanticColors.line` |

### 4.17 `flatmates_network_image.dart`

| Pattern | Replacement |
|---------|-------------|
| `surfaceContainerLow` (placeholder bg) | `AppSemanticColors.paper2` |
| `colorScheme.onSurfaceVariant` (error icon) | `AppSemanticColors.ink3` |

### 4.18 `flatmates_step_progress.dart`

| Pattern | Replacement |
|---------|-------------|
| `colorScheme.primary` (active step) | `AppSemanticColors.accent` |
| `colorScheme.outlineVariant` (inactive track) | `AppSemanticColors.line` |
| `surfaceContainerHighest` (track bg) | `AppSemanticColors.paper3` |

### 4.19 `flatmates_video_tour_player.dart`

| Pattern | Replacement |
|---------|-------------|
| `Colors.black54` (control overlay) | `AppSemanticColors.ink.withAlpha(0.54)` |
| `colorScheme.surface` (bg) | `AppSemanticColors.card` |
| `colorScheme.onSurfaceVariant` (icon) | `AppSemanticColors.ink3` |

---

## 5. Auth Feature (`lib/features/auth/`)

### 5.1 `auth/presentation/splash_page.dart`
- `AppPalette.electricIndigo.seedColor` → `AppPalette.inkOnPaper.seedColor` (auto via palette change)
- `colorScheme.primary` (progress bar) → auto via seed color
- `0xFF5B4BCF` hardcoded → `AppSemanticColors.accent`
- `AppGradients.primaryGradient(primary)` → auto via palette

### 5.2 `auth/presentation/login_page.dart`
- `colorScheme.error` (validation) → `AppSemanticColors.error`
- `Colors.white` (button text) → keep (white on terracotta)

### 5.3 `auth/presentation/enter_phone_page.dart`
- `colorScheme.error` (validation) → `AppSemanticColors.error`
- `Colors.white` (CTA text) → keep

### 5.4 `auth/presentation/otp_page.dart`
- `colorScheme.primary` (resend link, active indicator) → `AppSemanticColors.accent`
- `colorScheme.onSurface` (text) → `AppSemanticColors.ink`
- `colorScheme.onSurfaceVariant` (subtitle) → `AppSemanticColors.ink2`
- `colorScheme.error` (error) → `AppSemanticColors.error`

### 5.5 `auth/presentation/signup_page.dart`
- `colorScheme.primary` → `AppSemanticColors.accent`
- `colorScheme.onSurface` → `AppSemanticColors.ink`
- `colorScheme.onSurfaceVariant` → `AppSemanticColors.ink2`
- `colorScheme.error` → `AppSemanticColors.error`

---

## 6. Onboarding Feature (`lib/features/onboarding/`)

### 6.1 `onboarding/onboarding_page.dart`
- `colorScheme.primary` (CTA bg, dot indicator) → `AppSemanticColors.accent`
- `colorScheme.onPrimary` (CTA text) → `Colors.white`

### 6.2 `onboarding/onboarding_splash_pages.dart`
- `AppSemanticColors.lavenderBg` → `AppSemanticColors.paper` (alias auto-updates)
- `AppGradients` → auto via gradient updates

### 6.3 `onboarding/mode_selection_page.dart`
- `colorScheme.primary` (icon color, selected border) → `AppSemanticColors.accent`
- `colorScheme.primary.withAlpha(25)` (selected bg tint) → `AppSemanticColors.accent.withAlpha(25)`

### 6.4 `onboarding/location_selection_page.dart`
- `colorScheme.primary` (pin icon, selected city) → `AppSemanticColors.accent`
- `colorScheme.primary.withValues(alpha: 0.08)` (selected city bg) → `AppSemanticColors.accentSoft`

### 6.5 `onboarding/basic_info_page.dart`
- `AppSpacing` → no change
- `colorScheme.onSurface` / `onSurfaceVariant` → `ink` / `ink2`

### 6.6 `onboarding/preferences_page.dart`
- `colorScheme.primary` (section icon) → `AppSemanticColors.accent`
- `colorScheme.onSurface` / `onSurfaceVariant` → `ink` / `ink2`

### 6.7 `onboarding/budget_timeline_page.dart`
- `colorScheme.primary` (slider active) → `AppSemanticColors.accent`
- `colorScheme.error` → `AppSemanticColors.error`

### 6.8 `onboarding/lifestyle_quiz_page.dart`
- `colorScheme.onSurface` / `onSurfaceVariant` → `ink` / `ink2`

### 6.9 `onboarding/non_negotiables_page.dart`
- `colorScheme.primary` (selected chip) → `AppSemanticColors.accent`

### 6.10 `onboarding/profile_photo_page.dart`
- `colorScheme.primary.withValues(alpha: 0.95/0.72/0.18/0.1)` → `AppSemanticColors.accent.withValues(alpha: ...)`
- `surfaceContainerLow` → `AppSemanticColors.paper2`
- `surfaceContainerHighest` → `AppSemanticColors.paper3`

### 6.11 `onboarding/waitlist_page.dart`
- `AppGradients.nudgeGradient` → auto via gradient update
- `colorScheme.onSurface` → `AppSemanticColors.ink`

---

## 7. Discover Feature (`lib/features/discover/`)

### 7.1 `discover/discover_page.dart`
- `colorScheme.onSurface` / `onSurfaceVariant` → `ink` / `ink2`
- `AppSpacing` → no change

### 7.2 `discover/flat_details_page.dart`
- `colorScheme.primary` (share button, price) → `AppSemanticColors.accent`
- `colorScheme.onSurface` → `AppSemanticColors.ink`
- `Colors.white` (card bg) → `AppSemanticColors.card`

### 7.3 `discover/map_view_page.dart`
- `colorScheme.onSurface` / `onSurfaceVariant` → `ink` / `ink2`

### 7.4 `discover/search_filters_page.dart`
- `colorScheme.onSurface` / `onSurfaceVariant` → `ink` / `ink2`

### 7.5 `discover/share_listing_card.dart`
- `colorScheme.primary` (multiple: gradient, icon, border, indicator) → `AppSemanticColors.accent`
- `colorScheme.primary.withValues(alpha: 0.15/0.4)` → `AppSemanticColors.accent.withValues(alpha: ...)`
- `0xFF5B4BCF` (hardcoded) → `AppSemanticColors.accent`
- `Colors.white` (card bg) → `AppSemanticColors.card`

### 7.6 `discover/presentation/widgets/discover_header.dart`
- `colorScheme.onSurface` → `AppSemanticColors.ink`

### 7.7 `discover/presentation/widgets/discover_listing_card.dart`
- `colorScheme.primary` (accent elements) → `AppSemanticColors.accent`
- `colorScheme.onSurface` → `AppSemanticColors.ink`
- `Colors.white` (bg) → `AppSemanticColors.card`

### 7.8 `discover/presentation/widgets/discover_support_sections.dart`
- `colorScheme.onSurface` / `onSurfaceVariant` → `ink` / `ink2`
- `surfaceContainerLow` → `AppSemanticColors.paper2`

### 7.9 `discover/presentation/widgets/flat_details_carousel.dart`
- `colorScheme.primary` → `AppSemanticColors.accent`
- `Colors.white` → `AppSemanticColors.card`

### 7.10 `discover/presentation/widgets/flat_details_sections.dart`
- `colorScheme.onSurface` / `onSurfaceVariant` → `ink` / `ink2`

### 7.11 `discover/presentation/widgets/map_filter_bar.dart`
- `colorScheme.onSurface` / `onSurfaceVariant` → `ink` / `ink2`

### 7.12 `discover/presentation/widgets/map_listing_sheets.dart`
- `surfaceContainerLow` → `AppSemanticColors.paper2`
- `colorScheme.onSurfaceVariant` → `AppSemanticColors.ink2`

### 7.13 `discover/presentation/widgets/search_active_filter_chips.dart`
- `colorScheme.onSurface` / `onSurfaceVariant` → `ink` / `ink2`

### 7.14 `discover/presentation/widgets/search_filter_widgets.dart`
- `colorScheme.primary` (icon) → `AppSemanticColors.accent`
- `colorScheme.onSurface` / `onSurfaceVariant` → `ink` / `ink2`

### 7.15 `discover/presentation/widgets/search_more_filters_card.dart`
- `colorScheme.onSurface` / `onSurfaceVariant` → `ink` / `ink2`

### 7.16 `discover/presentation/widgets/staggered_card_appear.dart`
- `AppMotion` references → no change

---

## 8. Swipe Feature (`lib/features/swipe/`)

### 8.1 `swipe/swipe_deck_page.dart`
- `colorScheme.onSurface` / `onSurfaceVariant` → `ink` / `ink2`

### 8.2 `swipe/match_celebration_screen.dart`
- `0xFF5B4BCF` (hardcoded primary) → `AppSemanticColors.accent`
- `0xFF10B981` (hardcoded success) → `AppSemanticColors.success`
- `AppSemanticColors.compatHigh` / `compatMedium` / `compatLow` → updated values in token file
- `colorScheme.onSurface` → `AppSemanticColors.ink`

### 8.3 `swipe/match_qna_nudge.dart`
- `colorScheme.primary` → `AppSemanticColors.accent`
- `colorScheme.onSurface` / `onSurfaceVariant` → `ink` / `ink2`

### 8.4 `swipe/presentation/widgets/swipe_profile_card.dart`
- `colorScheme.primary` → `AppSemanticColors.accent`
- `colorScheme.onSurface` → `AppSemanticColors.ink`
- `AppShadows.card` / `.cardHover` / `.subtleGlow` → updated values in token file

### 8.5 `swipe/presentation/widgets/swipe_card_stack.dart`
- `AppSemanticColors.compatHigh` / `compatMedium` / `compatLow` → updated values
- `AppGradients.primaryGradient` → auto via gradient update

---

## 9. Chats Feature (`lib/features/chats/`)

### 9.1 `chats/conversations_page.dart`
- `colorScheme.primary` (unread indicator) → `AppSemanticColors.accent`
- `colorScheme.onSurface` / `onSurfaceVariant` → `ink` / `ink2`
- `AppShadows` references → updated values

### 9.2 `chats/chat_thread_page.dart`
- `surfaceContainerLow` (dark bg) → `AppSemanticColors.darkSurface`

### 9.3 `chats/match_qna_nudge.dart`
- `colorScheme.primary` → `AppSemanticColors.accent`
- `colorScheme.onSurface` → `AppSemanticColors.ink`

### 9.4 `chats/presentation/widgets/conversation_card.dart`
- `colorScheme.primary.withValues(alpha: 0.9/0.4)` → `AppSemanticColors.accent.withValues(alpha: ...)`
- `colorScheme.primary` → `AppSemanticColors.accent`
- `colorScheme.onSurface` → `AppSemanticColors.ink`
- `AppGradients.primaryGradient` → auto via gradient update

### 9.5 `chats/presentation/widgets/chat_message_bubble.dart`
- `colorScheme.primary` (sent bubble bg) → `AppSemanticColors.accent` (terracotta sent bubbles)
- `colorScheme.onSurface` (received text) → `AppSemanticColors.ink`
- `surfaceContainerLow` (dark bg) → `AppSemanticColors.darkSurface`

### 9.6 `chats/presentation/widgets/chat_input_bar.dart`
- `colorScheme.primary` (send button) → `AppSemanticColors.accent`
- `colorScheme.onSurface` → `AppSemanticColors.ink`

### 9.7 `chats/presentation/widgets/chat_app_bar.dart`
- `colorScheme.primary.withValues(alpha: 0.4)` (verified dot) → `AppSemanticColors.accent.withValues(alpha: 0.4)`
- `colorScheme.primary` → `AppSemanticColors.accent`
- `Colors.black` → `AppSemanticColors.ink`

### 9.8 `chats/presentation/widgets/chat_pre_message_area.dart`
- `colorScheme.primary` (CTA) → `AppSemanticColors.accent`

### 9.9 `chats/presentation/widgets/chat_qna_answers_card.dart`
- `colorScheme.primary` (icon, text) → `AppSemanticColors.accent`

### 9.10 `chats/presentation/widgets/chat_property_card.dart`
- `colorScheme.onSurface` / `onSurfaceVariant` → `ink` / `ink2`

### 9.11 `chats/presentation/widgets/chat_input_area.dart`
- `colorScheme.onSurface` / `onSurfaceVariant` → `ink` / `ink2`

### 9.12 `chats/presentation/widgets/chat_dialogs.dart`
- `colorScheme.error` → `AppSemanticColors.error`

### 9.13 `chats/presentation/widgets/message_list.dart`
- `colorScheme.onSurface` → `AppSemanticColors.ink`

---

## 10. Listings Feature (`lib/features/listings/`)

### 10.1 `listings/create_listing_page.dart`
- `colorScheme.onSurface` / `onSurfaceVariant` → `ink` / `ink2`

### 10.2 `listings/manage_listing_page.dart`
- `colorScheme.onSurface` / `onSurfaceVariant` → `ink` / `ink2`

### 10.3 `listings/listing_under_review_page.dart`
- `colorScheme.primary` → `AppSemanticColors.accent`
- `Colors.white` (bg) → `AppSemanticColors.card`

### 10.4 `listings/presentation/widgets/listing_step_header.dart`
- `colorScheme.primary` → `AppSemanticColors.accent`
- `colorScheme.onSurfaceVariant` → `AppSemanticColors.ink2`

### 10.5 `listings/presentation/widgets/manage_listing_card.dart`
- `colorScheme.primary` → `AppSemanticColors.accent`
- `colorScheme.onSurface` / `onSurfaceVariant` → `ink` / `ink2`

### 10.6 `listings/presentation/widgets/manage_stats_widgets.dart`
- `colorScheme.primary` → `AppSemanticColors.accent`
- `colorScheme.onSurface` / `onSurfaceVariant` → `ink` / `ink2`

### 10.7 `listings/presentation/widgets/step_flat_section.dart`
- `colorScheme.onSurface` / `onSurfaceVariant` → `ink` / `ink2`

### 10.8 `listings/presentation/widgets/step_location_section.dart`
- `colorScheme.onSurface` / `onSurfaceVariant` → `ink` / `ink2`

### 10.9 `listings/presentation/widgets/step_room_section.dart`
- `colorScheme.primary` → `AppSemanticColors.accent`
- `colorScheme.onSurface` / `onSurfaceVariant` → `ink` / `ink2`
- `surfaceContainerLow` → `AppSemanticColors.paper2`
- `colorScheme.error` → `AppSemanticColors.error`

### 10.10 `listings/presentation/widgets/step_costs_section.dart`
- `colorScheme.onSurface` / `onSurfaceVariant` → `ink` / `ink2`

### 10.11 `listings/presentation/widgets/step_about_section.dart`
- `colorScheme.onSurface` / `onSurfaceVariant` → `ink` / `ink2`

### 10.12 `listings/presentation/widgets/step_society_section.dart`
- `colorScheme.onSurface` / `onSurfaceVariant` → `ink` / `ink2`

### 10.13 `listings/presentation/widgets/step_review_section.dart`
- `colorScheme.primary` → `AppSemanticColors.accent`
- `colorScheme.onSurface` / `onSurfaceVariant` → `ink` / `ink2`

---

## 11. Profile Feature (`lib/features/profile/`)

### 11.1 `profile/profile_page.dart`
- `colorScheme.primary` (edit icon, role badge) → `AppSemanticColors.accent`
- `colorScheme.primary.withValues(alpha: 0.5)` (subtle accent) → `AppSemanticColors.accent.withValues(alpha: 0.5)`
- `colorScheme.onSurface` → `AppSemanticColors.ink`

### 11.2 `profile/edit_profile_page.dart`
- `colorScheme.onSurface` / `onSurfaceVariant` → `ink` / `ink2`

### 11.3 `profile/help_safety_page.dart`
- `colorScheme.primary` (CTA) → `AppSemanticColors.accent`
- `colorScheme.onSurface` → `AppSemanticColors.ink`

### 11.4 `profile/presentation/widgets/edit_profile_sections.dart`
- `colorScheme.primary` → `AppSemanticColors.accent`
- `colorScheme.onSurface` / `onSurfaceVariant` → `ink` / `ink2`
- `Colors.black` → `AppSemanticColors.ink`

---

## 12. Settings Feature (`lib/features/settings/`)

### 12.1 `settings/settings_page.dart`
- `colorScheme.primary` (accent elements) → `AppSemanticColors.accent`
- `colorScheme.onSurface` / `onSurfaceVariant` → `ink` / `ink2`
- `AppPalette` references → `inkOnPaper` is new default

### 12.2 `settings/settings_controller.dart`
- `AppPalette.electricIndigo` default → `AppPalette.inkOnPaper`

### 12.3 `settings/domain/settings_state.dart`
- `AppPalette.electricIndigo` default → `AppPalette.inkOnPaper`

### 12.4 `settings/change_password_page.dart`
- `colorScheme.error` → `AppSemanticColors.error`
- `colorScheme.primary` → `AppSemanticColors.accent`
- `AppGradients.primaryGradient` → auto via gradient update

### 12.5 `settings/blocked_users_page.dart`
- `colorScheme.onSurface` / `onSurfaceVariant` → `ink` / `ink2`
- `colorScheme.error` → `AppSemanticColors.error`

---

## 13. Visits Feature (`lib/features/visits/`)

### 13.1 `visits/schedule_visit_page.dart`
- `colorScheme.primary` (calendar, CTA) → `AppSemanticColors.accent`
- `colorScheme.onSurface` / `onSurfaceVariant` → `ink` / `ink2`
- `Colors.white` → `AppSemanticColors.card`

### 13.2 `visits/visits_page.dart`
- `colorScheme.onSurface` / `onSurfaceVariant` → `ink` / `ink2`
- `Colors.white` → `AppSemanticColors.card`

---

## 14. Notifications Feature (`lib/features/notifications/`)

### 14.1 `notifications/notifications_page.dart`
- `0xFF10B981` / `0xFFF59E0B` / `0xFFEF4444` (hardcoded compat/status colors) → Use `AppSemanticColors.success` / `.warning` / `.error`
- `colorScheme.onSurface` → `AppSemanticColors.ink`
- Notification icon containers → Use categorical pastels (see Section 4.1 for mapping)

---

## 15. Generated / Freezed Files

### 15.1 `settings/domain/settings_state.freezed.dart`

Auto-generated. After changing `settings_state.dart` and updating the default palette,
run: `dart run build_runner build --delete-conflicting-outputs`

---

## 16. Implementation Order

1. `app_semantic_colors.dart` — All other files depend on this
2. `app_palette.dart` — New default palette enum
3. `app_typography.dart` — New weights, font family names
4. `app_shadows.dart` — Warm shadow values
5. `app_radius.dart` — Adjusted radii
6. `app_gradients.dart` — Updated gradient colors
7. `app_theme.dart` — Wire new fonts, colors, backgrounds into ThemeData
8. `compatibility_engine.dart` — Update hardcoded score colors
9. **Run `flutter analyze`** — Verify theme layer compiles
10. `flatmates_ui.dart` — Largest single file, most replacements
11. Remaining shared components (4.2–4.19)
12. Auth feature (5 files)
13. Onboarding feature (11 files)
14. Discover feature (16 files)
15. Swipe feature (7 files)
16. Chats feature (13 files)
17. Listings feature (13 files)
18. Profile feature (4 files)
19. Settings feature (5 files)
20. Visits feature (2 files)
21. Notifications feature (1 file)
22. App shell (1 file)
23. `connectivity_monitor.dart` (1 file)
24. **Run `dart run build_runner build`** — Regenerate freezed files
25. **Run `flutter analyze`** — Zero errors
26. **Run `flutter test`** — All tests pass
27. **Visual QA** — Every screen in light + dark mode

---

## 17. Risk Areas

| Risk | Mitigation |
|------|------------|
| Fraunces font rendering on Android | Test on Android emulator; Fraunces variable features may not all render on older devices. Fall back to weight 400 without variation settings. |
| Warm dark mode contrast | Verify all text colors meet 4.5:1 contrast ratio on `#1A1612` scaffold. Test with accessibility scanner. |
| Pastel category color mapping | Need to define which feature/element maps to which of the 8 categories. Start with notification types and profile menu items. |
| Frost blur reduction (20σ → 3σ) | Lower blur may look less premium. Test on device; adjust if frosted glass feels too transparent. |
| Shadow warmth on dark surfaces | Ink-tinted shadows may be invisible on dark surfaces. Dark mode shadows already minimal — verify they add enough depth. |
| `colorScheme.fromSeed()` derivation | With terracotta seed `#C96442`, Material 3 will derive its own surface/container colors. We override scaffold and nav bar explicitly, but other Material widgets (Switch, Slider, Checkbox) will derive from terracotta automatically. Verify these look correct. |
| `flatmates_ui.dart` size | At 35KB+ with 22+ `colorScheme.primary` references, this is the highest-risk single file. Consider breaking into smaller widgets during migration. |

---

## 18. Verification Checklist

- [ ] `flutter analyze` — zero errors
- [ ] `flutter test` — all existing tests pass
- [ ] `scripts/banned_patterns.sh` — no new violations
- [ ] Light mode: scaffold bg is warm paper (#F4F3EE), not cool gray (#F8F9FA)
- [ ] Light mode: all CTAs are terracotta (#C96442), not purple (#5B4BCF)
- [ ] Light mode: display/H1/H2 headlines use Fraunces serif, body uses Inter
- [ ] Light mode: shadows are warm-tinted (ink base), not cool black
- [ ] Light mode: sent chat bubbles are terracotta, not purple
- [ ] Light mode: compatibility rings use warm green/amber/red
- [ ] Dark mode: scaffold bg is warm charcoal (#1A1612), not cool navy (#0F1321)
- [ ] Dark mode: text is warm off-white, not cool white
- [ ] Dark mode: terracotta accent is readable on dark surfaces
- [ ] Dark mode: shadows are minimal but visible
- [ ] Notification icons use categorical pastel backgrounds
- [ ] Profile menu items use categorical pastel icon containers
- [ ] Frosted glass surfaces use 3σ blur with paper-tinted overlay
- [ ] All 20 screens from DESIGN.md reviewed in both light and dark mode
- [ ] Accessibility: contrast ratios meet 4.5:1 minimum (warm ink on paper, white on terracotta)
- [ ] No hardcoded `0xFF5B4BCF`, `0xFF1A1A2E`, `0xFF6B7280`, `0xFF9CA3AF`, `0xFFE5E7EB` remain in feature files
- [ ] `pubspec.yaml` has `google_fonts` with Fraunces/Inter/JetBrains Mono available
