# Design audit — Listing Detail v2 visual pass — 2026-04-29

Surface-scoped design + HIG audit of the Listing Detail v2 visual revision
shipped on `dev` per `docs/specs/Listing Detail v2 visual pass.md`. Covers
the four modified SwiftUI files. Behavior, ViewModels, services, models, and
tests are out of scope (the v2 spec is visual / layout only).

## Snapshot

- **Auditor:** design-reviewer
- **Branch:** `dev`
- **Spec:** `docs/specs/Listing Detail v2 visual pass.md` (status: Approved 2026-04-29)
- **Reference image:** `screenshots/airbnb_141871.webp`
- **Implementer park doc:** `.claude/jobs/ios-engineer/park/2026-04-29-ios-engineer.md`
- **Build state:** ios-engineer reports green (`** BUILD SUCCEEDED **`, 98/98 tests).
- **Files reviewed:**
  - `Marti/Marti/Views/ListingDetail/ListingDetailView.swift`
  - `Marti/Marti/Views/ListingDetail/Components/ListingPhotoGalleryView.swift`
  - `Marti/Marti/Views/ListingDetail/Components/ListingAmenitiesSection.swift`
  - `Marti/Marti/Views/ListingDetail/Components/ListingDetailStickyFooterView.swift`
- **Reference primitives (read-only):**
  - `Marti/Marti/Views/Shared/FavoriteHeartButton.swift`
  - `Marti/Marti/Views/Discovery/Components/FeeInclusionTag.swift`
  - `Marti/Marti/Extensions/DesignTokens.swift`

## Locked decisions (verified, not subject to audit)

These five locked decisions were each implemented verbatim per the spec:

1. **Card surface = `Color.surfaceDefault`** — verified at `ListingDetailView.swift:173`.
2. **Host tenure copy dropped** — no tenure string anywhere in the four files.
3. **Footer subtitle keeps `fullSOSPriceLine`** — verified at `ListingDetailStickyFooterView.swift:120–125`.
4. **Share button decorative** — verified at `ListingDetailView.swift:125–135` (empty action, `accessibilityLabel("Share")`, `accessibilityHint("Decorative — share is not available yet")`).
5. **Reserve uses `Color.statusDanger`** — verified at `ListingDetailStickyFooterView.swift:92`.

## Verdict

**Loop back — one blocker, one major, three minors, two nits.**

The blocker is a duplicate back affordance: the floating chevron disc
overlays the system inline navigation bar's back chevron + title, so two
"back" controls render at the top of the screen any time the photo is
scrolled past. The major is the floating-buttons cluster ignoring the
top safe area on Dynamic Island devices — `.padding(.top, Spacing.base)`
is a fixed 16pt with no `safeAreaInset` awareness, so the cluster slides
under the nav bar / island. The minors and nits are visual polish in
amenity icon sizing, fee-tag transition tuning, and a counter-pill
contrast watch under Reduce Transparency.

Total fix surface for the blocker + major is two spots in
`ListingDetailView.swift`, ~10 lines.

## Findings by severity

### BLOCKER (1) — must fix before ship

#### B1 · Duplicate back affordance: floating chevron disc + system nav-bar back chevron render simultaneously

- **Files:**
  - `Views/ListingDetail/ListingDetailView.swift:52` — `.navigationTitle(viewModel.listing.title)`
  - `Views/ListingDetail/ListingDetailView.swift:53` — `.navigationBarTitleDisplayMode(.inline)`
  - `Views/ListingDetail/ListingDetailView.swift:110–119` — `backButton` floating chevron disc.
