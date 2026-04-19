# Design System: Marti (iOS Traveler App)

## Visual Identity

Marti feels like a premium, dark-themed travel app — closer to Skyscanner at night than Airbnb in daylight. The dark canvas (#010913) creates a cinematic backdrop that makes listing photos pop, reduces eye strain for users browsing late at night (diaspora travelers plan trips across time zones), and visually separates Marti from every other booking app on the market. The design is minimal and restrained: few colors, generous spacing, clear hierarchy. Trust is communicated through verified badges, host stats, and transparent pricing — not through decorative elements. The tone is calm and confident, not flashy.

Adapted from Skyscanner's Backpack iOS design system (dark/Night mode tokens) with Airbnb's rental listing UX patterns.

## Color System

Dark mode only in v1. No light mode. All colors are hardcoded to the dark palette — no dynamic trait resolution needed until v2.

### Semantic Tokens

| Token | Hex | Usage |
|---|---|---|
| `canvas` | `#010913` | App background, screen bg |
| `surfaceDefault` | `#131D2B` | Cards, tab bar, review cards |
| `surfaceElevated` | `#243346` | Modals, bottom sheets, input fields, host card |
| `surfaceHighlight` | `#1A2A3D` | Pressed/hover states, skeleton shimmer |
| `textPrimary` | `#FFFFFF` | Headings, titles, primary labels, prices |
| `textSecondary` | `#BDC4CB` | Body text, descriptions, metadata |
| `textTertiary` | `#95A0AE` | Placeholders, footnotes, timestamps, terms text (5:1 contrast, WCAG AA compliant) |
| `coreAccent` | `#84E9FF` | CTAs, links, active tab, active chips, send button, page dots |
| `corePrimary` | `#054184` | Secondary selections, subtle accent backgrounds |
| `statusSuccess` | `#62F1C6` | Verified badge, confirmed status, "Verified Host" label |
| `statusDanger` | `#FF649C` | Filled heart (saved), declined status, cancel actions, sign out, error states |
| `statusWarning` | `#FEEB87` | Star ratings, pending status badge, cancellation policy icon |
| `divider` | `rgba(255,255,255,0.08)` | 1px section dividers, list separators |

### Status Badge Colors

| Status | Background | Text |
|---|---|---|
| Verified | `rgba(98,241,198,0.15)` | `#62F1C6` |
| Confirmed | `rgba(98,241,198,0.15)` | `#62F1C6` |
| Pending | `rgba(254,235,135,0.15)` | `#FEEB87` |
| Declined | `rgba(255,100,156,0.15)` | `#FF649C` |

### Color Rules

- Color is never the sole indicator of state. Every badge carries text ("Verified", "Pending", "Confirmed") alongside its color.
- `textTertiary` was adjusted from the Skyscanner original (#8290A0, 4.3:1) to #95A0AE (5:1) to pass WCAG AA.
- The heart icon uses `statusDanger` when filled (saved) and white outline when unsaved — both readable at 24pt on dark surfaces.

## Typography

### Font

System font only (`system-ui` / San Francisco). No custom fonts in v1. This ensures Dynamic Type support, optimal rendering, and zero font-loading latency.

### Scale

| Style | Size | Line Height | Weight | Usage |
|---|---|---|---|---|
| `heading3` | 24pt | 28pt | Bold (700) | Screen titles ("Peaceful Villa in Hodan") |
| `heading4` | 20pt | 24pt | Bold (700) | Section headings ("What this place offers", "Price details") |
| `heading5` | 16pt | 20pt | Bold (700) | Card titles, subsection headings, prices |
| `bodyDefault` | 16pt | 24pt | Regular (400) | Descriptions, body text |
| `footnote` | 14pt | 20pt | Regular (400) | Secondary info, metadata, location |
| `caption` | 12pt | 16pt | Regular (400) | Timestamps, badge text, SOS currency |
| `label1` | 16pt | 24pt | Bold (700) | Button text |
| `label2` | 14pt | 20pt | Bold (700) | Chip text, small button text |
| `tabLabel` | 10pt | — | Medium (500/600) | Tab bar labels |

### Weight Conventions

- **Bold (700):** Headings, titles, prices, button labels, active states
- **Semibold (600):** Tab labels (active), form labels, unread message previews
- **Regular (400):** Body text, descriptions, secondary info
- **Never use:** Light (300) or Thin (100) on dark backgrounds — readability drops

### Typography Rules

- Uppercase with letter-spacing (0.5px) for form labels only: "CHECK-IN", "GUESTS", "COUNTRY"
- No uppercase for headings or body text
- Price always uses `heading5` bold for the dollar amount, `footnote` regular for "/night"

## Spacing & Layout

### Base Unit

8pt base unit. All spacing is a multiple of 4 or 8.

### Spacing Scale

| Token | Value | Usage |
|---|---|---|
| `xs` | 2pt | Micro gaps (badge icon to text) |
| `sm` | 4pt | Tight gaps (star to rating text, tab icon to label) |
| `md` | 8pt | Default element gap (within card content rows) |
| `base` | 16pt | Screen edge padding, card content padding, section gaps |
| `lg` | 24pt | Between major sections, generous padding areas |
| `xl` | 32pt | Between section groups, modal content padding |
| `xxl` | 40pt | Large whitespace (onboarding, confirmation screens) |

### Layout Conventions

- **Screen edge padding:** 16pt horizontal on all screens
- **Card content padding:** 12-14pt horizontal, 12pt top, 14pt bottom
- **Between listing cards:** 12-16pt vertical gap
- **Section dividers:** Full-width 1px line with 16pt horizontal padding, 20pt vertical spacing above and below
- **Tab bar:** 10pt top padding, 28pt bottom padding (safe area)
- **Bottom sticky bars:** 14pt top, 16pt horizontal, 32pt bottom (safe area)

### Screen Frame

iPhone 15: 390x844pt. All screens designed at this size.

## Corner Radius

| Token | Value | Usage |
|---|---|---|
| `xs` | 4pt | Skeleton shimmer bars, inline tags |
| `sm` | 8pt | Input fields, buttons, small cards, booking cards |
| `md` | 12pt | Listing cards, photo images, review cards, host card, map placeholder |
| `lg` | 24pt | Bottom sheets (top corners), modals |
| `xl` | 40pt | Search bar (pill shape), city chips, status badges |
| `full` | 100pt | Avatars, circular buttons, notification dots |

## Shadow / Elevation

| Level | Y Offset | Blur | Color | Usage |
|---|---|---|---|---|
| `sm` | 1pt | 3pt | `rgba(22,22,22,0.15)` | Cards (subtle depth) |
| `lg` | 4pt | 16pt | `rgba(22,22,22,0.15)` | Map price pins, elevated panels |

Shadows are subtle on dark backgrounds. Most elevation is communicated through surface color steps (canvas → surfaceDefault → surfaceElevated), not shadows.

## Iconography

### Style

Outline icons, 1.5pt stroke weight, 24x24pt default size. Inspired by Airbnb's clean, modern icon style. Not SF Symbols in the design — but implementation should use SF Symbols where exact matches exist to get Dynamic Type scaling for free.

### Sizing

| Context | Size | Stroke |
|---|---|---|
| Tab bar icons | 24x24pt | 1.5pt (inactive), 2pt (active) |
| Amenity list icons | 24x24pt | 1.5pt |
| Nav bar action icons | 20x20pt | 2pt |
| Inline metadata icons (location, star) | 14pt | — (filled for stars) |
| Badge icons (checkmark) | 12-14pt | — (filled) |

### Color Treatment

- Active tab icon: `coreAccent`
- Inactive tab icon: `textTertiary`
- Amenity/feature icons: `textSecondary`
- Star rating: `statusWarning` (filled yellow), `#44505F` (empty outline)
- Heart unsaved: white outline on dark
- Heart saved: `statusDanger` filled

### SF Symbol Mapping (for implementation)

| Design Icon | SF Symbol |
|---|---|
| Search | `magnifyingglass` |
| Heart | `heart` / `heart.fill` |
| Calendar | `calendar` |
| Message | `bubble.left` |
| Profile | `person` |
| Back | `chevron.left` |
| Close | `xmark` |
| Share | `square.and.arrow.up` |
| Filter | `line.3.horizontal.decrease` |
| Map | `map` |
| List | `list.bullet` |
| Star | `star.fill` |
| Checkmark | `checkmark` |
| Settings | `gearshape` |
| Help | `questionmark.circle` |
| Bell | `bell` |
| Shield | `shield` |
| Camera | `camera` |
| Lightning | `bolt` |
| WiFi | `wifi` |
| Car | `car` |
| Parking | `p.square` |

## Component Patterns

### Listing Card (Full Width)

Photo (full width, 200pt height, `md` radius) + content area (title, location, rating, price). `surfaceDefault` background, `md` radius. Heart icon top-right of photo (44x44pt tap target). Verified badge top-left.

### Listing Card (Compact Grid)

2-column layout on Saved tab. Photo (full width of column, 130pt height) + title + city + price. Smaller text. Pink filled heart.

### Primary Button

Full width, 48pt height, `coreAccent` background, `canvas` text, `sm` radius, `label1` weight. Used for: "Submit Request", "Send Code", "Create Profile", "Get Started", "Try Again".

### Secondary Button

Full width, 48pt height, `surfaceElevated` background, `coreAccent` text, `sm` radius. Used for: "Message Host".

### Ghost Button

Text-only, `coreAccent` color, `label1` weight, no background. 44pt minimum touch height. Used for: "View My Bookings", "Skip for now", "Read more", "Show all amenities".

### Destructive Button

Full width, 48pt height, transparent background, 1px `statusDanger` border (30% opacity), `statusDanger` text. Used for: "Cancel Booking", "Sign Out".

### Input Field

Full width, 48pt height, `surfaceElevated` background, `sm` radius. `textPrimary` for entered text, `textTertiary` for placeholder. Focused state: 1px `coreAccent` border.

### Search Bar

Pill shape (`xl` radius), `surfaceElevated` background, magnifying glass icon + placeholder text. 48pt height.

### City Chip

Pill shape (`xl` radius). Selected: `coreAccent` background, `canvas` text. Unselected: `surfaceElevated` background, `textSecondary` text. 44pt minimum touch height.

### Status Badge

Pill shape (`xl` radius), tinted background (15% opacity of status color), bold status text. Three variants: Verified (green), Pending (yellow), Confirmed (green).

### Bottom Sheet

`surfaceDefault` background, `lg` radius on top corners. 36x5pt drag handle centered, `#44505F` color. Dark overlay behind (`rgba(1,9,19,0.7)`).

### Tab Bar

5 tabs: Discover, Saved, Bookings, Messages, Profile. `surfaceDefault` background, 1px `divider` top border. Active: `coreAccent` icon (2pt stroke) + label. Inactive: `textTertiary` icon (1.5pt stroke) + label.

### Confirmation Dialog

iOS-style alert. `surfaceElevated` background, `md` radius. Title (17pt bold), message (13pt regular), divider lines, action buttons. Destructive action in `statusDanger`, safe action in `coreAccent` bold.

### Review Card

`surfaceDefault` background, `md` radius, 16pt padding. Avatar circle (40pt) with initial letter, name + date, star row, review text.

### Message Bubble

Sent: `coreAccent` background, `canvas` text, 16pt radius with sharp bottom-right corner. Received: `surfaceElevated` background, `textPrimary` text, 16pt radius with sharp bottom-left corner.

### Skeleton Loader

`surfaceHighlight` (#1A2A3D) rectangles with `xs` radius, mimicking the exact shape of the content they replace (search bar, chips, card photo, text lines).

## Motion & Animation

### When to Animate

- Tab bar selection (icon fill/stroke transition)
- Heart icon toggle (scale bounce + fill change)
- Booking confirmation checkmark (scale-in)
- Pull-to-refresh
- Bottom sheet presentation (slide up)
- Page indicator transitions

### Style

- Duration: 200ms for micro-interactions, 400ms for screen transitions
- Easing: `.spring(response: 0.3, dampingFraction: 0.7)` for bouncy feedback, `.easeInOut` for slides
- No decorative animations (no confetti, no particle effects, no parallax)

### Reduce Motion

All animations wrapped in `@Environment(\.accessibilityReduceMotion)` check. When enabled: instant state changes, no spring physics, crossfade instead of slide.

### Haptics

| Interaction | Feedback |
|---|---|
| Heart toggle | `.impact(.light)` |
| Booking submitted | `.notification(.success)` |
| Error state | `.notification(.error)` |
| Star rating selection | `.selection` |
| Pull-to-refresh | `.impact(.medium)` |

## Accessibility

### Dynamic Type

Support up to AX5 (largest accessibility size). Specific requirements:
- Horizontal stat grids (Profile, Host Profile) reflow to vertical stack at `.accessibility1` and above using `ViewThatFits`
- Dual-currency price display wraps to second line at large sizes
- Tab bar labels truncate gracefully (icons remain primary navigation)

### VoiceOver

- Every interactive element has `.accessibilityLabel`
- Heart button: "Save listing" / "Remove from saved"
- Verified badge: "Verified host"
- Star rating: single adjustable control with `.accessibilityAdjustableAction`, announces "4 out of 5 stars"
- OTP input: single hidden `TextField` with `.textContentType(.oneTimeCode)`, announces "Verification code, 3 of 6 digits entered"
- Status badges read their full text ("Booking confirmed" not just "Confirmed")

### Contrast

- All text/background combinations meet WCAG AA (4.5:1 for normal text, 3:1 for large text)
- `textTertiary` (#95A0AE) on `canvas` (#010913) = 5:1 ratio
- `textSecondary` (#BDC4CB) on `canvas` (#010913) = 8.2:1 ratio
- `textPrimary` (#FFFFFF) on `canvas` (#010913) = 19.4:1 ratio
- Sent message text (`canvas` #010913) on `coreAccent` (#84E9FF) = 12:1 ratio

### Touch Targets

Every interactive element: 44x44pt minimum tappable area. This applies to:
- Heart icons (24pt visual, 44pt tap area)
- City chips (visual height ~36pt, tap area 44pt)
- Map price pins (visual ~36pt, tap area 44pt)
- Skip/ghost text buttons (44pt minimum height)
- Stepper +/- buttons

## Localization

### Languages

- **V1:** English UI. Somali cultural flavor in greetings and confirmations ("Salaam" in chat).
- **V1.1:** Full Somali (Bokmål-style, Somali orthography)
- **V2:** Arabic

### RTL

Not required in v1 (English and Somali are both LTR). Arabic in v2 will require RTL layout. Use `.environment(\.layoutDirection, .rightToLeft)` when adding Arabic.

### Text Length

- Listing titles: up to ~40 characters before truncation on cards
- Host names: up to ~20 characters
- City chips: fixed set ("All", "Mogadishu", "Hargeisa")
- Button labels: max 20 characters
- SOS currency: abbreviate to "~1.5M SOS" on cards, full number on detail/booking screens

### Country Code

Default country code: +252 (Somalia). Dropdown supports all country codes but defaults to Somalia for the target audience.

## What This App Deliberately Does NOT Do

- **No light mode in v1.** Dark only. Adding light mode doubles the design QA surface for no real gain at launch scale.
- **No custom fonts.** System font (San Francisco) gives us Dynamic Type, weight variety, and zero load time for free.
- **No gradients on UI elements.** The dark theme relies on surface color steps for depth, not gradients. Photo placeholders use subtle gradients only as texture.
- **No card shadows.** Elevation is communicated through surface color, not drop shadows. The dark canvas makes shadows nearly invisible anyway.
- **No skeleton animations in v1.** Static skeleton shapes (no shimmer animation). Simpler to implement, reduces motion for everyone.
- **No custom navigation.** Standard iOS navigation patterns: tab bar, navigation stack push, modal sheets. No drawer menus, no custom transitions.
- **No carousels except the photo gallery.** Horizontal scrolling cards are a discovery antipattern — users miss content. List view and map view are the two discovery modes.
- **No onboarding longer than 3 slides.** Respect the user's time. The app should be self-explanatory.
- **No real-time "Online" indicators.** Hosts in Somalia have intermittent connectivity. Showing "Online" sets unrealistic expectations. Show "Responds within X hours" instead.

## Open Questions

None. All design decisions are resolved for v1.

## Screen Inventory

23 screens organized by user flow in the Paper design file ("Recurly Designs" → "Marti UI designs"):

| Row | Section | Screens |
|---|---|---|
| 1 | Onboarding & Auth | 1.1 Onboarding, 1.2 Auth Sheet, 1.3 Phone OTP, 1.4 OTP Verification, 1.5 Create Profile |
| 2 | Discovery & Browse | 2.1 Discover List, 2.2 Discover Map, 2.3 Filters, 2.4 Listing Detail, 2.5 Host Profile |
| 3 | Booking Flow | 3.1 Booking Request, 3.2 Booking Confirmation, 3.3 My Bookings, 3.4 Booking Detail |
| 4 | Engagement | 4.1 Messages Tab, 4.2 Chat Thread, 4.3 Saved Listings, 4.4 Write Review |
| 5 | Profile & Settings | 5.1 Profile Tab, 5.2 Settings |
| 6 | Utility States | 6.1 Loading Skeleton, 6.2 Error State, 6.3 Empty States |

---

*Last updated: 2026-04-18*
