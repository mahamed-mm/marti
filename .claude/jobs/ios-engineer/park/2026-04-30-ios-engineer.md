# Park Document — ios-engineer — 2026-04-30

> This is the end-of-session handoff. The next session of this role reads it first.

## Session summary

TDD bug fix in `ListingDetailViewModel.refresh()`. The bug: when the
ViewModel's `refresh()` reassigns `listing = Listing(dto: dto)` with a server
snapshot that has fewer photos than the SwiftData seed, `currentPhotoIndex`
could be left out of bounds. The downstream `ListingPhotoGalleryView`'s
`TabView(selection:)` would then point at an orphaned tag and the bottom
counter pill would render nonsense like `"6 / 3"`. No crash — visual drift
only, but a real user-visible defect.

Goal in: verify the report against current code, then if real, fix it via
TDD inside the ViewModel layer (not the View layer, per `architecture.md`'s
"Views are dumb"). Goal out: red→green→full-suite-green→build-green, with
state-file paperwork updated.

Pipeline: did the read-only investigation in the parent COO session
(diagnosis already complete), so this session was pure execution. TDD order
held: failing test landed first, then the clamp, then green confirmation,
then full suite, then build.

Note on test-count drift: the prior session's "97/97" baseline (logged in
the previous park doc as a "Loop 2 off-by-one correction") was itself wrong.
Actual pre-add count was 98, my +1 test makes it **99 unique test cases**,
0 failures. Updated `current.md` to reflect 99/99.

## Files touched

| File                                                                                            | Change   | Why                                                                                          |
| ----------------------------------------------------------------------------------------------- | -------- | -------------------------------------------------------------------------------------------- |
| `marti/Marti/ViewModels/ListingDetailViewModel.swift`                                           | Modified | Added one-line clamp on `currentPhotoIndex` immediately after the listing reassignment.      |
| `marti/MartiTests/ViewModels/ListingDetailViewModelTests.swift`                                 | Modified | Extended `makeListing` and `makeListingDTO` with a defaulted `photoURLs:` parameter; added `refresh_whenServerSnapshotHasFewerPhotos_clampsCurrentPhotoIndex`. |
| `.claude/jobs/ios-engineer/context/current.md`                                                  | Modified | Refreshed timestamp + flight summary; reset baseline to 99/99; reconciled the prior off-by-one drift. |
| `.claude/jobs/ios-engineer/park/2026-04-30-ios-engineer.md`                                     | Created  | This park doc.                                                                                |

### Production diff

In `ListingDetailViewModel.refresh()`, immediately after `listing = Listing(dto: dto)`:

```swift
// Clamp the gallery's selection to the new photo count so a
// shrunk server snapshot doesn't leave the TabView pointing at
// an orphaned tag (counter would render "6 / 3").
currentPhotoIndex = min(currentPhotoIndex, max(0, listing.photoURLs.count - 1))
```

The `max(0, …)` term guards the empty-photos edge case — if the new array
is empty, `currentPhotoIndex` collapses to 0 (which is fine because the
View body branches on `photoURLs.isEmpty` and skips the TabView entirely).

The whole `refresh()` method is already on `@MainActor`, so no extra
isolation annotation is needed.

### Test diff

Added one `@Test` under `// MARK: - Refresh`:

```swift
@Test func refresh_whenServerSnapshotHasFewerPhotos_clampsCurrentPhotoIndex() async {
    let seed = Self.makeListing(
        photoURLs: (0..<6).map { "https://test.invalid/\($0).jpg" }
    )
    let shrunkDTO = Self.makeListingDTO(
        id: seed.id,
        photoURLs: (0..<3).map { "https://test.invalid/\($0).jpg" }
    )
    let service = MockListingService()
    service.fetchListingHandler = { _ in shrunkDTO }

    let vm = Self.makeVM(seed: seed, service: service)
    vm.currentPhotoIndex = 5

    await vm.refresh()

    #expect(vm.listing.photoURLs.count == 3)
    #expect(vm.currentPhotoIndex == 2)
}
```