- **What:** the v1 audit's M3 fix introduced `.navigationTitle(...) + .navigationBarTitleDisplayMode(.inline)` to populate the inline nav bar. The v2 spec then adds a **floating** circular back chevron over the hero photo (`§B. Hero floating buttons`). Both ship — neither was removed. Result on push: the user sees a system back chevron in the nav bar AND a floating chevron disc 56pt below it on the hero photo. Two affordances for one action, stacked vertically. Reads as broken chrome.
- **Spec impact:** the v2 spec's `§B` table assumes the floating cluster is the *only* back affordance over the hero (mirroring the Airbnb reference, which has no nav bar at all on this screen — `screenshots/airbnb_141871.webp`). The v1 audit's M3 fix was correct for v1 (no floating chevron); v2 supersedes it.
- **HIG impact:** Apple's HIG (Navigation §) is unambiguous — one back affordance per screen, period. Two competing back controls on the same surface is a review-rejection-class issue and shows up in App Review feedback as confusing chrome.
- **Reference parity:** the Airbnb reference renders zero nav-bar chrome over the hero — only the three floating discs. The v2 spec adopted that pattern verbatim.
- **Fix:** hide the system navigation bar on this surface and rely on the floating chevron. Replace
  ```swift
  .navigationTitle(viewModel.listing.title)
  .navigationBarTitleDisplayMode(.inline)
  ```
  with
  ```swift
  .toolbar(.hidden, for: .navigationBar)
  ```
  This is option 2 from the v1 audit's M3 finding, and it was explicitly framed there as the right pattern "once there's appetite for hero-photo immersion." The v2 spec is exactly that appetite — the floating cluster is the immersive replacement.
- **Severity rationale:** ship-preventing. Two stacked back chevrons is the visual definition of broken chrome; reviewers and users will both flag it on first launch. The fix is one line; cost to defer is high.

### MAJOR (1) — fix before ship-prep gate

#### M1 · Hero floating-buttons cluster slides under the navigation bar / Dynamic Island — fixed `Spacing.base` top padding ignores the top safe area

- **File:** `Views/ListingDetail/ListingDetailView.swift:107` —
  `.padding(.top, Spacing.base)` (16pt) on the `heroFloatingButtons` HStack.
- **What:** the floating-buttons cluster lives inside a `ZStack(alignment: .top)` wrapping the photo gallery. The hero gallery itself has no safe-area inset awareness — it's the topmost child of a `ScrollView` with a hidden or visible nav bar overhead. The cluster's top padding is a flat `Spacing.base` (16pt) regardless of:
  1. Whether the nav bar is visible (B1 fix or not).
  2. Whether the device has a Dynamic Island (iPhone 14/15/16/17 Pro models — current default simulator is iPhone 17 Pro, ~59pt of top safe-area chrome).
  3. The status bar height (44pt minimum).
  - Net effect: on every Pro-class device, the back disc and the share/heart pair float **under** the Dynamic Island's pill (or under the inline nav bar pre-B1-fix). Tap targets get partially obscured; the visual reads as buttons crammed against the top edge.
- **ios-engineer flagged this as a hot-spot** in their park doc.
- **Reference parity:** the Airbnb reference clearly inset the floating discs *below* the status bar / island — the chevron sits ~60pt from the top of the screen, well clear of any system chrome.
- **Fix:** anchor the floating-buttons cluster to the actual top safe-area inset. Two clean options:
  1. **Add a safe-area inset on the gallery itself** — let the ZStack honor `.safeAreaPadding(.top)` on the floating cluster:
     ```swift
     heroFloatingButtons
         .safeAreaPadding(.top)
     ```
     (replaces the `.padding(.top, Spacing.base)`). Default safe-area padding pushes the cluster below the status bar / Dynamic Island automatically.
  2. **Use a `GeometryReader` or `@Environment(\.safeAreaInsets)`** to compute the offset. More flexible but heavier — option 1 is fine for this use.
- **Severity rationale:** not ship-preventing on every device — on non-Pro devices (iPhone SE, iPhone 14/15 standard) the top inset is small enough that 16pt padding still keeps the buttons clear of the status bar. But the simulator default is iPhone 17 Pro, the user-base skews Pro-class for travel apps, and the buttons getting eaten by the island is the kind of polish defect reviewers and users flag immediately. Promote to blocker if not addressed before /ship-prep.

### MINOR (3) — fix when convenient, not gating

