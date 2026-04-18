# Tasks: Listing Discovery

- **Spec:** `docs/specs/listing-discovery.md`
- **Status:** Complete (manual seeding + HIG pass pending)
- **Started:** 2026-04-18
- **Finished:** 2026-04-18

## Progress

- Total steps: 12
- Completed: 12
- Currently working on: —

## Steps

### Step 1: Project setup — Supabase + Mapbox SPM packages

Add the two approved dependencies to the Xcode project and verify they build.

- [x] Add `supabase-swift` via SPM (latest stable)
- [x] Add `mapbox-maps-ios` via SPM (latest stable, configure access token)
- [x] Create `SupabaseConfig.swift` with dev/prod project URLs + anon keys (from Xcode build schemes)
- [x] Create `MapboxConfig.swift` with access token
- [x] Verify clean build on iPhone 16 Pro simulator (used iPhone 17 Pro — 16 Pro not installed in Xcode 26.2)
- [x] Build passes

**Notes:** Mapbox requires a secret access token in `~/.netrc` for SPM download. The public token goes in `Info.plist` under `MBXAccessToken`. Supabase needs `SUPABASE_URL` and `SUPABASE_ANON_KEY` per environment — use xcconfig files keyed to Debug/Release schemes.

---

### Step 2: Models — Listing, ListingFilter, City

Define the core data types. No networking, no UI.

- [x] Create `Models/City.swift` — enum with `mogadishu`, `hargeisa`, raw String values, CaseIterable
- [x] Create `Models/ListingFilter.swift` — plain struct with city, checkIn, checkOut, guestCount, priceMin, priceMax, defaults
- [x] Create `Models/Listing.swift` — SwiftData `@Model` + `Codable` DTO, all 20 fields from spec
- [x] Create `Models/AppError.swift` — enum for typed errors (network, notFound, unauthorized, unknown)
- [x] Verify Codable round-trip: encode → decode a Listing with test JSON
- [x] Tests written (Listing Codable conformance, ListingFilter defaults) — 8 tests, all pass
- [x] Build passes

**Notes:** `pricePerNight` stored as Int (USD cents) to avoid floating-point math. `photoURLs` and `amenities` are `[String]` — SwiftData handles array storage natively. The `@Model` macro auto-generates `PersistentModel` conformance.

---

### Step 3: Services — CurrencyService

Small, isolated service with no Supabase dependency. Good warm-up.

- [x] Create `Services/CurrencyService.swift` — protocol with `usdToSOS(_:)` and `refreshRate()`
- [x] Create `Services/LiveCurrencyService.swift` — concrete implementation using URLSession + open.er-api.com (HTTPS, no key)
- [x] Cache rate in UserDefaults with 24h TTL
- [x] Format output: abbreviated on cards ("~1.5M SOS"), full on detail ("~1,530,000 SOS")
- [x] Handle stale rate (>7 days) by returning nil / hiding SOS
- [x] Tests written (formatting, cache hit, cache miss, stale rate) — 9 tests
- [x] Build passes

**Notes:** fixer.io free tier is HTTP only (no HTTPS). Alternative: exchangerate-api.com which supports HTTPS on free tier. Pick whichever works. Rate only needs to be approximate — this is a display convenience, not a financial calculation.

---

### Step 4: Services — ImageCacheService

Thin wrapper around URLSession + NSCache + URLCache.

- [x] Create `Services/ImageCacheService.swift` — protocol with `loadImage(from:)`
- [x] Create `Services/CachedImageService.swift` — concrete implementation
- [x] In-memory cache: `NSCache` for decoded `UIImage`, 50 item limit
- [x] Disk cache: `URLCache` with 200MB disk capacity
- [x] Return cached image immediately if available, otherwise fetch
- [x] Handle failed loads gracefully (return nil, caller shows placeholder)
- [x] Tests written (cache hit, cache miss, invalid URL) — 5 tests using URLProtocol stub
- [x] Build passes

