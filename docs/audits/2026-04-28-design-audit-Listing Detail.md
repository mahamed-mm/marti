# Design audit — Listing Detail — 2026-04-28

Surface-scoped design + HIG audit of the new Listing Detail feature shipped
on `dev` per `docs/specs/Listing Detail.md`. Covers the eight new SwiftUI
files plus the shared `NeighborhoodMapView`. Discovery, Auth and other
existing surfaces are out of scope.

## Snapshot

- **Auditor:** design-reviewer
- **Branch:** `dev`
- **Spec:** `docs/specs/Listing Detail.md` (status: Approved)
- **Implementer park doc:** `.claude/jobs/ios-engineer/park/2026-04-28-ios-engineer.md`
- **Maps park doc:** `.claude/jobs/maps-engineer/park/2026-04-28-maps-engineer.md`
- **Build state:** ios-engineer reports green (`** BUILD SUCCEEDED **`, 98/98 tests).
- **Files reviewed:**
  - `marti/Marti/Views/ListingDetail/ListingDetailView.swift`
  - `marti/Marti/Views/ListingDetail/Components/ListingPhotoGalleryView.swift`
  - `marti/Marti/Views/ListingDetail/Components/ListingHostCardView.swift`
  - `marti/Marti/Views/ListingDetail/Components/ListingAmenitiesSection.swift`
  - `marti/Marti/Views/ListingDetail/Components/ListingCancellationPolicyView.swift`
  - `marti/Marti/Views/ListingDetail/Components/ListingReviewsAggregateView.swift`
  - `marti/Marti/Views/ListingDetail/Components/ListingDetailStickyFooterView.swift`
  - `marti/Marti/Views/ListingDetail/Components/RequestToBookComingSoonSheet.swift`
  - `marti/Marti/Views/Shared/NeighborhoodMapView.swift`

## Verdict

**Loop back — one blocker, three majors.**

The blocker is a regression of the Discovery floating tab bar overlapping the
sticky CTA. The majors are the missing-listing UX (silent pop), the
non-functional haptic on the primary CTA, and the missing navigation title
that leaves the inline nav bar empty. None are deep — total fix surface is
a handful of lines across three files.

## Findings by severity

### BLOCKER (1) — must fix before ship

#### B1 · Floating tab bar overlays Listing Detail and clips the sticky CTA

- **Files:** `Views/ListingDetail/ListingDetailView.swift` (no `.hideFloatingTabBar`),
  `Views/Discovery/DiscoveryView.swift:78` (only hides in map mode).
- **What:** `FloatingTabView` renders its custom `FloatingTabBar` as a `ZStack` overlay
  at the bottom of the entire tab subtree (`Views/Shared/FloatingTabView.swift:82-104`).
  Visibility is controlled only via the `FloatingTabViewHelper.hideTabBar` flag, which
  any descendant can flip via `.hideFloatingTabBar(true)`.
  - `DiscoveryView.swift:78` toggles it on for map mode.
  - `ListingDetailView.swift` never calls it.
  - Result: when the user pushes Detail from list mode, the tab bar stays
    visible and floats over the bottom of the detail surface, sitting on
    top of `ListingDetailStickyFooterView` (the sticky CTA + price block).
- **Spec impact:** Direct AC1 violation — "the floating tab bar hides for the duration."
- **Fix:** add `.hideFloatingTabBar(true)` to `ListingDetailView.body`. One line.
  Recommend placing it after `.navigationBarTitleDisplayMode(.inline)` so the
  reader sees nav-bar config + tab-bar config together.
- **Severity rationale:** ship-preventing. The CTA is the conversion surface;
  having it visually fight with the tab bar makes both controls feel broken,
  and the price line below the button can be obscured at typical iPhone sizes.

### MAJOR (3) — fix before ship-prep gate

#### M1 · `.notFound` surfaces as a silent dismiss with no message to the user

