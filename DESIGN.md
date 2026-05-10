# DESIGN.md — 360 Flatmates Design System

> **Source of truth** for all UI tokens, component specifications, and screen-by-screen
> implementation targets. Every visual change in this codebase should reference this file.

## Register

Product app. Ink on paper — editorial, craft, warm. The aesthetic is warm-editorial:
approachable like a well-designed journal, polished enough for financial transactions
(rent, deposits), and distinctive enough to feel human in a sea of generic property portals.

**Physical scene:** A 26-year-old software engineer scrolling on their phone in a
Bangalore co-working space at 3 PM, natural daylight from floor-to-ceiling windows,
slightly distracted by Slack pings. They need to find a flatmate in the next two weeks
and are cautiously optimistic. The UI should feel like a helpful friend who works at a
design studio — someone who appreciates good typography, warm surfaces, and editorial craft.

---

## Color Tokens

### Primary Palette

| Token | Value | OKLCH (approx) | Usage |
|-------|-------|----------------|-------|
| **Primary (Accent)** | `#C96442` | oklch(0.55 0.12 30) | CTAs, active states, icons, progress bars, links |
| **Primary Soft** | `rgba(201,100,66,0.10)` | — | Light terracotta bg tints, selected states |
| **Primary Container** | `#F8D5C8` | oklch(0.90 0.04 30) | Filled chip backgrounds, hover states |

### Paper Scale (Background Surfaces)

| Token | Value | Usage |
|-------|-------|-------|
| **Paper** | `#F4F3EE` | Page scaffold background (warm off-white) |
| **Paper 2** | `#EDEBE3` | Sidebar bg, elevated surface, chip bg |
| **Paper 3** | `#E4E1D7` | Deeper surface, muted pill backgrounds |
| **Paper 4** | `#D8D4C7` | Deepest paper shade, disabled fills |
| **Surface (Card)** | `#FFFFFF` | Card backgrounds, input fills, modal surfaces |

### Ink Scale (Text)

| Token | Value | Usage |
|-------|-------|-------|
| **Ink (Text Primary)** | `#1F1A14` | Headlines, titles, important text, prices |
| **Ink 2 (Text Secondary)** | `#4A463E` | Body text, descriptions, subtitles |
| **Ink 3 (Text Tertiary)** | `#8A847A` | Timestamps, hints, placeholders, disabled text |
| **Ink 4 (Text Quaternary)** | `#B5AFA3` | Disabled outlines, faint dividers |

### Line Scale (Borders)

| Token | Value | Usage |
|-------|-------|-------|
| **Line** | `rgba(31,26,20,0.08)` | Dividers, card borders, input borders |
| **Line 2** | `rgba(31,26,20,0.04)` | Subtle borders, faint separators |
| **Line Low** | `rgba(31,26,20,0.04)` | Disabled outlines, minimal contrast |

### Semantic Colors

| Token | Value | Usage |
|-------|-------|-------|
| **Success** | `#5B8C44` | Match % rings, confirmed states, online indicators |
| **Success Soft** | `rgba(91,140,68,0.12)` | Success bg tints |
| **Error / Destructive** | `#B4452C` | Logout, errors, delete actions, declined states |
| **Error Soft** | `rgba(180,69,44,0.10)` | Error bg tints |
| **Warning** | `#B57828` | Pending states, reminders, expiring-soon badges |
| **Warning Soft** | `rgba(181,120,40,0.10)` | Warning bg tints |
| **Info** | `#C96442` (primary) | Informational badges, tips, links |

### Compatibility Score Colors

| Threshold | Color | Value | Usage |
|-----------|-------|-------|-------|
| ≥ 70% | Green | `#5B8C44` | High compatibility ring fill |
| 40–69% | Amber | `#B57828` | Medium compatibility ring fill |
| < 40% | Red | `#B4452C` | Low compatibility ring fill |

### Categorical Pastel Palette

Eight categorical colors for data visualization, feature pills, profile badges, and
compatibility dimension labels. Each has three tiers: soft (background), mid (icon/accent),
and ink (text on soft).

| Category | Soft (bg) | Mid (accent) | Ink (text on bg) | Usage |
|----------|-----------|-------------|-------------------|-------|
| **Blue** | `#E1EAF4` | `#5B88B5` | `#2A4868` | Gender filter, blue accent |
| **Purple** | `#E7DDF1` | `#8B7BB8` | `#4A3E70` | Purple accent, lifestyle |
| **Green** | `#DCEAD4` | `#6A9068` | `#2D4A2E` | Food habits (veg), nature |
| **Yellow** | `#F5E8B8` | `#C49840` | `#5C4318` | Warning category, budget |
| **Orange** | `#FCE0C8` | `#D17847` | `#5E3318` | Primary accent family, warmth |
| **Teal** | `#CFE4DF` | `#5A9DA8` | `#1A4A52` | Location, explore, map |
| **Pink** | `#F6DDE3` | `#C28098` | `#6B3548` | Profile, likes, social |
| **Coral** | `#F8D5C8` | `#C96442` | `#5E3318` | Primary accent, CTAs |

### Dark Mode Derivations

Dark mode derives a warm charcoal palette preserving the ink-on-paper feel:

| Token | Value | Usage |
|-------|-------|-------|
| **Dark Scaffold** | `#1A1612` | Page scaffold background (warm charcoal) |
| **Dark Surface** | `#2A2520` | Card surfaces, input fills |
| **Dark Surface Elevated** | `#342E28` | Elevated cards, bottom nav bg |
| **Dark Paper 2** | `#252018` | Sidebar/secondary surface |