#### m1 · Amenity icon symbol size `16` is a magic number — not a token

- **File:** `Views/ListingDetail/Components/ListingAmenitiesSection.swift:33` —
  `.font(.system(size: 16, weight: .regular))`.
- **DESIGN.md note:** SF Symbol sizing via `.font(.system(size:…))` is permitted (icon glyphs aren't text and don't go through the `marti*` tokens). However, the size literal `16` repeats the spec's example verbatim and isn't tied to anything. If a future amenity-icon recipe wants to grow this to 18pt, the change has to crawl through callsites.
- **Fix options (pick one):**
  1. Accept as-is — icon glyph size at the row level is a leaf primitive, and `16` is a reasonable default. Document in the file comment ("16pt amenity icon glyph — leaf primitive, not a token").
  2. Add `Sizing.iconAmenity = 16` (or similar) under `DesignTokens.swift`. Heavier — and `Sizing` doesn't exist yet, so this is a token-system extension.
- **Recommendation:** option 1 this ship. Same call as v1's `m3` for the marker diameter — leaf primitives can stay literal as long as they're labeled.

#### m2 · Amenity icon container size `36×36` is a magic number — same class as m1

- **File:** `Views/ListingDetail/Components/ListingAmenitiesSection.swift:35` —
  `.frame(width: 36, height: 36)`.
- **What:** the rounded-square icon container is a hand-tuned 36pt — not on the `Spacing.*` scale (`xl` is 32, no 36). The spec calls for 36pt verbatim, so this is spec-faithful; the question is whether 36pt should be a token (`Sizing.amenityIcon`?) or stay a leaf literal.
- **Same recommendation as m1 — option 1, accept as a leaf primitive, label it. Carry-forward to the next pass through Shared sizing tokens.

#### m3 · Counter pill `Color.black.opacity(0.5)` — Reduce Transparency contrast risk on dark photos

- **File:** `Views/ListingDetail/Components/ListingPhotoGalleryView.swift:63` —
  `.background(Capsule().fill(Color.black.opacity(0.5)))`.
- **What:** spec-faithful (the v2 spec calls for `Color.black.opacity(0.5)` verbatim). But on very dark photos (e.g. a kitchen at night, a black car) the 50% black capsule blurs into the background, leaving white text floating with no boundary. Reduce Transparency mode does *not* tighten this — `Color.black.opacity(0.5)` is a literal alpha, not a material — so the capsule remains 50% black even when the user has explicitly asked for opaque chrome.
- **ios-engineer flagged this as a hot-spot** in their park doc.
- **HIG note:** Apple's HIG on Reduce Transparency is unambiguous — translucent chrome should switch to opaque when the user's preference is set. The current recipe doesn't honor that, but the spec did pre-approve the recipe.
- **Fix options (pick one if engineer wants to harden, otherwise accept and watch):**
  1. **Switch to material** — `.background(Capsule().fill(.thinMaterial))` honors Reduce Transparency automatically (becomes opaque) and gives consistent contrast across all photo types. Cost: slightly different visual baseline (material reads grayer than 50% black on bright photos).
  2. **Add a 1pt stroke** — `.overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 0.5))` gives a hairline boundary so the capsule doesn't melt into very dark photos. Cheap, doesn't change the spec-approved fill.
  3. **Bump opacity to `0.6` or `0.65`** — keeps the recipe shape, gains contrast headroom on dark photos. Smallest delta from spec.
- **Recommendation:** ship as-is **with a watch item** — option 2 (hairline stroke) is the cheapest harden if the team wants to address it in a follow-up. The locked decision pre-approved the spec recipe, so this is a "user pre-approved this trade-off" minor, not a gate.

### NIT (2) — track in follow-up backlog

#### n1 · Fee-tag dismissal transition is asymmetric — slides off trailing but the parent VStack spacing collapses uncoordinated