- **File:** `Views/ListingDetail/ListingDetailView.swift:91-96` —
  `.onChange(of: viewModel.error)` calls `dismiss()` directly when
  `error == .notFound`, no alert shown.
- **What:** When `fetchListing` returns `.notFound` (the listing was deleted
  server-side between push and refresh), the screen pops back to Discovery
  with no explanation. The user sees their tap silently undone — visually
  indistinguishable from a back-button misfire or an aborted gesture.
- **Spec impact:** Edge Case 5 calls for "show alert + pop". ios-engineer
  flagged this trade-off in their park doc and explicitly asked the
  design-reviewer to make the call.
- **Decision (HIG):** **Require the alert.** See "Decision: `.notFound`
  silent-pop vs alert" below for full reasoning. Short version: a deletion
  the user couldn't see coming needs explicit acknowledgement, not a
  ghosted nav transition.
- **Fix:** wrap `dismiss()` in an `.alert("This listing is no longer available", isPresented: $vm.shouldShowNotFoundAlert) { Button("OK") { dismiss() } }`
  binding driven by the existing `error == .notFound` transition. ios-engineer
  estimates 5–10 minutes; their park doc already plans for this swap.
- **Severity rationale:** not ship-blocking — the screen does dismiss and
  no data is lost — but it's a visible UX regression vs. a competent
  alternative on every booking app the user has used. Promote to blocker
  if not addressed before /ship-prep.

#### M2 · "Request to Book" haptic is wired with a constant trigger and never fires

- **File:** `Views/ListingDetail/Components/ListingDetailStickyFooterView.swift:33` —
  `.sensoryFeedback(.impact(weight: .light), trigger: false)`.
- **What:** `.sensoryFeedback(_:trigger:)` only emits when its equatable value
  *changes*. The trigger is hardcoded `false` — it can never change, so the
  haptic is dead. Spec UI/UX section calls for "Request to Book tap —
  `.sensoryFeedback(.impact, …)` light".
- **Fix:** switch the trigger to a state value that flips on tap. Idiomatic
  pattern is to bind the trigger to a counter or a Bool that the action
  toggles. Cheapest: lift `triggerHaptic` `@State Bool` up from the footer
  and flip it inside `onRequestToBook`. ~6 lines.
- **Severity rationale:** silent loss of designed motion. Won't be caught
  by an automated test; will be obvious on first manual pass. Same class
  of bug as B1 (designed-but-not-wired).

#### M3 · Detail screen pushes with an empty inline navigation bar (no title, no chevron-only state)

- **File:** `Views/ListingDetail/ListingDetailView.swift:74` —
  `.navigationBarTitleDisplayMode(.inline)` is set, but no `.navigationTitle(...)`
  call. Combined with `MainTabView.swift:49` hiding the nav bar on the
  Discovery root, the pushed Detail screen renders an empty inline nav
  bar over the photo gallery — back chevron only, no title.
- **What's HIG-wrong:** an inline nav bar without a title reads as broken
  chrome. The user's mental model is "where am I?" — the bar exists to
  answer that. Without a title, it's a band of empty material.
- **Fix options (pick one):**
  1. Add `.navigationTitle(viewModel.listing.title)` so the title appears
     on scroll past the photo gallery (preferred — matches Apple Maps,
     Airbnb, Booking.com pattern).
  2. Hide the bar via `.toolbar(.hidden, for: .navigationBar)` and rely on
     a custom in-canvas back chevron over the photo gallery (matches Airbnb's
     iOS Detail). Requires building the chevron — bigger lift, deferable.
- **Recommendation:** option 1 this ship; option 2 is a nice-to-have once
  there's appetite for hero-photo immersion. Cite this in follow-up.
- **Severity rationale:** every push of this screen renders broken chrome.
  Visible on first launch; reviewers will flag it.

### MINOR (5) — fix when convenient, not gating

#### m1 · `lineSpacing(4)` magic number in description block

