# Tasks: Listing Detail

- **Spec:** `docs/specs/Listing Detail.md` (original ship), `docs/specs/Listing Detail v2 visual pass.md` (visual pass on top)
- **Status:** ✅ Completed
- **Started:** 2026-04-28
- **Completed:** 2026-04-28 (original ship); 2026-04-29 (v2 visual + layout pass)

## Progress

- Total steps: 8
- Completed: 8
- Currently working on: —

## Steps

### Step 1: Add `fetchListing(id:)` to ListingService + Supabase impl

- [x] Add `func fetchListing(id: UUID) async throws -> ListingDTO` to `ListingService` protocol in `marti/Marti/Services/ListingService.swift`.
- [x] Implement on `SupabaseListingService.swift` using PostgREST `eq("id", value: ...).single()`.
- [x] Verify `AppError.notFound` exists; add it to `AppError` if absent.
- [x] Map errors via the existing `map(_:)` helper.
- [x] Tests: `fetchListing_returnsSingleRowForExistingID`, `fetchListing_throwsNotFoundForMissingID`, `fetchListing_mapsURLErrorToNetwork`.
- [x] Build passes.

**Notes:** No schema change. Single-row PostgREST request against existing columns. Backend-engineer is not in this pipeline.

### Step 2: Build `NeighborhoodMapView` (maps-engineer)

- [x] Create `marti/Marti/Views/Shared/NeighborhoodMapView.swift`.
- [x] Public surface: `init(coordinate: CLLocationCoordinate2D, height: CGFloat = 200)`.
- [x] Single annotation at `coordinate`. Pan/zoom gestures disabled. Read-only.
- [x] Reuses existing `MapboxConfig.configure()`. No SPM changes.
- [x] Tests: snapshot test only if the design system primitive policy permits — otherwise none (per `testing.md` rule "snapshot tests only for design-system primitives"; treat this as one).
- [x] Build passes.

**Notes:** Owned by maps-engineer. Returns the public component API in their park doc for ios-engineer to wire.

### Step 3: `ListingDetailViewModel`

- [x] Create `marti/Marti/ViewModels/ListingDetailViewModel.swift` (`@Observable @MainActor`).
- [x] State: `listing`, `isLoading`, `error`, `isOffline`, `isSaved`, `isAuthSheetPresented`, `isComingSoonSheetPresented`, `currentPhotoIndex`, plus a private `isSavingInFlight` guard.
- [x] Init: `(listing, listingService, currencyService, authManager, isInitiallySaved, onSavedChanged?)`.
- [x] Methods: `refresh()`, `toggleSave()`, `requestToBook()`.
- [x] Behavior matches spec — seed-first, background refresh, optimistic save with rollback, auth gating, coming-soon sheet trigger.

**Notes:** Save pattern is copied from `ListingDiscoveryViewModel.toggleSave` (lines 285-309). Two callsites is below the abstraction threshold per `CLAUDE.md`. Added `shouldShowNotFoundAlert` to drive the `.notFound` UX policy alert.

### Step 4: `ListingDetailViewModel` tests

