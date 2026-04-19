# Feature Spec: Listing Discovery

- **Status:** Draft
- **Priority:** P0
- **PRD reference:** Feature 1 — Listing Discovery
- **Last updated:** 2026-04-18

## Overview

Listing Discovery is the first screen travelers see after onboarding (or immediately, since the app is browse-first with no auth wall). It lets users browse verified short-term rentals in Mogadishu and Hargeisa through two modes: a scrollable list view and an interactive map view (Mapbox). Users can filter by city, dates, guest count, and price range. Each listing card shows a photo, price (USD + SOS), rating, location, and verification badge with a save/heart toggle. This is the app's front door — it must load fast, look polished, and convert browsers into bookers.

## User Stories

1. As a traveler, I want to browse listings in Mogadishu so that I can find a place to stay for my trip.
2. As a traveler, I want to filter by dates and number of guests so that I only see available places.
3. As a traveler, I want to see listings on a map so that I can pick a location near family or landmarks.
4. As a traveler, I want to save listings I like so that I can compare them later (triggers auth if unauthenticated).
5. As a traveler, I want to switch between list and map views without losing my filter state.

## Acceptance Criteria

- [ ] AC1: List view shows listing cards with photo, title, location, rating, price (USD primary, SOS secondary), verification badge, and heart icon
- [ ] AC2: Map view shows Mapbox dark tiles with price pin annotations ($85, $120, etc.)
- [ ] AC3: Tapping a map pin highlights it (cyan) and scrolls the bottom sheet to that listing's card
- [ ] AC4: Filter by city (All / Mogadishu / Hargeisa) via horizontal chips
- [ ] AC5: Filter sheet supports date range, guest count (stepper), and price range (dual-thumb slider)
- [ ] AC6: Pull-to-refresh reloads listings from Supabase
- [ ] AC7: Cursor-based pagination loads 20 listings per page, loads next page on scroll-to-bottom
- [ ] AC8: Empty state shown when no listings match filters ("No listings found" + clear filters CTA)
- [ ] AC9: Loading state shows skeleton cards matching listing card shape
- [ ] AC10: Error state shown on network failure with "Try Again" button
- [ ] AC11: Heart icon toggles save state (triggers auth sheet if unauthenticated)
- [ ] AC12: Tapping a listing card navigates to Listing Detail
- [ ] AC13: Filter state persists when switching between list and map views
- [ ] AC14: Listings are cached in SwiftData for offline browsing

## Technical Design

### Models

**Listing** — SwiftData `@Model`, also `Codable` for Supabase JSON decoding.

```
Listing
├── id: UUID
├── title: String                    // "Peaceful Villa in Hodan"
├── city: String                     // "Mogadishu" or "Hargeisa"
├── neighborhood: String             // "Hodan", "Abdiaziz"
├── description: String
├── pricePerNight: Int               // USD cents (8500 = $85.00)
├── latitude: Double
├── longitude: Double
├── photoURLs: [String]              // Supabase Storage URLs
├── amenities: [String]              // ["WiFi", "AC", "Parking", ...]
├── maxGuests: Int
├── hostID: UUID
├── hostName: String                 // Denormalized for card display
├── hostPhotoURL: String?
├── isVerified: Bool
├── averageRating: Double?           // nil if no reviews
├── reviewCount: Int
├── cancellationPolicy: String       // "flexible" | "moderate" | "strict"
├── createdAt: Date
└── updatedAt: Date
```

**ListingFilter** — Plain struct, not persisted. Ephemeral UI state.

```
ListingFilter
├── city: City?                      // enum: .mogadishu, .hargeisa, nil = all
├── checkIn: Date?
├── checkOut: Date?
├── guestCount: Int                  // default 1, min 1, max 10
├── priceMin: Int?                   // USD cents
├── priceMax: Int?                   // USD cents
```

**City** — enum

```
City: String, CaseIterable
├── mogadishu = "Mogadishu"
├── hargeisa = "Hargeisa"
```

### Services

**ListingService** — protocol + `SupabaseListingService` implementation.

```
protocol ListingService {
    func fetchListings(filter: ListingFilter, cursor: UUID?, limit: Int) async throws -> [Listing]
    func toggleSaved(listingID: UUID, saved: Bool) async throws
}
```

- `fetchListings`: Queries Supabase `listings` table with PostgREST filters. Returns Codable DTOs, which the ViewModel maps to SwiftData `@Model` objects.
- `toggleSaved`: Inserts/deletes from `saved_listings` junction table. Requires authenticated user (service should throw if no auth token).
- Cursor-based pagination: `cursor` is the `id` of the last listing in the current page. Supabase query uses `.gt("id", cursor)` with `.order("id")` and `.limit(20)`.

**CurrencyService** — for SOS conversion display.

```
protocol CurrencyService {
    func usdToSOS(_ usdCents: Int) -> String    // Returns formatted "~1,530,000 SOS" or "~1.5M SOS"
    func refreshRate() async throws
}
```