Key dark mode rules:
- Primary accent stays `#C96442` (terracotta works well on dark)
- Ink text → lightened warm equivalents: primary `#F4F3EE`, secondary `#E4E1D7`, tertiary `#8A847A`
- Shadows reduce significantly (dark mode has inherent depth)
- Line/border alpha increases slightly for visibility on dark
- Categorical pastel soft tiers darken to maintain contrast

---

## Typography

### Font Families

- **Display / Headlines:** Fraunces (Google Fonts) — variable optical-size serif, editorial, confident. Uses `opsz` and `SOFT` variation settings for typographic warmth. Weight 400 (variable serifs are naturally expressive at light weights).
- **Body / UI:** Inter (Google Fonts) — clean, readable, neutral workhorse sans-serif
- **Mono / Eyebrow:** JetBrains Mono (Google Fonts) — code, terminals, eyebrow labels, tabular data
- **Italic Serif:** Instrument Serif (Google Fonts) — italic emphasis, pull quotes, decorative text

### Type Scale

| Name | Size | Weight | Line Height | Letter Spacing | Font | Usage |
|------|------|--------|-------------|----------------|------|-------|
| **Display** | 32sp | Regular (400) | 1.05 | -0.035 | Fraunces | Splash tagline, hero text |
| **H1** | 28sp | Regular (400) | 1.05 | -0.035 | Fraunces | Screen titles ("Profile", "Settings") |
| **H2** | 24sp | Regular (400) | 1.1 | -0.025 | Fraunces | Section heads ("Picked for You") |
| **H3** | 16sp | SemiBold (600) | 1.25 | -0.012 | Inter | Card titles, listing names |
| **H4-H6** | 14sp | SemiBold (600) | 1.3 | -0.01 | Inter | Subtitles, small headings |
| **Body Large** | 16sp | Medium (500) | 1.5 | 0 | Inter | Primary body text, greetings |
| **Body Medium** | 14sp | Medium (500) | 1.45 | 0 | Inter | Secondary text, descriptions |
| **Label Large** | 14sp | Bold (700) | 1.0 | 0.5 | Inter | Buttons, chip labels |
| **Label Medium** | 12sp | SemiBold (600) | 1.4 | 0.2 | Inter | Tags, badges, metadata |
| **Caption** | 12sp | Regular (400) | 1.4 | 0 | Inter | Timestamps, hints, placeholders |
| **Eyebrow** | 10sp | SemiBold (600) | 1.4 | 0.16em (uppercase) | JetBrains Mono | Section labels, category markers |
| **Italic Serif** | inherit | Regular (400) | inherit | -0.01 | Instrument Serif (italic) | Emphasized words, pull quotes |

### Fraunces Variable Settings

Headlines using Fraunces should set font variation settings for optimal rendering:
- `opsz`: Match the font size (e.g., H1 at 28sp → `opsz 112`, Display at 32sp → `opsz 144`)
- `SOFT`: 50 for display, 40 for H1, 30 for H2 (controls serif softness)
- `WONK`: 0 (disables alternate character forms for mobile readability)

### Rules