Helper extension was additive: existing call-sites use the default values
unchanged.

## Decisions made

- **What**: clamp `currentPhotoIndex` in the ViewModel, not via a SwiftUI
  `.onChange` modifier on the View.
- **Why**: per `.claude/rules/architecture.md` ("Views are dumb. No business
  logic in View bodies."), the state owner enforces the invariant. Side
  benefit: a real unit test against `ListingDetailViewModelTests`, instead
  of an untestable view-body modifier (per `.claude/rules/testing.md`).
- **Alternatives considered**: the bug report explicitly suggested a
  `.onChange(of: photoURLs.count)` on `ListingPhotoGalleryView`. Rejected:
  pushes ownership of the invariant outside the state owner; can't be unit
  tested; spreads the data-flow concern across two files.
- **Reversibility**: cheap. One line in one file. If we ever need a different
  clamp policy (e.g. snap to 0 instead of last index), trivially editable.

This is local invariant maintenance, not architecture. Not pushing to
`decisions.md`.

## Open questions / blockers

- None.

## Inbox state at session end

- No inbox messages received this session.
- No outbox traffic.

## What the next session should do first

1. Read `docs/STATUS.md` and `.claude/jobs/coo/context/current.md`.
2. If COO routes a new feature: start there. The next P0 per STATUS.md is
   Request to Book — wire-through from `ListingDetailStickyFooterView` to
   the host-view sheet.
3. If COO instead asks for a sweep: pick up the deferred carry-overs
   listed in this file's predecessor (still valid):
   - m1 `lineSpacing(4)` → `Spacing.sm`
   - m2 `avatarDiameter: 50` token vs document
   - m4 rating-star size unification (12pt vs 14pt)
   - m5 `MartiDivider` extraction in Shared
   - n1 lift `aspectRatio(4.0 / 3.0)` to parent
   - n3 `ComingSoonSheet` extraction

## Gotchas for next session

- **SourceKit phantom diagnostics struck again** as expected. Editing
  `ListingDetailViewModel.swift` produced ~10 spurious "Cannot find type"
  errors against types that were always in scope (`Listing`, `AppError`,
  `ListingService`, `CurrencyService`, `AuthManager`). `xcodebuild build`
  passed clean. Trust the build, not the editor diagnostics.
- **Test-count history is messy.** As of 2026-04-30 the actual count is 99
  unique test cases. Prior baselines of "98/98" (2026-04-28) were correct;
  prior baseline of "97/97" (2026-04-29 Loop 2) was the actual off-by-one.
  Anchor to the run output, not the docs, when verifying.
- **Swift Testing per-test `-only-testing:` filter format** doesn't accept
  bare method names the way XCTest does. Filtering down to one test inside
  a Swift Testing suite via `-only-testing:Bundle/Suite/method` returns
  `result: "unknown"` with empty results — the test simply doesn't run, but
  xcodebuild reports `** TEST SUCCEEDED **` because nothing failed. To
  actually run a single Swift Testing case, drop to suite-level
  (`-only-testing:Bundle/Suite`) and read the per-`Test case` lines, or use
  `xcrun xcresulttool get test-results tests --path <bundle>` for structured
  output. Cost me ~3 minutes today; avoid the trap.
- **The Listing seed→server-refresh data-flow pattern** is reused everywhere
  in this app (Discovery → Detail). When you add a new piece of state to a
  detail ViewModel that depends on `listing`'s shape (size of an array, ID
  presence, etc.), audit `refresh()` for "is this state still valid after
  the new listing landed?" — same class of bug as today.

## Session metadata

- **Duration**: approx. 25 minutes (incl. failed subagent-delegation rounds
  before COO took it directly)
- **Build state at end**: `** BUILD SUCCEEDED **` on iPhone 17 Pro
- **Test state at end**: 99 unique test cases, 0 failures, `** TEST SUCCEEDED **`
