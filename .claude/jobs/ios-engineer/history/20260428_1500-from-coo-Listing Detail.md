# Message — from coo to ios-engineer — 2026-04-28 15:00

**Topic**: Implement Listing Detail end-to-end
**Priority**: high
**Responding to**: (initial)

## Objective

Implement Listing Detail per the spec at `docs/specs/Listing Detail.md`. Replace `ListingDetailPlaceholderView` with a real `ListingDetailView` plus a `ListingDetailViewModel`, add `fetchListing(id:)` to the service, wire the two callsites in Discovery, and write Swift Testing unit tests for the new ViewModel.

## Acceptance criteria

Track these against `docs/tasks/Listing Detail.md` (Steps 1, 3, 4, 5, 6 are yours — Step 2 / NeighborhoodMapView is already done; see below). Done = all items below true:

- `ListingService` protocol gains `func fetchListing(id: UUID) async throws -> ListingDTO`.
- `SupabaseListingService` implements it via PostgREST `from("listings").select().eq("id", value: id.uuidString).single().execute()`. Errors mapped through the existing `map(_:)` helper.
- If `AppError.notFound` doesn't already exist, add it; map Supabase "no rows" → `.notFound`.
- `marti/Marti/ViewModels/ListingDetailViewModel.swift` exists and matches the responsibilities + state list in the spec's "ViewModel responsibilities" section. Save pattern is **copied** from `ListingDiscoveryViewModel.toggleSave` (lines 285-309), not extracted to a shared helper.
- `marti/Marti/Views/ListingDetail/ListingDetailView.swift` exists and renders, in order: photo gallery → title row → host card → amenities → description → neighborhood map → cancellation policy → reviews aggregate. Sticky bottom CTA bar via `safeAreaInset(edge: .bottom)`.
- Subcomponents in `marti/Marti/Views/ListingDetail/Components/`: `ListingPhotoGalleryView.swift`, `ListingHostCardView.swift`, `ListingAmenitiesSection.swift`, `ListingCancellationPolicyView.swift`, `ListingReviewsAggregateView.swift`, `ListingDetailStickyFooterView.swift`, `RequestToBookComingSoonSheet.swift`. All ≤ ~50 lines per `swiftui.md`; extract further if anything grows.
- Photo gallery is paged horizontal swipe with the native page-dot indicator (`TabView` + `.tabViewStyle(.page)`). `FavoriteHeartButton(.large)` overlays top-trailing.
- Sticky footer renders price/night USD as primary, full-form SOS via `LiveCurrencyService.format(sos:display:)` as secondary, plus `PrimaryButtonStyle` "Request to Book". Tap opens `RequestToBookComingSoonSheet` (mirrors `AuthSheetPlaceholderView`'s shape).
- Heart tap when `authManager.isAuthenticated == false` → `isAuthSheetPresented = true` (presents `AuthSheetPlaceholderView`). Heart tap when authed → optimistic toggle + `listingService.toggleSaved(...)` + rollback on error. The view exposes an `onSavedChanged: ((Bool) -> Void)?` callback fired on commit so Discovery's `savedListingIDs` can mirror.
- Both callsites swap to `ListingDetailView`:
  - `marti/Marti/Views/Discovery/DiscoveryView.swift:75-76`
  - `marti/Marti/Views/Discovery/Components/CategoryRailView.swift` (the line currently pushing `ListingDetailPlaceholderView`)
  Wire `isInitiallySaved: viewModel.savedListingIDs.contains(listing.id)` and an `onSavedChanged` closure that updates the parent.
- Delete `marti/Marti/Views/ListingDetail/ListingDetailPlaceholderView.swift` after the swap. Verify nothing else references it (`grep -r ListingDetailPlaceholderView marti/`).
- Tests: `marti/MartiTests/ViewModels/ListingDetailViewModelTests.swift` with the 10 tests listed in the spec's Testing Plan, plus the 3 new service tests in `SupabaseListingServiceTests.swift` (or wherever existing service tests live; add the file if needed).
- Build green:
  ```
  xcodebuild -project marti/Marti.xcodeproj -scheme Marti -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
  ```
- Tests green:
  ```
  xcodebuild -project marti/Marti.xcodeproj -scheme Marti -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:MartiTests test
  ```
- Park doc written at `.claude/jobs/ios-engineer/park/2026-04-28-ios-engineer.md`.

## Context

`/ship-feature Listing Detail` is in flight. Backend-engineer was skipped — no migration. Maps-engineer already shipped `NeighborhoodMapView` (see "Map interface contract" below). PRD says Feature 2 needs scrollable photo gallery, host profile (with verification — no response rate this ship), amenities, reviews with text (deferred to Feature 5 — aggregate-only this ship), neighborhood-level map, and a Request-to-Book CTA (Bookings deferred — coming-soon sheet this ship). All five scope decisions were locked at CHECKPOINT 1; see the "Open Questions" section of the spec for the resolutions.

## Locked decisions (from CHECKPOINT 1)

1. **Reviews** — aggregate only. No `reviews` table. `ListingReviewsAggregateView` shows star + average + "(N reviews)" + "Individual reviews ship with the Reviews feature." footnote.
2. **Host response rate** — deferred. Don't render it. Don't add the column.
3. **Request-to-Book CTA** — sticky bar; tap opens `RequestToBookComingSoonSheet`.
4. **Photo gallery** — paged horizontal swipe + page dots. No full-screen viewer.
5. **Save + auth** — heart tap when unauthed presents `AuthSheetPlaceholderView`.

## Map interface contract (from maps-engineer, 2026-04-28)

```swift
// marti/Marti/Views/Shared/NeighborhoodMapView.swift
struct NeighborhoodMapView: View {
    let coordinate: CLLocationCoordinate2D
    var height: CGFloat = 200

    init(coordinate: CLLocationCoordinate2D, height: CGFloat = 200)
}
```

- Self-contained leaf primitive. No env deps, no VM.
- Drop into the ScrollView directly. Component fixes its own height; spans full row width.
- Self-clips to `Radius.md` (12pt). If the spec wants a different radius, wrap with your own `.clipShape`.
- Annotation tap is a no-op; won't bubble.
- Accessibility: the embed exposes itself as one combined element with label "Approximate location" and hint "Neighborhood-level map. Exact address not shown."
- `coordinate` is captured at init — re-create the view to change it.
- No Mapbox config or SPM changes needed.

## Relevant files / specs

- Spec: `docs/specs/Listing Detail.md`
- Tasks: `docs/tasks/Listing Detail.md` (your steps: 1, 3, 4, 5, 6)
- Listing model: `marti/Marti/Models/Listing.swift`
- Service: `marti/Marti/Services/ListingService.swift`, `marti/Marti/Services/SupabaseListingService.swift`
- Existing VM patterns (esp. `toggleSave`, error mapping, offline pattern): `marti/Marti/ViewModels/ListingDiscoveryViewModel.swift` (lines 285-309 specifically for save)
- Discovery callsites: `marti/Marti/Views/Discovery/DiscoveryView.swift:75-76`, `marti/Marti/Views/Discovery/Components/CategoryRailView.swift`
- Patterns to reuse: `FavoriteHeartButton`, `VerifiedBadgeView`, `PrimaryButtonStyle`, `LiveCurrencyService`, `AuthSheetPlaceholderView`
- Architecture: `docs/ARCHITECTURE.md`, `.claude/rules/architecture.md`, `.claude/rules/swiftui.md`, `.claude/rules/style.md`, `.claude/rules/testing.md`, `.claude/rules/gotchas.md`, `.claude/rules/build.md`
- Maps-engineer park doc: `.claude/jobs/maps-engineer/park/2026-04-28-maps-engineer.md`

## Constraints

- No new SPM packages.
- No singletons (Apple-provided only).
- Swift 6 strict concurrency, default `MainActor` isolation.
- Listings cache write path: this screen does NOT need to write the cache — Discovery owns that. Just consume in-memory `Listing` and refresh the snapshot in your VM's local state. The DTO returned by `fetchListing(id:)` rebuilds a fresh `Listing` for VM-local state only. (If you want to opportunistically upsert the cache row, that's fine but optional.)
- Don't touch `ListingDiscoveryViewModel`'s save logic — copy the pattern, don't extract.
- Don't refactor any Discovery code beyond the two callsite swaps.
- Don't add a debug toggle for `AuthManager.isAuthenticated`. The placeholder behavior is enough for this ship.
- Don't touch Mapbox or `MapboxConfig` — maps-engineer's component is final.
- Don't pin Mapbox to a v11 release tag — separate ship-prep blocker.
- Tests: Swift Testing only (`@Test`, `#expect`, `#require`). No XCTest. Use a stub `ListingService` test double — no mocking framework. If the tests share `StubURLProtocol`-style mutable static state, annotate the suite `@Suite(.serialized)`.

## Expected response

Process this inbox item, implement the work, verify the build + tests are green, write your park doc, then move this message to `.claude/jobs/ios-engineer/history/`. Return a structured summary in your final message including:

1. **Files created / modified** (grouped: services / models / view models / views / tests / wiring; one bullet per file with the relative path).
2. **Test coverage summary**: how many new tests, where they live, and which behaviors they pin (matches the spec's Testing Plan).
3. **Build status**: ✅ passed / ❌ failed (with cause). Paste the last ~5 lines of xcodebuild output.
4. **Test status**: ✅ passed / ❌ failed (with cause). For green, paste the test count line.
5. **Any deviation from the spec** with rationale (e.g., "renamed `currentPhotoIndex` to `selectedPhotoIndex` because…"). If the spec was wrong, flag it and reply — don't silently re-scope.
6. **Any blockers or follow-ups** for qa-engineer or design-reviewer to know about.