**Notes:** This service is used by `ListingCardView` and later by `ListingDetailView`, `HostProfileView`, etc. Build it generic — not listing-specific.

---

### Step 5: Services — ListingService

The main data layer for discovery. Depends on Supabase SDK from Step 1.

- [x] Create `Services/ListingService.swift` — protocol with `fetchListings(filter:cursor:limit:)` and `toggleSaved(listingID:saved:)`
- [x] Create `Services/SupabaseListingService.swift` — concrete implementation
- [x] Build PostgREST query with filters: city `.eq()`, guests `.gte("max_guests", guestCount)`, price `.gte()` / `.lte()`
- [x] Cursor-based pagination: `.gt("id", cursor)` + `.order("id")` + `.limit(20)`
- [x] `toggleSaved`: insert/delete from `saved_listings` table, throw `AppError.unauthorized` if no session
- [x] Decode response into `[ListingDTO]` Codable structs
- [x] Tests written — 5 tests against `MockListingService` (which is also reused by Step 6 ViewModel tests). Real-SDK query-building isn't unit-testable without an integration backend; deferred to manual QA after Step 11.
- [x] Build passes
- [ ] Date availability filter (against `bookings` table) — stub'd; complete with Booking feature
- [ ] **Backend setup needed before Step 11:** run `docs/db/001_listings.sql` in Supabase SQL editor

**Notes:** Date availability filtering requires a server-side check against the `bookings` table — either via a Supabase RPC function or a subquery. If the `bookings` table doesn't exist yet, stub the date filter and mark it for completion when the Booking feature is built.

---

### Step 6: ViewModel — ListingDiscoveryViewModel

Core logic layer. Depends on Steps 2-5.

- [x] Create `ViewModels/ListingDiscoveryViewModel.swift` — `@Observable` class
- [x] Inject `ListingService`, `CurrencyService`, `AuthManager` via initializer
- [x] Implement state: listings, isLoading, isLoadingMore, error, filter, viewMode, selectedPinID, savedListingIDs, hasMorePages, isFilterSheetPresented, isAuthSheetPresented
- [x] Implement `loadListings()` — fetches from service; SwiftData cache layer added in Step 12
- [x] Implement `loadMore()` — cursor from last listing ID, append, sets hasMorePages
- [x] Implement `refresh()` — clear listings, reset cursor, reload
- [x] Implement `applyFilter(_:)` — debounce 300ms (injectable for tests), cancel in-flight, reset + reload
- [x] Implement `toggleSave(listingID:)` — optimistic toggle, auth gate, service call, revert on failure
- [x] Implement `setViewMode(_:)` and `selectPin(_:)`
- [x] Tests written — 15 ViewModel tests pass; `populatesFromCacheFirst` deferred to Step 12. Created stub `AuthManager` (real sign-in flow lands with the Auth feature).
- [x] Build passes

**Notes:** Use `Task` for async operations. Store task references to cancel on filter changes. The debounce can use a simple `Task.sleep(for: .milliseconds(300))` pattern with cancellation check. SwiftData reads/writes must happen on the `@MainActor`.

---

### Step 7: Shared UI components — ListingCardView, CityChipView, SkeletonCard

Reusable views used across multiple features. No feature-specific logic.

