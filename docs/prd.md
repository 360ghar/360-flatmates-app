# 360 Flatmates
**Find your flatmate. Find your vibe.**
*Product Requirements Document | Version 1.0*


|                                                          |                                                      |
| -------------------------------------------------------- | ---------------------------------------------------- |
| **Status**: Draft — V1 Scope Locked                        | **Platform**: Flutter (iOS + Android)                  |
| **Target Market**: Pan-India — Young Professionals (22–32) | **Monetization**: None in V1 — freemium hooks prepared |

# **1. Executive Summary**

360 Flatmates is a swipe-based flatmate-finding app built for India's young professional demographic. Inspired by the interaction patterns of modern dating apps, 360 Flatmates combines rich property listings, lifestyle compatibility scoring, and a structured conversation system to make flatmate discovery fast, trustworthy, and personality-driven.

The Indian flatmate market is large, fragmented, and deeply broken. Current solutions — Facebook groups, broker networks, NoBroker listings — are transactional and treat flatmate finding like furniture shopping. They optimise for finding a room, not finding the right person to share it with. 360 Flatmates's thesis is that shared living is fundamentally a human compatibility problem, and the best UX paradigm for human compatibility at scale is the one dating apps perfected.

360 Flatmates addresses three distinct user intents under one roof: finding a co-hunter to flat-search with, advertising a spare room to a quality flatmate, and putting your profile out there for any of the above. The result is a two-sided marketplace with three user modes, a compatibility engine, structured listing templates, rich chat with visit scheduling, and a society insights layer — all built on Flutter for a single shared codebase across iOS and Android.

# **2. Goals & Success Metrics**

## **2.1 Product Goals**

- **Reduce time-to-flatmate** — from the current average of 3–6 weeks to under 10 days for active users.

- **Increase trust** — through structured profiles, lifestyle compatibility scoring, and manual listing review.

- **Drive organic growth** — via WhatsApp-shareable listing cards that create a viral referral loop without ad spend.

- **Build monetization headroom** — by establishing freemium UI patterns (boost slots, swipe caps) even before charging begins.

## **2.2 V1 Success Metrics**

|                                          |                   |                   |
| ---------------------------------------- | ----------------- | ----------------- |
| **Metric**                               | **30-Day Target** | **90-Day Target** |
| Onboarding completion rate               | **> 65%**         | **> 72%**         |
| Listing approval time (manual review)    | **< 24 hours**    | **< 12 hours**    |
| Swipe-to-match conversion rate           | **> 8%**          | **> 12%**         |
| Match-to-chat conversion rate            | **> 55%**         | **> 65%**         |
| Chat-to-visit-scheduled rate             | **> 20%**         | **> 30%**         |
| Listing share-to-install rate (WhatsApp) | **> 5%**          | **> 10%**         |
| D7 user retention                        | **> 35%**         | **> 45%**         |
| Average onboarding time                  | **< 4 minutes**   | **< 3.5 minutes** |

# **3. Target Users & Personas**

## **3.1 Primary Demographic**

- **Age** — 22–32 years

- **Occupation** — Young professionals — tech, finance, consulting, design, media

- **Location** — Pan-India, with density expected in Bangalore, Delhi NCR, Mumbai, Hyderabad, Pune

- **Device** — Mid-range to flagship Android (primary), iPhone (secondary)

- **Behaviour** — High WhatsApp usage, familiar with swipe UX, privacy-conscious, income-positive but time-poor

## **3.2 User Personas**

### **Persona A — Priya, 26, Bangalore**

Software engineer relocating from Chennai for a new job. Doesn't know anyone in Bangalore. Needs a room within 2 weeks in Koramangala or HSR. Introverted, non-smoker, vegetarian, WFH 3 days a week. Her biggest fear: ending up with a flatmate whose lifestyle is incompatible with hers.

Mode: Co-Hunter / Open to Both. Primary need: compatibility first, location second.

### **Persona B — Arjun, 29, Delhi NCR**

Works in a startup, currently in a 3BHK in Gurugram. One flatmate is moving out. Doesn't want to deal with brokers. Needs someone clean, professional, who won't throw parties on weekdays. Has a dog.

Mode: Room Poster. Primary need: find a trustworthy person fast, with minimum friction.

### **Persona C — Meera & Siddharth, 24 & 25, Mumbai**

College friends both starting new jobs in Mumbai. Want to co-hunt together but need a third person to make rent affordable. Looking for someone with a similar social vibe who won't mind occasional house parties on weekends.

Mode: Co-Hunter (group). Primary need: find a third person to join their flat-search.

# **4. User Modes**

Every 360 Flatmates user belongs to exactly one mode at any given time. Mode is selected during onboarding and can be changed from the Profile tab at any time. Mode determines which version of the bottom navigation bar the user sees and which listing type they create.

|                  |                                                                                      |                                                                                                                                          |
| ---------------- | ------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------- |
| **Mode**         | **Who They Are**                                                                     | **What They Create**                                                                                                                     |
| **Room Poster**  | Already residing in a flat. Wants to rent out one spare room to a compatible person. | A structured room listing with property details, existing flatmate profiles, amenities, pricing breakdown, and preferred-person profile. |
| **Co-Hunter**    | Looking for one or more people to flat-search with together and split rent.          | A personal profile with budget, preferred area, lifestyle tags, move-in timeline, and what kind of co-hunter they want.                  |
| **Open to Both** | Flexible — happy to move into an existing flat or co-hunt with someone from scratch. | A combined profile indicating both openness to existing rooms and willingness to co-hunt.                                                |