- **File:** `Views/ListingDetail/ListingDetailView.swift:150` — raw `4` literal.
- **DESIGN.md violation:** "If a value isn't in the scale, add it to the scale —
  don't reach for raw literals." `4` happens to equal `Spacing.sm` but the
  callsite reads as a magic number.
- **Fix:** use `.lineSpacing(Spacing.sm)`. One line.

#### m2 · Avatar diameter (50pt) not in the spacing scale

- **File:** `Views/ListingDetail/Components/ListingHostCardView.swift:11` —
  `private let avatarDiameter: CGFloat = 50`.
- **DESIGN.md violation:** same "add it to the scale" rule. 50pt isn't in
  `Spacing.*` and isn't called out as a component-local exception. Other
  diameters (heart 28/44, verified disc 24) are inline-but-canonical via
  the component itself; here it's a one-off file-local literal.
- **Fix:** either (a) define a token like `Spacing.avatarMedium = 50` next
  to `Spacing.cardPadding`, or (b) accept this as a private component
  constant and document why. Either is fine; pick a side.

#### m3 · Marker diameter (18pt) magic number in `NeighborhoodMapView`

- **File:** `Views/Shared/NeighborhoodMapView.swift:39` —
  `private let markerDiameter: CGFloat = 18`.
- **Same class of issue as m2.** Comment justifies the choice well; just
  needs a token alias or an explicit `// not a Spacing token: visual-radius
  primitive specific to this map embed`. Lean toward documentation here —
  it's a leaf design primitive, not a recurring measurement.

#### m4 · Star size inconsistent between title row (12pt) and reviews aggregate (14pt)

- **Files:** `ListingDetailView.swift:125` (`size: 12`) vs.
  `ListingReviewsAggregateView.swift:35` (`size: 14`).
- **What:** the same star glyph for the same concept (rating) renders at
  two different sizes within one screen. DESIGN.md "Iconography" §:
  "Same glyph for the same concept across screens." That intent applies
  intra-screen too.
- **Fix:** pick one — recommend 14pt to match the heavier `martiLabel1`
  numeric in the reviews row, and uprate the title-row star to 14pt as well.
  Or pick 12pt for both. Either works; pick once and apply both places.

#### m5 · `Divider().background(Color.dividerLine)` × 7 — repeated recipe

- **File:** `ListingDetailView.swift` — seven `Divider()` callsites all
  apply the same background color.
- **What:** SwiftUI's default `Divider` is a system-mandated 0.5pt at
  ~`UIColor.separator`. Overriding with `.background(Color.dividerLine)`
  works but is verbose and easy to drift on. Three patterns coexist in the
  codebase already.
- **Fix:** add a `MartiDivider` view (or a `.martiDivider()` modifier on
  `Divider`) to `Views/Shared/`. Centralizes the recipe so future surfaces
  don't paint their own dividers.

### NIT (3) — track in follow-up backlog

#### n1 · `aspectRatio(4.0 / 3.0, contentMode: .fit)` in photo gallery — both empty and populated branches

- **File:** `Views/ListingDetail/Components/ListingPhotoGalleryView.swift:35,47` —
  the same aspect ratio is applied twice, once per branch of `@ViewBuilder`.
  Could lift to the parent `content` view and apply once. Pure tidiness.

#### n2 · Page-dot indicator visibility on dark photos is unverified

- **File:** `ListingPhotoGalleryView.swift:46` —
  `indexViewStyle(.page(backgroundDisplayMode: .interactive))`.
- **What:** the `.interactive` background only renders during scroll. On a
  static dark photo, the white page dots may still read fine (system tunes
  contrast), but `.always` on the background guarantees a translucent strip
  always sits behind the dots. Worth a Reduce-Transparency check too.
- **Action:** flag for the next manual pass at AX5 + Reduce Transparency.
  Not changing without empirical evidence.

#### n3 · `RequestToBookComingSoonSheet` and `AuthSheetPlaceholderView` duplicate sheet chrome

