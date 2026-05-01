# Spec — Listing Detail v3 (visual + scroll-rhythm pass)

**Status**: Draft (COO, 2026-04-30). Awaiting approval.
**Predecessor**: `docs/specs/Listing Detail v2 visual pass.md` (shipped 2026-04-29). v2 stays the source of truth for behavior, data flow, tests, locked decisions on share-button / footer / Reserve color. v3 is a **scroll-rhythm + section-stack** restructure layered on top.
**Inspiration source**: 14 physical-iPhone screenshots in `screenshots/IMG_0602.PNG … IMG_0615.PNG` (Airbnb listing detail in light mode, Norwegian copy). Scroll captures the full page top-to-bottom.

## Goal

Restructure the Listing Detail content stack so its **scroll rhythm and section vocabulary** match the reference: many small, divider-separated sections, each one a focused visual unit that the eye can scan in one beat. Keep Marti's dark-mode-only token system. **Visual / layout only.** No new schema, no color tokens, no service or VM API changes beyond optional UI-only state additions.

## Non-goals

- No new `Listing` columns. Sections that need data we don't have (per-room photos, host tenure, response rate, exact dates) **render placeholder copy or are deferred** with a one-liner pointing at the future feature — never invented.
- No new color tokens. No new typography styles. No new spacing values. v3 reuses what's in `Extensions/DesignTokens.swift`.
- No new SPM packages.
- No changes to `ListingService` / `SupabaseListingService`.
- No share-sheet plumbing (still decorative per v2 lock).
- No real "Send message to host" flow (Feature 4 territory).
- No changes to existing 99/99 passing tests except adding tests for any **new VM-state** introduced (e.g., `isAmenitiesSheetPresented`).

## What stays from v2 (do not touch)

1. Hero gallery component (`ListingPhotoGalleryView`) — paged swipe, 1/N pill, 4:3 aspect.
2. Floating-trio cluster (back · share · favorite) on `.glassDisc(diameter: 44)` — pinned to the top safe area via `.safeAreaPadding(.top)`.
3. `surfaceDefault` rounded-top card overlapping the hero by `Spacing.lg`.
4. Sticky footer existence and red `Color.statusDanger` Capsule Reserve button. (Internal layout of the footer is restructured — see §M.)
5. `.notFound` alert + auto-pop, hide-floating-tab-bar, AuthSheetPlaceholderView and RequestToBookComingSoonSheet hookups, `FeeInclusionTag` floating above the footer.
6. Locked decision: share button is decorative. Locked decision: do not invent host tenure or response rate.

## The new scroll rhythm — invariants

Inside the content card (`Color.surfaceDefault` overlay) all sections obey:

- **Section spacing**: `Spacing.lg` (24pt) above and below each section header / first row.
- **Section dividers**: 0.5pt hairline `Color.dividerLine` running edge-to-edge of the content card (i.e. respecting `Spacing.screenMargin` on both sides). Use `Divider().background(Color.dividerLine)` — already the project pattern.
- **Section headers**: `Font.martiHeading4`, `Color.textPrimary`, left-aligned, with `.accessibilityAddTraits(.isHeader)`. **No leading glyph.**
- **Body / secondary copy**: `Font.martiBody` for prose, `Font.martiFootnote` + `Color.textSecondary` for sub-labels.
- **Tappable rows** (sections that lead into a deferred feature): use a `chevron.right` (`16pt, .semibold`, `Color.textTertiary`) trailing affordance, full-row `.contentShape(Rectangle())`, haptic on tap, but the action body can be a placeholder (e.g. present a `ComingSoonSheetView`) until the destination ships.
- **"View all"-style buttons**: `Color.surfaceElevated` fill, `Radius.md`, ~48pt minHeight, full-width, `Font.martiLabel1`, `Color.textPrimary`. Reuse the `GhostButtonStyle` if its visual matches; otherwise inline the recipe — do **not** create a new global style yet.

## Section stack — scroll-order spec

Every section below sits inside the existing rounded-top `surfaceDefault` content card. The hero, floating buttons, and sticky footer continue to live outside it.

### A. Hero (unchanged from v2)

`heroZone(currentIndex:)` + `heroFloatingButtons` stay as in v2. **No changes.**

### B. Title block — centered, with capacity bullet line