## **4.1 Bottom Navigation by Mode**

|         |                        |                       |                       |
| ------- | ---------------------- | --------------------- | --------------------- |
| **Tab** | **Room Poster**        | **Co-Hunter**         | **Open to Both**      |
| Tab 1   | Home (Feed)            | Home (Feed)           | Home (Feed)           |
| Tab 2   | Post / Manage Property | Properties (Map View) | Properties (Map View) |
| Tab 3   | Swipe                  | Swipe                 | Swipe                 |
| Tab 4   | Likes & Chat           | Likes & Chat          | Likes & Chat          |
| Tab 5   | Profile                | Profile               | Profile               |

# **5. Onboarding Flow**

The entire onboarding must be completable in under 4 minutes. Every screen has a single primary action. Progress is shown via a minimal dot/step indicator. Users can skip optional steps and complete them later from their profile.

## **5.1 Splash Screens (3 screens)**

Cinematic, full-bleed illustration screens. No feature bullet points. Convey the lifestyle and emotional promise of the product:

- Screen 1 — A warm, sunlit room. Headline: "Your perfect flat is out there."

- Screen 2 — Two people sharing a cup of coffee at a kitchen counter. Headline: "So is your perfect flatmate."

- Screen 3 — App mockup. Headline: "360 Flatmates finds both."

- CTA on Screen 3: Get Started

## **5.2 Phone Authentication**

- Single screen: phone number input + country code selector (India +91 default)

- OTP screen: 6-digit OTP auto-read via SMS listener on Android

- No email, no password, no social login in V1

## **5.3 Mode Selection**

Single screen with three large illustrated cards:

- I have a room to give — "I'm living in a flat and looking for a flatmate to fill a spare room."

- Looking for a flatmate to co-hunt with — "I'm looking for someone to flat-search alongside."

- I'm open to both — "I'll move into an existing flat or team up to find a new one."

## **5.4 Basic Information**

One screen. Fields:

- First name (required)

- Age (required — must be 18+)

- Profession / Job title (required)

- City (required — searchable dropdown, all Indian cities)

- Preferred locality / area within city (optional at onboarding, required before swiping)

## **5.5 Profile Photo**

- Minimum 1 photo required (enforced before proceeding)

- Nudge: "Add 3 photos — profiles with 3+ photos get 4x more matches"

- Camera or gallery upload. No crop enforcement in V1 (just center-crop for card thumbnails).

## **5.6 Lifestyle Quiz**

8 swipeable quiz cards — one question per card. Feels like a personality test, not a form. Each card has a large emoji, a short question, and 2–4 answer options (tappable chips or a slider). Required: all 8.

|                         |                                                                  |
| ----------------------- | ---------------------------------------------------------------- |
| **Question**            | **Answer Options**                                               |
| 🌙 Sleep schedule       | Early bird (before 10pm) / Night owl (after midnight) / Flexible |
| 🧹 Cleanliness standard | Minimal / Tidy / Spotless (slider scale)                         |
| 🍽️ Food habits         | Vegetarian / Vegan / Non-vegetarian / No preference              |
| 🚬 Smoking & drinking   | Neither / Smoke outside only / Drink occasionally / Both fine    |
| 👥 Guests policy        | No overnight guests / Occasional ok / Open house                 |
| 🎉 Parties at home      | Never / Occasional weekends / Party-friendly                     |
| 💻 Work style           | WFH mostly / Office mostly / Mixed                               |
| 🐾 Pets                 | No pets / Have pets / Pet-friendly (no own pets)                 |

## **5.7 Budget & Move-In Timeline**

One screen, three inputs:

- Monthly budget range — dual-handle slider (min: Rs 5,000 / max: Rs 1,00,000+)

- Preferred localities — multi-select chip picker within selected city

- Move-in timeline — four chips: Immediate / This Month / Next Month / Flexible

## **5.8 Room Poster Listing Builder (Room Poster mode only)**

Room Posters proceed through one additional step after budget/timeline: the structured listing builder. This is described in full in Section 7.2. After completion, the listing enters manual review (24-hour SLA). The user lands on the home feed immediately with a 'Listing Under Review' banner.

> **Design Principle:** Every onboarding screen has exactly one primary CTA button. The back button is always visible. Progress dots are shown at the top. Zero dark patterns — no 'skip and lose features' framing.

# **6. Information Architecture**

## **6.1 Tab 1 — Home (Feed)**

- Default landing screen after onboarding

- 'Picked for You' horizontal scroll row — rules-based recommendations (same locality, vibe, budget overlap, compatible non-negotiables). Label: "Based on your profile"

- 'New in \[City]' section — profiles added in the last 48 hours

- 'Moving Soon' section — listings with move-in date within 7 days (countdown badge)

- Vibe filter chips at top: All / Quiet & Focused / Social & Lively / Working Professionals / Students / Pet Household

- Move-in timeline filter: All / Immediate / This Month / Next Month / Flexible

## **6.2 Tab 2 — Properties (Map View) / Post & Manage (Room Poster)**

### **Map View (Co-Hunter & Open to Both)**

- Clustered pins by locality. Color: orange = Room Available, blue = Co-Hunter.

- Filter bar: Budget range slider, Room type (single/shared/entire flat), Move-in date, Gender preference toggle, Verified listing toggle

- Tap cluster -> bottom sheet with horizontal scroll of cards for that locality

- Tap pin -> expanded mini-card with key details and 'View Full Profile' button

### **Post & Manage (Room Poster)**

- Shortcut to listing builder for new posts

- List of active listings with status badges: Live / Under Review / Expired / Paused

