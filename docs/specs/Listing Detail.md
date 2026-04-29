# Feature Spec: Listing Detail

- **Status:** Approved
- **Priority:** P0
- **PRD reference:** Feature 2 — Listing Detail
- **Last updated:** 2026-04-28

## Overview

Listing Detail is the screen a traveler reaches after tapping a listing card in Discovery. Today that tap lands on `ListingDetailPlaceholderView` (title + neighborhood + "coming soon"). This spec promotes that surface to the full PRD-described screen: photo gallery, title row, host card, amenities, description, neighborhood map, cancellation policy, reviews aggregate, and a sticky "Request to Book" CTA. It's the conversion screen — once Bookings ships, the CTA wires through; once Reviews ships, the aggregate row expands to text reviews. This ship deliberately scopes both extensions out so the surface ships now and unblocks subsequent features.

## User Stories

1. As a traveler, I want to see a photo carousel and detailed description so I know what to expect.
2. As a traveler, I want to see who the host is and whether they're verified so I trust the listing.
3. As a traveler, I want to see what amenities are included so I can compare to other listings.
4. As a traveler, I want a neighborhood-level map so I can judge proximity to family or landmarks without exposing the host's exact address.
5. As a traveler, I want the average rating and review count so I can gauge quality before committing.
6. As a traveler, I want to save the listing from this screen so I can compare it against others later.
7. As a traveler, I want to start a booking request from this screen so the path to commit is one tap (lands when Bookings ships; this spec stubs the CTA).

## Acceptance Criteria