Replace the current left-aligned title block with a **centered** stack mirroring IMG_0602 / IMG_0606:

- `Text(listing.title)` — `Font.martiHeading3`, `Color.textPrimary`, `multilineTextAlignment(.center)`.
- A subtitle line composed of `"\(neighborhood), \(city)"` followed by capacity facts joined by `" · "` (interpunct):
  - In the reference: `4 guests · 2 bedrooms · 3 bed · 1 bath`.
  - **Marti has only `maxGuests`** — the rest of those facts (bedrooms, beds, baths) are not on `Listing`. Until the schema grows, render only what we have:
    - Line 1: `"\(neighborhood), \(city)"` — `Font.martiFootnote`, `Color.textSecondary`.
    - Line 2: `"\(maxGuests) guests"` (singular at 1) — `Font.martiFootnote`, `Color.textSecondary`.
  - **Do not invent** "1 bedroom · 2 beds". Note the gap as a follow-up, not a fabrication.
- Drop the centered ★-rating row from v2 — that data moves into the **highlights stat row** (§C).
- Whole block centered: `.frame(maxWidth: .infinity)` + `.multilineTextAlignment(.center)`.

### C. Highlights stat row — three columns with vertical hairlines

New section, sits directly under the title block (no hairline divider above — they belong to the same title group; hairline below).

Three equal-width columns separated by 1pt vertical `Color.dividerLine` hairlines:

| Column 1                                                                                                                           | Column 2                                                                                                                                                                                                                                                                                                                                                                 | Column 3                                                                                                |
| ---------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------- |
| `String(format: "%.2f", averageRating)` (or `"New"` when `nil`) in `martiHeading4`, then `★★★★★` row of 5 small filled stars below | If `averageRating ?? 0 >= 4.8` and `reviewCount >= 3`: a **"Guest favorite"** label in `martiLabel2`, with a small decorative laurel-leaf glyph on either side (use `leaf.fill` flipped horizontally on one side — closest SF Symbol; OK to omit if it reads off). Otherwise: render a neutral fact like `"Verified"` (when `isVerified`) so the column never collapses. | `"\(reviewCount)"` in `martiHeading4`, then `"Reviews"` in `martiFootnote` `Color.textSecondary` below. |

- Container: `HStack(spacing: 0)` with `Divider().frame(width: 1, height: 40).background(Color.dividerLine)` between columns.
- Each cell: `VStack(spacing: Spacing.xs)` centered, both axes.
- Cell padding: `.vertical, Spacing.md`.
- Whole row left/right padding: handled by content-card horizontal padding.
- Bottom hairline divider beneath this row.

**Acceptance copy for the "Guest favorite" gate**: rule is `averageRating >= 4.8 && reviewCount >= 3`. Anything else falls back to the verified / neutral cell so the geometry stays rigid.

### D. Host preview row (small) — keep v2 component

Keep `ListingHostCardView` as the _small_ preview (50pt avatar + "Hosted by …" + verified-badge label). It maps to IMG_0602 row "Erik er vertskap / Superhost · 10 år som vertskap".

- Drop the "10 år som vertskap" tenure line — Marti has no tenure column (see locked decision in v2; carries forward).
- Container is row-level only — **no card chrome around this**, so it sits as a plain row, hairlines top and bottom.
- Whole row tappable (`.contentShape(Rectangle())`); tap should scroll the page to the **expanded host card** (§K) for now. In a future ship this becomes a host-profile push.

### E. Highlights / Why-stay rows — bare-glyph rows

Replace the current `ListingAmenitiesSection` recipe **for this section only** (amenities have their own section later). New section, modelled on IMG_0603 / IMG_0604:

- Section has **no header** — three rows just sit between hairlines, evoking a "things this place is great at" beat.
- Each row: `HStack(alignment: .top, spacing: Spacing.base)`:
  - `Image(systemName: …)` — 20pt regular, `Color.textPrimary`. **No background container, no stroke** (this is the visible delta from amenities §G — bare glyph here, container box there).
  - `VStack(alignment: .leading, spacing: Spacing.xs)`:
    - Title: `Font.martiLabel1`, `Color.textPrimary`.
    - Subtitle: `Font.martiFootnote`, `Color.textSecondary`, `.fixedSize(horizontal: false, vertical: true)`.