- Each listing card shows: match count, profile views, days until expiry, quick actions (Edit, Pause, Renew, Boost slot — free in V1)

## **6.3 Tab 3 — Swipe**

The core discovery and matching screen. Detailed in Section 7.1.

## **6.4 Tab 4 — Likes & Chat**

- Two sub-tabs: Likes (people who swiped right on you) and Chats (mutual matches with conversation)

- Likes sub-tab: grid of blurred profile photos with a 'Match' button — tapping initiates the match and opens Q\&A nudge

- Chats sub-tab: chronological list of active matches. Each row shows: profile photo, name, last message preview, unread count badge, match mode badge

## **6.5 Tab 5 — Profile**

- Profile photo carousel + edit button

- Name, age, profession, city, mode badge

- Lifestyle tags (edit from here)

- Non-negotiables section (edit)

- Budget & timeline (edit)

- Switch mode option

- Settings: Notifications, Privacy (hide last name toggle, hide exact location toggle), Account, Help & Safety

# **7. Core Features**

## **7.1 Swipe Deck — Hybrid Card Experience**

### **7.1.1 Card States**

The swipe deck uses a custom Flutter PageView with custom physics, rotation, and shadow depth animations. No third-party swipe library — built bespoke for full control of the hybrid expand behaviour.

**Collapsed State (Swipe State)**

- Primary photo (fills \~60% of card height)

- Secondary photo strip (2 small thumbnails, swipeable within card)

- Mode badge: Room Available / Co-Hunter / Open to Both (colored chip, top-left)

- Verified badge if listing has passed manual review (top-right)

- Name, age, profession (bold name, smaller age/profession)

- City + Locality (e.g., Koramangala, Bangalore)

- Rent / Budget range

- Compatibility % (large ring indicator — green 70%+, amber 40–70%, red <40%)

- 3 lifestyle chips (highest-weight matches from compatibility engine)

- 'Tap to see more' affordance (subtle upward chevron at bottom)

**Expanded State (Tapped)**

The card expands into a scrollable bottom sheet with a sticky action bar. Hero animation from collapsed to expanded. Sections:

- Video tour autoplay (muted) if posted — unmutes on tap

- 🏨 The Society — location, locality, connectivity, amenities tags

- 🌳 The Room — furnishing, balcony, attached bath, sunlight, photos

- 🏠 The Flat & Flatmates — existing flatmate mini-profiles (name, age, profession, 2 lifestyle chips each)

- 💰 Costs Breakdown — rent, deposit, maintenance, cook, maid, electricity. Bottom line: 'Your estimated monthly cost: Rs XX,XXX'

- 🧬 About Me — free-text 'typical day' prompt + full lifestyle tag cloud

- 📅 Move-in date + countdown if within 7 days

- 🏘️ Society Insights — bachelor-friendly, parking, visitor-friendly, pet-friendly, quiet, active community (user-submitted, Phase 2)

- Compatibility breakdown: per-dimension match/mismatch summary

**Sticky Action Bar (visible in both states)**

- Pass (red X, left)

- Super Like (yellow star, center)

- Like (green heart, right)

Swipe gestures also work — left to pass, right to like, up to super like. Haptic feedback on each action.

## **7.2 Listing Builder (Room Poster)**

The listing builder is a structured 8-step form that produces a rich, formatted listing. Designed to feel like filling in a beautiful template rather than a data entry form. A progress bar shows the current step out of 8. Each step has inline validation and a summary shown on completion. A final review step lets the user verify all entries before publishing.

**Step 1 — Property Location**

- Society / Building name (text + autocomplete from previously listed societies)

- Full address (used for geocoding — lat-lng stored, address blurred to locality level in public listing)

- Locality auto-populated from geocode

**Step 2 — The Society**

- Society type: Gated / Independent / Co-living / PG

- Society amenities (multi-select icon grid): Pool, Gym, Clubhouse, Sports Facilities, Parking, Power Backup, Water Backup, Security, Lift, CCTV, Visitor Entry System, Garden

- Society vibe tags (multi-select): Bachelor-friendly, Quiet, Active Community, Family-dominant, Pet-friendly, Visitor-friendly

**Step 3 — The Room**

- Room type: Single occupancy / Shared (2 people) / Master bedroom

- Room furnishing (icon checklist): Bed, Wardrobe, AC, Geyser, Study Table, Curtains

- Room features: Attached bathroom, Private balcony, Window with sunlight, Storage space

**Step 4 — Photos & Video Tour**

- Photo upload: minimum 2 photos of room (enforced), maximum 10

- Video tour: optional 15–30 second vertical video upload (max 50MB)

**Step 5 — The Flat**

- Flat configuration: 1BHK / 2BHK / 3BHK / 4BHK+ / Studio

- Floor number + total floors in building

- Flat amenities (separate from society): WiFi, Washing Machine, Refrigerator, Microwave, TV, Dining Table, Sofa, Kitchen Fully Equipped

- Existing flatmates: add mini-profiles for each current resident (name, age, profession, 3 lifestyle tags). This is the 'bundled listing' feature.

**Step 6 — Costs**

- Monthly rent (Rs)

- Security deposit (Rs)

- Maintenance: included in rent / separate amount

- Electricity: included / separate (estimated monthly Rs)

- Cook cost if applicable (Rs/month)

- Maid cost if applicable (Rs/month)

- One-time setup cost if applicable

- Auto-calculated summary: 'Total monthly outflow: Rs XX,XXX' (rent + maintenance + electricity estimate + cook + maid)

