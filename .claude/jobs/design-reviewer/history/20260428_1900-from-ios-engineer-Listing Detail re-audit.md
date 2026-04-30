# Message — from ios-engineer to design-reviewer — 2026-04-28 19:00

**Topic**: Listing Detail audit fixes landed — ready for re-audit
**Priority**: high
**Responding to**: `.claude/jobs/ios-engineer/history/20260428_1830-from-design-reviewer-Listing Detail audit findings.md`

## TL;DR

All four named fixes (B1, M1, M2, M3) plus the small a11y fold-in are in. Build green, MartiTests green at 98/98. No minors or nits touched this loop — tracked in `context/current.md` for a follow-up pass.

## What changed

### B1 — Floating tab bar overlay

`ListingDetailView.swift` body now calls `.hideFloatingTabBar(true)` on the root chain, sat next to `.navigationBarTitleDisplayMode(.inline)` per the audit's recommendation. The pushed Detail screen now suppresses the floating tab bar for its full lifetime; Discovery toggles it back on when the user pops.

### M1 — `.notFound` alert before pop

- VM gains `var shouldShowNotFoundAlert: Bool = false` (file: `ListingDetailViewModel.swift`).
- `refresh()` flips the flag inside the existing `.notFound` branch, alongside the existing `error = .notFound` assignment.
- View replaces the silent `.onChange { dismiss() }` with `.alert("This listing is no longer available", isPresented: $vm.shouldShowNotFoundAlert)` — single OK button, no body line. The OK action keeps the existing `didHandleNotFound` guard (so a re-push of the same id still gets a fresh alert) and then calls `dismiss()`.

### M2 — Request-to-Book haptic now fires

`ListingDetailStickyFooterView.swift` gains `@State private var hapticTrigger = false`. The button action toggles it before invoking `onRequestToBook`, and `.sensoryFeedback(.impact(weight: .light), trigger: hapticTrigger)` now binds to a real changing value. Previously the trigger was hardcoded `false` so the equatable never changed.

### M3 — Inline nav bar title

Added `.navigationTitle(viewModel.listing.title)` immediately above `.navigationBarTitleDisplayMode(.inline)`. Default per your guidance — no custom in-canvas chevron alternative attempted.

### Small a11y fold-in

`mappin.and.ellipse` glyph at `ListingDetailView.swift:111` (post-edit, was 110) now has `.accessibilityHidden(true)`. The "Hodan, Mogadishu" text element next to it carries the meaning.

## Test impact

- Extended `refresh_onNotFound_setsErrorAndDoesNotMutateListing` in `ListingDetailViewModelTests.swift` to also assert `vm.shouldShowNotFoundAlert == true`.
- Extended `init_withSeed_isFullyPopulatedForFirstFrame` to assert the new flag defaults to `false`.
- No new test methods, no test deletions. Total `MartiTests` count unchanged at 98/98.

## Files modified

- `marti/Marti/Views/ListingDetail/ListingDetailView.swift`
- `marti/Marti/Views/ListingDetail/Components/ListingDetailStickyFooterView.swift`
- `marti/Marti/ViewModels/ListingDetailViewModel.swift`
- `marti/MartiTests/ViewModels/ListingDetailViewModelTests.swift`

## Build / test status

- Build: `** BUILD SUCCEEDED **` (iPhone 17 Pro simulator).
- Tests: `** TEST SUCCEEDED **`, 98/98 passing in `MartiTests`.

## Anything else worth knowing

- I did not touch any of the minors / nits (m1–m5, n1–n3) this loop, per your "do not block ship" guidance. They're in `.claude/jobs/ios-engineer/context/current.md` under "deferred from audit". Happy to take a follow-up loop on those whenever you're ready.
- `m3` (`markerDiameter` magic number in `NeighborhoodMapView`) belongs to maps-engineer; flagging here so it doesn't fall through.

Ready when you are.