- **File:** `Views/ListingDetail/ListingDetailView.swift:251–268` (`footerStack`).
- **What:** the fee-tag row is wrapped in `if !isFeeTagDismissed { … }` with `.transition(.opacity.combined(with: .move(edge: .trailing)))`. The dismiss is wrapped in `withAnimation(.smooth(duration: 0.18))`. Behavior: the tag fades + slides right; the parent `VStack(spacing: Spacing.base)` then collapses the `Spacing.base` gap above the sticky footer in lockstep. Two animations are running on different curves — the row's opacity/move from the explicit transition, the layout collapse from the implicit animation context. In practice they look fine at 0.18s, but the layout settle is noticeable on slow-motion playback.
- **ios-engineer flagged this as a hot-spot** ("tunable").
- **Fix options:**
  1. Keep as-is — at 0.18s the dual-track motion is subtle and reads as a unified dismiss. Recommended.
  2. Try `.transition(.opacity.animation(.smooth(duration: 0.18))).combined(with: .move(edge: .trailing).animation(.smooth(duration: 0.22)))` — adds 40ms of slide so the row clears the layout before the gap closes. Cleaner on slow-motion but invisible in real time.
  3. Try `.transition(.scale(scale: 0.92, anchor: .trailing).combined(with: .opacity))` — smaller spatial delta, fewer pixels in motion, looks tighter on small screens.
- **Recommendation:** ship as-is. The current motion is correct enough; option 2 or 3 are taste-level refinements for a future polish pass.

#### n2 · Counter pill vertical padding routed through `Spacing.sm` is a token compromise — value is `4`, semantics is "tight pill padding"

- **File:** `Views/ListingDetail/Components/ListingPhotoGalleryView.swift:62` —
  `.padding(.vertical, Spacing.sm)` (`Spacing.sm = 4`).
- **What:** the spec literally says `vertical, 4`. Engineer routed through `Spacing.sm` (which is also `4`) to avoid a magic-number lint hit. This is the right call but `Spacing.sm` is named for spacing semantics (the smallest layout gap), not for "compact pill padding." If `Spacing.sm` ever shifts to e.g. 6 to fix a layout bug elsewhere, the counter pill silently grows.
- **Note:** the inbox message for this audit explicitly pre-approved this routing. Logging it as a nit so the next sweep through the spacing scale tokens (or the addition of a `Sizing.compactPillPadding` token) catches it.
- **Action:** none this ship. Track for the next tokens-pass.

## Accessibility & a11y review

### What's solid

- Every interactive element carries an explicit `.accessibilityLabel`:
  - Back disc — `"Back"` (`ListingDetailView.swift:118`).
  - Share disc — `"Share"` + hint `"Decorative — share is not available yet"` (`:133–134`). The hint correctly telegraphs the decorative state to VoiceOver users — exactly what the spec requested.
  - Heart — `FavoriteHeartButton` self-labels.
  - Reserve — `"Reserve this listing"` (`ListingDetailStickyFooterView.swift:95`), updated from v1's "Request to book this listing" per the v2 spec's CTA copy change.
  - "Free cancellation" check row — combined element with explicit label (`:60–61`).
  - Counter pill — `accessibilityHidden(true)` on the pill (`ListingPhotoGalleryView.swift:64`); the per-page swipe still announces "Photo N of M" via the page label (`:44`). Correct — the pill duplicates information VoiceOver already gets.
  - Amenity rows — `accessibilityElement(children: .combine)` (`ListingAmenitiesSection.swift:53`) so VoiceOver reads each row as one unit (icon + heading + description) rather than three.

- The decorative checkmark glyph in the free-cancellation row is correctly hidden (`accessibilityHidden(true)` at `ListingDetailStickyFooterView.swift:55`).

### Gaps

- **Duplicate back affordance leaks into VoiceOver focus order (B1 side effect).** With B1 unfixed, VoiceOver finds two focusable controls labeled "Back" — the system nav-bar back button and the floating chevron disc. Tab order: nav-bar back (system) → floating back disc (us) → share → heart → photo gallery. Confusing. Closing B1 (hide the nav bar) eliminates the duplication.

