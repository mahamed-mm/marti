# Park Document — ios-engineer — 2026-05-01

> This is the end-of-session handoff. The next session of this role reads it first.

## Session summary

Implemented the **Listing Detail v3 visual + scroll-rhythm pass** end-to-end
per `docs/specs/Listing Detail v3 visual pass.md`, applying the COO scope
overrides delivered in the delegation prompt: visual/layout only, no
ViewModel changes, no new tests, no commits, working tree handed back dirty.

The pass restructures the content card stack to match the v3 spec's section
order (§B → §C → §D → §E → §F → §G → §I → §J → §K → §L → sticky §M), adds
five new presentational components, restructures three existing ones,
re-routes amenities through a new sheet destination, and wires Apple Maps as
the §I expand-disc destination. §H "Where you'll sleep" is intentionally
deferred with a marker comment per spec.

Goal in vs. out: goal in was a 6-create + 5-modify visual pass landing
clean (build green, 99/99 tests still green). Goal out matches: 6 created,
4 effectively-modified files (the 5th targeted modification — `ListingHostCardView` —
landed as a no-op verification: copy already correct after v2). Build green,
test count unchanged at 99/99 unique cases passing on iPhone 17 Pro.

## Files touched

| File                                                                                                   | Change   | Why                                                                                                                                           |
| ------------------------------------------------------------------------------------------------------ | -------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| `marti/Marti/Views/Shared/ComingSoonSheetView.swift`                                                   | Created  | Generic "ships with feature X" sheet. §L houseRules + safety route here. Closes 2026-04-28 carry-over `n3`.                                   |
| `marti/Marti/Views/ListingDetail/Components/ListingDetailHighlightsRow.swift`                          | Created  | §C 3-column stat row with vertical hairlines. Owns the Guest-favorite gate + fallback logic.                                                  |
| `marti/Marti/Views/ListingDetail/Components/ListingDetailWhyStaySection.swift`                         | Created  | §E 3 bare-glyph rows (Self check-in, neighborhood location, optional Verified host).                                                          |
| `marti/Marti/Views/ListingDetail/Components/ListingDetailExpandedHostCard.swift`                       | Created  | §K `surfaceElevated` + `Radius.lg` two-column card with stat rows + factlets + verified paragraph.                                            |
| `marti/Marti/Views/ListingDetail/Components/ListingDetailThingsToKnowSection.swift`                    | Created  | §L 3 tappable rows; owns `enum DetailSheet { cancellation, houseRules, safety }` and `.sheet(item:)` routing.                                 |
| `marti/Marti/Views/ListingDetail/Components/ListingAmenitiesSheet.swift`                               | Created  | §G destination — full amenity list using v2's stroked-container row recipe. Re-uses `ListingAmenitiesSection.symbolName/description`.         |
| `marti/Marti/Views/ListingDetail/ListingDetailView.swift`                                              | Modified | Re-ordered content card to §B → §C → §D → §E → §F → §G → §I → §J → §K → §L. Added §I map-callsite expand-disc + Show-more. Added `@State` for amenities sheet + description-expanded. Added §H deferral comment. |
| `marti/Marti/Views/ListingDetail/Components/ListingAmenitiesSection.swift`                             | Modified | Dropped 36×36 stroked icon container (bare glyph + label only). Capped at first 6 rows. Added full-width "Show all N amenities" button with `onShowAll:` callback. Made `description(for:)` static internal so the sheet can reuse it. |
| `marti/Marti/Views/ListingDetail/Components/ListingReviewsAggregateView.swift`                         | Modified | Added centered hero rating block (`martiDisplay` rating + Guest-favorite label + "Based on N ratings and reviews."). Kept "New" branch for `nil` rating. |
| `marti/Marti/Views/ListingDetail/Components/ListingDetailStickyFooterView.swift`                       | Modified | §M: `secondaryLine` now returns `String?` and is omitted entirely when SOS is unavailable (was rendering bare "Monthly"). Doc comment updated to reference v3. |

### Verified-only / untouched

