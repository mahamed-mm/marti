# Architecture audit — 2026-04-19

First dated architecture snapshot for Marti. Describes the code as it actually exists, not what the spec says. `docs/ARCHITECTURE.md` remains the lean intent. Prior dated audits: none — `docs/audits/` contains only `intent-architecture.md` / `intent-design.md` from the v0 planning phase.

## Snapshot

- **Date:** 2026-04-19
- **Head commit:** `1c3f28c` — "📝 Add docstrings to `dev`"
- **Branch:** `dev`
- **Working tree:** dirty.
  - 22 modified files (discovery map redesign in flight), 5 new Discovery components untracked (`FloatingMapIconButton`, `MapListingsCarousel`, `MapToggleFAB`, `PricePinCluster`, `SearchThisAreaPill`), 1 renamed (`FilterSheetView.swift` → `SearchSheetView.swift`), 2 new supporting files committed to index (`Extensions/MapConfiguration.swift`, `MartiTests/Views/ListingPricePinTests.swift`).
  - `docs/ARCHITECTURE.previous.md` and `docs/DESIGN.previous.md` deleted — superseded by the audit convention this file is establishing.
  - `.claude/rules/` untracked (rules directory referenced from `CLAUDE.md` via `@` imports, not committed yet).

## Overview

Single-target SwiftUI iOS 26.2 app. MVVM with one `@Observable` `@MainActor` ViewModel per screen, SwiftData caching two `@Model` types, Supabase Swift SDK 2.43.1 as source of truth, Mapbox v11 for maps. Strict Swift 6 — `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` project-wide, all DTOs `nonisolated Sendable`. One feature shipped (Listing Discovery); map-mode redesign is mid-flight. The rest (Auth, Booking, Messaging, Reviews, Profile) is scaffolding or absent. No analytics, push, background tasks, widgets, or deep linking today.

## Module structure

Single Xcode project `marti/Marti.xcodeproj` with three targets — `Marti` (app), `MartiTests` (Swift Testing), `MartiUITests` (XCTest). Uses `PBXFileSystemSynchronizedRootGroup` so filesystem adds/deletes flow into the build without manual pbxproj churn.

**50 Swift files** under `marti/Marti/`:

```
marti/Marti/
├── MartiApp.swift                    ← @main; builds Supabase client + services
├── ContentView.swift                 ← Xcode-template "Hello, world!" stub (dead)
├── Info.plist                        ← SUPABASE_URL / SUPABASE_ANON_KEY / MBXAccessToken
├── Assets.xcassets                   ← AppIcon.appiconset, empty AccentColor.colorset
├── Models/                           6 files
│   ├── AppError.swift                enum (Equatable, Sendable)
│   ├── City.swift                    enum + CLLocationCoordinate2D helpers
│   ├── DiscoveryCategory.swift       @Model + nonisolated DiscoveryCategoryDTO
│   ├── DiscoveryRail.swift           struct { DiscoveryCategoryDTO, [Listing] }
│   ├── Listing.swift                 @Model (22 props) + nonisolated ListingDTO + ListingCursor
│   └── ListingFilter.swift           nonisolated struct (city, dates, guests, priceRange)
├── Services/                         9 files
│   ├── AuthManager.swift             @Observable @MainActor — 14-line placeholder
│   ├── CachedImageService.swift      NSCache + URLCache (nonisolated final)
│   ├── CurrencyService.swift         protocol + CurrencyDisplay enum
│   ├── ImageCacheService.swift       protocol
│   ├── ListingService.swift          protocol + DiscoveryFeedDTO
│   ├── LiveCurrencyService.swift     final class, @unchecked Sendable
│   ├── MapboxConfig.swift            enum; reads MBXAccessToken; calls MapboxOptions.accessToken =
│   ├── SupabaseConfig.swift          enum; builds SupabaseClient from Info.plist
│   └── SupabaseListingService.swift  PostgREST queries; nonisolated final
├── ViewModels/                       1 file
│   └── ListingDiscoveryViewModel.swift
├── Views/                            33 files
│   ├── MainTabView.swift
│   ├── Auth/AuthSheetPlaceholderView.swift
│   ├── ListingDetail/ListingDetailPlaceholderView.swift
│   ├── Discovery/
│   │   ├── DiscoveryView.swift       tab-root, owns list↔map toggle
│   │   ├── ListingListView.swift     rails list
│   │   ├── ListingMapView.swift      Mapbox canvas + pin/cluster layout
│   │   ├── SearchSheetView.swift     (renamed from FilterSheetView)
│   │   ├── CategoryRailView.swift    one rail of listing cards
│   │   ├── PriceRangeSlider.swift    dual-thumb slider
│   │   └── Components/               11 subviews
│   │       DiscoveryHeaderPill, DiscoveryHeroHeaderView, FeeInclusionTag,
│   │       FloatingMapIconButton*, ListingPricePin, MapEmptyStatePill,
│   │       MapListingsCarousel*, MapToggleFAB*, PricePinCluster*,
│   │       SearchThisAreaPill*, SelectedListingCard            (* = untracked)
│   └── Shared/                       9 files
│       Buttons, CityChipView, EmptyStateView, ErrorStateView, FavoriteHeartButton,
│       FloatingTabView, ListingCardView, SkeletonListingCard, VerifiedBadgeView
└── Extensions/                       3 files
    ├── CurrencyServiceEnvironment.swift   env key + NoOpCurrencyService
    ├── DesignTokens.swift                 colors, spacing, radii, type tokens
    └── MapConfiguration.swift             static Mogadishu fallback coord + zoom
```