- Per-person cost breakdown when sharing

**Step 7 — About You & Preferred Flatmate**

- Free-text 'typical day' prompt (100–300 chars)

- Gender of preferred flatmate: Female / Male / Any

- Age range preference: slider (18–40)

- Non-negotiables: select up to 3 deal-breakers from the standard list

- Move-in date: date picker + urgency toggle ('Flexible on this date')

**Step 8 — Review & Publish**

- Full summary of all previous steps with edit-per-section links

- Mini listing card preview showing how the listing will appear

- Total monthly outflow confirmation

- Publish button submits the listing for review

## **7.3 Compatibility Engine**

The compatibility score is calculated on-device using the two users' lifestyle quiz answers. It is a weighted average across 6 dimensions, displayed as a single percentage with a color ring on every swipe card.

|                        |            |                                                                                      |
| ---------------------- | ---------- | ------------------------------------------------------------------------------------ |
| **Dimension**          | **Weight** | **Scoring Logic**                                                                    |
| **Sleep Schedule**     | **20%**    | Exact match = 100. Adjacent = 50. Opposite = 0.                                      |
| **Cleanliness**        | **20%**    | Difference on 3-point scale. 0 gap = 100, 1 gap = 50, 2 gap = 0.                     |
| **Food Habits**        | **15%**    | Veg/Vegan strict match = 100. Non-veg + non-veg = 100. Mismatch with strict veg = 0. |
| **Smoking / Drinking** | **20%**    | Non-smoker + non-smoker = 100. One smokes = 30. Both = 100.                          |
| **Guests Policy**      | **15%**    | Exact match = 100. One step apart = 60. Two steps = 20.                              |
| **Work Style**         | **10%**    | WFH + WFH = 100 (high home presence overlap). Office + Office = 100. Mixed = 70.     |

The expanded card shows the full breakdown: per-dimension icons with match (green checkmark) or mismatch (amber warning) indicators and a one-line plain-English summary per dimension. Example: 'You're both night owls ✓ — Cleanliness mismatch ⚠ — Same food habits ✓'

## **7.4 Non-Negotiables & Deal-Breaker Filters**

Non-negotiables are hard filters applied silently before the swipe deck is populated. Incompatible profiles never appear — they are not shown as 'already passed'. Users select up to 3 non-negotiables during onboarding and can update them in Profile settings.

**Available Non-Negotiable Categories**

- Food: Vegetarian flatmates only / Vegan flatmates only / No restriction

- Smoking: Non-smoker only / No smoking inside flat / No restriction

- Drinking: No alcohol at home / Occasional ok / No restriction

- Guests: No overnight guests / Occasional guests ok / Open

- Pets: No pets / Pet-friendly / No restriction

- Gender: Female only / Male only / Any

- Partying: No parties at home / Occasional ok / Party-friendly

- Hygiene/Cleanliness: Minimum tidy standard (filters out 'minimal' self-reported cleanliness)

## **7.5 Search by Vibe**

Vibe filters appear as horizontal chip row on the Home feed and Map View. Each vibe is a named preset filter bundle that maps to combinations of lifestyle tags:

- Quiet & Focused — Non-smoker, no parties, office or WFH, early bird or flexible, low guests

- Social & Lively — Party-friendly or occasional, guests open, flexible sleep schedule

- Working Professionals — Office-goer or WFH, professional age range (24–35), tidy minimum

- Students — Age range 18–25 flag, flexible on most lifestyle dimensions

- Pet Household — Has pets or pet-friendly flag set

## **7.6 Move-In Timeline Filters**

- Four filter chips: Immediate / This Month / Next Month / Flexible

- Applied across feed, swipe deck, and map view simultaneously

- Listings with move-in date within 7 days show a red countdown badge: 'Moving in 4 days'

- Listings with expired move-in dates are automatically paused and flagged for Room Poster review

## **7.7 Smart Recommendations ('Picked for You')**

V1 uses rules-based recommendations — no ML required. Logic:

- Track: profiles tapped to expand (scroll depth > 50%), profiles saved/liked, profiles where user spent 10+ seconds in expanded view

- Recommend: same or adjacent locality, overlapping budget range (within 20%), matching vibe tags (2+), zero non-negotiable conflicts

- Surface as 'Picked for You' horizontal scroll row on Home tab, refreshed every 12 hours

- Each card shows a 'Why this?' tooltip: 'You both prefer quiet homes in Koramangala under Rs 25k'

V2 will upgrade this to a collaborative filtering model once sufficient interaction data exists.

## **7.8 Society & Community Insights**

**Phase 1 — Self-Declared (V1)**

Room Posters declare society insights during listing creation via a checkbox group. Six tags:

- Bachelor-friendly society

- Easy parking

- Visitor-friendly

- Pet-friendly society

- Quiet neighbourhood

- Active community (events, common areas used)

**Phase 2 — Community Corrections (V1.5)**

- Any user who has visited or lived in a society can vote on existing tags

- Each tag shows a thumbs up / thumbs down below it in the expanded listing view

- Tag with 3+ downvotes is flagged for admin review and shown with a 'Community disputed' warning

- A 'Report inaccurate info' button is available on all society tags from V1

**Phase 3 — Society Pages (V2)**

- Once 5+ listings exist from the same building, auto-generate a Society Page

- Aggregated insights, all current listings, average rent, community rating

# **8. Chat & Communication System**

## **8.1 Match Flow**

1. User A likes User B

2. If User B has already liked User A: mutual match triggered

3. Match celebration screen: animated card flip, 'It's a Match!' with both photos