- `marti/Marti/Views/ListingDetail/Components/ListingHostCardView.swift` — verify-only. Copy is already "Hosted by \(name)" + verified label after v2; no edit needed.
- `marti/Marti/ViewModels/ListingDetailViewModel.swift` — locked off per scope override #2.
- `marti/MartiTests/**` — no test changes per scope override #3.
- `marti/Marti/Extensions/DesignTokens.swift` — no new tokens.
- `marti/Marti/Services/ListingService.swift` and concrete impls — untouched.
- `marti/Marti/Models/Listing.swift` and `ListingDTO.swift` — untouched.
- `marti/Marti/Views/Shared/NeighborhoodMapView.swift` — untouched. Map view stays a leaf primitive; expand-disc + Show-more affordances live at the call-site in `ListingDetailView`.

## Decisions made

### 1. §C column-3 fallback when guest-favorite gate fails

- **What**: When the Guest-favorite gate (`averageRating >= 4.8 && reviewCount >= 3`) fails, column 2 falls back to `VerifiedBadgeView(.label)` if `isVerified == true`, otherwise an em-dash `"—"` in `martiHeading4` `Color.textTertiary`.
- **Why**: The spec offered "render `reviewCount` only" as the recommendation, but column 3 already shows the review count — re-rendering it in column 2 would be a duplicate. The em-dash placeholder maintains the rigid 3-column geometry without inventing a fact, and reads as "no notable signal here" rather than "blank cell". The Verified-label path stays preferred because it carries real information (trust signal) when we have it.
- **Alternatives considered**:
  - **Spec recommendation (review count duplicated)**: Rejected — duplicates column 3, reads as a copy-paste error.
  - **Empty cell**: Rejected — collapses the 3-column geometry visually.
  - **Star count word ("Excellent", "Great")**: Rejected — invents a marketing label not in the data.
- **Reversibility**: Cheap. Single `else` branch in `ListingDetailHighlightsRow.middleColumn`. Easy to swap if user research surfaces a better fallback.

### 2. §I expand-disc behavior — Apple Maps

- **What**: The expand-disc and the "Show more" caption both call a shared `openInAppleMaps()` helper that constructs an `MKMapItem(location:address:)` from the listing coordinate and calls `openInMaps(launchOptions:)`. The mapItem is named with the listing title.
- **Why**: Spec recommended attempting `MKMapItem(...).openInMaps()` if it reads cleanly. It does — one helper, three lines of body, no new dependencies (MapKit is system framework, already implicit via Mapbox SDK). Gives the affordance a real destination instead of leaving it decorative. Accessibility hint says "Opens this listing's neighborhood in Apple Maps." so VoiceOver users know what to expect.
- **Alternatives considered**:
  - **Decorative-only with hint**: Spec's fallback. Rejected — the affordance reads like an interactive control; users will tap it expecting something to happen.
  - **`MKMapItem(placemark:)`**: Deprecated under iOS 26 SDK (`'init(placemark:)' was deprecated in iOS 26.0`). Used the new `MKMapItem(location:address:)` initializer.
  - **Push to a full-screen map sheet**: Out of scope — would need a new `FullScreenNeighborhoodMapView`. Defer to v4 polish.
- **Reversibility**: Cheap. The `openInAppleMaps()` helper is private to `ListingDetailView`; replacing with a sheet push is a one-line swap on the two callers (disc + caption).

### 3. Description "Show more" toggle lives on the View, not the VM

- **What**: `@State private var isDescriptionExpanded = false` on `ListingDetailView`; toggled by the §F "Show more" button. The VM has no `isDescriptionExpanded` property.
- **Why**: Spec §F explicitly says "UI-only, no VM change. Use a `@State private var isDescriptionExpanded = false` on the view." This matches the project precedent (`isFeeTagDismissed` already lives on the view) and aligns with the COO override #2 directive.
- **Reversibility**: One-way conversion to VM-state if we later need it driven by a service-side flag (e.g., A/B test). Cheap to migrate at that point.

### 4. `ListingAmenitiesSection.description(for:)` promoted from `private` to `static internal`