- Cap body line length at ~65-70 characters (Flutter's default wrapping handles this)
- Headline-to-body scale ratio >= 1.25 (we use 28/16 = 1.75 for H1/body)
- Never use em dashes; use commas, colons, or parentheses
- Fraunces headlines should feel light and editorial — never bold the serif
- Use Instrument Serif italic for inline emphasis instead of bold
- Tabular/monospace text uses JetBrains Mono with `font-variant-numeric: tabular-nums`

---

## Border Radius

| Element | Radius | Notes |
|---------|--------|-------|
| **Cards (listing, notification, menu)** | 16px | Standard content cards |
| **Cards (flat, compact)** | 12px | Flat card variant |
| **Buttons (filled CTA)** | 10px | Primary action buttons |
| **Buttons (outline/secondary)** | 10px | Secondary actions |
| **Icon buttons** | 9px | Small square icon buttons |
| **Inputs / Text Fields** | 9px | Search bars, form fields |
| **Chips / Pills (filter, tag)** | 999px | Fully circular pills |
| **Avatars** | 12px | Square-rounded avatar (editorial style) |
| **Avatar (circular variant)** | 999px | Circular for profile photos |
| **Icon containers (menu item icon bg)** | 12px | Small square icon backgrounds |
| **Nav items** | 9px | Sidebar/bottom nav item background |
| **Notification icon bg** | 999px (circular) | 48px circle for notification type icons |
| **Bottom sheet / dialog top** | 8px | Top corners only |
| **Snackbar / toast** | 16px | Notification toasts |
| **FAB / floating action** | 16px | Edit avatar overlay button |
| **Dialog** | 8px | All corners |
| **Pipeline metrics** | 8px | Small metric cards |
| **Toggle** | 999px | Rounded pill toggle |

---

## Spacing

| Token | Value | Usage |
|-------|-------|-------|
| **Screen edge padding** | 20-24px | Left/right margins for page content |
| **Section gap** | 24-28px | Vertical space between major sections |
| **Card internal padding** | 16px | Padding inside cards |
| **Element gap (tight)** | 8px | Between icon and label in a row |
| **Element gap (normal)** | 12px | Between form fields, list items |
| **Element gap (relaxed)** | 16px | Between heading and content |
| **Element gap (section)** | 24px | Between distinct content blocks |
| **List item vertical spacing** | 12-16px | Between items in a list |

---

## Shadows

All shadows use warm ink tints (`rgba(31,26,20,...)`) instead of cool black. Primary-tinted
shadows use terracotta (`rgba(201,100,66,...)`) instead of purple.

### Shadow Scale

| Token | Shadow | Usage |
|-------|--------|-------|
| **Shadow xs** | `0 1px 2px rgba(31,26,20,0.04)` | Subtle nav items, flat cards |
| **Shadow sm** | `0 2px 6px rgba(31,26,20,0.06)` | Standard content cards |
| **Shadow md** | `0 6px 18px rgba(31,26,20,0.08)` | Hover lift, elevated elements |
| **Shadow lg** | `0 18px 60px rgba(31,26,20,0.12), 0 4px 16px rgba(31,26,20,0.06)` | Modals, drawers, overlays |

### Component Shadows

| Element | Shadow | Usage |
|---------|--------|-------|
| **Cards** | `0 2px 6px rgba(31,26,20,0.06)` | Subtle elevation for content cards (sm) |
| **Elevated (FAB, dropdown)** | `0 4px 12px rgba(31,26,20,0.10)` | Floating elements |
| **Buttons (filled)** | `0 2px 8px rgba(201,100,66,0.18)` | Terracotta-tinted CTA shadow |
| **Modal / Bottom Sheet** | `0 18px 60px rgba(31,26,20,0.12), 0 4px 16px rgba(31,26,20,0.06)` | Overlay surfaces (lg) |
| **Card hover glow** | `0 4px 16px rgba(201,100,66,0.08)` | Terracotta-tinted ambient glow on interactive card press |
| **Card pressed** | `0 4px 12px rgba(31,26,20,0.10)` | Elevated shadow for pressed interactive cards |
| **Bottom bar top** | `0 1px 2px rgba(31,26,20,0.04)` | Top-edge shadow for bottom nav (xs) |
| **Input focus glow** | `0 2px 12px rgba(201,100,66,0.12)` | Terracotta-tinted glow for focused search bars / inputs |

### Dark Mode Shadow Derivations

All shadow tokens have reduced-intensity warm dark mode variants:
- Card: `0 1px 2px rgba(31,26,20,0.04)` (xs only)
- Card hover: `0 2px 6px rgba(31,26,20,0.06)` (sm)
- Terracotta glow: `0 2px 6px rgba(201,100,66,0.04)` (minimal)
- Bottom bar: none (inherent dark-mode depth)
- Navigation bar: none

---

## Frost / Glassmorphism Tokens

| Token | Value | Usage |
|-------|-------|-------|
| **Frost blur (sigma)** | 3.0 | `BackdropFilter` sigma for frosted-glass surfaces (subtler than before) |
| **Frost overlay (light)** | `rgba(244,243,238,0.88)` | Paper-tinted overlay behind frosted surfaces |
| **Frost overlay (dark)** | `rgba(26,22,18,0.88)` | Warm charcoal overlay on dark surfaces |

### Frosted-Glass Surfaces

| Surface | Background Alpha | Blur | Notes |
|---------|-----------------|------|-------|
| **Bottom navigation bar** | 0.88 | 3σ | Semi-transparent paper surface over content |
| **Bottom sheet** | 0.92 | 3σ | `ClipRRect` + `BackdropFilter` before content |
| **Bottom action bar** | 0.88 | 3σ | `ClipRRect` + `BackdropFilter` before content |

---

## Gradient Tokens

| Token | Stops | Usage |
|-------|-------|-------|
| **Primary gradient** | accent(0.95) → accent(1.0) top-to-bottom | Subtle CTA depth |
| **Surface gradient** | paper(0.5) → paper-2 top-to-bottom | Card depth wash |
| **Shimmer gradient** | paper-2 → card → paper-2 (sweep) | Skeleton loading animation |
| **Success gradient** | `#DCEAD4` → `#C2DAB2` top-left → bottom-right | Status banner wash |
| **Warning gradient** | `#F5E8B8` → `#E8D5A0` top-left → bottom-right | Status banner wash |
| **Error gradient** | `#F8D5C8` → `#F0C0B0` top-left → bottom-right | Status banner wash |
| **Nudge gradient** | accent(0.08) → accent(0.03) top-left → bottom-right | Waitlist / promo cards |
| **Ingestion category gradients** | pastel-soft → white (135deg) | Feature category cards |

---

## Component Specifications

### Primary Button (Filled CTA)

- Background: solid `#C96442` (terracotta, NOT gradient)
- Text: white, 14sp bold (Label Large), center-aligned
- Padding: horizontal 24px, vertical 16px
- Border radius: 10px
- Height: 52px (standard), 56px (tall)
- Full-width variant: stretch to parent width
- Disabled: paper-4 bg, ink-3 text
- Shadow: terracotta-tinted shadow when enabled
- Press feedback: 0.97 scale on press (150ms easeOutCubic), terracotta glow shadow

### Secondary Button (Outline)

- Border: 1.5px solid #C96442 (or line for neutral)
- Text: #C96442 (or ink for neutral)
- Same dimensions as filled button
- No shadow
- Press feedback: 0.97 scale on press (150ms easeOutCubic), border animates to 0.7 alpha

### Tertiary Button (Text)

- Text only, #C96442 color, 14sp medium weight
- No border, no background, no shadow
- Used for Skip, "See all", links

### Listing Card (Home Feed — Horizontal Layout)

- Width: 300px, height: 370px
- Layout: Row with image left (148px wide), content right
- Image: aspect ratio 0.82, radius 16px, cover fit
- Image overlay: heart icon (top-right, 40px white circle bg)
- Price: 26sp bold, ink color (NOT terracotta)
- Title: 16sp semiBold (Fraunces for hero cards), below price
- Location: row with pin icon + ink-2 text
- Info pills: beds, baths, area as compact pills
- Feature pills: furnished, wifi, etc.
- Owner row: small avatar (34px) + name + interest count
- Description: 2-line max, truncated
- Footer: solid FlatmatesButton (terracotta)
- Compatibility ring: 32px, positioned above title
- Interactive: terracotta glow shadow + optional borderGlow on press

### Profile Grid Card (Likes Tab — 2-Column Grid)

- Layout: Column within fixed-width cell (~48% of screen width)
- Photo: top, 16px radius, 1:1 or 4:5 aspect ratio
- Match % circle: green ring, top-right corner of photo, 44px — animated arc-draw on mount (300ms)
- Name: 15sp bold, below photo
- Age + location: 12sp ink-2, below name
- Profession: 12sp ink-3, below location
- "Match" CTA: full-width, solid terracotta, 10px radius, 42px height — scale bounce 0.8→1.0 on appear (easeOutBack)

### Menu Item Row (Profile / Settings)

- Height: 56px
- Layout: Row with icon container (left), label (expanded), chevron (right)
- Icon container: 40x40px, rounded 12px, pastel-tinted bg matching category
- Label: 15sp medium weight, ink
- Chevron: 20px, ink-3 color
- Divider below each item (except last in group)
- Group spacing: 24px between groups
- Press feedback: 0.98 scale + icon container AnimatedOpacity (0.8→1.0), terracotta-tinted splash

### Notification Card

- Padding: 16px horizontal, 14px vertical
- Layout: Row with icon container (left), content (center), time+dot (right)
- Icon container: 48px circle, pastel bg per type:
  - Booking confirmed: teal-soft
  - New message: blue-soft
  - Visit reminder: yellow-soft
  - Listing approved: green-soft
- Title: 15sp semiBold, ink
- Description: 13sp regular, ink-2, 2 lines max
- Timestamp: 12sp, ink-3, right-aligned
- Unread indicator: 3px terracotta left accent border + 10px terracotta dot below timestamp
- Card bg: white, 16px radius, warm shadow sm

### Search Bar

- Height: 48px
- Border radius: 9px
- Background: card white (light mode) / dark surface (dark mode)
- Border: line (rgba(31,26,20,0.08))
- Leading icon: search, 20px, ink-3
- Placeholder: 14sp regular, ink-3
- Trailing icon: optional (location pin, clear, mic)
- Focus state: terracotta-tinted glow shadow (inputFocusGlow), 1.01 scale lift, prefix icon turns terracotta

### Filter Chip

- Selected: coral-soft bg (#F8D5C8), terracotta text, optional terracotta border
- Unselected: paper-2 bg, ink-2 text, line border
- Radius: 999px (pill-shaped)
- Padding: horizontal 14px, vertical 8px
- Avatar/icon support: 16px icon before label
- Selection spring: 1.03 scale with easeOutBack overshoot on selection

### Bottom Navigation Bar

- Height: 76px
- Background: paper color at 0.88 alpha with frosted-glass backdrop blur (3σ)
- Active: terracotta (#C96442) for icon + label
- Inactive: ink-3 (#8A847A) for icon + label
- Labels: always visible (labelBehavior.alwaysShow)
- No elevation / minimal top border
- Indicator: terracotta.withAlpha(0.14) background
- Mode-dependent destinations (see Navigation section below)

### Avatar

- Default size: 52px
- Shape: 12px rounded square (editorial style); circular variant available for profile photos
- Fallback: gradient from terracotta to terracotta.withAlpha(0.72), white initials
- Shadow: subtle (blur 10, offset Y 4, ink at 8% alpha)
- With image: ClipRRect + Image.network with error fallback
- Optional ring: animated terracotta arc-draw on mount (300ms, ease-out) via `showRing: true`

### Logo (36 FLATMATES)

- Compact mode: "36" at 28sp extra-bold (Fraunces) + rotate_right icon (30px) + "FLATMATES" at 13sp (Inter, uppercase, 0.16em tracking)
- Full mode: "36" at 38sp extra-bold (Fraunces) + rotate_right icon (38px) + "FLATMATES" at 15sp (Inter, uppercase, 0.16em tracking)
- Color: terracotta (#C96442) for all elements
- "36" letter-spacing: -1.4
- "FLATMATES" letter-spacing: +1.6

### Shared Component Library

All pages should use the `Flatmates*` shared widgets from
`features/shared/presentation/` (barrel-exported via `components.dart`) instead of
duplicating Scaffold/SafeArea/ListView/async-state patterns:

| Widget | Purpose |
|--------|---------|
| `FlatmatesScreen` | Unified page scaffold (Scaffold + SafeArea + padding + 200ms fade-in, paper background) |
| `FlatmatesAsyncView` | Async state handler — renders loading/data/empty/error from `AsyncValue<T>` |
| `FlatmatesNetworkImage` | Network image with placeholder/error fallback (replaces raw `Image.network`) |
| `FlatmatesCard` | Content card container (interactive press glow, optional gradient/borderGlow) |
| `FlatmatesChip` | Filter/tag chip with `.choice()` variant (selection spring animation) |
| `FlatmatesHeader` | Page header with optional back button and actions |
| `FlatmatesSkeleton` | Shimmer loading placeholder (`.card`, `.list`, `.feed`, `.profile` variants) |
| `FlatmatesErrorState` | Error display with retry action (200ms fade-in + slide-up entry) |
| `FlatmatesEmptyState` | Empty state with illustration and message (200ms fade-in + breathing icon) |
| `FlatmatesBottomActionBar` | Sticky bottom action bar for CTAs (frosted-glass backdrop) |
| `FlatmatesBottomSheet` | Styled bottom sheet container (frosted-glass backdrop) |
| `FlatmatesSearchBar` | Search input with leading/trailing icons (focus glow + scale lift) |
| `FlatmatesSegmentedControl` | Tab-style segmented selector (sliding pill indicator) |
| `FlatmatesStepProgress` | Multi-step progress indicator |
| `FlatmatesPriceText` | Formatted price display |
| `FlatmatesTrustBadge` | Verified/trust indicator badge |
| `FlatmatesProfileMiniCard` | Compact profile row (avatar + name + subtitle) |
| `FlatmatesListingMiniCard` | Compact listing row (thumbnail + title + price) |

---

## Navigation Structure

### Mode-Dependent Bottom Navigation (PRD Section 4.1)

Every user has exactly one mode. Mode determines which bottom nav tabs they see.

| Tab | Room Poster | Co-Hunter | Open to Both |
|-----|------------|-----------|-------------|
| **1** | Home (Feed) | Home (Feed) | Home (Feed) |
| **2** | Post / Manage Property | Properties (Map View) | Properties (Map View) |
| **3** | Swipe | Swipe | Swipe |
| **4** | Likes & Chat | Likes & Chat | Likes & Chat |
| **5** | Profile | Profile | Profile |

**Tab Icons & Labels:**

| Tab | Icon (outlined / rounded) | Label |
|-----|--------------------------|-------|
| Home | home_outlined / home_rounded | Home |
| Post (Room Poster) | add_home_outlined / add_home_rounded | Post |
| Explore (Co-Hunter/Open) | map_outlined / map_rounded | Explore |
| Swipe | swap_horiz (same) | Swipe |
| Likes & Chat | favorite_border / favorite_rounded | Likes & Chat |
| Profile | person_outline / person_rounded | Profile |

**Note:** Notifications is accessed via a route (/notifications), not a tab.
The notification bell icon may appear in specific screen headers but not globally.

---

## Screen-by-Screen Specifications

### Screen 01 — Splash (`360f_01_splash.png`)

- Warm paper background (#F4F3EE)
- Centered: 360 FLATMATES logo (full size, terracotta)
- Tagline: "Find. Connect. Live Together." — Display/Regular, Fraunces, centered
- Subtitle: "The smarter way to find your flat and flatmates." — Body Medium, Inter, centered
- Illustration: Living room line art (sofa, plant, lamp, picture frame)
- Bottom: Thin progress bar (track: paper-3, fill: terracotta, height: 4px, width: 60%)

### Screen 02 — Onboarding (`360f_02_onboarding.png`)

- Background: very light warm tint (#F4F3EE)
- Illustration: Two people at cafe table (colored, warm tones)
- Headline: "Find the **right** flat. The **right** flatmates." — H1, Fraunces Regular, "**right**" words in Instrument Serif italic
- Subtitle: "Verified homes. Compatible flatmates. Better living, together." — Body Medium, Inter
- Bottom row: Skip (text button, left) + Next (filled terracotta CTA with arrow icon, right)
- Page dots: 4 dots, outline style, active = filled terracotta circle, centered above buttons

### Screen 03 — Choose Role / Mode Selection (`360f_03_choose-role.png`)

- Back arrow: top-left
- Progress indicator: 4 dots connected by lines at top, first dot active (filled)
- Heading: "I am looking to" — H1 bold
- Subtitle: "Select the option that best describes you" — Body Medium
- **3 option cards** (vertical stack, 16px radius, white bg, subtle shadow):
  - Each: 56px terracotta-soft circle with outline icon (left) + text column (center) + chevron (right)
  - Card 1: home icon + "Find a Flat / Flatmate" (H3) + "I want to find a place or a flatmate to stay with"
  - Card 2: group icon + "List My Flat / Find Flatmate" (H3) + "I want to list my flat or find a flatmate"
  - Card 3: swap_horiz icon + "Open to Both" (H3) + "I'm flexible — open to both finding a place and listing my flat"
- CTA: "Continue" — filled terracotta, full width, 10px radius

### Screen 04 — Location Selection (`360f_04_location.png`)

- Back arrow: top-left
- Heading: "Select your preferred location" — H1
- Search bar: "Search location" placeholder, search icon
- "Use my current location" row: location icon + terracotta text + chevron
- Divider
- "POPULAR CITIES" label: Caption uppercase, letter-spaced, ink-3 color
- City rows (5): pin icon (terracotta) + city name + chevron, each in a rounded container (12px radius, paper-2 bg)
- Cities: Bangalore, Hyderabad, Pune, Chennai, Mumbai
- CTA: "Continue" — filled terracotta, full width

### Screen 05 — Home / Discover (`360f_05_home-discover.png`)

- Header row:
  - Left: Greeting "Hi, [Name]!" (H2 bold)
  - Below greeting: Location with dropdown chevron
  - Right: Notification bell icon + user avatar (52px)
- Search bar: "Search by location, name or landmark", 20px radius
- Filter chips row (horizontal scroll): Nearby, 1BHK, Furnished, Budget+ (with + icon)
- "Picked for You" section header + "See all >" link
- Listing cards: horizontal scroll, 300px wide each (horizontal layout per user decision)
- "New in [City]" section: subtitle + "Explore >" link
- Bottom nav: 5 tabs (mode-dependent)

### Screen 06 — Search & Filters (`360f_06_search-filters.png`)

- Back arrow (left) + filter/tune icon (right)
- Heading: "Search & Filters" — H1
- Search bar with location pin icon (right side of bar)
- "Filters" section label — H3
- Collapsible filter sections:
  - Location: label + "Select preferred areas" hint + selected chips (with X) + chevron
  - Budget: label + "Select your budget range" + selected range text + chevron
  - Room Type: label + "Select room configuration" + pills (Any/Private/Shared)
  - Furnishing: label + "Select furnishing type" + pills (Any/Furnished/Unfurnished)
  - Gender: label + "Select preferred gender" + pills (Any/Male/Female)
  - Move-in: label + "Select move-in date" + "Anytime" + chevron
  - More filters: expandable (chevron down/up)
- CTA: "Show Results" — filled terracotta, full width, with filter icon

### Screen 07 — Flat Details (`360f_07_flat-details.png`)

- Image carousel: full-width, ~220px tall, back/share/heart icon overlays (top)
- Title: "Modern 2BHK Flat" — H2 bold
- Price: "₹24,000 / month" — H3 bold, terracotta color
- Location: pin icon + "HSR Layout, Bangalore" — Body Medium
- Icon row (compact): Beds(2), Furnished, WiFi, High-Speed, 24/7 Security, Parking, Lift
- "About this Flat" section: description paragraph
- Availability grid: Available from (date) | Posted on (date) — 2 columns
- Action buttons: "Shortlist" (outline, left) + "Contact" (filled terracotta, right)
- Verified badge: checkmark + "Verified listing"

### Screen 08 — Chat Thread (`360f_08_chat.png`)

- App bar: back arrow + avatar (40px) + name + verified dot + role badge + phone icon + video icon + 3-dot menu
- Property card: thumbnail (88px) + title + price + owner + "View Listing" outlined button + time
- Message bubbles:
  - Sent: solid terracotta (#C96442), white text, 16px radius, right-aligned
  - Received: paper-3 bg, ink text, 16px radius, left-aligned, avatar per message
- Timestamps: below each bubble, 11sp, ink-3 color
- Read receipts: double-check marks
- Input bar: smiley icon (left) + "Type a message..." field + attachment + send circle (terracotta, right)

### Screen 09 — Likes & Chat (`360f_09_likes-chat.png`)

- Header: 360 logo (compact, left) + icons (search?, more?) + "Likes & Chat" (H1, bold)
- Toggle: "Likes" (filled terracotta pill) / "Chats" (outline pill)
- **Likes tab:** "People who liked you" (heart icon + text + "See all")
  - 2-column grid of profile cards (photo, name/age/location/profession, match % circle, Match CTA)
- **Chats tab:** Conversation list (avatar, name, preview, time)
- Safety banner: shield icon + "Safety first" + privacy note + chevron
- Bottom nav: 5 tabs

### Screen 10 — Schedule Visit (`360f_10_schedule-visit.png`)

- Back arrow (left) + 360 logo (top-center)
- Property card: image + title + matched date + owner avatar/name
- "Schedule Visit" — H2 bold
- Calendar picker: month navigation, date grid, selected date circled (terracotta)
- "Select Time Slot": Morning / Afternoon (selected, terracotta fill) / Evening pills
- "Add a Note (Optional)": textfield with character count
- Privacy note: shield icon + "Your visit request will be shared with [Owner]."
- CTA: "Send Request" — filled terracotta, full width, with paper plane icon
- Bottom nav: 5-6 tabs

### Screen 11 — Add Listing Step 1 (`360f_11_add-listing.png`)

- Back arrow (left) + 360 logo (top-center)
- "List Your Flat" — H1 bold
- "Step 1 of 7" + progress bar (thin, terracotta fill proportion)
- Form fields (white bg, no card wrappers):
  - Flat Details (dropdown with chevron)
  - Flat Title (text input, placeholder "E.g. 2BHK in Koramangala")
  - Location (dropdown with pin icon + chevron)
  - Rent (text input with ₹ prefix icon)
  - Room Type (dropdown with chevron)
  - Furnishing (dropdown with chevron)
- CTA: "Next" — filled terracotta, full width

### Screen 12 — Add Photos (`360f_12_photos.png`)

- Back arrow (left)
- "Add Photos" — H1 bold
- Tips toggle (right-aligned): "Tips" pill button
- Instruction: "Add clear photos of the room and common areas to get more matches."
- Uploaded photo cards: 3 shown, each with delete (X) icon overlay, 16px radius
- "+ Add More" link with plus icon
- Pagination dots: 3 dots, second active
- CTA: "Next" — filled terracotta, full width

### Screen 13 — Preferences (`360f_13_preferences.png`)

- Back arrow (left)
- Progress bar: 5 segments, third segment filled (step 3 of 5+)
- "Preferences" — H1 bold
- Subtitle: "Tell us what matters to you so we can find the right flatmates and homes."
- Collapsible sections (each with icon, label, hint, chevron):
  - Preferred Gender: pills (No Preference / Male Only / Female Only / Other)
  - Allowed Flatmates: number pills (1 / 2 / 3 / 4+)
  - Food Habits: pills (Veg / Non-Veg / Egggetarian / No Preference)
  - Pets: pills (Yes / No / No Preference)
  - Smoking: pills (No / Yes / No Preference)
  - Move-in Timeline: dropdown ("Within 1 Month")
- CTA: "Next →" — filled terracotta, full width, with arrow icon

### Screen 14 — Review & Publish (`360f_14_review-publish.png`)

- Back arrow (left)
- Progress bar: 5 segments, fourth filled (step 4 of 5)
- "Review Your Listing" — H1 bold
- Subtitle: "Please review all details before publishing."
- Property photo + details card (compact listing preview)
- Expandable sections (each with icon + label + edit chevron):
  - Preferences summary
  - Property Rules summary
  - Nearby & Notes summary
- Review notice banner: shield icon + "We'll review your listing" + approval note
- CTA: "Publish Listing" — filled terracotta, full width, with upload icon
- "Save as Draft" — text link, centered

### Screen 15 — Profile (`360f_15_profile.png`)

- Header: "Profile" (H1, left) + settings gear icon (top-right)
- Avatar: large circular photo with edit pencil FAB overlay (bottom-right, terracotta circle bg)
- Name: "Rahul Sharma" — H2 bold, centered
- Role badge: checkmark icon + "Co-Hunter" — outlined pill, terracotta color
- Location: pin icon + "Bengaluru, Karnataka" — Body Medium, centered
- Menu list (using FlatmatesMenuItem):
  1. My Bookings (calendar_month_outlined)
  2. Shortlisted (favorite_border)
  3. My Chats (chat_bubble_outline)
  4. Documents (description_outlined)
  5. Payment Methods (payment_outlined)
  6. Settings (settings_outlined)
  7. Help & Support (help_outline)
  8. Logout (logout, error color)
- Bottom nav: 5 tabs

### Screen 16 — Listing Under Review (`360f_16_listing-under-review.png`)

- 360 logo (top-left area)
- Clipboard/checkmark illustration (center-top)
- "Listing Under Review" — H1 bold
- "Thank you! Your listing has been submitted." — Body Medium
- "Review Listing" button — outlined terracotta
- "We'll review your listing within 24 hours" — highlighted text
- "What happens next?" — H3 + 3 numbered steps:
  1. Team reviews (quality + safety)
  2. Verify you (ID confirmation)
  3. Go live (flat connecting)
- Property preview card (small)
- CTAs: "Go to Home Feed" (filled, with home icon) + "View Listing" (outline, with eye icon)
- Bottom nav: 5-6 tabs

### Screen 17 — Notifications (`360f_17_notifications.png`)

- Header: "Notifications" (H1, left) + checkmark/mark-all-read icon (top-right)
- Notification cards (using FlatmatesNotificationCard):
  1. Booking Confirmed — calendar icon, "Your visit with Arjun is confirmed..."
  2. New Message from Priya — chat icon, "Hey! I'm interested..."
  3. Visit Reminder — bell icon, "You have a visit with Neha..."
  4. Listing Approved — verified icon, 'Your listing "2BHK..." is now live.'
- Each card: unread dot (terracotta) for unread items
- Bottom nav: 5 tabs, notifications tab highlighted if present

### Screen 18 — Help & Support (`360f_18_help-support.png`)

- Back arrow (left)
- "Help & Support" — H1 bold
- Search bar: "Search for help" placeholder
- Category rows (using FlatmatesMenuItem pattern):
  1. FAQ (?) — "Find answers to common questions"
  2. Popular Topics (fire) — "Explore trending help topics"
  3. Payments & Refunds (wallet) — "Payment issues, refunds and more"
  4. Booking & Agreements (clipboard) — "Bookings, agreements & policies"
  5. Account & Profile (person) — "Manage your account and profile"
  6. Contact Support (headset) — "Get in touch with our support team"
- CTA: "Chat with Us" — filled terracotta, full width, with chat icon
- Note: "We usually reply in a few minutes" with shield icon
- Bottom nav: 5 tabs

### Screen 19 — Settings (`360f_19_settings.png`)

- Back arrow (left)
- "Settings" — H1 bold, centered
- Groups using FlatmatesMenuItem:
  - **Account:**
    1. Edit Profile (person)
    2. Change Password (lock)
    3. Privacy & Security (shield)
    4. Preferences (tune)
  - **App:**
    5. Notification Settings (bell)
    6. Blocked Users (person_off)
  - **Legal:**
    7. About (info)
    8. Terms & Conditions (description)
  - **Standalone:**
    9. Logout (logout, error text + error icon)
- Bottom nav: 5 tabs, Settings active

### Screen 20 — Post & Manage Property (`360f_20_post-manage-property.png`)

- 360 logo (top-left) + icons (search?, more?)
- "Post & Manage Property" — H1 bold
- "New Listing" CTA: filled terracotta, full width, with grid icon + "New Listing" text
- Tab bar: "Active Listings (N)" / "Drafts (N)" / "Expired (N)" — segmented control
- Property cards:
  - Image + title + price + quick stats (beds/baths/sqft/wifi)
  - Owner info row
  - Stats grid (2 rows x 3 cols): Match Count (24) | Edit | Boost | View Stats (3.8k) | Review | Share
- Bottom nav: 5 tabs, Post/Manage active

---

## Animation Guidelines

| Animation | Duration | Curve | Notes |
|-----------|----------|-------|-------|
| Page transitions (route push/pop) | 250ms | ease-out-quart (decelerate) | Default Material transition |
| Android page transition | — | FadeUpwardsPageTransitionsBuilder | Applied via `pageTransitionsTheme` |
| iOS page transition | — | CupertinoPageTransitionsBuilder | Platform-convention slide |
| Tab switch (bottom nav) | 200ms | ease-out | Fade + slight scale |
| Button press (ripple/scale) | 150ms | ease-out-circ | Scale down to 0.97 on press |
| Card appear (staggered list) | 300ms | ease-out | 50ms stagger between items |
| Hero / shared-element transition | 300ms | ease-out-quart | Shared element transitions |
| AnimatedSwitcher | 220ms | ease-out-cubic | Content swap transitions |
| Page entry fade-in | 200ms | ease-out-cubic | FlatmatesScreen mount animation |
| Stagger item delay | 100ms | — | Delay between menu group / list item animations |
| Breathing icon pulse | 2000ms | linear | Repeating reverse for empty-state icons |
| Swipe card rotation | varies | spring physics | Max 15° rotation |
| Compatibility ring fill | 300ms | ease-out | Animated arc drawing |
| Avatar ring draw | 300ms | ease-out | Animated arc on mount via `showRing` |
| Match celebration | <600ms | ease-out-expo | Card flip + confetti |
| Filter chip select | 150ms | ease-out-back | 1.03 scale spring overshoot |
| Bottom sheet show/dismiss | 280ms | ease-out-quart | From bottom |
| FAB → expanded state | 250ms | ease-out-back | Slight overshoot |
| Skeleton shimmer | 1200ms | linear | Repeating gradient |
| Segmented pill slide | 220ms | ease-out-quart | AnimatedPositioned indicator |

### Motion Rules

- Don't animate layout properties (use AnimatedSize/Position instead)
- Ease-out curves only (exponential: quart/quint/expo)
- No bounce, no elastic (except intentional FAB overshoot)
- Keep animations under 400ms for micro-interactions
- Respect `reduceAccessibility` / animation scale settings

### Premium Motion Behaviors

- **Press feedback**: All interactive cards, buttons, and menu items scale down to 0.97 on pointer-down via `AnimatedScale` + `Listener` (not `GestureDetector`, to avoid gesture arena conflicts). Return to 1.0 on pointer-up with `easeOutCubic` (150ms).
- **Focus glow**: Search bar and focused inputs gain a terracotta-tinted `BoxShadow` glow (`inputFocusGlow`) + subtle 1.01 scale lift on focus.
- **Selection spring**: Chips scale to 1.03 with `easeOutBack` overshoot on selection, returning to 1.0 on deselect.
- **Staggered appear**: Feed cards fade in + slide up with 50ms stagger between items (`StaggeredCardAppear`). Profile menu groups stagger with 100ms delay between groups.
- **Animated ring**: Compatibility rings and avatar rings draw their arc on mount (300ms, ease-out) via `CustomPaint` inside `AnimatedBuilder`.
- **Frosted glass**: Bottom nav, bottom sheets, and bottom action bars use `BackdropFilter` with 3σ blur + semi-transparent paper surface (0.88–0.92 alpha). Apply `ClipRRect` before `BackdropFilter` to constrain blur bounds.
- **Page entry**: `FlatmatesScreen` wraps body in 200ms `FadeTransition` for silky page entry. Android routes use `FadeUpwardsPageTransitionsBuilder`.
- **Sliding pill**: `FlatmatesSegmentedControl` uses `AnimatedPositioned` for a sliding selection indicator (220ms, easeOutQuart).
- **Entry animations**: `FlatmatesEmptyState` and `FlatmatesErrorState` fade in + slide up on mount (200ms). Empty-state icons have a subtle 2s breathing (pulse) animation.

---

## Dark Mode

All tokens above apply to both light and dark modes. Dark mode specifics:

- Backgrounds derive from warm charcoal palette (`#1A1612`, `#2A2520`, `#342E28`)
- Text colors use lightened warm ink equivalents: `#F4F3EE` (primary), `#E4E1D7` (secondary), `#8A847A` (tertiary)
- Cards use `#2A2520` instead of pure white
- Primary terracotta stays the same (#C96442) — it works well on dark
- Borders become slightly more visible (dark mode needs more contrast; use `rgba(31,26,20,0.16)`)
- Shadows are reduced (dark mode has inherent depth)
- Categorical pastel soft tiers darken to maintain contrast
- All screens must be tested in dark mode after any light-mode changes

---

## Accessibility

- Minimum touch target: 44x44px for all interactive elements
- Color contrast ratio: minimum 4.5:1 for normal text, 3:1 for large text
- Don't convey information by color alone (always pair with icons/text)
- Screen reader labels on all interactive elements (via Semantics or Tooltip)
- Focus indication visible for keyboard/navigation users
- Reduced motion: disable/ simplify all animations when system setting is on
