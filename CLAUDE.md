# Project: Marti

Marti — a short-term rental marketplace connecting travelers with verified hosts across Somalia and the Horn of Africa, built for the Somali diaspora visiting home and business travelers seeking trusted local stays.

## Stack

- **Language:** Swift 6 (strict concurrency on; `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`)
- **UI:** SwiftUI
- **Architecture:** MVVM
- **State:** `@Observable` macro (not `ObservableObject`)
- **Testing:** Swift Testing (`@Test`, `#expect`) — not XCTest
- **Persistence:** SwiftData (`@Model`) for local cache; Supabase for source of truth
- **Networking:** `URLSession` + async/await; Supabase Swift SDK
- **Map:** Mapbox Maps iOS SDK v11 (declarative SwiftUI API)
- **Deployment target:** iOS 26.2
- **Xcode:** 26.x

## Feature status

- ✅ **Listing Discovery** — complete (see `docs/tasks/listing-discovery.md`)
- 🚧 **Listing Detail** — next
- 🚧 **Auth** — placeholder sheet; real sign-in pending
- 🚧 **Booking** — depends on Listing Detail
- 🚧 **Messaging / Reviews / Profile** — later

## Build / Test / Run

No XcodeBuildMCP — use `xcodebuild` directly.

```bash
# Build
xcodebuild -project marti/Marti.xcodeproj -scheme Marti \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Unit tests only (UI tests sometimes fail to launch in CI)
xcodebuild -project marti/Marti.xcodeproj -scheme Marti \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:MartiTests test

# Install + launch on booted simulator
xcrun simctl install booted /path/to/Marti.app
xcrun simctl launch booted so.Marti
```