- [x] Create `marti/MartiTests/ViewModels/ListingDetailViewModelTests.swift`.
- [x] Tests per spec (10 tests listed in the spec's Testing Plan).
- [x] Use a stub `ListingService` test double (no mocking framework).
- [x] All tests green.

**Notes:** Annotate `@Suite(.serialized)` only if shared static state is touched. Suite did not need it.

### Step 5: `ListingDetailView` + components

- [x] Create `marti/Marti/Views/ListingDetail/ListingDetailView.swift`.
- [x] Subcomponents in `marti/Marti/Views/ListingDetail/Components/`:
  - `ListingPhotoGalleryView.swift` (paged TabView + dots + heart overlay)
  - `ListingHostCardView.swift`
  - `ListingAmenitiesSection.swift` (with SF Symbol mapping table)
  - `ListingCancellationPolicyView.swift`
  - `ListingReviewsAggregateView.swift` (aggregate + placeholder copy)
  - `ListingDetailStickyFooterView.swift` (`.thinMaterial` + `safeAreaInset`)
  - `RequestToBookComingSoonSheet.swift` (mirrors `AuthSheetPlaceholderView`)
- [x] Sections render in the spec's order.
- [x] `.task { await vm.refresh() }`, `.sheet`s for auth + coming-soon, `.navigationBarTitleDisplayMode(.inline)`.
- [x] No `"use client"` analog — keep view body lean; extract anything > ~50 lines.
- [x] Build passes.

**Notes:** `FavoriteHeartButton(.large)` overlay top-trailing on the gallery. `LiveCurrencyService.format(sos:display:)` used in the sticky footer's SOS line — full-form (not abbreviated) per `gotchas.md`. v2 visual pass (2026-04-29) restructured this view: floating-button cluster, rounded-top overlay card, counter pill, restyled amenity rows, red Reserve pill — see `docs/specs/Listing Detail v2 visual pass.md`.

### Step 6: Wire callsites + delete placeholder

- [x] In `marti/Marti/Views/Discovery/DiscoveryView.swift:75-76`, replace `ListingDetailPlaceholderView(listing:)` with `ListingDetailView(viewModel: ListingDetailViewModel(...))` constructed with the listing + injected services + `isInitiallySaved: viewModel.savedListingIDs.contains(listing.id)` + an `onSavedChanged` closure that updates the parent's `savedListingIDs`.
- [x] In `marti/Marti/Views/Discovery/Components/CategoryRailView.swift` around line 79, the same swap.
- [x] Delete `marti/Marti/Views/ListingDetail/ListingDetailPlaceholderView.swift`.
- [x] Build passes.

**Notes:** Wiring is the only DiscoveryView edit needed.

### Step 7: Full test suite green

- [x] `xcodebuild -project marti/Marti.xcodeproj -scheme Marti -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:MartiTests test` — all green.
- [x] Includes existing Discovery regression tests (`freshViewModel_startsInLoadingState_…`).

**Notes:** qa-engineer task. Final test count is **97 passing** (the original park doc's "98/98" figure was off by one; reconciled by ios-engineer during the 2026-04-29 v2 ship). No skips/disables.

### Step 8: HIG audit + manual verification

- [x] design-reviewer audit lands at `docs/audits/2026-04-28-design-audit-Listing Detail.md`.
- [x] No blockers / majors. Minors and nits captured in audit doc.
- [x] Manual: tap card from list + rail; tab bar hides; gallery swipes; heart toggles; map renders; CTA opens coming-soon; offline drop preserves seed.

**Notes:** Loop 1 surfaced 1 blocker (B1: silent dismiss on `.notFound`) + 3 majors (M1–M3). Loop 2 cleared all four. Re-audit verdict: Ship.

## v2 Visual Pass (2026-04-29) — follow-on revision

Visual + layout pass on top of the shipped v1 to mirror an Airbnb reference. Spec at `docs/specs/Listing Detail v2 visual pass.md`. Single-loop ship → audit → 2-line fix → re-audit → Ship verdict. Test count held at 97/97. Files modified: `ListingDetailView.swift`, `ListingPhotoGalleryView.swift`, `ListingAmenitiesSection.swift`, `ListingDetailStickyFooterView.swift`. Audit at `docs/audits/2026-04-29-design-audit-Listing Detail v2.md`.

## Changes Log

| Date       | Step  | What changed                                                                       |
| ---------- | ----- | ---------------------------------------------------------------------------------- |
| 2026-04-28 | 0     | Spec + tasks created.                                                              |
| 2026-04-28 | 1–8   | Listing Detail v1 shipped. Build green, 97/97 tests green, design verdict: Ship.   |
| 2026-04-29 | v2    | Visual + layout pass (Airbnb reference). 4 view files restyled; tests untouched. Build green, 97/97 tests green, design verdict: Ship. |