- Three default highlights, computed from `Listing` (not from a new column):

| Glyph                | Title                        | Subtitle                                                                               | Show when                            |
| -------------------- | ---------------------------- | -------------------------------------------------------------------------------------- | ------------------------------------ |
| `key.fill`           | `"Self check-in"`            | `"Easy entry on arrival — host coordinates by message."`                               | Always. (Generic enough not to lie.) |
| `mappin.and.ellipse` | `"\(neighborhood) location"` | `"Near \(city)'s daily life — markets, mosques, restaurants within walking distance."` | Always.                              |
| `medal.fill`         | `"Verified host"`            | `"Host has been ID-verified by Marti."`                                                | Only when `isVerified == true`.      |

- Row-to-row spacing: `Spacing.lg`.
- Section ends with a hairline divider.
- **Future-proofing**: when we have real amenity-derived highlights (e.g., "Sea breeze", "Quiet block") promote them into this slot; today's copy is intentionally generic so it's never wrong.

### F. About this place — prose

- Header: `"About this place"` — `Font.martiHeading4`, primary, accessibility header trait.
- Body: `listing.listingDescription` — `Font.martiBody`, `Color.textSecondary`, `lineSpacing(4)`, `lineLimit(6)` initially.
- "Show more" affordance: when `listingDescription` exceeds the 6-line clamp, render a tappable `"Show more"` row in `Font.martiLabel2`, `Color.textPrimary`, with a `chevron.right` (12pt, semibold, `Color.textTertiary`). Tap toggles `lineLimit(nil)`. Use a `@State private var isDescriptionExpanded = false` on the view — UI-only, no VM change.
- Hairline divider beneath.

### G. Amenities preview + "Show all" — restructured

Replaces the current `ListingAmenitiesSection` body (file stays, contents change).