- **What**: The `description(for:)` lookup table on `ListingAmenitiesSection` was `private static`. Promoted to `static` (default internal access) so `ListingAmenitiesSheet` can re-use it without duplicating the table.
- **Why**: DRY — the lookup is the single source of truth for amenity → description copy. Two callers in the same target both need it; a duplicate table would drift.
- **Alternatives considered**:
  - **Extract to a free-standing `AmenityCopy` namespace**: Premature abstraction at two callsites. Holding off until a third caller surfaces.
  - **Pass the descriptions in via an init parameter**: Awkward and error-prone — the sheet would need to compute the descriptions before constructing the rows.
- **Reversibility**: Cheap.

None of these decisions are architectural enough to warrant a `decisions.md`
entry. Recorded here for posterity.

## Open questions / blockers

- None. All sections built, build green, tests green.

## Inbox state at session end

- Inbox was empty at session start. No new inbound traffic during the session.

## Outbox summary

- No outbound messages to specialists or COO this session. The dirty tree
  + this park doc is the entire hand-back.

## What the next session should do first

1. Read this park doc and the most recent COO park doc (where v3 was queued).
2. If COO has run a design-reviewer audit, address findings.
3. If qa-engineer is gating: confirm 99/99 still green from a clean state.
4. Once v3 is merged, the v4 polish list per spec mentions:
   - Collapsing nav-bar morph (IMG_0606 → IMG_0607).
   - Per-room photos schema + `ListingBedroomsRail` (§H slot).
   - Real "Send message to host" wire-up (Feature 4 dependency).
5. Lower-priority carry-overs from prior sessions still apply (lineSpacing
   token, avatar diameter token, MartiDivider extraction, etc.) — see
   `current.md`.

## AC self-check (per spec §Acceptance criteria)

| AC  | Status | Note |
| --- | ------ | ---- |
| #1 — scroll order §B→…→§L→§M | ✅ Met | Order confirmed in `ListingDetailView.contentCard`. |
| #2 — every section header uses `martiHeading4`, primary, header trait | ✅ Met | Verified across `ListingAmenitiesSection`, `ListingReviewsAggregateView`, `ListingDetailThingsToKnowSection`, the inlined "Meet your host" header in `ListingDetailView`, and the inlined "Neighborhood" / "About this place" headers. |
| #3 — single 0.5pt `dividerLine` hairline between sections | ✅ Met | `Divider().background(Color.dividerLine)` between every pair of sections in `contentCard`. |
| #4 — §C three-column stat row with vertical hairlines, never collapses | ✅ Met | `ListingDetailHighlightsRow` renders 3 columns separated by 1×40 `dividerLine` rectangles; em-dash fallback when no Guest-favorite + no Verified. |
| #5 — §E why-stay rows render bare glyphs | ✅ Met | `ListingDetailWhyStaySection` rows: `Image(systemName:)` direct, no container. |
| #6 — §G amenities preview at most 6 rows + "Show all" sheet | ✅ Met | `ListingAmenitiesSection.previewCap = 6`, "Show all N amenities" stroked button, sheet routes to `ListingAmenitiesSheet`. |
| #7 — §I map has expand-disc top-right + Show-more caption | ✅ Met | `mapWithExpandDisc` ZStack + `showMoreNeighborhoodLink` button. Both call `openInAppleMaps()`. |
| #8 — §K expanded host card uses `surfaceElevated` + `Radius.lg`; no invented tenure | ✅ Met | `ListingDetailExpandedHostCard.card` uses `RoundedRectangle(cornerRadius: Radius.lg).fill(Color.surfaceElevated)`. No tenure stat. |
| #9 — §L rows tappable, present sheets, ComingSoon for house-rules + safety | ✅ Met | `ListingDetailThingsToKnowSection` `.sheet(item:)` routes cancellation → ListingCancellationPolicyView, houseRules + safety → `ComingSoonSheetView`. |
| #10 — §M sticky footer stacks `$price` + `Monthly · SOS`; drops sub-line cleanly when not | ✅ Met | `ListingDetailStickyFooterView.secondaryLine` is now `String?`; the line is omitted when `fullSOSPriceLine == nil`. |
| #11 — Build green on iPhone 17 Pro (Xcode 26.x) | ✅ Met | `** BUILD SUCCEEDED **` confirmed. |
| #12 — Test count 99 → 100 with `isAmenitiesSheetPresented_defaultsFalse` | ⛔ Skipped | Overridden by COO scope override #3. Test count stays at 99. |
| #13 — AX5 sweep: section headers as headers, tappable rows announce target, decorative announces decorative, "Show all amenities, button" | ✅ Met | All section headers use `.accessibilityAddTraits(.isHeader)`. §L rows have `.accessibilityHint("Tap to view…")`. §G "Show all" has `.accessibilityLabel("Show all amenities")` + `.accessibilityHint`. §I expand-disc + "Show more" carry hints describing their action. Manual VoiceOver sweep at AX5 deferred to design-reviewer + qa-engineer per process. |
| #14 — No new third-party packages, no new design tokens, no service or schema changes | ✅ Met | Verified — no SPM changes, no `DesignTokens.swift` edits, no `Models/` or `Services/` touches. Only addition was `import MapKit` in `ListingDetailView.swift` (system framework, free with iOS SDK). |