Default simulator: **iPhone 17 Pro** (Xcode 26.x doesn't ship iPhone 16 Pro by default).

## Architecture rules

- **Views are dumb.** No business logic, no networking, no persistence in `View` bodies.
- **ViewModels are `@Observable` classes**, one per screen. Inject dependencies via initializer.
- **Models are pure Swift value types** except SwiftData `@Model` classes, which are reference types by necessity. Pair `@Model` with a Codable DTO struct (`Listing` + `ListingDTO`) and map between them at the service boundary.
- **Services are protocol + concrete implementation.** Protocol lives next to the implementation.
- **No singletons** except Apple-provided ones (`FileManager`, `URLSession.shared`, etc.).
- **No global state.** Everything flows through ViewModels or environment.

## File layout

```
marti/Marti/
├── MartiApp.swift                 — @main entry, composes services into MainTabView
├── Info.plist                     — SUPABASE_URL / SUPABASE_ANON_KEY / MBXAccessToken
├── Models/                        — Listing (@Model) + ListingDTO, ListingFilter, City, AppError,
│                                     DiscoveryCategory (@Model) + DiscoveryCategoryDTO, DiscoveryRail
├── Services/                      — protocol + concrete impl pairs
├── ViewModels/                    — @Observable classes, one per screen
├── Views/
│   ├── MainTabView.swift          — composes FloatingTabView
│   ├── Shared/                    — FloatingTabView, ListingCardView, CityChipView, EmptyStateView,
│   │                                 ErrorStateView (+ OfflineBannerView), SkeletonListingCard,
│   │                                 Buttons (PrimaryButtonStyle + GhostButtonStyle),
│   │                                 FavoriteHeartButton, VerifiedBadgeView
│   ├── Discovery/
│   │   ├── DiscoveryView.swift    — list + map layouts, filter / auth sheets
│   │   ├── ListingListView.swift
│   │   ├── ListingMapView.swift   — Mapbox v11 declarative Map
│   │   ├── CategoryRailView.swift — horizontal rail (rail variant of ListingCardView)
│   │   ├── FilterSheetView.swift
│   │   ├── PriceRangeSlider.swift
│   │   └── Components/            — DiscoveryHeaderPill, FeeInclusionTag, ListingPricePin,
│   │                                 MapEmptyStatePill, SelectedListingCard
│   ├── ListingDetail/             — placeholder for now
│   └── Auth/                      — placeholder auth sheet
├── Extensions/
│   ├── DesignTokens.swift         — Colors/Spacing/Radius/Font helpers (see DESIGN.md)
│   └── CurrencyServiceEnvironment.swift
└── Assets.xcassets

marti/MartiTests/
├── Models/
├── Services/
├── ViewModels/                    — ListingDiscoveryViewModelTests (the bulk of the suite)
└── Views/                         — FavoriteHeartButtonTests (component constants)

docs/
├── PRD.md                         — Product Requirements Document
├── ARCHITECTURE.md                — observed architecture (regenerate via /audit-architecture)
├── DESIGN.md                      — observed design system (regenerate via /audit-design)
├── specs/                         — per-feature specs
├── tasks/                         — per-feature task trackers
└── db/                            — SQL migrations:
                                      001_listings.sql, 002_sample_listings.sql,
                                      003_categories.sql, 004_sample_categories.sql
```

## Development workflow

For new features, follow the PRD workflow:

1. `/create-prd` — at project start, generate `docs/PRD.md`.
2. `/generate-spec <feature>` — generate `docs/specs/<feature>.md` from the PRD.
3. `/generate-tasks <feature>` — break the spec into ordered tasks.
4. `/new-feature <feature>` — implement, test, build, HIG-review.
5. `/build`, `/test`, `/run-app` — quick standalone commands.
6. `/ship-prep` — App Store readiness check before submission.

## Code style

- Follow the [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/) without exceptions.
- Prefer `let` over `var`. Prefer value types over reference types.
- `async`/`await` over completion handlers. No Combine for new code.
- Force unwraps (`!`) are banned outside `@IBOutlets` and tests.
- Use `guard` for early returns, not nested `if`.
- Comments explain _why_, not _what_. Self-documenting code first.
- Keep functions under ~20 lines. Extract when they grow.

## SwiftUI rules

- Use `@State` for view-local state only.
- Use `@Bindable` (not `@ObservedObject`) for `@Observable` ViewModels.
- Extract subviews when a body exceeds ~50 lines.
- Prefer `ViewBuilder` closures over `AnyView`.
- Use SF Symbols for all icons. No raster icons unless brand assets.
- Always provide `.accessibilityLabel` on interactive elements without visible text.
- Test layouts at AX5 (largest accessibility size).
- For Swift 6 strict concurrency, mark value-type models `nonisolated` (e.g. `nonisolated struct ListingDTO`) so Codable/Equatable conformances don't get stuck on `MainActor`.

## Testing

- Use Swift Testing for all new tests (`@Test`, `#expect`, `#require`).
- Test ViewModels and Services. Do not test SwiftUI view bodies.
- Snapshot tests are reserved for design-system primitives only.
- One test file per ViewModel, mirroring the source folder structure.
- Mock services by conforming a test double to the service protocol. No mocking frameworks.
- For suites sharing mutable static state (e.g. a `StubURLProtocol` responder), annotate with `@Suite(.serialized)` to prevent Swift Testing's default parallel execution from racing.
- Cover happy path, error path, and edge cases (empty, nil, boundary).

## Dependencies

- **Default policy:** no third-party SPM packages without explicit approval.
- **Currently approved:**
  - [`supabase-swift`](https://github.com/supabase/supabase-swift) @ 2.43.1
  - [`mapbox-maps-ios`](https://github.com/mapbox/mapbox-maps-ios) @ `main` — ⚠️ pin to a v11 release tag before App Store submission
- Prefer Apple frameworks. Reach for third-party only when the cost of building it ourselves is clearly higher.

## What NOT to do

- Don't write UIKit code unless explicitly requested (tab bar appearance tweaks via `UITabBar.appearance()` are the exception because SwiftUI doesn't expose those knobs).
- Don't use deprecated APIs (`NavigationView`, single-param `.onChange`, etc.).
- Don't generate App Icons or Launch Screens — these are designed manually.
- Don't add lorem ipsum placeholder text. Ask for real copy or use realistic examples.
- Don't auto-format the project unless asked.
- Don't add AI attribution to commit messages, PRs, or code comments.

## Project-specific notes

- **Prices stored as Int (USD cents).** `8500` = `$85.00`. Avoid floating-point math on money.
- **Two currency displays.** Cards show abbreviated SOS (`~1.5M SOS`); detail/booking screens show full numbers (`~1,530,000 SOS`). Abstraction lives in `LiveCurrencyService.format(sos:display:)`.
- **Browse-first auth.** App launches straight into Discovery. Auth gate lives on save/book/message actions; `AuthManager` is in the environment and checked via `authManager.isAuthenticated`.
- **SwiftData as cache, Supabase as truth.** Writes always hit Supabase first. `ViewModel.loadListings()` reads cache first for instant display, then refetches network and upserts into the cache, deleting stale rows.
- **Image cache is generic**, not listing-specific — reused by any remote-image view.
- **Supabase publishable key is public-by-design.** Committed in `Info.plist`. RLS policies protect data. The Mapbox **secret** token lives only in `~/.netrc`.
- **Date availability filter is stubbed.** Will hook into the `bookings` table once that feature ships.
- **`Package.resolved` is committed.** Keep SPM pin stable across dev machines.
- **Mapbox pin is currently `main`.** Before shipping, pin to a v11 release tag and rerun SPM resolution.
- **iOS 26 quirk:** `ScrollView` inside a `Tab` with `.toolbarVisibility(.hidden, for: .tabBar)` doesn't respect `.safeAreaInset` or `.safeAreaPadding` from ancestors. `FloatingTabView` works around this with a canvas-masked home-indicator area approach; see `Views/Shared/FloatingTabView.swift`.