- [x] Create `Views/Shared/ListingCardView.swift` — three variants: `.full`, `.compact`, `.mapPreview`
- [x] Full variant: photo (200pt), title (heading5), location with pin icon, rating with star, price (USD + SOS), verified badge, heart button (44pt target)
- [x] Compact variant: photo (130pt), title (14pt bold), city, price — for Saved grid
- [x] Map preview variant: thumbnail (100x80) + title + location + rating + price — for map bottom sheet
- [x] Heart button: filled pink when saved, white outline when unsaved, `.sensoryFeedback(.impact(.light))`
- [x] Create `Views/Shared/CityChipView.swift` — selected/unselected styles, 44pt min height
- [x] Create `Views/Shared/SkeletonListingCard.swift` — static shape (no shimmer per DESIGN.md)
- [x] Create `Views/Shared/EmptyStateView.swift` — icon + title + subtitle + optional CTA button
- [x] Create `Views/Shared/ErrorStateView.swift` — error icon + message + "Try Again" button
- [x] Apply design tokens from DESIGN.md (colors, spacing, radius, typography) via `Extensions/DesignTokens.swift`
- [x] Tests: N/A (views not unit tested per architecture doc)
- [x] Build passes
- [ ] HIG-review pass (deferred — perform when Step 8 wires the cards into a real screen)

**Notes:** `ListingCardView` is the most reused component in the app. Get it right here — it appears on Discovery, Saved, Map, Booking Detail, and Host Profile. Use `@Environment` for `CurrencyService` to format SOS prices. Heart button accessibility: label "Save listing" / "Remove from saved".

---

### Step 8: Discovery List View — DiscoveryView + ListingListView

The main screen. Composes shared components into the list discovery experience.

- [x] Create `Views/Discovery/DiscoveryView.swift` — root Discover tab view
- [x] Search bar (pill shape, non-functional in v1 — just shows "Search Mogadishu, Hargeisa...")
- [x] City chips row (All / Mogadishu / Hargeisa) — horizontal scroll, `CityChipView`
- [x] View mode toggle (List / Map / Filters chips)
- [x] Content area: `ListingListView` or `MapPlaceholderView` (Mapbox view in Step 10)
- [x] Create `Views/Discovery/ListingListView.swift`
- [x] `ScrollView` + `LazyVStack` of `ListingCardView(.full)`
- [x] `.refreshable` for pull-to-refresh
- [x] Pagination sentinel: `.onAppear` on the (count-3) card → `loadMore()`
- [x] Loading state → `SkeletonListingCard` x 2
- [x] Empty state → `EmptyStateView`
- [x] Error state → `ErrorStateView`
- [x] Tap card → `NavigationLink` to `ListingDetailPlaceholderView`
- [x] Wire up `ListingDiscoveryViewModel` via `@State`
- [x] Apply design tokens (canvas bg, 16pt edges, card spacing)
- [x] Build passes
- [ ] HIG-review pass deferred to Step 11 (full app integration is when first manual run happens)

**Notes:** Use `NavigationStack` (not `NavigationView`). The search bar is visual-only in v1 — tapping it does nothing. It's there for visual consistency and future search implementation. `LazyVStack` is critical for performance with many cards.

---

### Step 9: Filter Sheet — FilterSheetView

Modal filter interface. Depends on Step 6 (ViewModel) and Step 7 (shared components).

- [x] Create `Views/Discovery/FilterSheetView.swift`
- [x] Present as `.sheet(isPresented:)` with `.presentationDetents([.large])`
- [x] Title + "Clear all" ghost button + close button
- [x] City toggle: two buttons (Mogadishu / Hargeisa), selected = cyan, unselected = elevated
- [x] Date range: two native `DatePicker(.compact)` with add/clear toggle
- [x] Guest count: stepper (- count +), min 1, max 10
- [x] Price range: custom dual-thumb `PriceRangeSlider` ($0 – $500, $5 step) with adjustable VoiceOver
- [x] "Show listings" primary CTA (live result count deferred — needs separate Supabase count query)
- [x] On apply: call `viewModel.applyFilter()`, dismiss sheet
- [x] Build passes
- [ ] HIG-review pass deferred to Step 11 manual run

**Notes:** The dual-thumb price slider has no native SwiftUI equivalent. Build a simple custom one: two draggable circles on a track. Each thumb needs a 44pt tap target and VoiceOver `.accessibilityAdjustableAction`. The listing count in the CTA ("Show 12 listings") can use a lightweight Supabase count query, or estimate from cached data.

