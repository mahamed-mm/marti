# Marti

Short-term rental marketplace connecting travelers with verified hosts across Somalia and the Horn of Africa — built for the Somali diaspora visiting home and business travelers seeking trusted local stays.

iOS, SwiftUI, Swift 6, Supabase, Mapbox.

---

## Status

**v1 — Listing Discovery feature complete.** The Discover tab ships the list view, map view (Mapbox), filter sheet, and empty / error / loading states. Real listings are served from Supabase. Photos, verified badges, ratings, USD + SOS pricing all rendered.

What's shipped:
- Discovery (list + map with Mapbox, filters, skeleton / empty / error states)
- Floating tab bar with fade-on-detail behavior
- SwiftData offline cache
- Supabase client wired with Row-Level Security
- USD → SOS currency conversion (open.er-api.com, 24h cache)
- Image caching layer (NSCache + URLCache)
- 43 unit tests passing

What's deferred (explicit):
- Listing Detail feature (next)
- Auth (placeholder sheet toggles `isAuthenticated` for now)
- Bookings → date availability filter will land with it
- Pin Mapbox SDK to a v11 release tag before shipping
- Insert live-count query for "Show X listings" CTA

Full progress: [`docs/tasks/listing-discovery.md`](docs/tasks/listing-discovery.md).

---

## Tech stack

| Layer | Tool |
|---|---|
| Language | Swift 6 (strict concurrency, default actor isolation = `MainActor`) |
| UI | SwiftUI, iOS 26 SDK (deployment target 26.2) |
| Architecture | MVVM with `@Observable` ViewModels |
| Persistence | SwiftData (`@Model`) for local cache; Supabase Postgres for source of truth |
| Networking | `URLSession` + `async/await`; Supabase Swift SDK for PostgREST/Auth/Realtime |
| Map | Mapbox Maps iOS SDK v11 (declarative `Map` / `MapViewAnnotation`) |
| Testing | Swift Testing (`@Test`, `#expect`) |
| Xcode | 26.x (simulator: iPhone 17 Pro) |

---

## Dependencies (SPM)