- **Files:** `RequestToBookComingSoonSheet.swift`, `Views/Auth/AuthSheetPlaceholderView.swift`.
- **What:** structurally identical — `NavigationStack` with icon + title +
  body + full-width primary + cancel toolbar item, both with
  `.presentationDetents([.medium])` and `.surfaceDefault` background. Two
  copies today; if a third "coming soon" surface lands (Bookings list,
  Messages, Profile) we'll have three.
- **Action:** queue a `ComingSoonSheetView(icon:title:body:cta:)` extraction
  for the next sweep through Shared. Not blocking.

## Accessibility & a11y review

### What's solid

- Every interactive element carries an `.accessibilityLabel`:
  - Heart — `FavoriteHeartButton` already labels (`Save listing` / `Remove from saved`).
  - Photo gallery — each page reads `Photo N of M` (AC9 / spec edge case 9).
  - Verified badge — `VerifiedBadgeView` labels both variants `"Verified host"`.
  - Approximate-location marker — `"Approximate location"` + a hint
    `"Neighborhood-level map. Exact address not shown."`.
  - Sticky CTA price block — `"$NN per night"` (`.accessibilityElement(children: .combine)`).
  - "Request to Book" — `"Request to book this listing"`.
- `accessibilityAddTraits(.isHeader)` on every section title — VoiceOver
  rotor will list them as headings.
- Aggregated rows (`ListingHostCardView`, `ListingReviewsAggregateView`,
  `ListingCancellationPolicyView`) all use `.accessibilityElement(children: .combine)`
  with explicit composed labels — VoiceOver navigation order is logical.

### Gaps

- **No `@Environment(\.accessibilityReduceMotion)` checks anywhere on the
  detail surface.** No screen-level animations exist today (the photo
  TabView swipe is a system gesture, exempt), but the spec UI/UX
  section calls out `.sensoryFeedback(.impact)` which is independent of
  `reduceMotion`. No motion violation today; flag for the next animated
  surface added here. Track as a watch item.
- **No `@Environment(\.dynamicTypeSize)` checks.** Spec edge case 10 says
  "title row and host card stack vertically when text crowds; sticky CTA
  bar grows in height to accommodate". The current `HStack` with
  `Spacer(minLength: 0)` will let the layout grow but won't switch
  axis at AX5. Verify manually before /ship-prep:
  - Title row + neighborhood + rating row at AX5 — does anything truncate?
  - Sticky footer "Request to Book" button at AX5 — does the price column
    crowd under 2 lines? `.lineLimit(1)` is set on the SOS line which
    *will* truncate at AX5 instead of wrapping. Consider switching to
    `.lineLimit(1...2)` or removing the cap.
- **`mappin.and.ellipse` icon at 12pt** has no `.accessibilityHidden(true)`.
  VoiceOver will read "mappin and ellipse" — exactly the case
  `swiftui.md` calls out as decorative. Add `.accessibilityHidden(true)`
  on the symbol. Trivial fix, queueing as part of M3 or m4 cleanup.

## Cross-rule conformance summary

| Rule (DESIGN.md / swiftui.md / gotchas.md) | Status | Notes |
| --- | --- | --- |
| All colors via `DesignTokens` (no hex / `Color(red:…)` / `Color("…")`) | Pass | Every callsite reads a token. |
| All spacing via `Spacing.*` | Mostly pass | Two raw literals: `4` (m1), `50` (m2), `18` (m3). |
| All typography via `marti*` tokens | Pass | The two `.font(.system(size:…))` callsites are SF Symbol icon sizing — permitted. |
| Radii via `Radius.*` | Pass | `Radius.md` used on the map embed; corner radii on the photo gallery come from the `TabView` page style. |
| Tap targets ≥ 44×44 | Pass | Heart hit target 44 (per `FavoriteHeartButton`); primary CTA `minHeight: 48`. |
| `.accessibilityLabel` on every unlabeled interactive control | Mostly pass | One missed `.accessibilityHidden(true)` on the location pin glyph (a11y gaps §). |
| HIG navigation patterns | Fail | Empty inline nav bar (M3); tab bar overlays push (B1). |
| Reduce Motion respected | N/A | No screen-level animations on this surface today. Watch item. |
| Dynamic Type / AX5 layout | Untested | Manual pass required (a11y gaps §). |
| Dark mode parity | N/A | App is dark-only — every token is a dark value. Pass by construction. |
| State coverage (loading / empty / error / success) | Partial | Loading is intentionally skipped (seed always present). Error path is the focus of M1. Empty amenities collapses cleanly. Empty `photoURLs` shows a placeholder pane. |
| SF Symbols only | Pass | No raster icons. |
| Browse-first auth | Pass | Heart-tap-while-unauthed routes to `AuthSheetPlaceholderView` (per AC12). |