---

### Step 10: Map View — ListingMapView

Mapbox integration. Depends on Step 1 (Mapbox SDK), Step 6 (ViewModel), Step 7 (shared components).

- [x] Create `Views/Discovery/ListingMapView.swift` — declarative SwiftUI `Map` (Mapbox v11 API, no `UIViewRepresentable` needed)
- [x] Dark style via `.mapStyle(.dark)`
- [x] Price pin annotations via `MapViewAnnotation` (`ForEvery`) — pill with bold $ text
- [x] Selected pin: cyan background; unselected: surfaceDefault
- [x] Tap pin → `viewModel.selectPin`, bottom sheet shows `ListingCardView(.mapPreview)`
- [x] Bottom sheet: surfaceDefault bg, drag handle, result count, compact card, dismiss button
- [x] Tap compact card → NavigationLink to `ListingDetailPlaceholderView`
- [x] Center map on listings via `Viewport.overview(geometry: MultiPoint)` when listings change
- [x] Handle Mapbox load failure → fallback "Map unavailable" view
- [x] Build passes
- [ ] HIG-review pass deferred to Step 11 manual run

**Notes:** Mapbox SwiftUI support is still UIKit-based via `UIViewRepresentable`. Use `MapboxMaps.MapView` with `Style.dark`. Price pins are custom `UIView` annotations — a white rounded rect with bold text. Selected state changes the background to `coreAccent`. Center the map on the bounding box of all visible listings using `CameraOptions`.

---

### Step 11: Integration — Tab bar + navigation + auth gate

Wire everything together in the app's tab bar and navigation structure.

- [x] Update `MartiApp.swift` to construct `SupabaseClient`, `SupabaseListingService`, `LiveCurrencyService` and inject into `MainTabView`
- [x] `MainTabView` with `TabView` — Discover first, then Saved / Bookings / Messages / Profile placeholders
- [x] Wrap Discover tab in `NavigationStack` with "Discover" title
- [x] `AuthManager` instantiated at MainTabView and put into `.environment(auth)` at app root
- [x] `CurrencyService` injected via `.environment(\.currencyService, ...)`
- [x] Heart tap (unauthenticated) → `viewModel.isAuthSheetPresented = true` → `AuthSheetPlaceholderView` (toggles `auth.isAuthenticated`)
- [x] Verified visually: app launches, tab bar appears, Discover renders empty state cleanly (table exists, 0 rows), nav title shows
- [x] Build passes

**Notes:** This step connects all the pieces. The other 4 tabs are just icons + placeholder text ("Coming soon") for now — they'll be built as separate features. The auth sheet is also a placeholder at this stage unless the Auth feature is built first.

---

### Step 12: SwiftData caching + offline + final polish

Cache layer and edge case handling. Last step because it depends on everything above working.

- [x] Configure `ModelContainer` in `MartiApp` for `Listing` model
- [x] On `loadListings()`: cache-first read, display immediately, then network fetch and cache update
- [x] On `refresh()`: clears in-memory + cache via the cache writer's stale-removal pass
- [x] Offline handling: if fetch fails and cache exists, keep cached + set `isOffline` → banner in `ListingListView`
- [x] Offline handling: if no cache and no network, surface error state (existing flow)
- [x] Stale listings: `writeCache` deletes models not present in fresh response
- [x] Build passes
- [ ] Manual seeding: insert sample rows in Supabase (user action — RLS blocks the publishable key from inserting). Once seeded, run the 12-scenario manual test pass and HIG review.

**Notes:** SwiftData `ModelContext.save()` after inserting/updating listings from Supabase response. Use `FetchDescriptor` with predicates matching the current filter for cache reads. Be careful with `@MainActor` — SwiftData operations must happen on the main actor.

---

## Dependency Graph