## Token / pattern questions deferred to COO

None. Every recipe in the v3 spec resolved to existing tokens and chrome
helpers (`Spacing.md/lg`, `Radius.md/lg`, `Color.surfaceElevated/dividerLine/textPrimary/textSecondary/textTertiary/statusWarning/statusDanger/coreAccent/canvas`,
`Font.martiDisplay/Heading3/Heading4/Label1/Label2/Body/Footnote`,
`glassDisc(diameter:)`). Did not need to inline any one-off, did not need
to escalate.

One small note: `ListingDetailExpandedHostCard` uses `Color.surfaceDefault`
behind the avatar's initial-fallback Circle — same `surfaceDefault` that the
content card sits on. The expanded card itself is `surfaceElevated`, so
`surfaceDefault` for the fallback gives a one-step-down contrast. If COO
wants the fallback to use `canvas` instead (one step deeper), trivial change.

## Suggested follow-ups (don't implement)

- **f1 — Per-room photos schema** (§H deferral): Land `bedrooms: [BedroomDTO]`
  on `Listing` + new `ListingBedroomsRail` component. The marker comment
  in `ListingDetailView.contentCard` is the slot.
- **f2 — `host_languages: [String]`** (§K language assumption): The
  expanded host card hard-codes "Speaks English & Somali". When v1.1 brings
  multi-language hosts, add the column and replace the literal.
- **f3 — `host_city: String`** (§K location assumption): Currently using
  `listing.city` as a stand-in for "host lives in". Same column-add pattern.
- **f4 — Years-hosting / response-rate / response-time** (§K stat rows):
  Three Airbnb-staple stats currently absent. Stat row plumbing is in place;
  add columns, then populate.
- **f5 — Real Reviews carousel** (§J upgrade): The `martiDisplay`-rating
  hero is in place. When Reviews ship, append the per-review carousel
  beneath the existing footnote.
- **f6 — Real Send-message button** (§K): The expanded host card has space
  for it; spec explicitly skipped to avoid a dead button. Drop in once
  Feature 4 lands.
- **f7 — Collapsing nav-bar morph on scroll** (v4 polish, IMG_0606 → IMG_0607).
  The floating-trio cluster currently scrolls with the photo. v4 ticket.
- **f8 — Translate notice + Trust banner**: Both deferred per spec until
  Somali localization and messaging exist.
- **f9 — Unify rating-star size** (carry-over `m4`): `ListingReviewsAggregateView.newRow` still uses 14pt; `ListingDetailHighlightsRow.starRow` uses 10pt. Different contexts (hero block vs. compact column), so the gap is intentional now, but if a §J "no rating" branch ever needs to read at the same scale as §C's column, revisit.
- **f10 — `MartiDivider` extraction** (carry-over `m5`): I added two new `Divider().background(Color.dividerLine)` callsites this session (§D→§E and §K→§L), bringing the total higher than 7. Extraction is increasingly worth it.

## Phantom-diagnostic notes