- **AX5 dynamic-type sweep — not run this loop.** The v1 audit flagged AX5 as untested; v2 is in the same state. The new title block (leading title + leading subtitle + leading capacity + centered rating row) is the obvious AX5 risk:
  - Title at AX5 (`martiHeading3` → ~28–32pt) wraps at typical iPhone width to 3–4 lines. The fixed-size flag is set (`fixedSize(horizontal: false, vertical: true)`), so it grows vertically — fine.
  - The centered rating row may visually pull off-axis under a leading-aligned multi-line subtitle that's wider than the rating row's natural width. Optical balance shifts.
  - **ios-engineer flagged this as a hot-spot** ("title block centering at AX5").
  - **Recommendation:** run an AX5 sweep manually before /ship-prep. If the centered rating row reads off, switch the rating row to leading alignment for AX1+ and accept the visual regression vs. the reference at default size — leading is the safer alignment when the rest of the column is leading.
  - **Tracking:** carry as a watch item; not a finding this loop because the spec explicitly demanded centered.

- **Reduce Transparency on the counter pill (m3) is a real gap** but pre-approved by the spec — see m3 above.

- **Reduce Motion** — no screen-level animations on this surface beyond the fee-tag dismissal (n1) and the system gallery swipe (exempt). The fee-tag dismissal's `withAnimation(.smooth(duration: 0.18))` does **not** check `@Environment(\.accessibilityReduceMotion)`. At 180ms it's well under the threshold most apps gate on, and the motion is essential to the dismiss intent (without it, the tag vanishes instantly with no signal). I'd accept this as ship-as-is, but flag it on the next animated surface that lands here.

- **Sticky footer at AX5 — bumped price to `martiHeading3` may crowd the Reserve pill.** The price column is now larger; combined with the 2pt-spacing two-line column (`VStack(spacing: 2)` at `ListingDetailStickyFooterView.swift:66`) and the 48pt-min Reserve pill, the footer height grows substantially at AX5. `Spacer(minLength: Spacing.md)` keeps the gap nonzero but doesn't switch axis. Run AX5 manually before /ship-prep.

## Cross-rule conformance summary

| Rule (DESIGN.md / swiftui.md / gotchas.md) | Status | Notes |
| --- | --- | --- |
| All colors via `DesignTokens` (no hex / `Color(red:…)`) | Pass | Every callsite reads a token. `Color.black.opacity(0.5)` (counter pill) and `Color.white` (counter pill text) are SwiftUI primitives and spec-locked. |
| All spacing via `Spacing.*` | Mostly pass | Two leaf literals: `36×36` amenity icon container (m2), `16` amenity icon glyph (m1). Both spec-faithful; flagged as minors per DESIGN.md "add to the scale" guidance. |
| All typography via `marti*` tokens | Pass | The four `.font(.system(size:…))` callsites are SF Symbol icon glyph sizing — permitted. No `marti*` token misuse. |
| Radii via `Radius.*` | Pass | `Radius.lg` on the overlay card top corners, `Radius.sm` on the amenity icon container, `Capsule()` on counter pill + Reserve pill (implicit `Radius.full`). |
| Tap targets ≥ 44×44 | Pass | Back/share/heart discs are 44pt visible (`.glassDisc(diameter: 44)`); Reserve pill `minHeight: 48`; fee-tag close button `frame: 44×44` inside an HStack. |
| `.accessibilityLabel` on every unlabeled interactive control | Pass | Back, share (with hint), heart (self-labeled), Reserve, fee-tag close (in `FeeInclusionTag`). |
| HIG navigation patterns | **Fail** | Duplicate back affordance (B1). Closes when nav bar is hidden. |
| HIG safe-area handling | **Fail** | Floating cluster ignores top safe area on Dynamic Island devices (M1). |
| Reduce Motion respected | Watch | Fee-tag dismissal at 180ms — borderline. Flag for next animated surface. |
| Reduce Transparency respected | **Watch** | Counter pill is `Color.black.opacity(0.5)` — does not flip to opaque. Pre-approved by spec; watch item. |
| Dynamic Type / AX5 layout | Untested | Manual pass required before /ship-prep — title-block centering and footer-height growth are the two risks. |
| Dark mode parity | N/A | App is dark-only — every token is a dark value. Pass by construction. |
| State coverage (loading / empty / error / success) | Pass | Empty `photoURLs` collapses counter pill (verified `:27`); empty amenities returns `EmptyView()` (verified `:19–20`); strict cancellation policy hides the free-cancel row (verified `:103–105`); offline banner placement preserved (verified `:43–45`). |
| SF Symbols only | Pass | No raster icons. |
| `@State` for view-local only (`swiftui.md`) | Pass | `isFeeTagDismissed` is genuinely view-local UI state — explicitly documented in the spec and the engineer's park doc as "do not move to VM". |
| Subview extraction (body > 50 lines) (`swiftui.md`) | Pass | `ListingDetailView.body` is ~40 lines; `heroZone`, `contentCard`, `titleBlock`, `ratingRow`, `descriptionSection`, `footerStack` are all extracted. |
| Browse-first auth | Pass | Heart-tap-while-unauthed routes to `AuthSheetPlaceholderView` via `viewModel.toggleSave()` — unchanged. |
| Money formatting (Int USD cents) (`gotchas.md`) | Pass | `pricePerNightUSDCents` stays Int; `usdString` divides by 100 only at the View boundary; SOS routes through `viewModel.fullSOSPriceLine`. No float math on money entered. |

