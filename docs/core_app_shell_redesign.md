# Core 5-Tab App Shell Redesign

Last updated: 2026-05-16

## Scope

This phase redesigns the core logged-in shell only:

1. Home
2. Search
3. Swipe
4. Inbox
5. Me

Swipe remains the center engagement tab and must stay visible in bottom navigation.

## UX Audit Summary

Primary issues found in the current shell:

- Navigation labels were unclear: Explore, Likes & Chat, and Profile did not match the product mental model.
- Mode labels used internal language: Room Poster, Co-Hunter, Open to Both.
- Broken image errors could show technical broken-image icons.
- Match UI could expose low-confidence scores as percentages.
- Home header underused the greeting and value proposition.
- Inbox copy felt like a feature label, not a messaging product.
- Me lacked profile strength, trust motivation, and grouped account actions.
- Swipe actions were icon-only, which weakened clarity and accessibility.

## Information Architecture

Bottom navigation:

| Tab | Purpose | Primary route |
| --- | --- | --- |
| Home | Personalized recommendations and market pulse | `/discover` |
| Search | Map-led room discovery and filters | `/tab2` |
| Swipe | Fast flatmate matching with trust context | `/swipe` |
| Inbox | Likes, outgoing likes, and chats | `/chats` |
| Me | Profile, trust, documents, payments, settings | `/profile` |

Room-posting and listing management should remain available through profile or contextual CTAs, not as a mode-dependent bottom tab.

## Visual Design System

Use existing tokens from `lib/core/theme/` and avoid new magic numbers.

Colors:

- Background: `AppSemanticColors.paper`
- Surface: `AppSemanticColors.card`
- Primary action: `AppSemanticColors.accent`
- Text primary: `AppSemanticColors.textPrimaryFor`
- Text secondary: `AppSemanticColors.textSecondaryFor`
- Borders: `AppSemanticColors.line`
- Success/trust: `AppSemanticColors.success`
- Warning: `AppSemanticColors.warning`
- Error: `AppSemanticColors.error`

Components:

- Cards: `FlatmatesCard`, subtle border or shadow, no nested cards.
- Search: `FlatmatesSearchBar`, 48px minimum height, no truncated placeholder.
- Chips: `FlatmatesChip`, selected state uses terracotta tint and text label.
- Trust: `FlatmatesTrustBadge`, visible near people, listings, and profile state.
- Empty states: `FlatmatesEmptyState`, always title, explanation, CTA when action is available.
- Images: `FlatmatesNetworkImage`, never show a broken-image icon.
- Buttons: `FlatmatesButton` for text and icon CTAs. Avoid icon-only primary actions unless the surrounding UI is explicit.

## Core Screen Redesign

### Home

Goal: show value in 10 seconds and move users toward Search or Swipe.

Structure:

- Location selector
- Notification icon
- Avatar
- Greeting: "Good afternoon, [name]"
- Subtitle: "Find your next flatmate in [city]"
- Search: "Search area, budget, flatmate..."
- Market insight card: active verified people nearby
- Best matches for you
- New rooms near you
- Moving soon

Cards should show price, title, locality, availability, room metadata, trust cue, and save or like action.

### Search

Goal: make map browsing comparable and decisive.

Structure:

- Search bar: "Search location, sector, society..."
- Filter chips: budget, room type, move-in, gender, verified
- Map pins with compact prices
- Cluster bottom sheet for dense areas
- Listing bottom sheet for selected pin

Required next iteration:

- Add "Search this area" after map movement.
- Keep selected pin visually distinct.
- Support half and full bottom sheet states for list comparison.

### Swipe

Goal: make matching fun, fast, and trustworthy.

Current behavior to preserve:

- Left swipe: Pass
- Right swipe: Like
- Tap card: expanded profile

Required UI:

- Large real photo or premium "Photo pending" fallback
- Mode chip: Looking for a room, Has a room, Looking together
- Match ring only when data is available, otherwise "New"
- Match explanation chips below the photo
- Swipe gestures only (no on-screen action buttons): swipe right to Like, swipe left to Pass
- Expanded profile includes compatibility breakdown, lifestyle, budget, location, trust, and report/block access

Match scores:

- Never show 0%.
- Use "New" when insufficient data.
- Prefer explainable scores with visible reasons.

### Inbox

Goal: feel like a communication hub, not a combined utility page.

Tabs:

- Likes You
- You Liked
- Chats

Copy:

- Empty likes: complete profile to improve visibility.
- Empty chats: like a few profiles to start conversations.
- Safety banner: "Visit the room before paying."

Required next iteration:

- Add a separate Matches segment when backend data supports mutual matches as a list.
- Add schedule call or schedule visit CTA after a match is created.

### Me

Goal: make the profile feel trustworthy and growth-oriented.

Structure:

- Title: Me
- Avatar, name, verification badge, city, looking status
- Profile strength card with progress and Complete profile CTA
- Discovery group: schedule, shortlisted, chats
- Trust group: documents, payment methods
- Account group: settings, help and safety
- Logout as separate destructive action

Avoid duplicate settings gear and settings row.

## User Flow Improvements

Activation:

1. User lands on Home.
2. User sees local verified activity.
3. User taps Swipe or Search.
4. User likes a profile or room.
5. Mutual interest creates an Inbox conversation.
6. Trust and safety CTA pushes visit-first behavior.

Conversion CTAs:

- Home: View active seekers
- Search: Like listing, View details
- Swipe: Pass, Like, View full profile
- Inbox: Match, Open conversation
- Me: Complete profile

## Trust And Safety Design

Trust indicators:

- Phone/email verified: Basic Verified
- Identity plus phone: Verified
- Identity, documents, and photo check: Verified Plus

Safety moments:

- Inbox safety banner: visit before payment
- Profile verification and documents in Me
- Report/block in expanded Swipe and chat
- No outside-payment warning in payment or schedule flows

## Empty, Loading, And Error States

Shared rules:

- Use skeletons for loading cards and lists.
- Use premium photo fallbacks for missing or failed images.
- Never show technical broken-image icons.
- Each empty state needs a title, short explanation, and primary CTA where possible.
- Failed map loading should offer Retry and Search filters.
- Message send failure should keep the draft and offer Retry.

## Implementation Notes

- Keep GoRouter and existing Riverpod providers.
- Keep all authenticated network traffic through shared Dio.
- Use `FlatmatesEndpoints` for API paths.
- Use existing `Flatmates*` shared components.
- Add localized copy in English and Hindi together.
- Keep tap targets at least 44x44.
- Use `Listener` for press effects around interactive children.
- Avoid hardcoded durations and curves. Use `AppMotion`.
- Keep bottom nav fixed and safe-area aware.
- Test small Android screens for search hint, bottom nav labels, and Swipe action labels.

## QA Checklist

- Swipe is still a main bottom tab.
- Bottom nav reads Home, Search, Swipe, Inbox, Me.
- No broken image icons are visible.
- Missing photos render a polished fallback.
- Search placeholders do not clip.
- Mode labels use user-facing language.
- No 0% match badges appear.
- Swipe buttons have icon and text labels.
- Empty states guide the next action.
- Profile has a visible completion or trust motivation.
- Inbox has clear likes and chats separation.
- All key icon buttons have labels or text context.
- English and Hindi strings are updated together.
- `flutter analyze` is clean or remaining issues are known pre-existing infos.
- At least one fast Flutter test passes.

## Risks And Open Decisions

- The backend should expose reliable verification levels before showing Verified Plus.
- Search area behavior needs map camera-change support for "Search this area."
- Mutual matches need a dedicated API or filtered conversation state before adding a separate Matches tab.
- Photo visibility rules should be enforced server-side so public discovery requires at least one approved photo.
- City naming should be standardized across backend seed data and user profiles. Prefer Gurugram.