One spec/reality mismatch: `docs/ARCHITECTURE.md` lists `CategoryRailView` under `Views/Discovery/Components/`. Actual path is `Views/Discovery/CategoryRailView.swift`. Cosmetic.

## Data flow — traced example

Cold launch → discovery rails on screen:

1. `MartiApp.init` (`MartiApp.swift:17–25`) calls `MapboxConfig.configure()`, constructs `SupabaseClient(supabaseURL:supabaseKey:)` from `SupabaseConfig` statics, wraps in `SupabaseListingService`, instantiates `LiveCurrencyService()`.
2. `WindowGroup { MainTabView(...) }` attaches `.modelContainer(for: [Listing.self, DiscoveryCategory.self])` (`MartiApp.swift:34`).
3. `MainTabView.body` (`Views/MainTabView.swift:35–64`) renders `FloatingTabView` → in the `.discover` case, builds `ListingDiscoveryViewModel(listingService:currencyService:authManager:modelContext:)` inline (`MainTabView.swift:41–46`) and passes to `DiscoveryView.init`, which stores it via `_viewModel = State(initialValue: viewModel)` (`Views/Discovery/DiscoveryView.swift:43–46`).
4. `DiscoveryView.task` fires `viewModel.loadListings()` if listings are empty (`DiscoveryView.swift:58–62`).
5. `ListingDiscoveryViewModel.loadListings()` (`ViewModels/ListingDiscoveryViewModel.swift:170–210`):
   - Cancels any in-flight `loadTask`.
   - Reads DTO cache via `readCache()` → `[ListingDTO]` (declared at `:367`) and `readCategoryCache()` (`:401`) — never returns `@Model` instances.
   - Seeds `self.listings`/`self.categories` with freshly-constructed detached `Listing(dto:)` / `DiscoveryCategory(dto:)` values.
   - Awaits `listingService.fetchDiscoveryFeed(city:)`.
6. `SupabaseListingService.fetchDiscoveryFeed(city:)` (`Services/SupabaseListingService.swift:60–71`) fires two queries concurrently via `async let`:
   - `fetchCategories(city:)` → `categories` table, filter `city = <X> OR city IS NULL` (`:77–86`).
   - `fetchListingsWithCategories(city:)` → `listings_with_categories` DB view, optional `.eq("city", …)` filter (`:93–101`).
   - Returns `DiscoveryFeedDTO(categories:listings:)`.