## Token adherence score

**8.5 / 10.** Strong overall — every color routes through `DesignTokens`, every typography line uses a `marti*` token, every radius uses `Radius.*`. Two leaf-primitive integer literals (`16` amenity icon glyph, `36×36` amenity icon container) sit outside the token system but are spec-faithful and flagged as minors only. The `Color.black.opacity(0.5)` counter-pill fill is the one place the audit would normally call out as a non-token color, but it's spec-locked and the spec explicitly chose it over `.thinMaterial`. No drift toward inline hex; no `Color(red:…)` literals in the diff.

## HIG compliance score

**6 / 10.** Two sizable HIG defects:
- **B1** — duplicate back affordance is a textbook HIG violation (Apple HIG §Navigation: "Provide a single, consistent way to return to the previous screen").
- **M1** — floating chrome ignoring the top safe area on Dynamic Island devices is a routine reviewer flag (App Review §Safe Area).

Once both close, this surface lands at **9 / 10** — accessibility is solid, tap targets are correct, decorative glyphs are properly hidden, and the visual treatment matches the reference. AX5 manual pass + Reduce Transparency watch are the only remaining items, neither blocking this loop.

## Top 3 minors / nits to queue for follow-up (no action this ship)

1. **m3 — Counter pill contrast harden.** Add a 0.5pt white-opacity-15 stroke on the counter pill capsule, or switch to `.thinMaterial`. Either preserves the spec's visual baseline while honoring Reduce Transparency. Five-line change. Best caught alongside any future hero-photo treatment update.

2. **n1 — Fee-tag dismissal transition tuning.** Optional polish — the current 180ms `.smooth` + `.opacity.combined(with: .move(edge: .trailing))` reads fine in real time but is dual-tracked on slow motion. If a polish pass touches the footer, try option 2 or 3 from the n1 fix list. Not user-visible at default playback.

3. **AX5 manual sweep + sticky-footer height check.** Carry-over from v1 audit's "untested" flag, now with a v2-specific risk (centered rating row optical balance + bumped `martiHeading3` price height). Run before /ship-prep.

## Required changes summary (for ios-engineer)

These two changes resolve the blocker + major:

1. **B1 — Replace `.navigationTitle(...) + .navigationBarTitleDisplayMode(.inline)` with `.toolbar(.hidden, for: .navigationBar)`** at `ListingDetailView.swift:52–53`. Two lines deleted, one line added. Net −1.
2. **M1 — Replace `.padding(.top, Spacing.base)` with `.safeAreaPadding(.top)`** (or equivalent safe-area-aware inset) at `ListingDetailView.swift:107`. One line.