No SourceKit phantoms surfaced this session because I did not edit
`ListingDetailViewModel.swift` (where the prior session hit them). If COO
re-opens the VM in a follow-up session, watch for the recurring "Cannot
find type" cluster on `Listing` / `AppError` / `ListingService` /
`CurrencyService` / `AuthManager` — they are not real, the build is.

The new files that import `MapKit` (`ListingDetailView.swift`) compiled
cleanly — no warnings about missing `import` despite SwiftUI sharing some
namespace overlap with MapKit at the framework level.

## Gotchas for next session

- **`MKMapItem(placemark:)` is deprecated in iOS 26**. The replacement is
  `MKMapItem(location: CLLocation, address: MKAddress?)`. I used `address:
  nil` because we have no street address — only a coordinate. If the spec
  ever surfaces a real address (street + city + country), pass it via
  `MKAddress` for a richer Maps card.
- **§I disc + caption call the same helper** (`openInAppleMaps()`). If a
  future product call wants the caption to push a full-screen map and the
  disc to keep the Maps hand-off (or vice versa), split the helper at that
  point — kept as one for now per "minimum surface area" reflex.
- **`.sheet(item:)` on the §L section vs `.sheet(isPresented:)` on the
  amenities sheet** — they coexist on different ancestors and work fine.
  But if a future §L row ever needs to dismiss-and-then-present another
  sheet, that's two coordinated `.sheet(...)` modifiers — Apple's preferred
  fix is a single source of truth via an enum. Today's decoupling is fine.
- **Test count history is settled**: 99/99 unique test cases as of session
  end, identical to session start. Anchor to the run output, not the docs,
  if drift surfaces again.