- Reads cached rate from UserDefaults. If older than 24h, fetches from fixer.io.
- Abbreviates on listing cards ("~1.5M SOS"), full number on detail/booking screens.

**ImageCacheService** — for listing photo loading.

```
protocol ImageCacheService {
    func loadImage(from url: URL) async throws -> UIImage
}
```

### ViewModel Responsibilities

**ListingDiscoveryViewModel** — `@Observable` class, one instance per Discover tab lifetime.

**State:**
```
listings: [Listing]                  // Current page of listings
isLoading: Bool                      // True during initial load
isLoadingMore: Bool                  // True during pagination load
error: AppError?                     // Non-nil shows error state
filter: ListingFilter                // Current active filters
viewMode: ViewMode                   // .list or .map
selectedPinID: UUID?                 // Highlighted map pin (map mode)
savedListingIDs: Set<UUID>           // Local cache of saved state
hasMorePages: Bool                   // False when last page returned < 20 results
isSearchSheetPresented: Bool
```

**Actions:**
```
loadListings()                       // Initial fetch + SwiftData cache write
loadMore()                           // Pagination — append next page
refresh()                            // Pull-to-refresh — clear + reload
applyFilter(_ filter: ListingFilter) // Update filter, reload
toggleSave(listingID: UUID)          // Heart toggle — checks auth, calls service
selectPin(_ id: UUID)                // Map pin highlight
setViewMode(_ mode: ViewMode)        // Switch list ↔ map
```

**Behavior:**
- On init: load listings from SwiftData cache first (instant), then fetch from Supabase (refresh in background).
- Filter changes trigger a new fetch (reset cursor, clear listings, show loading).
- `toggleSave` checks `AuthManager.isAuthenticated` — if false, sets a flag that triggers auth sheet presentation in the view. On auth success, retries the save.
- `loadMore` is triggered when the last visible listing card appears (using `.onAppear` on a sentinel view).
- Errors are caught and stored in `error` property. View shows error state with retry.

### Views

**File:** `Views/Discovery/DiscoveryView.swift`
- Root view for the Discover tab
- Reads `ListingDiscoveryViewModel` via `@State`
- Contains: search bar, city chips, view mode toggle, content area (list or map), tab bar
- Presents: filter sheet (`.sheet`), auth sheet (`.sheet` via `AuthManager`)

**File:** `Views/Discovery/ListingListView.swift`
- `ScrollView` + `LazyVStack` of `ListingCardView`
- Pull-to-refresh via `.refreshable`
- Pagination sentinel at bottom
- Skeleton loading state
- Empty state
- Error state

**File:** `Views/Discovery/ListingMapView.swift`
- Mapbox `MapView` wrapper (UIViewRepresentable)
- Dark-style map tiles
- Price pin annotations (white pill with bold price, cyan when selected)
- Bottom sheet overlay with compact listing card for selected pin
- Tapping pin → select, tapping card → navigate to detail

**File:** `Views/Discovery/SearchSheetView.swift`
- Presented as `.sheet` with `.presentationDetents([.large])`
- City toggle (Mogadishu / Hargeisa)
- Date range picker (native `DatePicker(.compact)`)
- Guest count stepper
- Price range slider (custom dual-thumb)
- "Show X listings" CTA (count from a lightweight Supabase count query)
- "Clear all" ghost button

**File:** `Views/Shared/ListingCardView.swift`
- Reusable listing card component
- Photo (AsyncImage + ImageCacheService), title, location, rating, price, verified badge, heart button
- Used by: DiscoveryView (full width), SavedListingsView (compact grid), MapView (bottom sheet compact)
- Three variants via an enum: `.full`, `.compact`, `.mapPreview`

**File:** `Views/Shared/CityChipView.swift`
- Horizontal chip: selected (cyan bg, dark text) vs unselected (surfaceElevated bg, secondary text)
- 44pt minimum touch target

**File:** `Views/Shared/SkeletonListingCard.swift`
- Shimmer placeholder matching listing card shape

### Navigation

```
Discover Tab (DiscoveryView)
├── Tap listing card → push ListingDetailView (NavigationStack)
├── Tap filter chip → present SearchSheetView (.sheet)
├── Tap heart (unauthenticated) → present AuthSheetView (.sheet via AuthManager)
└── Tap map pin → select pin, show compact card in bottom sheet
     └── Tap compact card → push ListingDetailView
```

### Dependencies

- **Supabase Swift SDK** (`supabase-swift`) — already approved in architecture
- **Mapbox Maps SDK for iOS** (`mapbox-maps-ios`) — already approved in architecture
- **AuthManager** — environment dependency for save/heart auth gates
- **CurrencyService** — for SOS display
- **ImageCacheService** — for photo loading
- No new SPM packages required

## UI/UX

### Design Reference

Paper design file: "Recurly Designs" → "Marti UI designs" page.