- Header: `"What this place offers"` — `Font.martiHeading4`, primary, header trait.
- Render the **first 6** amenities (or all if fewer than 6) in a list. Each row:
  - `Image(systemName: ListingAmenitiesSection.symbolName(for: amenity))` — 20pt regular, `Color.textPrimary`. **No 36×36 stroked container** (drop v2's icon box for this section). Bare glyph + label only — matches IMG_0608 / IMG_0609.
  - `Text(amenity)` — `Font.martiBody`, `Color.textPrimary`.
  - For amenities the listing **doesn't** have (a future "Carbon monoxide alarm" no-show), apply `.strikethrough()` and use a slashed-circle SF Symbol variant. v1 schema only stores positive amenities, so this branch is **dormant** until we model negatives — note in code comment, do not add UI for it now.
- Below the rows, when `amenities.count > 6`: a full-width `"Show all \(amenities.count) amenities"` button, `Color.surfaceElevated` fill, `Radius.md`, 48pt minHeight, `Font.martiLabel1`, primary text. Tap presents a sheet (`ListingAmenitiesSheet`) showing the full amenity list using the **v2 stroked-container row recipe** (the sheet can use the richer treatment because it's the destination). VM gains `@Published var isAmenitiesSheetPresented: Bool = false` + a unit test asserting default is `false`.
- Hairline divider beneath. Section is suppressed entirely when `amenities.isEmpty`.

### H. Where you'll sleep — DEFERRED stub

The reference shows a horizontal rail of bedroom photos (IMG_0608). Marti has **no per-room photos** — `Listing.photoURLs` is the apartment as a whole. **Defer**:

- Do **not** add this section to v3.
- Add a one-line comment in `ListingDetailView.swift`'s contentCard stack at the position where it would slot in: `// Where you'll sleep — deferred until per-room photos schema lands.`
- Future ticket: schema column `bedrooms: [BedroomDTO]` + new `ListingBedroomsRail` component.

### I. Neighborhood — map embed with expand affordance + show-more link

Replaces the current standalone `NeighborhoodMapView` placement.

- Header: `"Neighborhood"` — `Font.martiHeading4`, primary, header trait.
- Subtitle line directly under header: `"\(neighborhood), \(city)"` — `Font.martiFootnote`, `Color.textSecondary`. (Mirrors IMG_0610's "Bergen, Hordaland, Norge".)
- Map: existing `NeighborhoodMapView(coordinate:)` — **no behavior change**. Mapbox ornament fix (logo + (i)) from 2026-04-30 stays.
- Top-right overlay on the map: a `glassDisc(diameter: 36)` containing `arrow.up.left.and.arrow.down.right` (20pt `.semibold`, `Color.textPrimary`). Decorative for v3 (no full-screen map yet) — accessibility hint: `"Decorative — full-screen map coming soon."`
- Below the map: a left-aligned `"Show more"` row with trailing `chevron.right` (`Font.martiLabel2`, `Color.textPrimary`). Decorative tap for v3 (or open Apple Maps with the coordinate via `MKMapItem` if trivial — engineer's call). If decorative, accessibility hint as above.
- Hairline divider beneath.

### J. Reviews summary — keep aggregate, add framing

Reuses `ListingReviewsAggregateView` but visually upgraded to mirror IMG_0611's centered hero rating block when `averageRating != nil`:

- Header: `"Reviews"` — `Font.martiHeading4`, primary, header trait.
- Centered block beneath:
  - Large `String(format: "%.2f", rating)` in `Font.martiDisplay`.
  - Small "Guest favorite" label in `Font.martiLabel2` (only when same gate as §C, otherwise omit).
  - One line of `Font.martiFootnote` `Color.textSecondary` underneath: `"Based on \(reviewCount) ratings and reviews."` (skip the laurel decoration — too risky to fake without a custom asset, and the §C row already uses leaves).
- Below the centered block: keep the existing footnote `"Individual reviews ship with the Reviews feature."` (Feature 5 placeholder; do not change copy).
- When `averageRating == nil`: render the existing "New" treatment — no centered hero.
- Hairline divider beneath.

### K. Meet the host — expanded card

This is the **second** host surface — the larger, more prominent card from IMG_0612. Marti currently has only the small preview row at the top (§D). Add this as a new section.

- Header: `"Meet your host"` — `Font.martiHeading4`, primary, header trait.
- Card: `Color.surfaceElevated` fill, `Radius.lg`, padding `Spacing.lg`. Two-column:
  - **Leading column** (60% width): 80pt circular avatar (use the same `AsyncImage` + `initialFallback` recipe as `ListingHostCardView`, but at 80pt). If `isVerified`, overlay a small `VerifiedBadgeView(variant: .icon)` at the bottom-trailing of the avatar. Below avatar: `hostName` in `Font.martiHeading4`, primary, centered. Then a small "Superhost"-style label only when `isVerified == true`: render the existing `VerifiedBadgeView(variant: .label)`.
  - **Trailing column** (40% width): a vertical stack of stat rows with hairline `dividerLine` between them — driven by what we have:
    - `"\(reviewCount)"` (heading4) over `"Reviews"` (footnote secondary) — always.
    - When `averageRating != nil`: `"\(rating) ★"` (heading4) over `"Rating"` (footnote secondary).
    - **Skip** the "Years hosting" stat — no tenure data.
- Below the card: a row of `Font.martiFootnote` factlets, each prefixed by a 16pt SF Symbol — **only render the ones we have**:
  - `globe` + `"Speaks English & Somali"` — hard-coded for v1 (every Marti host launches with these two languages; document as an assumption in the code comment).
  - `house.fill` + `"Lives in \(city)"` — using `listing.city` as a stand-in until host has its own city column.
- "Erik er Superhost" paragraph — render only when `isVerified`: copy = `"Verified hosts have been ID-checked by Marti and have a track record of great stays."` `Font.martiBody`, `Color.textSecondary`.
- **No "Send message to host" button** (Feature 4 territory). Skip it. Do not stub a sheet that goes nowhere — the row vacancy reads better than a dead button.
- Hairline divider beneath.

### L. Things to know — three tappable rows

Modeled on IMG_0613 / IMG_0614. Replaces the current `ListingCancellationPolicyView` placement (the component itself is reused, restructured into a row).

- Header: `"Things to know"` — `Font.martiHeading4`, primary, header trait.
- Three rows, each: 20pt SF Symbol leading, `VStack(alignment: .leading, spacing: Spacing.xs)` (title in `martiLabel1`, subtitle in `martiFootnote` secondary), `Spacer`, trailing `chevron.right` (16pt, semibold, `Color.textTertiary`):

| Glyph                                             | Title                   | Subtitle                                                                                                              | Tap behavior                                                                                |
| ------------------------------------------------- | ----------------------- | --------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| `xmark.bin` (or `calendar.badge.exclamationmark`) | `"Cancellation policy"` | Computed from `cancellationPolicy` via existing `displayName` + `subtitle` mapping in `ListingCancellationPolicyView` | Present a sheet showing the full `ListingCancellationPolicyView` rendering.                 |
| `key.fill`                                        | `"House rules"`         | `"Check-in after 2pm. Check-out before noon. Max \(maxGuests) guests."`                                               | Present a `ComingSoonSheetView` ("Full house rules ship with host onboarding").             |
| `shield.lefthalf.filled`                          | `"Safety & property"`   | `"Host has agreed to Marti's safety standards."`                                                                      | Present a `ComingSoonSheetView` ("Detailed safety info ships with Trust & Safety surface"). |

- Each row: `.contentShape(Rectangle())`, `.onTapGesture` flips a single `@State` enum on the view — `enum DetailSheet { case cancellation, houseRules, safety }`. The `.sheet(item:)` resolves to the right sheet content.
- Hairline divider beneath.

### M. Sticky footer — restructured

Reuse `ListingDetailStickyFooterView`; restructure its internal layout to match IMG_0615:

- **Top row** (small, when `cancellationPolicy != "strict"`): keep the existing `checkmark + "Free cancellation"` line (no change).
- **Bottom row**: two-column layout.
  - **Left column** (`VStack(alignment: .leading, spacing: 2)`):
    - Line 1: bold price — keep `"$\(int)"` in `Font.martiHeading3`. Append `" total"` only when we have a real total (we don't — drop the "total" word for v3 and stick with the existing `$120` shape).
    - Line 2: small secondary line. **Replace** current `"Monthly · \(SOS)"` with two stacked sub-lines per the reference's "16.–18. okt." + "0 kr i dag · Kostnadsfri kansellering" pattern, but adapted to what Marti has:
      - Sub-line 2a (only when SOS rate present): `"Monthly · \(fullSOSPriceLine)"` in `Font.martiFootnote`, `Color.textSecondary`.
      - Sub-line 2b (when `cancellationPolicy != "strict"`): omit — already represented by the top row. (Don't double up.)
  - **Right column**: existing red `Color.statusDanger` Capsule with `"Reserve"` label — **no change**. (Future: when Request-to-Book ships, label can dynamically change to `"Reserve"` / `"Request to book"` based on listing's instant-book flag — defer.)
- Footer container, dividers, `.thinMaterial` background, top hairline — all unchanged from v2.
- The `FeeInclusionTag` continues to float above this footer via `safeAreaInset(.bottom)` — unchanged.

## Scroll behavior

- Whole page is one `ScrollView`. **No scroll-position-driven nav-bar morph** in v3 — the floating-trio cluster pinned to the top safe area scrolls **with** the photo (it's already inside the `ScrollView`'s `VStack`). The reference does have a collapsing nav-bar treatment (IMG_0606 → IMG_0607), but that's a **v4 polish item**, not v3 scope.
- `.toolbar(.hidden, for: .navigationBar)` stays.
- `hideFloatingTabBar(true)` stays.

## Component file map

| File                                             | Change kind       | Notes                                                                                                                                                                                                        |
| ------------------------------------------------ | ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `ListingDetailView.swift`                        | **Restructure**   | Re-order content card stack to §B → §C → §D → §E → §F → §G → §I → §J → §K → §L. Add section sheet `@State enum` for §L.                                                                                      |
| `ListingPhotoGalleryView.swift`                  | No change         | v2 hero gallery untouched.                                                                                                                                                                                   |
| `ListingHostCardView.swift`                      | Tighten           | Confirm copy is just "Hosted by \(name)" + verified label. (Already correct after v2.)                                                                                                                       |
| `ListingAmenitiesSection.swift`                  | **Restructure**   | Drop the 36×36 stroked icon container in this surface. Limit to first 6 rows + "Show all" button when more exist. Keep `symbolName(for:)` and `description(for:)` lookup tables (the sheet still uses them). |
| `ListingCancellationPolicyView.swift`            | Reuse             | Used inside the cancellation sheet; remove its standalone placement from `ListingDetailView`.                                                                                                                |
| `ListingReviewsAggregateView.swift`              | **Restructure**   | Add the centered hero rating block; reuse the gate from §C.                                                                                                                                                  |
| `ListingDetailStickyFooterView.swift`            | Tweak             | Internal stack restructure per §M. No new public API.                                                                                                                                                        |
| `NeighborhoodMapView.swift`                      | No change to file | Add the expand-disc + show-more affordances at the **callsite** in `ListingDetailView`, not inside `NeighborhoodMapView` (keeps it a leaf).                                                                  |
| **NEW** `ListingDetailHighlightsRow.swift`       | Create            | The 3-column stat row from §C. Pure presentational.                                                                                                                                                          |
| **NEW** `ListingDetailWhyStaySection.swift`      | Create            | The 3 bare-glyph rows from §E. Computed from `Listing` only.                                                                                                                                                 |
| **NEW** `ListingDetailExpandedHostCard.swift`    | Create            | The card from §K.                                                                                                                                                                                            |
| **NEW** `ListingDetailThingsToKnowSection.swift` | Create            | The 3 tappable rows from §L. Owns the `enum DetailSheet` and renders sheet content.                                                                                                                          |
| **NEW** `ListingAmenitiesSheet.swift`            | Create            | Sheet destination for §G's "Show all". Reuses `ListingAmenitiesSection`'s row recipe but with the v2 stroked container.                                                                                      |
| **NEW** `ComingSoonSheetView.swift`              | Create            | Generic "ships with feature X" sheet. Shared with §L's house-rules + safety sheets. (This was a 2026-04-28 carry-over follow-up — folding it in here lets us close it.)                                      |
| `ListingDetailViewModel.swift`                   | Add UI state      | `@Published var isAmenitiesSheetPresented: Bool = false`. No service or business logic change.                                                                                                               |

## ViewModel additions

```swift
extension ListingDetailViewModel {
    /// True when the "Show all amenities" sheet is presenting. UI-only;
    /// flipped by the view, not by services.
    var isAmenitiesSheetPresented: Bool  // backed by @Observable storage
}
```

Add one unit test in `ListingDetailViewModelTests`:

- `isAmenitiesSheetPresented_defaultsFalse()` — asserts the default state.

The §L sheet enum stays on the view (`@State`), not the VM — it's pure UI navigation state with no business meaning, consistent with how `isFeeTagDismissed` is handled.

## Tokens audit (constraint check)

Every visual recipe above resolves to existing `DesignTokens.swift` entries:

- Colors: `canvas`, `surfaceDefault`, `surfaceElevated`, `dividerLine`, `textPrimary`, `textSecondary`, `textTertiary`, `statusWarning`, `statusDanger`, `coreAccent`. **No new colors.**
- Spacing: `xs (2)`, `sm (4)`, `md (8)`, `base (16)`, `lg (24)`, `xl (32)`, `screenMargin (16)`. **No new spacing.**
- Radius: `sm (8)`, `md (12)`, `lg (24)`. **No new radii.**
- Typography: `martiDisplay`, `martiHeading3`, `martiHeading4`, `martiHeading5`, `martiBody`, `martiFootnote`, `martiLabel1`, `martiLabel2`. **No new fonts.**
- Chrome recipes: `glassDisc(diameter:)`, `floatingIslandBackground(_:)`, `shadow(token:)`. **No new recipes.**

If the engineer hits a case that genuinely needs a new token, they **stop and escalate to COO** rather than inlining a one-off — the v3 brief's contract is "no token additions."

## Acceptance criteria

1. Scroll order matches §B → §C → §D → §E → §F → §G → §I → §J → §K → §L → (sticky M).
2. Every section header uses `martiHeading4`, primary, header accessibility trait.
3. Every section pair is separated by a single 0.5pt `Color.dividerLine` hairline.
4. The §C stat row has three equal columns with vertical `dividerLine` hairlines between them; cells fall back as specified when data is missing (never collapses to nothing).
5. The §E why-stay rows render bare glyphs (no container box).
6. The §G amenities preview shows at most 6 rows + "Show all" button; full list lives in `ListingAmenitiesSheet`.
7. The §I map has an expand-disc top-right and a "Show more" caption underneath.
8. The §K expanded host card uses `surfaceElevated` + `Radius.lg`; never invents tenure / response-rate.
9. The §L "Things to know" rows are tappable, present sheets, and fall through to `ComingSoonSheetView` for house-rules + safety.
10. The §M sticky footer stacks `$price` + `Monthly · SOS` correctly when SOS is available; drops the SOS sub-line cleanly when not.
11. Build green on iPhone 17 Pro (Xcode 26.x).
12. Test count moves from 99 → 100 (`isAmenitiesSheetPresented_defaultsFalse`). All other tests unchanged and green.
13. AX5 sweep: every section header reads as a header in VoiceOver; tappable rows announce their target ("Cancellation policy. Tap to view full policy."); the decorative expand-disc and "Show more" caption announce as decorative; the §G "Show all" button announces "Show all amenities, button".
14. No new third-party packages. No new design tokens. No service or schema changes.

## Out of scope (explicitly deferred)

- **Per-room photos** rail (§H) — needs schema column.
- **Send message to host** button — Feature 4 (Messaging).
- **Reviews carousel with text** — Feature 5 (Reviews).
- **Date picker / availability** row — Feature 3 (Request to Book).
- **Similar listings** rail — needs a "listings near coordinate" service method; defer.
- **Report listing** flag link — Trust & Safety surface, separate feature.
- **Collapsing nav-bar morph** on scroll (the IMG_0606 → IMG_0607 transition) — v4 polish.
- **Translate notice** banner ("Some info shown in original language") — only meaningful after Somali localization (`Localizable.xcstrings` migration, v1.1).
- **Trust banner** ("Always pay on Marti, never message off-platform") — defer until messaging exists.

## Risks / open questions

- **§C column-3 fallback**: should "Verified" be the fallback when guest-favorite gate fails, or should we render `reviewCount` only? Recommend **`reviewCount` only** (the column already shows the count number when guest-favorite gate passes; just lose the laurel framing). Engineer's call — flag in PR for COO review.
- **§E generic copy**: "Self check-in", "Quiet location", and "Verified host" risk feeling samey across listings. Acceptable for v3 because they're rotated by `isVerified`. If user research surfaces "all listings look the same", we promote real amenity-derived highlights into this slot in v4.
- **§I expand-disc decorative tap** vs. opening Apple Maps: opening Maps via `MKMapItem` is one-line (`MKMapItem(placemark:).openInMaps()`) — engineer should attempt it; if it fails ToS / linking checks, fall back to decorative. Default to opening Maps if the implementation reads cleanly.
- **§K language assumption** ("Speaks English & Somali") is hard-coded. If a v1.1 listing surfaces a different language profile, we need a `host_languages: [String]` column. Today's hard-code is a deliberate placeholder — comment it in the source.

## Delivery posture

- **Single PR**, 4 commits suggested:
  1. New components (5 files) + `ComingSoonSheetView`.
  2. `ListingAmenitiesSection` restructure + `ListingAmenitiesSheet` + VM state + test.
  3. `ListingReviewsAggregateView` + `ListingDetailStickyFooterView` restructure.
  4. `ListingDetailView` re-order + map-callsite affordances.
- Each commit builds + passes the test suite.
- Final commit message references this spec by path.
- Post-merge: `design-reviewer` audit + AX5 manual sweep before STATUS.md update.

---

## Appendix — quick mapping table from inspiration screenshots → spec sections

| Screenshot                   | Maps to                                                                  |
| ---------------------------- | ------------------------------------------------------------------------ |
| IMG_0602, IMG_0603           | §A hero, §B title block                                                  |
| IMG_0603, IMG_0604, IMG_0605 | §C stat row, §D host preview, §E why-stay rows                           |
| IMG_0606, IMG_0607           | §F about-this-place prose + Show more                                    |
| IMG_0608, IMG_0609           | §G amenities preview + Show all (§H room rail is the deferred slot here) |
| IMG_0609, IMG_0610           | §I neighborhood map + expand + Show more                                 |
| IMG_0611                     | §J reviews summary (centered hero)                                       |
| IMG_0612                     | §K expanded host card                                                    |
| IMG_0613, IMG_0614           | §L things-to-know rows                                                   |
| IMG_0615                     | §L tail + sticky footer §M                                               |

---

_Authored by COO, 2026-04-30. Awaiting approval before delegating to ios-engineer (primary) + maps-engineer (§I overlay) + design-reviewer (post-merge audit)._