- **Working tree is dirty by design** (per COO scope override #4): v1 + v2
  + 4 fixes + COO paperwork + this v3 session all coexist. Do not clean
  it without COO approval.
- **Apple Maps hand-off needs a real device or a simulator with Maps
  installed** to actually launch — `xcodebuild build` does not exercise it.
  If qa-engineer wants to validate the §I tap, run on a booted simulator.

## Session metadata

- **Duration**: approx. 35 minutes.
- **Build state at end**: `** BUILD SUCCEEDED **` on iPhone 17 Pro, no warnings.
- **Test state at end**: `** TEST SUCCEEDED **`, 99/99 unique test cases passing. Slowest case (`SupabaseListingServiceTests/fetchListing_mapsURLErrorToNetwork`) ~7–8s; suite-total ≈ 30–35s.

---

## Loop 2 — fix round (2026-05-01)

Design-reviewer audited the v3 visual pass and surfaced 2 blockers + 4
majors. COO bundled all 6 into a single fast-follow round with re-audit to
follow. This loop applied them; build + tests still green.

### Fixes applied

| Tag | File:line                                                                                   | Change                                                                                                                                                                                              | Verified by                |
| --- | ------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------- |
| B1  | `Views/ListingDetail/ListingDetailView.swift` (§D row + §K anchor)                          | Wrapped `contentCard`'s outer VStack in `ScrollViewReader`. Tagged the §K VStack with `.id(Self.expandedHostCardAnchor)`. Extracted `hostPreviewRow(scrollProxy:)` with `.contentShape(Rectangle())` + `.onTapGesture { hostPreviewHapticTrigger.toggle(); withAnimation(.smooth(duration: 0.35)) { proxy.scrollTo(anchor, anchor: .top) } }` + `.sensoryFeedback(.selection, trigger:)`. Added `@State hostPreviewHapticTrigger`. Re-combined the row as a `.isButton` AT element with hint "Scrolls to the host details below." | Build + mental-model walk: tap on §D fires haptic, animates scroll, lands §K at the top of the visible area. |
| B2  | `Views/ListingDetail/Components/ListingDetailThingsToKnowSection.swift` (line 71 + line 80) | Lifted the `.sensoryFeedback(.selection, trigger: presentedSheet?.id ?? "")` to the section's outer VStack. Removed the per-row attachment from `row(...)`. Confirmed only one functional `.sensoryFeedback` modifier remains in the file (`grep -n` shows match on line 71 only, plus an explanatory comment on line 67). | Build + grep + mental-model walk: any row tap flips `presentedSheet?.id`; section-level trigger evaluates once → one haptic. |
| M1  | `Views/ListingDetail/Components/ListingReviewsAggregateView.swift` (body)                   | Removed `.accessibilityElement(children: .combine)` + `.accessibilityLabel(...)` from the outer VStack. Moved them to wrap **only** the `centeredHero` block (and the `newRow` for the "New" branch). Renamed the helper from `accessibilityLabel` to `ratingBlockAccessibilityLabel` and added a Guest-favorite suffix when the gate passes. | Build + mental-model walk: VoiceOver focus order is "Reviews, heading" → "[combined rating block]" → "Individual reviews ship with the Reviews feature." `.isHeader` trait on "Reviews" is preserved (it's its own AT element again). |
| M2  | `Views/ListingDetail/Components/ListingAmenitiesSection.swift` (`showAllButton`)            | Replaced `RoundedRectangle.stroke(...)` with `RoundedRectangle.fill(Color.surfaceElevated)`. Hairline stroke **dropped** (see decision note below).                                                | Build + mental-model walk against spec §G: fill recipe matches "View all-style buttons" invariant. |
| M3  | `Views/ListingDetail/ListingDetailView.swift` (`mapWithExpandDisc`)                         | `Image(...).font(.system(size: 16, weight: .semibold))` → `size: 20`. Added a one-line comment citing the spec § and review tag.                                                                    | Build + mental-model walk: 20pt glyph on a 36pt disc — the spec dimensions, with plenty of disc room left over. |
| M4  | `Views/ListingDetail/Components/ListingAmenitiesSection.swift` (`showAllButton`)            | Added `@State private var showAllHapticTrigger = false`. Button action now toggles the flag before calling `onShowAll()`. Attached `.sensoryFeedback(.selection, trigger: showAllHapticTrigger)`. | Build + mental-model walk: matches §L's row haptic style (`.selection` for sheet triggers); `Reserve` keeps its `.impact` for primary-CTA differentiation. |

### Files touched in this round

1. `marti/Marti/Views/ListingDetail/ListingDetailView.swift` — B1 + M3.
2. `marti/Marti/Views/ListingDetail/Components/ListingDetailThingsToKnowSection.swift` — B2.
3. `marti/Marti/Views/ListingDetail/Components/ListingReviewsAggregateView.swift` — M1.
4. `marti/Marti/Views/ListingDetail/Components/ListingAmenitiesSection.swift` — M2 + M4.

(Four files, six fixes, exactly as the prompt predicted.)

### Build state — Loop 2 end

`** BUILD SUCCEEDED **` on iPhone 17 Pro. No warnings.

### Test state — Loop 2 end

`** TEST SUCCEEDED **`. **99/99 passing, 0 failures, 0 regressions.** Suite
duration ≈ 30s; slowest case `SupabaseListingServiceTests/fetchListing_mapsURLErrorToNetwork`
~7s.

### M2 stroke decision — dropped

Design-reviewer left this an engineer's call ("Stroke can stay as a hairline
boundary or drop entirely — your call.").

**Decision: dropped.**

**Why**: the spec's "View all-style buttons" recipe in §invariants names
fill + radius + minHeight + font + foreground only — no stroke. The project
precedent (`PrimaryButtonStyle` in `Buttons.swift`) is also fill-only. A
hairline stroke on top of `surfaceElevated` adds chrome without information
in dark mode (the surface already separates from the surrounding
`surfaceDefault` via its lighter fill). Cleaner, more consistent with the
in-app pattern.

**Reversibility**: cheap. If a future audit asks for the hairline back,
add an `.overlay(RoundedRectangle(cornerRadius: Radius.md).stroke(Color.dividerLine, lineWidth: 1))`
on the same shape.

### Decisions made during this loop (not architectural)

1. **§D scroll animation duration = 0.35s smooth**. Felt-out value — long
   enough to read as deliberate motion, short enough that a quick-tap user
   doesn't feel the page lock up. Used `.smooth(duration: 0.35)` rather
   than `.spring()` so the animation is monotone (no overshoot bouncing
   the §K card past the top edge).
2. **§D scroll anchor = `.top`**. Spec says "scroll to the expanded host
   card" without specifying anchor. `.top` lands §K's "Meet your host"
   header at the visible top, which is the natural read for a "more about
   the host" tap. `.center` would push the §K card halfway down the
   viewport with the §J reviews still visible above — reads less
   intentional.
3. **§D haptic = `.sensoryFeedback(.selection, …)`**. Matches the §L row
   haptic post-B2 fix. `.impact` reserved for primary CTAs (the Reserve
   pill keeps it).
4. **`expandedHostCardAnchor` lifted to a `private static let`** on
   `ListingDetailView`. Anchor strings as inline literals are a bug-class
   nobody catches at compile time — the §K `.id(...)` and the
   `proxy.scrollTo(...)` must agree exactly. One constant, two call-sites.
5. **B1 accessibility** — added `.accessibilityElement(children: .combine)`
   + `.accessibilityAddTraits(.isButton)` + a hint to the §D row wrapper.
   Loop 1's bare `ListingHostCardView` already had a combined label
   ("Hosted by Erik, verified host."), so the trait additions layer on
   without colliding with the existing AT element.

### Phantom-diagnostic notes for Loop 2

- **None of the SourceKit ghosts the prior session warned about surfaced
  this loop**. Editing `ListingDetailView.swift` (with new `ScrollViewReader`,
  new helper, new `@State`) compiled clean on first try — no "Cannot find
  type" cluster. Same for the other three files. The `xcodebuild` log shows
  zero errors and zero warnings across the whole project.
- **`MapKit` import warnings stayed silent.** The §I expand-disc continues
  to use `MKMapItem(location:address:)`; SDK didn't surface the deprecated-init
  noise the prior session avoided.

### Surprises this loop

- **The §J accessibility erasure (M1) is a really easy mistake to make.**
  Combining children at the outer level *feels* clean — one VoiceOver
  swipe per visual section is the rule of thumb — but it silently flattens
  every nested AT trait, including `.isHeader`. Filing this as a pattern
  to remember: **whenever a section has a true header `Text` you want
  VoiceOver to announce as a heading, never combine at the section root.**
  Combine on the *contentful child*, not the parent that includes the
  header. Worth a one-paragraph note in `.claude/rules/swiftui.md` if COO
  wants to codify it.
- **`ScrollViewReader` placement.** The reader must wrap a view *inside*
  the surrounding `ScrollView`, not the `ScrollView` itself. The
  `contentCard` is already the inner content of the outer `ScrollView` in
  `body`, so wrapping the `contentCard`'s VStack with `ScrollViewReader`
  is correct — but I double-checked because the docs on this are subtle.
  The `proxy.scrollTo` call resolves against the nearest enclosing
  `ScrollView`, and that's the outer one in `body`, which is what we
  want. No surprises in practice.
- **B2's triple-buzz was a textbook SwiftUI footgun.** Three `.sensoryFeedback`
  modifiers with the same trigger expression all fire simultaneously when
  the trigger flips — the feedback fires per-attached, not per-tap.
  Pattern to remember: **`.sensoryFeedback` belongs on the surface that
  owns the state change, not the surface that emits the gesture.** For a
  group of rows that share state, that's the section, not each row. Worth
  another one-paragraph note in the same rules doc.

### Inbox state — Loop 2 end

- No new inbox traffic this loop.

### What the next session should do first (post-Loop 2)

1. Re-audit by design-reviewer (per COO bundle).
2. If audit passes: qa-engineer step (full suite from clean build).
3. If audit surfaces more findings: a Loop 3 fix round.
4. Carry-overs (m1, m2, m4, m5, n1, the v3 follow-ups f1–f10) remain on
   the back-burner — only pick them up on COO direction.

### Loop 2 metadata

- **Duration**: approx. 25 minutes (read-fixes-build-test-park).
- **Build state at end of Loop 2**: `** BUILD SUCCEEDED **` on iPhone 17 Pro, no warnings.
- **Test state at end of Loop 2**: `** TEST SUCCEEDED **`, 99/99 unique test cases passing, 0 regressions.
