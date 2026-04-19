# Architecture: Marti — Observed

## Snapshot

- **Audit run:** 2026-04-19 (refresh, late)
- **Branch:** `dev`
- **Head commit:** `ae05b0e feat: added discovery header component` (5 commits beyond the prior audit's `a5dfd94`; working tree clean)
- **Shipped features:** Listing Discovery (v1) plus the in-flight map-mode redesign is the only fully wired screen. Saved / Bookings / Messages / Profile all render a single `ComingSoonView` stub (`MainTabView.swift:51–58`).
- **Source of truth vs. intent:** the original intent doc is preserved at `docs/ARCHITECTURE.previous.md`; this file is the observed reality.

## Overview

Marti is a single-target SwiftUI iOS 26.2 app built around one shipped feature — Listing Discovery — with placeholders for the other four tabs. It uses MVVM with `@Observable` ViewModels, SwiftData as a local cache keyed off Supabase, and Supabase (PostgREST) as the source of truth. Mapbox v11 renders the map. One `@Observable` ViewModel (`ListingDiscoveryViewModel`, 375 lines) powers the only working screen; two other `@Observable` classes (`AuthManager`, `FloatingTabViewHelper`) are shared-state holders injected via `.environment`. Auth is a placeholder boolean — no real sign-in, tokens, or identity exist yet. Networking is through the Supabase Swift SDK (PostgREST) plus two `URLSession` outliers in `CachedImageService` and `LiveCurrencyService`.

## Module structure

The app has **no Swift packages** — it's a single `Marti` target inside `marti/marti.xcodeproj`, with two test targets (`MartiTests`, `MartiUITests`). Swift 6 strict concurrency is on (`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, `SWIFT_VERSION = 6.0`).

```
marti/marti/
├── MartiApp.swift                       — @main, builds SupabaseClient + services, installs modelContainer
├── ContentView.swift                    — Xcode template, unused (dead code)
├── Info.plist                           — SUPABASE_URL / SUPABASE_ANON_KEY / MBXAccessToken
├── Assets.xcassets                      — AccentColor, AppIcon only
├── Models/
│   ├── AppError.swift                   — enum: .network / .notFound / .unauthorized / .unknown
│   ├── City.swift                       — enum { .mogadishu, .hargeisa }
│   ├── Listing.swift                    — SwiftData @Model + paired ListingDTO (Codable); categoryIDs default []
│   ├── ListingFilter.swift              — struct: city, dates, guest count, price bounds
│   ├── DiscoveryCategory.swift          — SwiftData @Model + DiscoveryCategoryDTO
│   └── DiscoveryRail.swift              — transient in-memory (category, [Listing]) grouping
├── Services/
│   ├── AuthManager.swift                — @Observable, single Bool isAuthenticated
│   ├── SupabaseConfig.swift             — reads Info.plist; fatalError on missing key; static .client is unused
│   ├── MapboxConfig.swift               — reads Info.plist, calls MapboxOptions.accessToken =
│   ├── ListingService.swift             — protocol + DTOs (ListingCursor, DiscoveryFeedDTO)
│   ├── SupabaseListingService.swift     — PostgREST: fetchListings / fetchDiscoveryFeed / toggleSaved
│   ├── CurrencyService.swift            — protocol: usdToSOS(_:display:) + refreshRate()
│   ├── LiveCurrencyService.swift        — URLSession → open.er-api.com; caches in UserDefaults
│   ├── ImageCacheService.swift          — protocol: loadImage(from:)
│   └── CachedImageService.swift         — NSCache + URLCache impl (currently unused in-app, see Smells)
├── ViewModels/
│   └── ListingDiscoveryViewModel.swift  — the only ViewModel in the app (375 lines)
├── Views/
│   ├── MainTabView.swift                — FloatingTabView host + 5 TabKind cases (.discover plus 4 ComingSoon stubs)
│   ├── Auth/AuthSheetPlaceholderView.swift — flips auth.isAuthenticated = true
│   ├── Discovery/
│   │   ├── DiscoveryView.swift          — list / map switch, filter + auth sheets, push destination
│   │   ├── ListingListView.swift        — offline banner + rails or loading / error / empty
│   │   ├── ListingMapView.swift         — Mapbox v11 SwiftUI Map, price pins, recenter
│   │   ├── CategoryRailView.swift       — horizontal rail with .containerRelativeFrame
│   │   ├── FilterSheetView.swift        — city, dates, guests, price range inputs
│   │   ├── PriceRangeSlider.swift
│   │   └── Components/                  — DiscoveryHeaderPill, DiscoveryHeroHeaderView, FeeInclusionTag, ListingPricePin, MapEmptyStatePill, SelectedListingCard
│   ├── ListingDetail/ListingDetailPlaceholderView.swift
│   └── Shared/                          — FloatingTabView, Buttons, ListingCardView, SkeletonListingCard, EmptyStateView, ErrorStateView (+ OfflineBannerView), CityChipView, FavoriteHeartButton, VerifiedBadgeView
└── Extensions/
    ├── DesignTokens.swift               — Color/Spacing/Radius/Font helpers (see DESIGN.md)
    └── CurrencyServiceEnvironment.swift — EnvironmentKey + NoOpCurrencyService default

marti/MartiTests/
├── Models/ListingTests.swift, ListingFilterTests.swift
├── Services/MockListingService.swift, MockListingServiceTests.swift, LiveCurrencyServiceTests.swift, CachedImageServiceTests.swift
├── ViewModels/ListingDiscoveryViewModelTests.swift  (567 lines — the bulk of the suite)
├── Views/FavoriteHeartButtonTests.swift, VerifiedBadgeViewTests.swift  (enum-Size / variant constants only; no body rendering)
└── MartiTests.swift                                 (Xcode template stub)

marti/MartiUITests/
└── MartiUITests.swift, MartiUITestsLaunchTests.swift  (Xcode templates only)
```

## Data flow

Traced end-to-end for "cold launch → user sees rails":

1. `MartiApp.init()` calls `MapboxConfig.configure()`, constructs a `SupabaseClient` from `SupabaseConfig.url/anonKey`, and builds `SupabaseListingService` + `LiveCurrencyService` as constants (`MartiApp.swift:17–25`).
2. The `WindowGroup` renders `MainTabView(listingService:currencyService:)` and attaches `.modelContainer(for: [Listing.self, DiscoveryCategory.self])` (`MartiApp.swift:27–34`).
3. `MainTabView` owns `@State private var auth = AuthManager()` and reads `@Environment(\.modelContext)`; inside its `FloatingTabView` closure, the `.discover` branch constructs `ListingDiscoveryViewModel(...)` inline and passes it to `DiscoveryView` (`MainTabView.swift:35–60`).
4. `DiscoveryView.task` starts the initial load when `viewModel.listings.isEmpty`.
5. `ListingDiscoveryViewModel.loadListings()` reads cached `Listing` / `DiscoveryCategory` rows, converts them to DTO snapshots, maps them back to detached `@Model` instances, and surfaces them immediately to seed the UI — then awaits `listingService.fetchDiscoveryFeed(city:)`.
6. `SupabaseListingService.fetchDiscoveryFeed` runs two concurrent PostgREST queries — `categories` and the `listings_with_categories` view — and returns a `DiscoveryFeedDTO` (`SupabaseListingService.swift:60–71,77–102`).
7. The ViewModel replaces `listings` + `categories`, calls `writeCache` / `writeCategoryCache` to upsert and purge stale rows, sets `hasMorePages = false` (rails aren't paginated), and flips `isLoading = false`. `rails` is a computed property that joins categories + listings on `categoryIDs`.
8. `ListingListView` observes the ViewModel via `@Bindable`, renders rails through `CategoryRailView`, and falls back to `ErrorStateView` / `EmptyStateView` when rails are empty. In list mode, `DiscoveryHeroHeaderView` sits above the rails (`DiscoveryView.swift:57`); it reads `viewModel.filter` to render the search capsule and dispatches `viewModel.setViewMode(.map)` / `viewModel.isFilterSheetPresented = true` from its trailing icon buttons.

Save flow: `DiscoveryView` → `viewModel.toggleSave(listingID:)`. If unauthenticated, the ViewModel presents `AuthSheetPlaceholderView`. Otherwise it optimistically toggles `savedListingIDs`, then `SupabaseListingService.toggleSaved` inserts / deletes a `saved_listings` row. Any throw rolls the optimistic state back and surfaces an `AppError` (`SupabaseListingService.swift:111–135`).

## State management

| State | Where it lives | Evidence |
|---|---|---|
| Auth state | `AuthManager` (`@Observable @MainActor`) held as `@State` in `MainTabView`, injected via `.environment(auth)` | `MainTabView.swift:7,61`; `AuthManager.swift` |
| Discovery screen state | `ListingDiscoveryViewModel` (`@Observable @MainActor`) held as `@State` in `DiscoveryView`, constructed inline by `MainTabView` | `MainTabView.swift:41–46`; `ListingDiscoveryViewModel.swift` |
| View-local state (viewport, sheets, `loadFailed`, `pushedListing`, drag offsets) | `@State` in the owning view | `ListingMapView.swift`; `DiscoveryView.swift`; `SelectedListingCard.swift:28–30` |
| Tab-bar hide toggle | `FloatingTabViewHelper` (`@Observable`) installed by `FloatingTabView` into the environment; mutated via `.hideFloatingTabBar(_:)` | `FloatingTabView.swift` |
| Currency service | Environment key with `NoOpCurrencyService` default; injected by `MainTabView` | `CurrencyServiceEnvironment.swift`; `MainTabView.swift:62` |
| SwiftData cache | `.modelContainer(for: [Listing.self, DiscoveryCategory.self])` at `@main`; read via `@Environment(\.modelContext)` | `MartiApp.swift:34`; `MainTabView.swift:9` |

No `@AppStorage`, no `EnvironmentObject`, no `@Query`, no singletons beyond Apple-provided ones. Only one screen-scoped ViewModel exists today.

## Persistence

| Data | Storage | File reference |
|---|---|---|
| Listings cache | SwiftData `@Model Listing` | `Models/Listing.swift` (255 LOC) |
| Discovery categories cache | SwiftData `@Model DiscoveryCategory` | `Models/DiscoveryCategory.swift` (82 LOC) |
| USD→SOS exchange rate + timestamp | `UserDefaults` (`currency.usdToSosRate`, `currency.usdToSosFetchedAt`) | `LiveCurrencyService.swift:4,12,62,69–74` |
| Image bytes | `URLCache(diskCapacity: 200MB)` on a dedicated `URLSession` inside `CachedImageService` (built but unused — see Smells) | `CachedImageService.swift` |
| Decoded `UIImage` | `NSCache<NSURL, UIImage>` (count limit 50) inside `CachedImageService` (same caveat) | `CachedImageService.swift` |
| Auth tokens | *(not persisted — no real auth yet)* | `AuthManager.swift` |
| Onboarding / first-launch flags | *(none observed)* | — |
| Saved listings | Supabase `saved_listings` only (no local mirror) | `SupabaseListingService.swift:111–135` |

`Listing ↔ ListingDTO` (and `DiscoveryCategory ↔ DiscoveryCategoryDTO`) are the standard pairing: the DTO is `nonisolated struct`, Codable, snake_case mapped; the `@Model` class is hydrated via `Listing(dto:)` and re-emitted via `ListingDTO(model:)`. The cache read path deliberately returns DTOs (not attached `@Model` instances) so a concurrent `writeCache` stale-purge can't detach a model still held by a View.

Migration safety: `Listing.categoryIDs` has a default `[]` so pre-migration caches decode; `ListingDTO.init(from:)` also calls `decodeIfPresent([UUID].self, forKey: .categoryIDs)` because the bare `listings` table doesn't expose that column (only the `listings_with_categories` view does) — `Listing.swift:172–198`.

## Networking

- **Supabase Swift SDK** (`supabase-swift` @ 2.43.1; pinned in `Package.resolved` alongside the Mapbox stack, `swift-asn1`, `swift-crypto`, `swift-http-types`, `swift-clocks`, `swift-concurrency-extras`, `xctest-dynamic-overlay`, `turf-swift`). Used exclusively inside `SupabaseListingService` for PostgREST. Realtime and Auth modules are transitive dependencies but aren't exercised — `client.auth.user().id` is only called inside `toggleSaved` and throws `AppError.unauthorized` today because no one ever signs in.
- **URLSession** is reached for in two places only: `CachedImageService` (its own session with a 200MB disk cache; not currently instantiated by the app) and `LiveCurrencyService` (`URLSession.shared` → `https://open.er-api.com/v6/latest/USD`).
- **Pagination:** `SupabaseListingService.fetchListings` implements keyset pagination over `(created_at DESC, id DESC)` with a PostgREST `or(...)` filter (`SupabaseListingService.swift:21–53`). The Discovery feed (`fetchDiscoveryFeed`) does *not* paginate — the ViewModel explicitly flips `hasMorePages = false` after a feed load.
- **Error mapping:** `SupabaseListingService.map(_:)` converts `URLError` → `AppError.network`, preserves `AppError`, otherwise returns `.unknown`. ViewModels wrap anything else via `mapError` → `AppError.unknown`.
- **Offline handling:** `loadListings` catches errors when the cache is non-empty and flips `isOffline = true` instead of surfacing an error; `ListingListView` then prepends `OfflineBannerView` (defined in `Views/Shared/ErrorStateView.swift`).
- **No Combine. No completion handlers. No long-lived subscriptions.** All I/O is `async`/`await` with `Task` references stored on the ViewModel so they can be cancelled (`loadTask`, `debounceTask`). The VM also exposes `awaitPendingDebounce()` as a test hook.

`Info.plist` contains a single `SUPABASE_URL` / `SUPABASE_ANON_KEY`. Scheme-based dev/prod Supabase switching (listed as intent) is **not** implemented today.

## Background & system integration

- **No push notifications.** No `UNUserNotificationCenter`, no APNs registration, no entitlements file in the repo.
- **No background tasks.** No `BGTaskScheduler`, no `UIBackgroundModes` in `Info.plist`.
- **No widgets.** No widget extension target.
- **No deep linking.** No URL scheme, no Universal Links, no `DeepLinkRouter`.
- **No analytics.** TelemetryDeck (mentioned in the intent doc) is not integrated. No Sentry / Firebase either.

The only system integrations observed are haptics (`.sensoryFeedback(.impact, ...)` on `FavoriteHeartButton` and the floating tab bar) and `UITabBar.appearance()` — the latter is absent here because `FloatingTabView` draws its own bar.

## Security & privacy

Observed protections:
- **Supabase publishable anon key** is committed in `Info.plist` by design; the `sb_publishable_` prefix matches Supabase's public-key convention. Data access is gated by RLS policies defined in `docs/db/001_listings.sql` and `docs/db/003_categories.sql`.
- **Mapbox public token (`pk.…`)** is also in `Info.plist`. No secret (`sk.…`) token is in the repo — it's expected to live in `~/.netrc` per `CLAUDE.md`.
- **HTTPS only.** All endpoints in code are `https://` (Supabase URL + `open.er-api.com`). No `NSAppTransportSecurity` overrides in `Info.plist`.
- **RLS:** `listings` is public-read; `saved_listings` uses `auth.uid() = user_id` for select/insert/delete.

NOT verified by this audit:
- No app entitlements file is present anywhere in the repo — so location permission, camera permission, Apple sign-in capability, and push entitlements can't be inspected here. They may be managed entirely through the Xcode project's build settings.
- No privacy usage-description strings (`NSLocationWhenInUseUsageDescription`, `NSCameraUsageDescription`, etc.) in `Info.plist`. These will need to land before any feature that touches location / photos / camera ships.
- Keychain storage of auth tokens cannot be verified — no real auth flow has shipped yet.
- No Supabase Storage / signed-URL usage is in code yet (photo URLs are plain text in `photo_urls` arrays).

## Testing coverage

| Target / file | Coverage |
|---|---|
| `ViewModels/ListingDiscoveryViewModelTests.swift` | 567 lines. Initial load, rails composition, pagination, save toggle with rollback, filter debounce, cache reads, offline fallback. Biggest test file by far. |
| `Services/MockListingServiceTests.swift` | Sanity checks on the test double + `ListingDTO` fixtures |
| `Services/LiveCurrencyServiceTests.swift` | Rate caching, 24h refresh interval, 7d staleness cutoff, abbreviated / full formatting |
| `Services/CachedImageServiceTests.swift` | Memory hit, disk fallback, HTTP-error handling (via a serialized `StubURLProtocol`) |
| `Models/ListingTests.swift`, `Models/ListingFilterTests.swift` | DTO ↔ `@Model` conversion; filter equality + defaults |
| `Views/FavoriteHeartButtonTests.swift` | Asserts `Size.small` / `Size.large` constants. **Not** a body/snapshot test — just verifies the enum numbers (32 / 44). |
| `Views/VerifiedBadgeViewTests.swift` | 17-line sibling to the heart-button test — asserts the badge's variant constants (size / icon weight), no body rendering. |
| `MartiTests.swift`, `MartiUITests/*` | Xcode templates — stubs only |

Framework: **Swift Testing** (`@Test`, `#expect`) throughout. No XCTest in new files. No snapshot tests. No integration tests against a live Supabase. No tests for `SupabaseListingService` (request construction, PostgREST filter strings, and keyset pagination go untested), `AuthManager`, or any SwiftUI view body.

Gaps that matter:
- `SupabaseListingService.fetchListings` builds a non-trivial PostgREST `or(...)` cursor string — that logic is untested.
- `AuthManager` is trivial today but will need tests once real sign-in lands.
- Both "view tests" so far (`FavoriteHeartButtonTests`, `VerifiedBadgeViewTests`) only assert enum constants — a useful pattern, but calling the folder `Views/` creates an expectation of body/snapshot coverage that doesn't exist.

## Drift from intent

The original `docs/ARCHITECTURE.previous.md` described a fuller v1. Observed drift (unchanged since the prior refresh — no intent items have been delivered in the last five commits):

| Intent | Reality |
|---|---|
| Models: `Listing`, `Booking`, `Message`, `Review`, `UserProfile`, `Host` | Only `Listing`, `DiscoveryCategory` (+ `DiscoveryRail` transient grouping) exist |
| Services: `ListingService`, `BookingService`, `MessagingService`, `ReviewService`, `ImageCacheService`, `CurrencyService`, `AuthManager` | Listing + ImageCache + Currency + Auth only; Booking / Messaging / Review services don't exist yet |
| 8 ViewModels | 1 (`ListingDiscoveryViewModel`); the other four tabs show `ComingSoonView` stubs |
| "Two Supabase projects via Xcode schemes (Debug / Release)" | A single `SUPABASE_URL` / `SUPABASE_ANON_KEY` in `Info.plist`; no scheme-based switching |
| TelemetryDeck analytics | Not integrated |
| APNs push + SMS delivery via edge functions | Not wired; no notification code in the app |
| Keychain for auth tokens | N/A — no real auth flow yet |
| Sign in with Apple / Phone OTP | `AuthSheetPlaceholderView.swift` flips a Bool |
| `ImageCacheService` wired into listing photos | Protocol + implementation exist (split across two files) but no call site wires one into the app — `AsyncImage` loads listing photos in `ListingCardView.photo()` and `SelectedListingCard` |

None of the drift is surprising given the feature-status section of `CLAUDE.md` — Listing Discovery is the only shipped feature and everything else is under-implementation, not divergence.

The last five commits refine Discovery (hero header, outlined heart, icon-based verified badge, map-mode redesign follow-ons) without expanding surface area into the other tabs.

## Smells observed

1. **`ContentView.swift` is dead.** The Xcode template file is checked in but unreferenced — `MartiApp.swift` builds `MainTabView` directly. Low-risk to delete.
2. **`ListingDiscoveryViewModel` is doing a lot (375 lines, up from 339).** It owns network load, SwiftData cache read/write for two `@Model` types, pagination state, filter debounce, save toggling, view-mode toggling, pin selection, fee-tag dismissal, and auth-gate sheet presentation. Extracting the SwiftData layer into a `ListingCacheStore` / generic cache protocol would shrink it and let cache behavior be tested against a `ModelContainer(.ephemeral)` in isolation.
3. **`writeCache` / `writeCategoryCache` are near-duplicates.** Same three-step shape (fetch existing → delete stale → upsert fresh). Worth genericizing once a second ViewModel needs SwiftData caching, not before.
4. **`SupabaseConfig.client` is dead.** `MartiApp.init()` builds its own `SupabaseClient` by reading `SupabaseConfig.url/anonKey` directly; the static `SupabaseConfig.client` has zero callers in the codebase.
5. **`CachedImageService` is dead in the shipping app.** It is instantiated only inside `CachedImageServiceTests.swift`; `MartiApp` never builds one and no View imports it. Listing photos load via `AsyncImage` in `ListingCardView` and `SelectedListingCard`. Either wire the cache in (via an environment key, as with `CurrencyService`) or delete it.
6. **`nonisolated(unsafe)` on `CachedImageService.memoryCache`** is defensible (`NSCache` is thread-safe) but uncommented — a one-line "why safe" note would help the next reader.
7. **`MainTabView` re-instantiates `ListingDiscoveryViewModel` inline inside its tab closure** (`MainTabView.swift:40–46`). SwiftUI's `@State private var viewModel: ListingDiscoveryViewModel` in `DiscoveryView` holds it stable across re-renders, but the pattern still relies on `DiscoveryView`'s `@State` initial-value capture to dedupe — worth a manual trace to confirm no extra `loadListings()` calls fire on tab switches.
8. **`OfflineBannerView` lives inside `ErrorStateView.swift`.** Fine, but surprising — future-you will grep the filename and miss it. Move it to its own file when next touched.
9. **`SupabaseConfig` and `MapboxConfig` call `fatalError` on missing plist keys** (`SupabaseConfig.swift`, `MapboxConfig.swift`). Acceptable for dev; worth replacing with a startup error screen before App Store submission so a misconfigured build surfaces a diagnostic instead of crashing at launch.
10. **Mapbox SPM pin is still `main` (revision `53d142e3…`)**, tracking `main` rather than a tagged v11 release. Per `CLAUDE.md`, this must be pinned to a v11 tag before App Store submission.
11. **`Info.plist` is missing privacy usage descriptions.** No `NSLocationWhenInUseUsageDescription`, `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, or similar. The map doesn't request user location today, so this is latent — but any feature that touches location, photos, or camera (host onboarding, "places near me", profile photo) will need strings in place before it ships or the App Store review will bounce the build.
12. **Two "view tests" assert only enum constants.** `FavoriteHeartButtonTests` (heart sizes) and `VerifiedBadgeViewTests` (badge variants) live under `MartiTests/Views/` but never render a `View` body. The pattern is useful, but the folder name misleads — either rename the folder (`ViewConstants/`) or move the constants under the Models/ area.

## Open questions

1. **Where are the app's entitlements and capabilities configured?** No `.entitlements` file is visible anywhere in the repo. Location permission, push, and Sign in with Apple will each require changes — the Xcode project is the only place to look, and this audit didn't open it.
2. **Does `DiscoveryView` re-run `loadListings()` on tab switches?** `MainTabView` re-evaluates its tab closure; whether SwiftUI re-inits `DiscoveryView`'s `@State`-captured VM is worth verifying with a print-on-init.
3. **Is `CachedImageService` deliberately parked?** It was built with tests and is structurally ready — the absence of any call site suggests it was shelved mid-wire-up or that `AsyncImage` was deemed sufficient. Decision needed.
4. **Does `DiscoveryHeroHeaderView`'s search capsule set expectations we can't meet?** It's `.accessibilityHidden(true)` and the code comment says "search not functional in v1", but sighted users still see a capsule that reads like a search field. Worth deciding whether to gate it behind a feature flag until real search lands.

---

## Summary

**Diff vs. the earlier audit today:** five commits on `dev` since `a5dfd94`. Material changes:

- **New component:** `Views/Discovery/Components/DiscoveryHeroHeaderView.swift` (126 LOC) — editorial list-mode header with a demoted (but still visible) search capsule and map/filter icon buttons; replaces the previous static list-mode header.
- **Iconography pass:** `FavoriteHeartButton` now uses an outlined heart everywhere with a filled variant when filters are active; the verified badge became an icon (`39e6f6b`, `a3af1e5`).
- **Test additions:** `MartiTests/Views/VerifiedBadgeViewTests.swift` (17 LOC, constants-only, sibling pattern to `FavoriteHeartButtonTests`).
- **ViewModel growth:** `ListingDiscoveryViewModel` grew from 339 → 375 LOC, mostly category-cache plumbing and an `awaitPendingDebounce()` test hook.
- **Everything else is unchanged:** no new ViewModels, services, or persistence types; no entitlements; no push / widgets / background tasks; SPM pins identical; `ContentView.swift` still checked in and unused.

**Previous intent doc is preserved** at `docs/ARCHITECTURE.previous.md` — not overwritten by this refresh, and not duplicated by it either.

**3 concrete follow-ups worth addressing before the next feature lands:**

1. **Prune dead code:** `ContentView.swift`, `SupabaseConfig.client`, and (if not intended to ship) `CachedImageService`. All three are zero-caller in the shipping app and will confuse the next feature author.
2. **Split the SwiftData cache layer out of `ListingDiscoveryViewModel`.** Listing Detail and Bookings are next — a `ListingCacheStore` (or a small generic over `@Model` + DTO pair) keeps the next ViewModel from inheriting ~80 lines of boilerplate and makes cache behavior unit-testable against a `ModelContainer(.ephemeral)`.
3. **Harden app config before submission:** replace `fatalError` in `SupabaseConfig` / `MapboxConfig` with a startup error screen, pin Mapbox to a v11 release tag, and add privacy usage-description strings to `Info.plist` for whichever system permissions the next features request.

*Refreshed 2026-04-19 (late). Prior intent doc preserved at `docs/ARCHITECTURE.previous.md`.*