| Screen | Artboard |
|---|---|
| 2.1 Discover - List View | OV-1 |
| 2.2 Discover - Map View | XR-1 |
| 2.3 Filters Sheet | 1CC-1 |
| 6.1 Loading Skeleton | 1SW-1 |
| 6.2 Error State | 1SX-1 |
| 6.3 Empty States | 1SY-1 |

### Key Interactions

- **City chip selection:** Immediate filter — tapping "Mogadishu" filters instantly, no confirmation needed.
- **List ↔ Map toggle:** Chips at top of screen. Filter state persists across toggle. Map centers on current listings.
- **Heart toggle:** Instant visual feedback (fill animation + haptic). Network save is fire-and-forget with retry on failure. Optimistic UI — toggle immediately, revert on error.
- **Pull-to-refresh:** Standard iOS pull gesture on list view. Shows native refresh indicator.
- **Pagination:** Seamless — no "Load more" button. Next page loads when the user scrolls within 3 cards of the bottom.
- **Map pin selection:** Tapping a pin highlights it (cyan), scrolls bottom sheet to show that listing. Tapping the listing card navigates to detail.

## Edge Cases

1. **Zero listings in a city** → Show empty state: "No listings in [city] yet" with a suggestion to try the other city or clear filters.
2. **All listings filtered out** → Show empty state: "No listings match your filters" with "Clear filters" CTA.
3. **Network failure on initial load** → Show error state with "Try Again" button. If SwiftData cache exists, show cached listings with a "No connection" banner at top.
4. **Network failure during pagination** → Show a small inline error at the bottom of the list with "Tap to retry". Don't replace existing listings.
5. **Heart toggle while unauthenticated** → Present auth sheet. On successful auth, complete the save action automatically (don't require the user to tap heart again).
6. **Heart toggle network failure** → Revert the heart state immediately with a brief toast: "Couldn't save listing. Try again."
7. **Photo fails to load** → Show surfaceHighlight placeholder with a small image icon (same as design skeleton). Never show a broken image indicator.
8. **Listing deleted server-side while cached** → On next refresh, listing disappears from the list. If the user had it open in detail view, show an alert: "This listing is no longer available."
9. **SOS rate unavailable** → Hide the SOS secondary line entirely. Don't show stale rates older than 7 days.
10. **User switches cities rapidly** → Debounce filter changes by 300ms to avoid multiple concurrent network requests. Cancel in-flight requests when a new filter is applied.
11. **Mapbox fails to load tiles** → Show a fallback dark rectangle with a "Map unavailable" message. List view remains functional.
12. **Deep link to a specific listing** → If the listing exists in cache, navigate directly to detail. If not, fetch it first, then navigate.

## Testing Plan

### ViewModel Unit Tests

- `test_initialLoad_fetchesListingsFromService`
- `test_initialLoad_populatesFromCacheFirst`
- `test_filterByCity_reloadsListings`
- `test_filterByDates_reloadsListings`
- `test_filterByGuests_reloadsListings`
- `test_filterByPriceRange_reloadsListings`
- `test_clearFilters_resetsToDefaults`
- `test_pagination_appendsNextPage`
- `test_pagination_stopsWhenNoMorePages`
- `test_pullToRefresh_clearsCacheAndReloads`
- `test_toggleSave_whenAuthenticated_callsService`
- `test_toggleSave_whenUnauthenticated_triggersAuthSheet`
- `test_toggleSave_onFailure_revertsState`
- `test_networkError_setsErrorState`
- `test_emptyResults_setsEmptyState`
- `test_viewModeSwitch_preservesFilters`
- `test_rapidFilterChanges_debounced`

### Service Tests

- `test_fetchListings_buildsCorrectPostgRESTQuery`
- `test_fetchListings_withCursor_paginatesCorrectly`
- `test_fetchListings_withCityFilter_appliesFilter`
- `test_fetchListings_withDateFilter_checksAvailability`
- `test_toggleSaved_insertsJunctionRow`
- `test_toggleSaved_deletesJunctionRow`
- `test_fetchListings_decodesResponseCorrectly`

### Manual Test Scenarios

- [ ] Launch app → listings load within 2 seconds
- [ ] Tap "Mogadishu" chip → only Mogadishu listings shown
- [ ] Toggle to Map → pins appear at correct locations
- [ ] Tap a map pin → bottom sheet shows correct listing
- [ ] Pull to refresh → listings reload
- [ ] Scroll to bottom → next page loads seamlessly
- [ ] Tap heart (not signed in) → auth sheet appears
- [ ] Sign in → heart state saves correctly
- [ ] Turn off WiFi → cached listings still visible
- [ ] Open filters → set price range → "Show X listings" updates
- [ ] Clear filters → all listings return
- [ ] Kill app and relaunch → cached listings appear instantly

## Open Questions

None. All technical decisions for this feature are resolved by the PRD, Architecture, and Design docs.

---

*Generated from PRD Feature 1, Architecture module structure, and Design system specifications.*