7. VM replaces state, calls `writeCache(replacingWith:)` (`:378`) + `writeCategoryCache(replacingWith:)` (`:412`) to upsert the SwiftData cache, sets `hasMorePages = false` (rails don't paginate), clears `isOffline`.
8. On `catch` (`:200–207`): if cache was non-empty → `isOffline = true`, preserve rails. Otherwise `self.error = mapError(error)` (`:353`).

The VM's cache-first comment (`:173–177`) explicitly documents the "DTO only, never attached `@Model`" contract. Fresh `Listing(dto:)` instances live in `self.listings` as detached reference-type carriers — they're never inserted into `modelContext`, which removes the stale-purge crash class.

Pagination (`:222–237` via `loadMore`) uses `ListingCursor(createdAt:id:)` (declared `Models/Listing.swift:5–8`) — composite keyset `(created_at DESC, id DESC)` rendered into PostgREST `.or(...)` at `Services/SupabaseListingService.swift:34–38`.

## State management

| State                         | Owner                                                                            | Binding                 |
| ----------------------------- | -------------------------------------------------------------------------------- | ----------------------- |
| Auth state                    | `AuthManager` — `@State` on `MainTabView.swift:7`, `.environment(auth)` line 61  | `@Environment(AuthManager.self)` (e.g. `Views/Auth/AuthSheetPlaceholderView.swift:6`); **also** injected via constructor to VM (`MainTabView.swift:44`). |
| Screen state (filter, rails)  | `ListingDiscoveryViewModel` @ `DiscoveryView.swift:4` (`@State`)                 | `@Bindable` in subviews — `ListingListView`, `ListingMapView`, `SearchSheetView`, `DiscoveryHeroHeaderView`. |
| View-local UI                 | `@State` on individual views (e.g. `mapBottomChromeHeight` `DiscoveryView.swift:15`, `recenterTrigger` `:28`) | Direct. |
| Floating tab bar helper       | `FloatingTabViewHelper` (`@Observable @MainActor`) `Views/Shared/FloatingTabView.swift:32–36`  | `.environment(helper)` at `:105`. |
| Currency service              | `LiveCurrencyService` — from `MartiApp.init()`                                   | `@Environment(\.currencyService)` via custom key `Extensions/CurrencyServiceEnvironment.swift`. |
| Model context                 | SwiftData container declared `MartiApp.swift:34`                                 | `@Environment(\.modelContext)` read at `MainTabView.swift:9`, forwarded to VM ctor. |

Verified absent across the whole codebase: `@ObservedObject`, `@EnvironmentObject`, `@AppStorage`, `@Query`, singletons beyond Apple's (`FileManager`, `URLSession.shared`), `.preferredColorScheme(.light)`. Only `.preferredColorScheme(.dark)` at `MainTabView.swift:63`.

## Persistence

| Data                            | Storage                                                                                          | Notes                                                                                             |
| ------------------------------- | ------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------- |
| Listings                        | SwiftData `@Model Listing` (`Models/Listing.swift:4–75`); cache reads return DTOs (`ViewModels/ListingDiscoveryViewModel.swift:367`) | Migration-safe default `categoryIDs: [UUID] = []` (line 28); decoder fallback `?? []` at `:197`. |
| Categories                      | SwiftData `@Model DiscoveryCategory` (`Models/DiscoveryCategory.swift:4–32`)                     | Two types in container; declared `MartiApp.swift:34`.                                             |
| Currency rate + timestamp       | `UserDefaults` keys `currency.usdToSosRate`, `currency.usdToSosFetchedAt` (`Services/LiveCurrencyService.swift:6–7`) | Injectable defaults default to `.standard`. 24h refresh, 7d hard stale cutoff.                    |
| Fee-inclusion toast dismissal   | `UserDefaults` key `discovery.feeTagDismissed` (`ViewModels/ListingDiscoveryViewModel.swift:138`) | VM takes injectable `userDefaults:` (default `.standard`).                                        |
| Image bytes                     | Custom `URLCache(diskCapacity: 200 MB)` with `.returnCacheDataElseLoad` (`Services/CachedImageService.swift:17–19`) | Own `URLSession` — not `.shared`.                                                                 |
| Decoded `UIImage`               | `NSCache<NSURL, UIImage>` count-limit 50, marked `nonisolated(unsafe)` (`Services/CachedImageService.swift:9`) | Failures return `nil` silently — no logging.                                                      |
| Saved listings                  | Supabase table `saved_listings` only (`Services/SupabaseListingService.swift:111–135`, RLS in `docs/db/001_listings.sql:39–62`) | No local mirror — opposite of listings/categories.                                                |
| Auth tokens                     | **None shipped.** `AuthManager` is a 14-line bool holder (`Services/AuthManager.swift:6–14`) flipped by `AuthSheetPlaceholderView`. Keychain plumbing is planned but unwritten. | Spec calls out Keychain for when real auth lands.                                                 |

## Networking

- **Supabase SDK 2.43.1.** Single `SupabaseClient` in `MartiApp.init()` (line 19–22), injected into `SupabaseListingService`. Client also used for `auth.user()` at `Services/SupabaseListingService.swift:112`. No Realtime, no Storage, no Auth UI wired.
- **Raw `URLSession`** at exactly two call sites:
  - `CachedImageService.loadImage(from:)` (`:31–46`) — custom session + `URLCache`.
  - `LiveCurrencyService.refreshRate()` (`:40–64`) — `URLSession.shared`, hardcoded endpoint `https://open.er-api.com/v6/latest/USD` (`:19`), no API key (free tier).
- **Pagination.** Keyset cursor implemented in `SupabaseListingService.fetchListings(filter:cursor:limit:)` (`:21–53`). Cursor-after render at `:34–38`:
  ```swift
  query = query.or("created_at.lt.\(ts),and(created_at.eq.\(ts),id.lt.\(cursor.id.uuidString))")
  ```
  Default limit 20 (`Services/ListingService.swift` protocol extension). Empty response signals end of pages.
- **Error mapping.** `SupabaseListingService.map(_:)` at `:139–147`: preserve `AppError`, coerce `URLError` → `.network(localizedDescription)`, everything else → `.unknown(localizedDescription)`. No Supabase-specific error shapes surfaced.
- **Offline handling.** VM-level. `ListingDiscoveryViewModel.loadListings()` sets `isOffline = true` when cache is non-empty on error (`:202–204`) — banner shown but rails stay on screen. `loadMore` (`:222–237`) just surfaces `AppError`.
- **No Combine, no completion handlers, no long-lived subscriptions.** All `async`/`await`. Two `Task<Void, Never>?` handles stored on the VM (`loadTask`, `debounceTask` — `:142–143`); cancelled on task re-entry and on filter changes.

## Background & system integration

- **Absent:** `BGTaskScheduler`, `WidgetKit`, `UNUserNotificationCenter`, `CLLocationManager`, analytics SDK, deep-link router, Universal Links, `SwiftUI.openURL` routing.
- **CoreLocation** imported only for the `CLLocationCoordinate2D` value type. `Extensions/MapConfiguration.swift` hardcodes a static Mogadishu fallback (2.0469°N, 45.3182°E, zoom 12.5) — the seam for a future `UserLocationService`, as noted in its doc comment.
- **Haptics** via `.sensoryFeedback(.impact(...))`:
  - Tab bar — `Views/Shared/FloatingTabView.swift` (`hapticsTrigger`).
  - Save heart toggle — `Views/Shared/FavoriteHeartButton.swift`.
  - Search-this-area pill — `Views/Discovery/Components/SearchThisAreaPill.swift` (untracked).
  - Map-mode FAB — `Views/Discovery/Components/MapToggleFAB.swift` (untracked).
- **Reduce Motion** respected via `@Environment(\.accessibilityReduceMotion)` — checked in `ListingPricePin` (idle→selected animation), `SelectedListingCard` (spring entry), others.

## Security & privacy

- **Secrets in `Info.plist`:**
  - `SUPABASE_URL` — project URL (public).
  - `SUPABASE_ANON_KEY` — publishable anon key (public; matches `sb_publishable_` convention; gated by RLS server-side).
  - `MBXAccessToken` — Mapbox **public** token.
  Mapbox **secret** token is not in the repo — expected to live in `~/.netrc` per `.claude/rules/gotchas.md`.
- **Row-Level Security** in `docs/db/001_listings.sql:39–62` and `docs/db/003_categories.sql`:
  - `listings`, `categories`, `listing_categories` — public `SELECT` (anon + authenticated).
  - `saved_listings` — SELECT/INSERT/DELETE all gated on `auth.uid() = user_id`.
- **Force-unwraps / `fatalError`** only in startup config paths (misconfigured build = fail fast):
  - `SupabaseConfig.url` (`:10`) and `.anonKey` (`:19`).
  - `MapboxConfig.accessToken` (`:9`).
  - `LiveCurrencyService` hardcoded endpoint URL (`:19`, `URL(string:)!`).
- **Not verified in this audit** (noted for next pass):
  - No `Marti.entitlements` file found — no Keychain, App Groups, Push, Associated Domains configured.
  - No privacy usage-description keys (`NSCameraUsageDescription` etc.) in `Info.plist`. Acceptable today — no feature currently touches sensitive APIs; required the moment Camera/Photos/Location ships.
  - No ATS exception keys. Good — HTTPS enforced.
  - Keychain integration is **not written** — `AuthManager` is a bool.

## Testing coverage

**Framework:** Swift Testing (`@Test`, `#expect`, `@Suite`). XCTest is confined to `MartiUITests` (placeholder stubs).

**Unit target — `MartiTests/` — 10 files, ~76 tests:**

| Suite                                | Tests | Notes                                                                                   |
| ------------------------------------ | ----- | --------------------------------------------------------------------------------------- |
| `ListingDiscoveryViewModelTests`     | 40    | Happy/error/offline/pagination/save-toggle/pin-selection/model-context-safety regression. |
| `CachedImageServiceTests`            | 5     | `StubURLProtocol` + `@Suite(.serialized)` for shared responder closure.                  |
| `LiveCurrencyServiceTests`           | 9     | Format (abbreviated/full), 24h refresh gate, 7d stale cutoff, injectable `now:`.         |
| `MockListingServiceTests`            | 7     | Verifies the test double itself (handler injection, call counting).                     |
| `ListingFilterTests`                 | 3     | Defaults + static `.default`.                                                            |
| `ListingTests`                       | 5     | `ListingDTO` Codable round-trip; DTO ↔ model mapping.                                    |
| `FavoriteHeartButtonTests`           | 2     | 28pt/44pt visual vs 44pt hit target.                                                     |
| `ListingPricePinTests`               | 2     | VoiceOver labels (saved / unsaved).                                                      |
| `VerifiedBadgeViewTests`             | 2     | Default variant = `.icon`.                                                               |

**Not tested:** `SupabaseListingService` (no integration harness), `AuthManager`, the 5 untracked Discovery components. Views outside design-system primitives are intentionally not unit-tested (spec rule).

**Mock/stub patterns:**
- Closure-injected mocks conforming to protocols (`MockListingService` with `fetchHandler`, `toggleHandler`, …).
- `StubURLProtocol` subclass for `URLSession` interception.
- `Locked<T>` NSLock wrapper for assertions under concurrent tests.
- `@Suite(.serialized)` applied exactly where required (shared-state stub).

**UI tests:** `MartiUITests/` — XCTest, 3 placeholder tests (`testExample`, `testLaunchPerformance`, `testLaunch`). Matches the "UI tests flaky in CI" posture in `.claude/rules/build.md`.

**Coverage gaps worth naming:** `ListingMapView` + Mapbox projection/cluster math (`recomputeAnnotationLayout` in `Views/Discovery/ListingMapView.swift`) has no tests. Reasonable given the spec rule against testing view bodies, but the cluster union-find + deterministic ID-hash logic is business logic living in a view — a test-worthy seam if it gets extracted.

## Drift from `docs/ARCHITECTURE.md`

1. **Redundant `AuthManager` injection.** `AuthManager` is in the environment (`.environment(auth)` at `Views/MainTabView.swift:61`), which matches the spec. It is **also** passed as a constructor argument to `ListingDiscoveryViewModel(authManager:)` at `MainTabView.swift:44`. `AuthSheetPlaceholderView` reads it from the environment (`Views/Auth/AuthSheetPlaceholderView.swift:6`); the VM reads it from its stored `authManager` property. Pick one: environment is cleaner and matches the "Environment-scoped shared state" line in `docs/ARCHITECTURE.md §State management`.
2. **`AuthManager` installed at `MainTabView`, not `MartiApp`.** Since `MainTabView` is the `WindowGroup` root, scope is effectively the same — but if a second root-level surface ever appears (auth splash, welcome screen), the placement becomes load-bearing. Moving the `@State var auth = AuthManager()` + `.environment(auth)` up to `MartiApp`'s scene body is a no-cost alignment with spec.
3. **VM constructed inside a `ViewBuilder` closure.** `ListingDiscoveryViewModel(...)` is built inline in the `.discover` `switch` case at `MainTabView.swift:41–46`. `@State(initialValue:)` on `DiscoveryView.swift:44` preserves identity across body re-evals, so filters/camera/scroll survive — **state is not lost**. But `MainTabView` allocates a throwaway VM on every body pass. Hoist the VM to `@State` on `MainTabView` (or use a factory closure) to avoid the allocation churn and make ownership explicit.
4. **Mapbox pinned to `main`.** `Package.resolved` shows `mapbox-maps-ios` tracking branch `main` (commit `53d142e`), with `mapbox-common-ios` on `24.23.0-SNAPSHOT-04-16--02-05` and `mapbox-core-maps-ios` on `11.23.0-SNAPSHOT-04-16--02-05`. Already called out in `.claude/rules/gotchas.md` but reiterating: must tag to a v11 release before App Store submission. Every teammate fresh-clone gets a different commit.
5. **`ContentView.swift` is dead.** Xcode-template "Hello, world!" globe stub at `ContentView.swift:10–19`. Nothing references it; `MartiApp` roots on `MainTabView`. Safe to delete.
6. **Five Discovery map-mode components untracked.** `FloatingMapIconButton`, `MapListingsCarousel`, `MapToggleFAB`, `PricePinCluster`, `SearchThisAreaPill`. Modified (tracked) `DiscoveryView.swift` / `ListingMapView.swift` reference them, so the `dev` branch does not compile from a clean fresh checkout of HEAD without including the untracked files. In-flight work, not drift in the strict sense, but worth naming because an out-of-sync checkout right now will not build.
7. **`Views/Discovery/CategoryRailView.swift` lives outside `Components/`.** Spec layout shows it under `Components/`; actual file is at the `Discovery/` level. Cosmetic only.

## Smells observed

- **`LiveCurrencyService` is `@unchecked Sendable`** (`:5`). All stored properties are `let` of Sendable types (`URLSession`, `UserDefaults`, `URL`, `@Sendable () -> Date`). `@unchecked` is unnecessary — plain `Sendable` conformance compiles.
- **`SearchSheetView.destinationQuery` is a dead input.** The field exists with a TODO note ("wire to search service when v2 adds destination-text search"). Accepting keystrokes into an unused `@State` is a footgun; hide the field until the server-side search lands.
- **`CachedImageService` swallows all failures to `nil`.** Both `loadImage(from:)` branches (non-2xx response, `UIImage(data:)` failure) return `nil` without logging. In the field, a silent failure mode against photos hosted on Supabase Storage will be hard to diagnose — at least `os_log` the URL + status.
- **Listing/category cache purge strategy not obvious from code.** `writeCache(replacingWith:)` and `writeCategoryCache(replacingWith:)` (`ViewModels/ListingDiscoveryViewModel.swift:378, :412`) exist but the name implies full-replace. If the app ever ships partial rail fetches or section-level paging, this strategy needs rethinking; today it is fine because rails load as a single feed.
- **Two casings for the project folder coexist.** `git status` shows entries under both `marti/marti/...` (index) and `Marti/Marti/...` (working tree new files). macOS default filesystem is case-insensitive so builds work, but on a case-sensitive volume (CI runner, Linux container) this could bite. Prefer the `Marti/Marti/` casing the Xcode project uses.

## Open questions

1. Should `AuthManager` move up to `MartiApp` scope with a single source of injection (environment), and be removed from the `ListingDiscoveryViewModel` constructor?
2. Is inline VM construction in `MainTabView`'s `ViewBuilder` intentional (readability), or a candidate for a `@State`-owned VM as more feature tabs come online?
3. When does Mapbox pin to a release tag? (App Store gate.)
4. Is `AccentColor.colorset` being kept empty intentional (spec notes the only `.tint(...)` passes `Color.coreAccent`), or should the asset be deleted outright?
5. Delete `ContentView.swift`, or keep as a scratch file?
6. Should the Mapbox cluster layout in `ListingMapView.recomputeAnnotationLayout` be extracted to a testable pure function? The clustering is genuine business logic currently living in a view body.

## Diff vs prior audit

No prior dated audit. `docs/audits/intent-architecture.md` and `intent-design.md` predate the audit convention — they are v0 planning artifacts, not dated snapshots. This file is the baseline.

---

## Summary

Architecture matches spec in nearly every load-bearing way: MVVM + `@Observable`, DTO/@Model split, protocol-based services, Swift 6 strict concurrency, SwiftData-as-cache + Supabase-as-truth, keyset pagination, offline-with-cache pattern. The drift is small and all correctable in trivial PRs.

**Three concrete items worth addressing before the next feature lands:**

1. **Pin Mapbox to a v11 release tag.** Highest blast radius — `main` branch pinning means fresh clones drift out from under committed code. App Store submission is blocked until this is fixed anyway. (`Marti.xcodeproj/project.pbxproj` SPM reference + `Package.resolved`.)
2. **Consolidate `AuthManager` injection to the environment.** Today it's in both the environment and the VM ctor. Pick environment, remove the `authManager:` constructor parameter from `ListingDiscoveryViewModel`, read `@Environment(AuthManager.self)` inside the VM (or its parent view, if that's the pattern the team prefers). Tightens every future feature VM's ctor.
3. **Delete `ContentView.swift`, or make it the root.** The Xcode-template stub serves no purpose and will confuse the next reader who greps for "Hello, world!". If it's being kept as a splash or placeholder for auth-gated surfaces, add a comment saying so. Otherwise delete.