## Decision: `.notFound` silent-pop vs alert

**Decision: alert is required. The silent dismiss does not ship.**

Categorized as M1 above; the engineer's own park doc already estimates a
5–10 minute swap.

### Reasoning

ios-engineer's argument:

> An alert that says "this listing is no longer available" then pops to the
> same Discovery screen the user was just on adds a friction click without
> new information.

The argument has a point — *if* the user knows the listing was deleted,
the alert is redundant. But the user *doesn't* know. The `.notFound`
transition fires after a successful card tap that hydrated the seed and
pushed the screen — from the user's perspective, everything was working.
A silent dismiss reads as one of:

1. "Did I just tap back by accident?"
2. "Is the app broken?"
3. "Was that a phantom navigation event?"

None of those are the truth. The truth is "the host or admin removed this
listing in the last 30 seconds." That's important context: it tells the
user the Discovery surface is *currently stale*, that re-saving the listing
will never bring it back, and that retrying the same card is futile.

HIG-wise, Apple's pattern across Mail (deleted message), Photos (shared
album item missing), Maps (saved place removed) is consistent: when a
resource the user explicitly navigated to is gone, *acknowledge the
change* before unwinding. The alert's job isn't to inform; it's to turn
a confusing nav event into a deliberate one.

### What ships

- Title: **"This listing is no longer available"** (matches the spec's
  exact phrasing in Edge Case 5).
- Body: optional. The title carries the message. Apps that add a body line
  ("It may have been removed by the host.") err toward redundant.
  Recommend leaving the body off this ship; revisit if user-feedback says
  the title alone is opaque.