```
Step 1 (SPM setup)
    ↓
Step 2 (Models) ──────────────────┐
    ↓                              │
Step 3 (CurrencyService)          │
    ↓                              │
Step 4 (ImageCacheService)        │
    ↓                              │
Step 5 (ListingService) ←─────────┘
    ↓
Step 6 (ViewModel) ←── Steps 2-5
    ↓
Step 7 (Shared UI) ←── Step 2 (Models)
    ↓
Step 8 (List View) ←── Steps 6, 7
Step 9 (Filter Sheet) ←── Steps 6, 7
Step 10 (Map View) ←── Steps 1, 6, 7
    ↓
Step 11 (Integration) ←── Steps 8, 9, 10
    ↓
Step 12 (Caching + Polish) ←── Step 11
```

Steps 3, 4, and 7 can be built in parallel with other steps once Step 2 is complete.

## Changes Log

| Date | Step | What changed |
|---|---|---|
| 2026-04-18 | 1 | Added `supabase-swift` 2.43.1 + `mapbox-maps-ios` (main) via SPM. Created `Services/SupabaseConfig.swift` and `Services/MapboxConfig.swift` reading from `Info.plist`. Wired `MapboxConfig.configure()` into `MartiApp.init()`. Build passes on iPhone 17 Pro simulator. Single-environment config for now (Supabase prod project deferred). |
| 2026-04-18 | 2 | Created `Models/City.swift`, `Models/AppError.swift`, `Models/ListingFilter.swift`, `Models/Listing.swift`. `Listing` is a SwiftData `@Model` class; `ListingDTO` is the Codable struct that decodes Supabase snake_case rows and maps into the model. Tests at `MartiTests/Models/ListingTests.swift` (5) and `MartiTests/Models/ListingFilterTests.swift` (3) — all pass. |
| 2026-04-18 | 3 | Created `Services/CurrencyService.swift` (protocol + `CurrencyDisplay` enum) and `Services/LiveCurrencyService.swift` (open.er-api.com, HTTPS, no key). Caches rate in UserDefaults (24h refresh, 7d staleness). Abbreviated format ("~48.5K SOS", "~1.5M SOS") + full format ("~1,530,000 SOS"). 9 tests in `MartiTests/Services/LiveCurrencyServiceTests.swift` — all pass. |
| 2026-04-18 | 4 | Created `Services/ImageCacheService.swift` (protocol) and `Services/CachedImageService.swift` (NSCache memory + URLCache disk, 50 items / 200 MB). Returns nil on any failure for graceful placeholder fallback. 5 tests in `MartiTests/Services/CachedImageServiceTests.swift` using a `StubURLProtocol`; suite is `@Suite(.serialized)` because the stub uses static state. |
| 2026-04-18 | 5 | Created `Services/ListingService.swift` (protocol), `Services/SupabaseListingService.swift` (PostgREST impl with city/guests/price/cursor filters; `toggleSaved` insert/delete via `auth.user().id`). Test double `MartiTests/Services/MockListingService.swift` records inputs and supports throwing handlers (used here + by Step 6 ViewModel tests). Backend schema: `docs/db/001_listings.sql` — must be run in Supabase before app can fetch live data. Date-availability filter deferred until the Bookings feature exists. |
| 2026-04-18 | 6 | Created `Services/AuthManager.swift` (minimal `@Observable` MainActor class — full sign-in flow lands with Auth feature). Created `ViewModels/ListingDiscoveryViewModel.swift` with cancellable load/debounce tasks, optimistic save with revert, auth-sheet trigger on unauthenticated saves, pagination, refresh. 15 tests in `MartiTests/ViewModels/ListingDiscoveryViewModelTests.swift` — all pass. SwiftData cache-first layer deferred to Step 12. |
| 2026-04-18 | 7 | Created design tokens at `Extensions/DesignTokens.swift` (colors / spacing / radius / typography from DESIGN.md). Added `Extensions/CurrencyServiceEnvironment.swift` with `NoOpCurrencyService` default. Created shared views: `Views/Shared/{ListingCardView, CityChipView, SkeletonListingCard, EmptyStateView, ErrorStateView}.swift`. `ListingCardView` covers all three variants (.full, .compact, .mapPreview) and reads currency formatter from `@Environment`. Static skeletons (no shimmer per DESIGN.md). HIG review deferred to Step 8 once cards live on a real screen. |
| 2026-04-18 | 8 | Created `Views/Discovery/DiscoveryView.swift` (search bar, city chips, list/map/filters chips) and `Views/Discovery/ListingListView.swift` (ScrollView + LazyVStack, refreshable, pagination sentinel, skeleton/empty/error states, NavigationLink to placeholder detail). Map view is placeholder until Step 10. Created `Views/ListingDetail/ListingDetailPlaceholderView.swift`. |
| 2026-04-18 | 9 | Created `Views/Discovery/FilterSheetView.swift` and `Views/Discovery/PriceRangeSlider.swift` (custom dual-thumb slider with `.accessibilityAdjustableAction`). Sheet edits a draft `ListingFilter`, calls `viewModel.applyFilter` on apply. Wired into `DiscoveryView` via `.sheet(isPresented:)`. |
| 2026-04-18 | 10 | Created `Views/Discovery/ListingMapView.swift` using Mapbox v11 declarative SwiftUI (`Map` + `MapViewAnnotation` via `ForEvery`). Dark style. Price pins with selected (cyan) state, recenter on listings change via `Viewport.overview(MultiPoint)`, fallback view on map load error. Bottom sheet shows the selected listing as a `ListingCardView(.mapPreview)` with NavigationLink to detail. |
| 2026-04-18 | 11 | Created `Views/MainTabView.swift` (5 tabs) and `Views/Auth/AuthSheetPlaceholderView.swift`. Updated `MartiApp.swift` to wire `SupabaseClient`, `SupabaseListingService`, `LiveCurrencyService`, `AuthManager` into the environment and present the tab bar. Verified the app launches and renders the Discover tab with the empty state on the iPhone 17 Pro simulator (Supabase is reachable; `listings` table exists with 0 rows). |
| 2026-04-18 | 12 | Added `.modelContainer(for: Listing.self)` in `MartiApp` and threaded the `ModelContext` into `ListingDiscoveryViewModel`. ViewModel now reads cached listings first, then fetches Supabase, then upserts and prunes stale rows. On fetch failure with a non-empty cache, sets `isOffline = true` and renders a "No connection" banner in `ListingListView`. Existing tests still pass (cache is opt-in via optional `modelContext`). |
| 2026-04-18 | UI design pass | Reviewed implementation against Paper artboards `OV-1`, `XR-1`, `1CC-1`, `1SW-1`, `1SX-1`, `1SY-1`. Removed the "Discover" nav title (A1), dropped the List/Map/Filters chip row from List view in favour of a compact map-icon button next to the search bar (A2), made the search bar text reflect the active filter (B1). Stripped the heart's dark pill background, restacked the listing card so the price line sits left-aligned at the bottom, tightened map-preview to put `★ rating · $price/night` on one row (A3/A4/A5/B2). Rebuilt `FilterSheetView`: medium detent + drag indicator, inline "Filters / Clear all" header, simple date pills opening a graphical `DatePicker` in a child sheet, outline-style stepper circles (C1/C2/C3). Skeleton screen now shows search-bar + chip skeletons via new `SkeletonHeader`, and `SkeletonListingCard` renders four bars (D1/D2). Replaced inset yellow banner with full-width pink `OfflineBannerView` at top of `ListingListView`; `ErrorStateView` icon is now circle-with-exclamation, "Try Again" is auto-width (E1/E2/E3). `EmptyStateView` is card-wrapped with a 64pt tinted-circle icon and supports `.ghost` or `.primary` CTA styles (F1/F2/F3). All 43 unit tests still pass. |