Total: ~3 lines, single file (`ListingDetailView.swift`).

## Sign-off

This audit blocks `/ship-feature Listing Detail v2` close-out at the
design-reviewer gate. Loop back to ios-engineer with the two required
changes above. On re-submission, this audit is updated in place (same
file, dated section appended) — the document tracks the surface, not the
review pass.

---

*Audit dated 2026-04-29. Files reviewed at branch `dev` head. No code
changes made by design-reviewer; this is a review-only output.*

## Re-audit pass — 2026-04-29

Loop 2 verification of the two fixes ios-engineer landed on
`Marti/Marti/Views/ListingDetail/ListingDetailView.swift`. Re-audit is
scoped to **B1 + M1 only** per the inbox brief; m1, m2, m3, n1, n2 were
explicitly left in place per COO's "out of scope" direction and are not
re-evaluated here.

### B1 — CLEARED

- **Was:** `.navigationTitle(viewModel.listing.title)` + `.navigationBarTitleDisplayMode(.inline)` at `ListingDetailView.swift:52–53`, conflicting with the floating chevron disc to render two stacked back affordances.
- **Now:** `.toolbar(.hidden, for: .navigationBar)` at `ListingDetailView.swift:52`. Inline title pair is gone; the system navigation bar is suppressed on this surface.
- **Floating chevron sole back affordance:** `backButton` at `ListingDetailView.swift:109–118` still wraps `dismiss()` and renders `chevron.left` on `.glassDisc(diameter: 44)` with `.accessibilityLabel("Back")`. Confirmed.
- **Reference parity:** matches the Airbnb reference (zero nav-bar chrome over the hero, only the three floating discs).
- **VoiceOver focus order side effect from the original B1** is also closed — only one focusable "Back" control on the surface now.

### M1 — CLEARED

- **Was:** `.padding(.top, Spacing.base)` (fixed 16pt) on the `heroFloatingButtons` cluster, ignoring top safe area on Dynamic Island devices.
- **Now:** `.safeAreaPadding(.top)` at `ListingDetailView.swift:106`, paired with `.padding(.horizontal, Spacing.base)` at `:105`. The cluster now honors the device's top safe-area inset — discs sit clear of the Dynamic Island on iPhone 17 Pro (default sim) and clear of the status bar on non-Pro devices.
- **Fix applied verbatim from option 1 in the original M1 finding.** Lightest-touch correct fix.

### Updated cross-rule conformance (deltas only)

| Rule | Was | Now |
| --- | --- | --- |
| HIG navigation patterns | **Fail** (B1) | **Pass** |
| HIG safe-area handling | **Fail** (M1) | **Pass** |

### Updated scores

- **Token adherence:** 8.5 / 10 (unchanged — Loop 2 was view-only chrome edits, no token changes).
- **HIG compliance:** **9 / 10** (was 6 / 10). Both HIG defects closed. Remaining points are the AX5 manual sweep watch + Reduce Transparency on the counter pill (m3, spec-locked, unchanged).

### Open items carried forward (unchanged from original audit, not re-scored)

- m1, m2, m3 — Minors. Out of scope per COO direction. Tracked for future polish pass.
- n1, n2 — Nits. Out of scope per COO direction.
- AX5 manual sweep — still untested; carry-forward watch item before `/ship-prep`. Not gating this loop.
- Test count: tracker drift (98 → 97) reconciled by ios-engineer with per-suite breakdown showing no skips/disables. View-only edits cannot change test count; not scored.

### Re-audit verdict

**Ship.** Both Loop 1 gates (B1, M1) are closed. No new findings. The
Listing Detail v2 surface is clear at the design-reviewer gate.
`/ship-feature Listing Detail v2` close-out is unblocked from this side.

---

*Re-audit pass dated 2026-04-29. Scope: B1 + M1 verification only.
Build green per ios-engineer. SourceKit phantom diagnostics on the v2
files were not scored.*