- Single button: **OK**. On dismiss, pop the navigation stack.
- Trigger: state-driven, not a one-shot. Add a `shouldShowNotFoundAlert`
  Bool to the VM that flips `true` when `error == .notFound` and `false`
  on dismiss. Reuse the existing `didHandleNotFound` guard so a
  re-trigger after the user re-pushes the same listing still works
  (relevant if Discovery hasn't refreshed yet).
- The `dismiss()` call moves into the alert's button action; the
  current inline `.onChange { dismiss() }` block is replaced.

### Why this isn't a blocker

The screen is functional today — the user does end up back on Discovery,
they just don't know why. A blocker is "ship will be rejected by App
Review" or "user data is at risk." This is neither; it's a visible
polish issue. Hence Major, not Blocker. If the gap is unresolved at
the next /ship-prep run, promote to blocker.

## Top 3 minors / nits to queue for follow-up (no action this ship)

These do **not** gate ship; they're worth surfacing so the next pass
through this surface (or the Reviews / Bookings ships that touch it) can
clean them up cheaply:

1. **m4 — Rating-star size consistency.** Pick 12pt or 14pt for the star
   glyph and apply both in `ListingDetailView.ratingRow` and
   `ListingReviewsAggregateView.ratingRow`. Five-line change, eliminates
   one inter-component inconsistency. Best caught in the Reviews-feature
   ship since that surface will iterate on the aggregate row anyway.

2. **m5 — `MartiDivider` extraction.** Seven `Divider().background(Color.dividerLine)`
   callsites in one file — add a single shared modifier or wrapper view to
   `Views/Shared/` and migrate. Reduces drift surface for every detail-ish
   screen that follows (Saved, Bookings detail, Profile).

3. **n3 — Coming-soon sheet extraction.** `RequestToBookComingSoonSheet`
   and `AuthSheetPlaceholderView` are structurally identical. With Bookings,
   Messages, and Profile all due to ship a "coming soon" stub, this is
   about to grow to 3-4 copies. Extract a `ComingSoonSheetView(icon:title:body:)`
   in the shipping pass before the next "coming soon" surface lands.

## Required changes summary (for ios-engineer)

These four changes resolve the blocker + majors:

1. **B1 — `.hideFloatingTabBar(true)` on `ListingDetailView.body`.** One line.
2. **M1 — Alert on `.notFound`.** Replace `.onChange { dismiss() }` with
   `.alert(...)`-driven dismiss. ~10 lines.
3. **M2 — Real haptic trigger on Request to Book.** ~5 lines (state Bool +
   tap toggle).
4. **M3 — `.navigationTitle(viewModel.listing.title)` (or `.toolbar(.hidden, for: .navigationBar)`
   if option 2 preferred — flag back to design-reviewer if so).** One line.

Total: ~17 lines. Single file (`ListingDetailView.swift`) for three of the
four; one line in `ListingDetailStickyFooterView.swift` for M2.

## Sign-off

This audit blocks `/ship-feature Listing Detail` close-out at the
design-reviewer gate. Loop back to ios-engineer with the four required
changes above. On re-submission, this audit is updated in place (same
file, dated section appended) — the document tracks the surface, not the
review pass.

---

*Audit dated 2026-04-28. Files reviewed at branch `dev` head. No code
changes made by design-reviewer; this is a review-only output.*

## Re-audit (Loop 2) — 2026-04-28

Second pass after ios-engineer landed the four named fixes (B1, M1, M2, M3)
plus the small a11y fold-in. Scope is narrow on purpose: only the four
findings + the pin glyph a11y note are re-verified. Minors and nits were
**not** re-audited this loop — engineer's `context/current.md` carries them
as deferred follow-ups and nothing visibly regressed in the surrounding
diff.

### Verification by finding

#### B1 · Floating tab bar overlay → ✅ pass

- **Verified at:** `Views/ListingDetail/ListingDetailView.swift:76` —
  `.hideFloatingTabBar(true)` sits in the modifier chain immediately
  after `.navigationBarTitleDisplayMode(.inline)`, exactly where the
  audit recommended for read-order with the nav-bar config.
- **Behavior:** ambient `FloatingTabViewHelper.hideTabBar` flag flips
  on detail push; Discovery toggles it back when the user pops. Sticky
  CTA + price block now sit clean above the home indicator with no
  tab-bar overlay.
- **AC1 violation closed.**

#### M1 · `.notFound` alert before pop → ✅ pass

- **Verified at:**
  - `ViewModels/ListingDetailViewModel.swift:50` — `var shouldShowNotFoundAlert: Bool = false` declared and documented.
  - `ViewModels/ListingDetailViewModel.swift:108–112` — `.notFound` branch in `refresh()` flips the flag alongside `error = .notFound`, with a comment that links the alert path to the View's OK action.
  - `Views/ListingDetail/ListingDetailView.swift:93–102` — `.alert("This listing is no longer available", isPresented: $vm.shouldShowNotFoundAlert)` with a single OK `Button` whose action calls `dismiss()`.
- **Title matches spec phrasing exactly** ("This listing is no longer available"). No body line, single OK button — matches the design call in the original audit's "What ships" section.
- **`didHandleNotFound` guard** preserved inside the OK action so a re-push of the same id after acknowledgement still pops cleanly.
- **Test coverage extended:** `ListingDetailViewModelTests.swift:31` asserts the flag defaults `false` at init; `:81` asserts it flips `true` on `.notFound`. Existing test methods were extended (no new methods, no deletions) — clean diff.

#### M2 · Request-to-Book haptic actually fires → ✅ pass

- **Verified at:** `Views/ListingDetail/Components/ListingDetailStickyFooterView.swift:20`,
  `:37–38`, `:41`.
- **Mechanism:** `@State private var hapticTrigger = false` lives on the
  footer; the button action calls `hapticTrigger.toggle()` *before*
  invoking `onRequestToBook`; `.sensoryFeedback(.impact(weight: .light), trigger: hapticTrigger)`
  binds to the changing `Bool`. The previous `trigger: false` constant
  is gone.
- **Comment at line 17–19** explains the prior bug ("previously the
  trigger was hardcoded `false` and the haptic was dead") — useful
  archaeology for the next reader.
- **Light-impact** weight matches the spec UI/UX note.

#### M3 · Inline navigation title → ✅ pass

- **Verified at:** `Views/ListingDetail/ListingDetailView.swift:74` —
  `.navigationTitle(viewModel.listing.title)` placed immediately above
  `.navigationBarTitleDisplayMode(.inline)`. Option 1 from the audit,
  per recommendation. No custom in-canvas chevron alternative attempted.
- **Behavior:** title appears on scroll past the photo gallery; back
  chevron + title together populate the nav bar so it no longer reads
  as broken chrome on push.
- **Note for future ship:** option 2 (hide nav bar + custom chevron over
  hero photo) remains a deferred polish item if there's appetite for
  hero-photo immersion later. Not a regression — the current pattern
  matches Apple Maps / Airbnb / Booking.com inline-title behavior.

#### a11y fold-in · `mappin.and.ellipse` decorative glyph → ✅ pass

- **Verified at:** `Views/ListingDetail/ListingDetailView.swift:117` —
  `.accessibilityHidden(true)` on the `mappin.and.ellipse` `Image`.
- **VoiceOver behavior:** the glyph no longer announces "mappin and
  ellipse" as a standalone element. The adjacent `"Hodan, Mogadishu"`
  text carries the meaning, which is what a sighted user reads as well.
- **Closes the a11y gap** flagged in §"Accessibility & a11y review" of
  the original audit.

### Build + test verification

Re-run by design-reviewer (not just trusting engineer's report):

- **Build:** `** TEST SUCCEEDED **` end-to-end (build implicitly ran as
  part of `-only-testing:MartiTests`).
- **Tests:** 98 passed, 0 failed in `MartiTests`. Matches the engineer's
  report exactly. No regressions surfaced.
- **Command used:** `xcodebuild -project marti/Marti.xcodeproj -scheme Marti -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:MartiTests test`.

### Final verdict (Loop 2)

✅ **Ship.** All four named findings (B1, M1, M2, M3) and the a11y
fold-in pass re-audit. No new regressions introduced by the fix loop.
Build + test status matches the engineer's report.

The minors (m1–m5) and nits (n1–n3) from Loop 1 are still open by
intent and tracked in `.claude/jobs/ios-engineer/context/current.md`
under "deferred from audit" for a follow-up sweep. They do not gate
ship per the original audit's severity calls. (`m3` /
`markerDiameter` belongs to maps-engineer — flagged in the engineer's
re-submission note so it doesn't fall through.)

The two open policy questions to COO from Loop 1 — project-wide
auto-hide-tab-bar invariant, and project-wide `.notFound` UX policy —
remain open. Neither blocks this ship; both are decision-log
candidates rather than design-reviewer calls.

This audit is now closed at the design-reviewer gate. `/ship-feature
Listing Detail` may proceed once COO is satisfied.

---

*Re-audit dated 2026-04-28 (Loop 2). Verified at branch `dev` head
post-fix. No code changes made by design-reviewer; the re-run of
`MartiTests` is read-only verification.*