4. Soft Q\&A nudge appears (see 8.2)

5. Chat thread opens (with or without Q\&A completion)

## **8.2 Guided Q\&A (Pre-Chat Soft Nudge)**

On match, before the chat thread opens, a bottom sheet appears with the title: 'Break the ice first?' Two buttons: 'Answer 3 quick questions' (primary) and 'Skip for now' (ghost, smaller).

**The 3 Default Q\&A Questions**

- 'What does your ideal flatmate situation look like?' (free text, 100 char max)

- 'How social are you at home on a typical weekday?' (5-point scale: Very private to Very social)

- 'One thing you absolutely need in a flatmate?' (free text, 60 char max)

**Q\&A Display Logic**

- If both users complete Q\&A: their answers are shown to each other at the top of the chat thread with a 'Both answered' banner — strong trust signal

- If only one answers: the completed answers are shown to the other person with a prompt 'They answered — want to share yours?'

- Questions rotate from a bank of 10–12 across matches so they don't feel repetitive

- Q\&A answers are stored and visible on the full profile for context

## **8.3 Chat Thread Features**

**Core Messaging**

- Text messaging with read receipts: single tick (sent), double tick (delivered), blue tick (read)

- Photo sharing — 1-tap gallery access. Users share room photos, society photos, etc.

- Push notifications for new messages (foreground and background)

**Icebreaker Prompts**

Shown as tappable chips above the keyboard before the first message is sent. Chips disappear after first message.

- 'Tell me about the room 🏠'

- 'What are your flatmates like? 👥'

- 'Are you open to negotiating rent? 💰'

- 'What's the vibe of the society? 🏘️'

- 'What does a typical weekend look like for you? 🌞'

**Match Context Card**

- Pinned at top of every chat thread — shows listing thumbnail or profile photo, mode badge, locality, and rent/budget range

- Collapsible after first view

- Tapping reopens the full listing/profile in a bottom sheet without leaving chat

**Chat Safety**

- Report button (three-dot menu): Fake profile / Spam / Inappropriate content / Uncomfortable interaction / Other

- Unmatch — removes match, chat history retained locally for safety

- Block — removes match and prevents future appearance in swipe deck

## **8.4 Schedule a Visit**

A dedicated 'Schedule Visit' button in the chat toolbar (calendar icon, persistent). Flow:

6. Requester taps Schedule Visit

7. Date picker + time slot picker (morning / afternoon / evening, or specific time)

8. Optional note: 'Main gate, ask for Arjun'

9. Visit request card appears in chat thread for the other person to confirm or suggest alternative time

10. On confirmation: visit card in thread updates to 'Visit Confirmed'. Both parties receive push notification.

11. Optional: Google Calendar sync (one-tap, asks permission once)

> **V2 Addition:** An automated follow-up message 24 hours after a scheduled visit: 'How did the visit go? Did you find your match? 👍' — this drives review and match confirmation data.

# **9. Trust & Safety**

## **9.1 V1 Trust Stack**

- **Phone OTP** — All accounts created via verified phone number. Duplicate phone number registration blocked.

- **Manual Listing Review** — All Room Poster listings go through a 24-hour human review queue before going live. Profile posts (Co-Hunters) are auto-approved.

- **AI Pre-Screening** — Before entering the human queue, listings are auto-flagged if: photos missing, key fields empty, suspicious pricing (Rs 0 or Rs 10L+), or content keywords that suggest spam/inappropriate content. Estimated 60% reduction in queue volume.

- **Report & Block System** — In-chat report flows for all user types. Repeat-reported profiles are auto-paused pending admin review after 3 reports.

- **Address Privacy** — Listing location is blurred to locality level in public view. Full address is never shown to unmatched users. Revealed only in chat post-match at Room Poster's discretion.

## **9.2 Admin Review Queue (Flutter Web)**

Built as a Flutter Web application from the same codebase. Accessible to admin team only.

- Review queue sorted by submission time, oldest first

- Each listing shows: all photos, full listing content, Room Poster's profile, phone number (masked), AI flag reason if any

- Three actions: Approve / Request Edit (templated reason + free text) / Reject (templated reason)

- 'Request Edit' sends a push notification to the Room Poster with specific changes required. Listing re-enters queue on resubmission.

- 24-hour SLA tracked. Overdue listings flagged in red in the queue.

## **9.3 Data Stored for V2 Trust Features**

- Listing lat-lng coordinates stored on every listing creation (for V2 nearby essentials integration)

- Society tag vote counts (for V2 community corrections)

- Profile view duration per session (for V2 smart recommendations upgrade)

- Match + visit + resolution outcomes (for V2 success rate metrics and review system)

# **10. Growth Strategy**

## **10.1 WhatsApp Share Card (Primary Growth Channel)**

Every listing auto-generates a shareable image card. The card is generated on-device or server-side and formatted for WhatsApp / Instagram Stories sharing:

- Card dimensions: 1080x1920 (9:16 vertical) for Stories; 1080x1080 square for WhatsApp

- Card content: Primary room photo, Society name, Locality, Rent per month, Top 3 amenity icons, Move-in date, QR code, 360 Flatmates branding with App Store + Play Store links

- One-tap share to WhatsApp / Instagram / copy link

- Deep link in QR code and URL directs to: App Store/Play Store if not installed, or directly to the listing in-app if installed

- Room Posters are nudged to share their listing after approval: 'Your listing is live — share it to reach 5x more people'

## **10.2 Cold Start Strategy (Pan-India)**

Going pan-India from day one creates a density problem in smaller cities. Mitigation:

- **City counter** — Home screen shows 'X people looking in \[your city] right now'. Transparency over fake activity.

- **Waitlist mode** — In cities below a density threshold (< 50 active users), show a 'Notify me when more people join in \[city]' CTA instead of an empty swipe deck.

- **Broad search radius default** — Users in tier-2 cities default to a 30km search radius rather than 5km, increasing visible deck size.

- **Co-hunter matching boost** — Co-hunters see each other across a wider radius than Room Posters, since co-hunters need a person, not a specific location.

## **10.3 Freemium Hooks (V1 Preparation)**

No monetization in V1, but the following UI patterns are built in to train user behaviour and enable a frictionless paywall introduction in V2:

- **Boost slot** — The Room Poster's 'Manage Listing' screen already shows a 'Boost listing' button — free in V1, paid in V2. This slot in the UI trains Room Posters to see boosting as a normal action.

- **Swipe cap UI** — The swipe deck shows a faint 'X swipes remaining today' counter (but the cap is set to a high number like 100 in V1 so it's never actually hit). Trains users to see swipes as a resource.

- **Super Like scarcity** — Super Likes are capped at 3 per day in V1 (genuinely enforced). This establishes Super Like as a premium signal even before a paywall.

- **Profile boost on listing approval** — Notify Room Posters that 'Your listing has been boosted for 24 hours' on first approval — models paid boost value.

# **11. Technical Architecture**

## **11.1 Stack Overview**

|                           |                                                                                                            |
| ------------------------- | ---------------------------------------------------------------------------------------------------------- |
| **Layer**                 | **Technology**                                                                                             |
| **Frontend (Mobile)**     | Flutter 3.x — single codebase for iOS and Android                                                          |
| **Frontend (Admin)**      | Separate web dashboard (see real-estate-admin-dashboard repo)                                              |
| **State Management**      | Riverpod — providers, Notifier, AsyncNotifier, FamilyNotifier                                              |
| **Routing**               | GoRouter with StatefulShellRoute for bottom navigation                                                     |
| **Networking**            | Dio with auth interceptor (Bearer token + 401 refresh retry)                                               |
| **Backend**               | FastAPI monolith (existing 360 Ghar backend) — extended with flatmate-specific endpoints                   |
| **Authentication**        | Supabase Auth (Phone OTP + password) — Supabase Flutter SDK                                                |
| **Media Storage**         | Supabase Storage for photos and video tours (buckets: profile-photos, listing-photos, chat-photos, listing-videos) |
| **Realtime Chat**         | Supabase Realtime for message streaming in chat threads                                                    |
| **Geocoding**             | Google Maps Geocoding API — called on listing save (lat-lng stored, not displayed in V1)                   |
| **Push Notifications**    | Firebase Cloud Messaging (FCM) + flutter_local_notifications                                               |
| **Maps**                  | Google Maps Flutter with client-side clustering by locality                                                |
| **Share Card Generation** | RepaintBoundary + share\_plus for on-device card generation (WhatsApp square 1080x1080, Instagram story 1080x1920) |
| **AI Pre-Screening**      | Backend-side keyword/completeness classifier (no external ML API needed in V1)                             |
| **Image Caching**         | CachedNetworkImage for all remote images                                                                   |
| **Localization**          | ARB-based l10n — English + Hindi                                                                           |
| **Theming**               | Material 3 with ColorScheme.fromSeed — 3 swappable palettes, light/dark/system                            |

## **11.2 Flutter Project Structure**

- lib/features/ — feature-first folder structure (auth, onboarding, bootstrap, discover, swipe, listings, chats, visits, profile, settings, notifications, shared)
- lib/core/ — theme tokens, networking, errors, storage, compatibility engine, notifications, deep links, analytics, domain utilities
- lib/app/ — app widget, app shell (bottom nav), GoRouter configuration
- lib/bootstrap.dart — app initialization pipeline
- Business metadata served server-driven via /api/v1/flatmates/catalogs — not hardcoded

## **11.3 Key Data Model (PostgreSQL via FastAPI)**

The backend is an existing FastAPI monolith backed by PostgreSQL. The flatmate product surface reuses existing tables and introduces a shared social layer.

**Existing tables extended for flatmates:**

- `users` — primary flatmate profile record: mode, profile status, onboarding completion, bio, budget range, move-in timeline, city/locality, six compatibility dimensions, last active timestamp. Flatmate-specific metadata stored in `users.preferences` JSONB column.
- `properties` — flatmate room listings identified by `property_type` and `purpose`. Contains all listing fields, poster reference, status (pending/live/paused/expired), lat-lng, society tags, amenities, costs, flatmates array, listing preferences.
- `user_swipes` — supports both listing and profile actions. `target_type=property` with `property_id` for listing swipes; `target_type=user` with `target_user_id` for profile swipes. `swipe_action`: pass/like/super-like. `context_property_id` retains listing context for person-to-person actions.
- `visits` — supports two contexts: `property_tour` for real-estate visits and `flatmate_meet` for in-chat flatmate meet requests. Carries counterparty user and optional conversation/match linkage.

**New shared social layer tables:**

- `user_matches` — uid1, uid2, listing context, matched timestamp, Q&A answers
- `user_conversations` — two-user conversation with peer info, context property, last message preview, unread count, source type, status
- `user_messages` — conversation messages with sender, body, message type (text/image/visit_request), attachment URL, read timestamp
- `user_blocks` — blocked user pairs
- `user_reports` — reported users with reason
- `app_catalogs` — server-driven business metadata (modes, timelines, quiz dimensions, vibe tags, report reasons, icebreakers, room types, furnishing options, etc.)

**API surface:** Dedicated flatmate endpoints under `/api/v1/flatmates` (bootstrap, profile, catalogs, swipes, conversations, matches, blocks, reports, notifications). Existing `/api/v1/properties` reused for listing discovery. Existing `/api/v1/visits` extended for flatmate meet context.

## **11.4 Important Implementation Notes**

- **Lat-lng storage** — Always geocode and store lat-lng on every listing save, even in V1 where nearby essentials are not yet displayed.

- **Compatibility calculation** — Calculated client-side from locally cached lifestyle data using a 6-dimension weighted scoring engine. No server call needed per swipe — fast and cost-free.

- **Deal-breaker filtering** — Applied client-side before swipe deck population and as query parameters on discover/map endpoints. Non-negotiables stored as user profile fields.

- **Video tour** — Uploaded to Supabase Storage (listing-videos bucket). Size cap: 50MB, duration cap: 30 seconds (enforced client-side before upload).

- **WhatsApp share card** — Generated on-device using RepaintBoundary with three templates: original card, WhatsApp square (1080x1080), Instagram story (1080x1920). Includes QR code with deep link.

- **Real-time chat** — Supabase Realtime subscription on `chat_messages` table filtered by `conversation_id`. Falls back to 5-second polling if realtime unavailable.

- **Auth flow** — Supabase Phone Auth for OTP. Access token stored in FlutterSecureStorage. Dio auth interceptor handles Bearer token injection and 401 refresh with request queuing.

- **Server-driven catalogs** — All business metadata (modes, timelines, quiz options, vibe tags, report reasons, icebreakers) loaded from `/flatmates/catalogs` at bootstrap. Hardcoded fallbacks exist for offline support.

- **Theme and localization** — Material 3 with 3 palette presets (Electric Indigo, Ember Coral, Monsoon Teal). Light/dark/system mode. English + Hindi ARB-based localization. All persisted via SharedPreferences.

# **12. Feature Priority Matrix — V1 vs V2**

|                                                               |        |        |               |
| ------------------------------------------------------------- | :----: | :----: | :-----------: |
| **Feature**                                                   | **V1** | **V2** | **Data Only** |
| Phone OTP authentication                                      |  **✅** |        |               |
| Three user modes (Room Poster, Co-Hunter, Open to Both)       |  **✅** |        |               |
| Onboarding flow (under 4 mins)                                |  **✅** |        |               |
| Lifestyle quiz (8 questions)                                  |  **✅** |        |               |
| Structured listing builder (8-step)                           |  **✅** |        |               |
| Amenities icon grid (room + society)                          |  **✅** |        |               |
| Existing flatmate mini-profiles (bundled listings)            |  **✅** |        |               |
| Pricing split calculator                                      |  **✅** |        |               |
| Video room tours (15–30 sec)                                  |  **✅** |        |               |
| Hybrid swipe card (collapsed + expanded)                      |  **✅** |        |               |
| Compatibility score (6-dimension, % + ring)                   |  **✅** |        |               |
| Deal-breaker hard filters (up to 3)                           |  **✅** |        |               |
| Move-in timeline filter (4 states)                            |  **✅** |        |               |
| Move-in countdown badge (7-day urgency)                       |  **✅** |        |               |
| Search by vibe (5 preset filter bundles)                      |  **✅** |        |               |
| Society tags — self-declared by Room Poster                   |  **✅** |        |               |
| Map view with clustered pins and filter bar                   |  **✅** |        |               |
| WhatsApp share card (deep link, QR)                           |  **✅** |        |               |
| Soft Q\&A nudge on match (3 questions)                        |  **✅** |        |               |
| Icebreaker chips in chat                                      |  **✅** |        |               |
| Full chat (text + photo + read receipts)                      |  **✅** |        |               |
| Schedule Visit in chat (date/time picker + confirmation card) |  **✅** |        |               |
| Match context card pinned in chat                             |  **✅** |        |               |
| Report / Unmatch / Block                                      |  **✅** |        |               |
| Push notifications (new match, message, visit)                |  **✅** |        |               |
| Manual listing review queue (Flutter Web admin)               |  **✅** |        |               |
| AI pre-screening before review queue                          |  **✅** |        |               |
| Freemium hook UI (boost slot, swipe counter, super like cap)  |  **✅** |        |               |
| Cold start: waitlist mode + city counter                      |  **✅** |        |               |
| Lat-lng storage on all listings                               |        |        |     **✅**     |
| Society tag vote counts (for community corrections)           |        |        |     **✅**     |
| Profile view duration tracking                                |        |        |     **✅**     |
| Smart recommendations — rules-based 'Picked for You'          |  **✅** |        |               |
| Smart recommendations — ML collaborative filtering upgrade    |        |  **✅** |               |
| Society insights — community votes & disputes                 |        |  **✅** |               |
| Society Pages (aggregated per-building view)                  |        |  **✅** |               |
| Nearby essentials (metro, gym, grocery, hospital)             |        |  **✅** |               |
| Roommate review system (post-move-in rating)                  |        |  **✅** |               |
| Roommate agreement PDF generator                              |        |  **✅** |               |
| Aadhaar / Govt ID verification                                |        |  **✅** |               |
| Paid boost / featured listing monetization                    |        |  **✅** |               |
| Google Calendar sync for visits                               |        |  **✅** |               |

# **13. Screen-by-Screen Flow Reference**

## **13.1 Room Poster Flow**

- Splash (3 screens) → Phone OTP → Mode Selection → Basic Info → Profile Photo → Lifestyle Quiz (8 cards) → Budget & Timeline → Listing Builder (6 steps) → Listing Under Review screen → Home Feed

* Tab 2 (Post/Manage): New Listing button → Listing Builder | Active listing card → View Stats, Edit, Pause, Share

* Tab 3 (Swipe): Swipe deck of Co-Hunters and Seekers. Like/Pass/Super Like. Tap to expand profile.

* Tab 4 (Likes & Chat): Likes sub-tab (blurred cards with Match button) → Match → Q\&A nudge → Chat thread

## **13.2 Co-Hunter Flow**

- Splash → OTP → Mode → Basic Info → Photo → Lifestyle Quiz → Budget & Timeline → Home Feed

* Tab 2 (Properties/Map): Clustered map → Tap cluster → Card carousel → Tap card → Expanded listing → Like from expanded view

* Tab 3 (Swipe): Swipe deck of Room Postings + other Co-Hunters. Hybrid card.

* Tab 4 (Likes & Chat): Same as above → Chat → Schedule Visit → Visit Confirmed

## **13.3 Chat Thread Screen Flow**

- Enter chat → Q\&A answers shown if available (or nudge to complete) → Match context card (collapsible) → Icebreaker chips if first message → Message thread → Schedule Visit (toolbar) → Visit card in thread → Confirm/Reschedule

## **13.4 Admin Queue Screen Flow**

- Login (admin accounts only, Firebase Auth with role claim) → Queue list (sorted by submission time) → Listing detail view (all photos, content, poster profile, AI flag reason) → Approve / Request Edit / Reject → Notification sent to Room Poster

# **14. Design Principles & UI Guidelines**

## **14.1 Design Philosophy**

- **Personality-first** — Lead with the person, not the property. Compatibility % appears before rent price on swipe cards.

- **Structured freedom** — Listings are structured enough to be scannable in 10 seconds but rich enough to tell a story. The emoji-section template (🏨 🌳 🏠 💰) makes even lazy users produce good posts.

- **Trust through transparency** — Show compatibility breakdowns, not just scores. Show why something is recommended. Show how many people are in the city right now.

- **Mobile-native** — Every interaction designed for one-handed phone use. No horizontal scroll for primary actions. Bottom sheet patterns over navigation pushes wherever possible.

## **14.2 Color System**

|                  |             |                                                             |
| ---------------- | ----------- | ----------------------------------------------------------- |
| **Token**        | **Hex**     | **Usage**                                                   |
| **Brand Purple** | **#5B4FCF** | Primary CTA, active tab, compatibility ring, mode badges    |
| **Brand Light**  | **#EDE9FF** | Card backgrounds, callout boxes, tag backgrounds            |
| **Accent Coral** | **#FF6B6B** | Pass button, error states, urgency badges                   |
| **Match Green**  | **#10B981** | Like button, compatibility match indicators, success states |
| **Super Yellow** | **#F59E0B** | Super Like, V2 feature badges, countdown urgency            |
| **Dark Navy**    | **#1A1A2E** | Primary text, headings                                      |
| **Body Gray**    | **#374151** | Body copy, secondary text                                   |
| **Light Gray**   | **#F3F4F6** | Screen backgrounds, alternate table rows                    |

## **14.3 Typography**

- **Font** — Inter (preferred) or system default (SF Pro on iOS, Roboto on Android) — do not import custom fonts for V1 to keep bundle size lean

- **Display / Names on cards** — 24sp, Bold

- **Body / Listing content** — 14sp, Regular, line height 1.5

- **Chips / Tags** — 12sp, Medium, rounded 100px border radius

- **Captions / Metadata** — 12sp, Regular, secondary text color

## **14.4 Animation Guidelines**

- Swipe card: PageView with custom physics. Rotation: max 15 degrees at full drag. Shadow deepens on lift. Snap-back on release below threshold (20% screen width).

- Card expand: Bottom sheet slides up with spring physics. Hero animation on primary photo.

- Match animation: Card flip + confetti burst (keep under 600ms total).

- Tab switching: Fade transition, 200ms. No slide transitions on tab bar.

- Compatibility ring: Animated fill on card appearance (300ms ease-out).

# **15. Open Questions & Decisions Deferred**

|                                                                              |                                                                                        |
| ---------------------------------------------------------------------------- | -------------------------------------------------------------------------------------- |
| **Open Question**                                                            | **Notes**                                                                              |
| **State management: Riverpod vs Bloc?**                                      | Riverpod recommended for new projects. Bloc if team has existing Bloc expertise.       |
| **App name: '360 Flatmates' confirmed or placeholder?**                      | Name used throughout this doc. Confirm before domain / App Store registration.         |
| **Should Co-Hunters be able to form groups (2+ people searching together)?** | Described in personas but not scoped in V1 flows. Defer to V1.5.                       |
| **Should broker/agent accounts be allowed to post listings?**                | V1 assumes individual users only. Broker accounts are a monetization lever for V2.     |
| **What is the maximum swipe cap for V1?**                                    | Recommended: 100/day (effectively unlimited). Set lower cap in V2 paywall.             |
| **Video tour: Firebase Storage or third-party CDN?**                         | Firebase Storage sufficient for V1. Evaluate Cloudflare Stream or Mux at V2 scale.     |
| **Should users be able to change mode freely or once per 30 days?**          | Recommend: freely changeable in V1 to reduce friction. Add rate-limit in V2 if abused. |

---
**360 Flatmates — PRD v1.0**
*This document is confidential. All feature decisions subject to sprint review.*