- [ ] AC1: Tapping a Discovery card (list mode or category rail) pushes `ListingDetailView` via `NavigationStack`; the floating tab bar hides for the duration.
- [ ] AC2: Photo gallery is a paged horizontal swipe with a page-dot indicator. Renders all `photoURLs`. AsyncImage placeholder is the same `surfaceHighlight` panel as elsewhere; never shows a broken-image glyph.
- [ ] AC3: Title row shows title, "Neighborhood, City", and a rating row with star + `averageRating` (1 decimal) + `(reviewCount)` count. If `averageRating == nil`, render "New" instead of a numeric rating.
- [ ] AC4: Host card shows `hostName`, host avatar (`hostPhotoURL` or initial-circle fallback), and `VerifiedBadgeView(.label)` if `isVerified`. **Host response rate is intentionally not rendered this ship.**
- [ ] AC5: Amenities section renders `amenities: [String]` as a vertical list with SF Symbols (mapped per amenity name) and the amenity label.
- [ ] AC6: Description renders `listingDescription` with line spacing matched to `martiBody`.
- [ ] AC7: Neighborhood map embed (`NeighborhoodMapView`) renders a fixed-height (~200pt) read-only Mapbox map centered on `(latitude, longitude)` with a single annotation. Pan/zoom gestures are disabled.
- [ ] AC8: Cancellation policy section renders the `cancellationPolicy` string with a one-line explanatory subtitle (Flexible / Moderate / Strict per the PRD table).
- [ ] AC9: Reviews aggregate row shows star + `averageRating` + `(reviewCount) reviews` plus the placeholder copy "Individual reviews ship with the Reviews feature." **Text reviews are intentionally out of scope this ship.**
- [ ] AC10: Sticky bottom bar shows `pricePerNight` (USD primary, full-form SOS secondary via `LiveCurrencyService.format(sos:display:)`) and a `PrimaryButtonStyle` "Request to Book" button.
- [ ] AC11: Tapping "Request to Book" presents `RequestToBookComingSoonSheet` (lightweight `.sheet` mirroring `AuthSheetPlaceholderView`'s shape). **Bookings infra is out of scope.**
- [ ] AC12: Save heart (`FavoriteHeartButton(.large)`) overlays the photo gallery top-trailing. Tap when authenticated → optimistic toggle + service call, rolling back on error. Tap when **un**authenticated → presents `AuthSheetPlaceholderView`.
- [ ] AC13: On push, ViewModel hydrates synchronously from the `Listing` already in hand (no spinner-flash for the seeded data) and refreshes via `fetchListing(id:)` in the background. On network error with seeded data present, render the seeded snapshot + offline banner pattern (mirrors Discovery).
- [ ] AC14: VoiceOver labels exist on every interactive element. Detail screen is usable at AX5.

## Technical Design

### Models

No new models. `Listing` + `ListingDTO` (`marti/Marti/Models/Listing.swift`) already carry every field this screen renders.

### Services

Add **one** method to the existing `ListingService` protocol:

```swift
protocol ListingService: Sendable {
    // ...existing methods...

    /// Fetches a single listing by ID. Used by Listing Detail to refresh
    /// the seeded `Listing` against the source of truth.
    /// Throws `AppError.notFound` if the row is gone, `.network` on transport
    /// failure, otherwise `.unknown`.
    func fetchListing(id: UUID) async throws -> ListingDTO
}
```

`SupabaseListingService` implementation: PostgREST `from("listings").select().eq("id", value: id.uuidString).single().execute()`. Re-uses the existing `map(_:)` error mapping. No migration, no new RPC, no schema change — `listings` already exposes every column we need.

`AppError.notFound` may need to be added if it doesn't already exist; ios-engineer to verify.

### ViewModel responsibilities

**`ListingDetailViewModel`** — `@Observable @MainActor final class`, owned as `@State` on `ListingDetailView`.

State:
```
listing: Listing                       // seeded at init from the navigation hand-off
isLoading: Bool                        // true on background refresh; false initially since we have a seed
error: AppError?                       // surfaced via offline banner if cache present
isOffline: Bool                        // mirrors Discovery pattern
isSaved: Bool                          // optimistic; seeded from a savedListingIDs set passed in
isAuthSheetPresented: Bool             // gates AuthSheetPlaceholderView
isComingSoonSheetPresented: Bool       // gates RequestToBookComingSoonSheet
currentPhotoIndex: Int                 // bound to TabView selection for the page-dot indicator
```

Dependencies (init):
```
listing: Listing                       // seed
listingService: ListingService
currencyService: CurrencyService
authManager: AuthManager
isInitiallySaved: Bool                 // from caller's savedListingIDs set
onSavedChanged: ((Bool) -> Void)?      // pushes the toggle back to the parent so Discovery's heart stays in sync
```

Actions:
```
refresh() async                        // fires fetchListing(id:); replace listing on success
toggleSave() async                     // gated on authManager.isAuthenticated; if false, sets isAuthSheetPresented = true.
                                       // optimistic toggle, rollback on error, callback to parent on commit.
requestToBook()                        // sets isComingSoonSheetPresented = true (no service call)
```

Behavior notes:
- Initial render is fully populated from the seeded `Listing`. `refresh()` runs once via `.task`.
- Errors during `refresh()` follow the Discovery pattern: with seeded data → `isOffline = true` only; with no seed (impossible today, since seed is required) → `error` set.
- `toggleSave` is the same pattern as `ListingDiscoveryViewModel.toggleSave` (lines 285-309) — copy, do not extract a shared helper. Two callsites is below the abstraction threshold per `CLAUDE.md`.

### Views

**`ListingDetailView`** (`Views/ListingDetail/ListingDetailView.swift`) — replaces `ListingDetailPlaceholderView`.
- Root: `ScrollView` with sections in order: photo gallery → title row → host card → amenities → description → neighborhood map → cancellation policy → reviews aggregate.
- Bottom: `safeAreaInset(edge: .bottom)` with the sticky CTA bar.
- Top-trailing of the photo gallery: `FavoriteHeartButton(.large)` overlay.
- `.sheet(isPresented: $vm.isAuthSheetPresented) { AuthSheetPlaceholderView() }`
- `.sheet(isPresented: $vm.isComingSoonSheetPresented) { RequestToBookComingSoonSheet() }`
- `.task { await vm.refresh() }`
- `.navigationBarTitleDisplayMode(.inline)`

**Subcomponents** (`Views/ListingDetail/Components/`):
- `ListingPhotoGalleryView.swift` — `TabView(selection:)` with `.page(indexDisplayMode: .always)` style. Each page is an `AsyncImage` filling `4:3` aspect. Page dots are the native indicator.
- `ListingHostCardView.swift` — host avatar (50pt), name, verified badge label.
- `ListingAmenitiesSection.swift` — header + vertical list of `(symbol, label)` rows. Symbol mapping table is local to the file: WiFi → "wifi", AC → "snowflake", Parking → "parkingsign.circle", Airport pickup → "airplane.arrival", etc. Anything unmapped falls back to "checkmark.circle".
- `ListingCancellationPolicyView.swift` — header + policy name + one-line subtitle.
- `ListingReviewsAggregateView.swift` — header + star + numeric + count + "Individual reviews ship with the Reviews feature." footnote.
- `ListingDetailStickyFooterView.swift` — HStack: USD primary + SOS secondary on the leading side, `PrimaryButtonStyle` "Request to Book" trailing. Uses `.background(.thinMaterial)` and `.safeAreaInset` to anchor above home indicator.
- `RequestToBookComingSoonSheet.swift` — same construction style as `AuthSheetPlaceholderView`. Title, body line, dismiss button.

**`NeighborhoodMapView`** (`Views/Shared/NeighborhoodMapView.swift`) — owned by maps-engineer. Public surface:
```swift
struct NeighborhoodMapView: View {
    let coordinate: CLLocationCoordinate2D
    var height: CGFloat = 200
    // body: fixed-height Mapbox map, single annotation at coordinate, gestures disabled.
}
```

### Navigation

```
DiscoveryView (list or rail)
└── tap card → push ListingDetailView via .navigationDestination(item:)
    ├── floating tab bar auto-hides via .hideFloatingTabBar (already wired)
    ├── tap heart unauthed → .sheet AuthSheetPlaceholderView
    ├── tap heart authed → optimistic toggle → SupabaseListingService.toggleSaved
    └── tap "Request to Book" → .sheet RequestToBookComingSoonSheet
```

The two callsites that currently push `ListingDetailPlaceholderView` (`DiscoveryView.swift:75-76`, `CategoryRailView.swift:79`) swap to push `ListingDetailView`. After the swap, delete `ListingDetailPlaceholderView.swift`.

### Dependencies

- No new SPM packages. Mapbox and Supabase already approved in `decisions.md`.
- `AuthManager` (env), `LiveCurrencyService`, `ListingService`, `FloatingTabViewHelper` — all existing.

## UI/UX

### Section order

1. Photo gallery (paged, 4:3 aspect, with page dots and floating heart top-trailing)
2. Title + neighborhood + rating row
3. Host card
4. Amenities list
5. Description
6. Neighborhood map embed (~200pt)
7. Cancellation policy
8. Reviews aggregate row (no individual reviews)
9. Sticky CTA bar (`safeAreaInset`)

### Key interactions

- **Photo swipe** — native paged TabView; haptic on page change is the system default.
- **Heart tap** — `.sensoryFeedback(.impact, …)` on `isSaved`; optimistic UI; auth sheet on unauthed tap.
- **Request to Book tap** — `.sensoryFeedback(.impact, …)` light; presents coming-soon sheet.
- **Map tap** — no-op this ship. Annotation is purely informational.

## Edge Cases

1. **`photoURLs` empty** — render a single-page `surfaceHighlight` placeholder pane; page dots hidden.
2. **`averageRating == nil` and `reviewCount == 0`** — show "New" badge in the title row's rating slot.
3. **`hostPhotoURL == nil`** — render initial-circle fallback (first letter of `hostName` on `surfaceElevated` disc).
4. **Network failure on `refresh()`** — keep seeded `Listing` on screen, set `isOffline = true`, render existing offline-banner pattern.
5. **`fetchListing(id:)` returns `notFound`** — show alert "This listing is no longer available", pop the navigation stack.
6. **Listing has 0 amenities** — collapse the amenities section header (don't render an empty list).
7. **`cancellationPolicy` is an unrecognized string** — render the raw string and skip the friendly subtitle.
8. **Heart tap fires while a save is in flight** — no-op the second tap until the first completes (guard via local `isSaving` flag inside the VM).
9. **VoiceOver swipe through photo gallery** — each page reads "Photo N of M" via `.accessibilityValue`. Heart reads "Save listing" / "Remove from saved" per `FavoriteHeartButton`.
10. **AX5 Dynamic Type** — title row and host card stack vertically when text crowds; sticky CTA bar grows in height to accommodate the larger button label without the price column truncating below 2 lines.
11. **Listing pushed twice rapidly** — `ListingDetailViewModel` is `@State`-owned per push, so two pushes get two VMs; no shared state to corrupt.
12. **iOS 26 ScrollView/safeAreaInset gotcha** — N/A here; this screen is pushed inside a NavigationStack, not nested in a Tab with `.toolbarVisibility(.hidden, for: .tabBar)`.

## Testing Plan

### ViewModel unit tests (`MartiTests/ViewModels/ListingDetailViewModelTests.swift`)

- `init_withSeed_isFullyPopulatedForFirstFrame`
- `refresh_onSuccess_replacesListingWithFreshDTO`
- `refresh_onNetworkFailure_keepsSeedAndFlipsIsOffline`
- `refresh_onNotFound_setsErrorAndDoesNotMutateListing`
- `toggleSave_whenUnauthenticated_presentsAuthSheetAndDoesNotCallService`
- `toggleSave_whenAuthenticated_optimisticallyTogglesAndCallsService`
- `toggleSave_onServiceFailure_rollsBackOptimisticState`
- `toggleSave_concurrentTaps_areGuarded`
- `requestToBook_setsComingSoonSheetPresented`
- `currentPhotoIndex_isObservableForPageDotIndicator`

### Service tests (extend `MartiTests/Services/SupabaseListingServiceTests.swift`)

- `fetchListing_returnsSingleRowForExistingID`
- `fetchListing_throwsNotFoundForMissingID`
- `fetchListing_mapsURLErrorToNetwork`

### Manual test scenarios

- [ ] Tap a card from the list view → detail pushes, tab bar hides, photos swipe, page dots advance.
- [ ] Tap a card from a category rail → same as above.
- [ ] Tap heart while unauthenticated → auth sheet appears; dismiss → heart stays unfilled.
- [ ] Toggle `AuthManager.isAuthenticated = true` (via debug menu, eventually) → tap heart → fills + persists across re-push.
- [ ] Tap "Request to Book" → coming-soon sheet appears.
- [ ] Drop network mid-screen → offline banner appears, content remains.
- [ ] AX5 Dynamic Type layout doesn't truncate the title or CTA.
- [ ] VoiceOver pass: photo gallery reads "Photo N of M", heart reads correctly, all sections have headers.

## Open Questions

None. All scope choices were locked at CHECKPOINT 1:

1. Reviews — aggregate only this ship. Text reviews ship with Feature 5.
2. Host response rate — deferred. Not rendered.
3. Request-to-Book CTA — sticky bar + coming-soon sheet stub.
4. Photo gallery — paged horizontal swipe with page dots; full-screen viewer deferred.
5. Save + auth — heart tap when unauthed presents `AuthSheetPlaceholderView`.

---

*Generated 2026-04-28 from PRD Feature 2, Architecture rules, and CHECKPOINT 1 decisions.*
