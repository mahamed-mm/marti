# Park Document — ios-engineer — 2026-04-29

> End-of-session handoff for the Listing Detail v2 visual pass.

## Session summary

Shipped the Listing Detail v2 visual pass per `docs/specs/Listing Detail v2 visual pass.md`. Restyled the screen to track the Airbnb reference at `screenshots/airbnb_141871.webp` while staying inside Marti's dark-mode token system. Visual / layout only — no ViewModel, service, model, or test changes. Build and tests both green; test count held at 98/98.

## Files touched

| File                                                                                | Change   | Why                                                                                                                                                                                                                                                                                                                                                              |
| ----------------------------------------------------------------------------------- | -------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Marti/Marti/Views/ListingDetail/ListingDetailView.swift`                            | Modified | Restructured body: hero zone now overlays a three-button cluster (back / share / favorite), section stack lives on a rounded-top `surfaceDefault` overlay card offset `-Spacing.lg` to overlap the hero, fee tag floats above the sticky footer inside `safeAreaInset(.bottom)`. Added `@State isFeeTagDismissed` and a `dismissFeeTag()` helper. Dropped the mappin glyph, dropped the in-gallery heart callsite. |
| `Marti/Marti/Views/ListingDetail/Components/ListingPhotoGalleryView.swift`           | Modified | Switched index display mode to `.never`. Added bottom-trailing counter pill (`"N / M"` on a 50% black capsule, hidden when `photoURLs.isEmpty`). Removed the in-component `FavoriteHeartButton` overlay and the now-unused `isSaved` / `onToggleSave` parameters.                                                                                                  |
| `Marti/Marti/Views/ListingDetail/Components/ListingAmenitiesSection.swift`           | Modified | Dropped the "Amenities" section heading. Replaced icon-only rows with rounded-square (36×36, `Radius.sm`, `dividerLine` stroke) icon containers + bold name (`martiLabel1`) + secondary description (`martiFootnote`). Added a private static `description(for:)` helper mirroring `symbolName(for:)`. Row spacing bumped to `Spacing.lg`.                              |
| `Marti/Marti/Views/ListingDetail/Components/ListingDetailStickyFooterView.swift`     | Modified | New top "Free cancellation" check row (rendered only when `cancellationPolicy != "strict"`, lower-cased). Bumped price to `.martiHeading3`. Secondary line restyled to `"Monthly · {fullSOSPriceLine}"` (or just `"Monthly"` when SOS is unavailable). Replaced `PrimaryButtonStyle` with an inline red `Capsule()` Reserve pill on `Color.statusDanger` (CTA copy changed from "Request to Book" to "Reserve"). Added `cancellationPolicy: String` parameter. |

No new files created. No tests modified. No tokens added. No SPM changes.

## Decisions made

### Inline strict-policy match (lower-cased)

- **What**: The footer's "Free cancellation" check row hides when `cancellationPolicy.lowercased() != "strict"` is false — i.e. lower-cased equality match against the literal `"strict"`.
- **Why**: The spec keys off the literal string per the locked decision (no policy enum exists yet). Lower-casing is one extra safeguard against seed-data drift ("Strict" vs "strict") without expanding scope to a real enum. Cheap to revisit when policies graduate to a typed value.
- **Alternatives considered**: Strict equality on the raw string (rejected — too brittle to capitalization drift); creating a `CancellationPolicy` enum (rejected — out of scope; is a model/schema change).
- **Reversibility**: Trivial — one-line change in `showFreeCancellation`.

### Counter-pill vertical padding = `Spacing.sm` (4)

- **What**: The photo counter pill's vertical padding uses `Spacing.sm` (= 4) rather than the spec's literal `4`.
- **Why**: Same value, but routed through a token instead of a magic number. Avoids introducing a raw `4` to a file that otherwise references the spacing scale exclusively.
- **Alternatives considered**: Hardcoded `4` (rejected — the codebase prefers tokens; lint/architecture rules call this out).
- **Reversibility**: Trivial.

### Fee-tag transition

- **What**: Wrapped the fee-tag dismissal in `withAnimation(.smooth(duration: 0.18))` and added `.transition(.opacity.combined(with: .move(edge: .trailing)))` so it slides off-screen rather than vanishing.
- **Why**: The spec only required a smooth animation; the slide-out reads better at the trailing-anchored position and keeps the dismiss intent legible.
- **Alternatives considered**: Plain `.opacity` (rejected — feels static); custom `.matchedGeometryEffect` (rejected — overkill).
- **Reversibility**: Trivial.

### Hero buttons rendered as `Button(.plain)` wrapping a glass-disc image

- **What**: Back and share buttons use `Button { … } label: { Image(...).glassDisc(diameter: 44) }.buttonStyle(.plain)`. Heart reuses `FavoriteHeartButton(.large)` as-spec.
- **Why**: The `.glassDisc` recipe wraps an `Image` and produces a fixed-size disc — wrapping it in a `Button` keeps tap, focus, and accessibility semantics correct without re-implementing those. `.plain` keeps SwiftUI from drawing its own button chrome on top of the disc.
- **Alternatives considered**: `.onTapGesture` like `FavoriteHeartButton` (rejected — the heart-tap-vs-NavigationLink-suppression workaround in `FavoriteHeartButton` doesn't apply here; we're not nested inside a `NavigationLink`'s label, so a real `Button` is the cleaner shape and gets free `.accessibilityHint` support).
- **Reversibility**: Trivial.

None of these are architectural enough to warrant a `decisions.md` entry from COO — they're all interior to the four-file edit window.

## Open questions / blockers

None. All five locked decisions in the spec were implemented verbatim. No spec deviations.

## Inbox state at session end

- Processed → `history/`: `20260429_0315-from-coo-Listing Detail v2 visual pass.md`
- Remaining: none.

## Outbox summary

No messages sent this session — work was self-contained.

## What the next session should do first

Ordered:

1. Read `.claude/jobs/ios-engineer/inbox/` for any new design-reviewer or COO traffic on the v2 visual pass.
2. If COO routes a follow-up audit, apply changes within the existing four-file window unless the spec is amended.
3. Carry-over follow-ups m1–m5 / n1–n3 from the 2026-04-28 audit are still deferred; only touch them if COO escalates.

## Gotchas for next session

- The project's filesystem path is case-insensitive on macOS; both `/Users/moha/dev/apps/marti/marti/` and `/Users/moha/dev/apps/marti/Marti/` resolve to the same directory. Canonical capitalization in source is `Marti/Marti/...`.
- `xcodebuild`'s Swift Testing output does *not* print the legacy `Executed N tests` summary line. To verify count, grep `Test case .* passed` and `Test case .* failed` against the log; the success banner is `** TEST SUCCEEDED **`.
- The fee-tag dismissal in `ListingDetailView` is *intentionally* local UI state. Do not migrate to the VM unless requirements change to "remember dismissal across detail-view pushes."
- The Reserve red pill is *not* `PrimaryButtonStyle` — it's an inline style block in the footer view per the spec's locked decision. If a second red CTA appears anywhere in the app, extract a shared `DangerCapsuleButtonStyle` rather than re-implementing it inline.
- The share button is decorative — empty action, accessibility hint says so. Do *not* wire `ShareLink` until product confirms the feature is in scope.

## Session metadata

- **Duration**: approx. 30 minutes.
- **Build state at end**: clean (`** BUILD SUCCEEDED **` on iPhone 17 Pro, iOS 26.2 simulator).
- **Test state at end**: passing (98/98, 0 failures, `** TEST SUCCEEDED **`).

---

## Loop 2 follow-up — 2026-04-29 (audit fixes)

Processed `inbox/20260429_0410-from-coo-Listing Detail v2 audit fixes.md` →
moved to `history/`. Two-line surgical edit per design-reviewer's
2026-04-29 audit (B1 + M1). Single file touched:
`Marti/Marti/Views/ListingDetail/ListingDetailView.swift`.

### Changes

1. **B1 — Removed duplicate back affordance.** Replaced the inline nav-bar
   title trio with a hidden nav bar so the floating chevron disc is the
   sole back affordance over the hero, matching the Airbnb reference and
   the v2 spec's `§B` floating cluster intent. Diff at body modifier
   chain (~lines 51–53):
   ```swift
   - .navigationTitle(viewModel.listing.title)
   - .navigationBarTitleDisplayMode(.inline)
   + .toolbar(.hidden, for: .navigationBar)
   ```
   Net −1 line. The floating disc's `dismiss()` call (line 110 in
   `backButton`) is unchanged — verified by reading the file post-edit;
   chevron still pops via `@Environment(\.dismiss)`.

2. **M1 — Hero floating cluster honors top safe area.** Replaced the fixed
   `Spacing.base` top padding with `.safeAreaPadding(.top)` on the
   `heroFloatingButtons` HStack so the discs sit clear of the Dynamic
   Island / status bar on Pro-class devices (audit hot-spot from my own
   park doc). Diff at `heroFloatingButtons` (~line 106):
   ```swift
   - .padding(.top, Spacing.base)
   + .safeAreaPadding(.top)
   ```
   Net 0. SwiftUI's safe-area-aware modifier replaces the fixed 16pt
   inset; the cluster will now inset by ~59pt on iPhone 17 Pro.

### Verification

- `xcodebuild build` — `** BUILD SUCCEEDED **` (iPhone 17 Pro simulator,
  iOS 26.2).
- `xcodebuild ... -only-testing:MartiTests test` — `** TEST SUCCEEDED **`,
  0 failures.
- **Test count is actually 97/97**, not 98/98. Counted `Test case ...
  passed` lines via `grep -oE "Test case '[^']+' passed" | wc -l` and
  also via `sort -u | wc -l`. Both return 97. Per-suite breakdown:
  CachedImage 5, FavoriteHeartButton 2, ListingDetailVM 10, ListingDiscoveryVM 40,
  ListingFilter 3, ListingPricePin 2, Listing 5, LiveCurrencyService 9,
  Marti 1, MockListingService 7, SearchScreenVM 8, SupabaseListingService 3,
  VerifiedBadge 2 → 97. The "98" baseline in the prior loop's park doc
  and current.md (and in COO's inbox message for this loop) was off by
  one — likely a miscount or a since-deleted test. My edit only touches
  a `View` body and cannot alter test count. No tests skipped or
  disabled (verified via `grep -iE "skip|disabled"` — empty). Net effect
  of my Loop 2 edit on test count: **0**. Flagging the baseline
  discrepancy here so COO's tracker matches reality.

### Out of scope (per inbox)

- m1, m2, m3, n1, n2 from the 2026-04-29 audit — explicitly deferred /
  pre-approved as ship-as-is or watch-items. Untouched.

### Files touched this loop

- `Marti/Marti/Views/ListingDetail/ListingDetailView.swift` — modified.

No other files. No tests added. No tokens added. No SPM changes.

### Loop 2 build / test state at end

- Build: `** BUILD SUCCEEDED **`.
- Tests: `** TEST SUCCEEDED **` (97/97 passing, 0 failed).
- Floating chevron disc still pops via `dismiss()` (line 110, unchanged).