| Package | Version |
|---|---|
| [`supabase-swift`](https://github.com/supabase/supabase-swift) | 2.43.1 (up-to-next-major) |
| [`mapbox-maps-ios`](https://github.com/mapbox/mapbox-maps-ios) | `main` branch — ⚠️ pin to a v11 release tag before App Store submission |

---

## Getting started

### 1. Clone

```bash
gh repo clone <your-org>/marti
cd marti
```

### 2. Mapbox credentials

Mapbox's SPM package pulls binary frameworks from a secure download URL. It authenticates via `~/.netrc`.

1. Create a **secret** access token at [account.mapbox.com/access-tokens](https://account.mapbox.com/access-tokens/) with the `DOWNLOADS:READ` scope enabled. It starts with `sk.…`.
2. Create / edit `~/.netrc`:

   ```
   machine api.mapbox.com
   login mapbox
   password sk.YourSecretTokenHere
   ```

   Make sure the file ends with a newline and `password ` is on its own line with the literal keyword.

3. `chmod 0600 ~/.netrc`

You also need a **public** token (starts with `pk.…`) for the runtime SDK. This goes in `marti/Marti/Info.plist` under `MBXAccessToken` — already committed as a placeholder. Replace with your own if you're forking.

### 3. Supabase

1. Create a Supabase project. Copy the **Project URL** and **publishable key** (formerly "anon key") from Settings → API.
2. Paste them into `marti/Marti/Info.plist`:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
3. Run the two SQL files against your Supabase project, in order:
   - `docs/db/001_listings.sql` — schema + RLS policies
   - `docs/db/002_sample_listings.sql` — six sample rows (idempotent)

### 4. Build

```bash
xcodebuild \
  -project marti/Marti.xcodeproj \
  -scheme Marti \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build
```

Or open `marti/Marti.xcodeproj` in Xcode 26 and ⌘R.

### 5. Run tests

```bash
xcodebuild \
  -project marti/Marti.xcodeproj \
  -scheme Marti \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:MartiTests \
  test
```

---

## Project layout

```
marti/Marti/
├── MartiApp.swift                 — @main; configures Supabase client, Mapbox, ModelContainer
├── Info.plist                     — SUPABASE_URL / SUPABASE_ANON_KEY / MBXAccessToken
├── Assets.xcassets
├── Models/                        — Listing (@Model) + ListingDTO, ListingFilter, City, AppError
├── Services/
│   ├── AuthManager.swift          — minimal auth state (@Observable) — full sign-in flow pending
│   ├── CurrencyService.swift      — protocol + display enum
│   ├── LiveCurrencyService.swift  — open.er-api.com + UserDefaults cache
│   ├── ImageCacheService.swift    — protocol
│   ├── CachedImageService.swift   — NSCache memory + URLCache disk
│   ├── ListingService.swift       — protocol
│   ├── SupabaseListingService.swift — PostgREST impl
│   ├── SupabaseConfig.swift       — reads Info.plist
│   └── MapboxConfig.swift         — sets MapboxOptions.accessToken at launch
├── ViewModels/
│   └── ListingDiscoveryViewModel.swift
├── Views/
│   ├── MainTabView.swift          — uses FloatingTabView
│   ├── Shared/
│   │   ├── FloatingTabView.swift  — generic container, config, hide helper
│   │   ├── ListingCardView.swift  — 3 variants: .full / .compact / .mapPreview
│   │   ├── CityChipView.swift
│   │   ├── SkeletonListingCard.swift + SkeletonHeader
│   │   ├── EmptyStateView.swift
│   │   └── ErrorStateView.swift + OfflineBannerView
│   ├── Discovery/
│   │   ├── DiscoveryView.swift    — list + map layouts
│   │   ├── ListingListView.swift
│   │   ├── ListingMapView.swift   — Mapbox declarative Map
│   │   ├── FilterSheetView.swift
│   │   └── PriceRangeSlider.swift
│   ├── ListingDetail/
│   │   └── ListingDetailPlaceholderView.swift
│   └── Auth/
│       └── AuthSheetPlaceholderView.swift
└── Extensions/
    ├── DesignTokens.swift         — colors, spacing, radius, fonts from DESIGN.md
    └── CurrencyServiceEnvironment.swift

marti/MartiTests/
├── Models/
└── Services/
└── ViewModels/
    └── ListingDiscoveryViewModelTests.swift   — 15 tests, all passing

docs/
├── PRD.md               — Product Requirements
├── ARCHITECTURE.md      — high-level architecture decisions
├── DESIGN.md            — design system (tokens, typography, components)
├── specs/               — per-feature specs
├── tasks/               — per-feature task trackers
└── db/                  — SQL migrations + sample data
```

---

## Key architectural rules

- **Views are dumb** — no networking, no persistence, no business logic in `View` bodies.
- **ViewModels are `@Observable` classes** — one per screen, dependencies injected via init.
- **Services are protocol + concrete impl** — mocks conform to the same protocol (no mocking frameworks).
- **SwiftData is local cache only** — Supabase is the source of truth. Writes always hit Supabase first.
- **Browse-first auth** — app launches straight into Discovery; auth triggers lazily on save / book / message.
- **No third-party packages without explicit approval** — current whitelist: `supabase-swift`, `mapbox-maps-ios`.

Full details: [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) and [`docs/DESIGN.md`](docs/DESIGN.md).

---

## Workflow for new features

1. `/generate-spec <feature>` → writes `docs/specs/<feature>.md` from the PRD.
2. `/generate-tasks <feature>` → breaks the spec into ordered tasks in `docs/tasks/<feature>.md`.
3. `/new-feature <feature>` → implements, tests, builds, HIG-reviews.

---

## License

TBD.
