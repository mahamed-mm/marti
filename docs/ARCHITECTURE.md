# Architecture: Marti

The shape of the app, the rules that apply to every feature, and where things live. Audits live in `docs/audits/`.

For architectural _rules_ (Views dumb, VMs `@Observable`, etc.) see @.claude/rules/architecture.md. This doc covers structure and patterns.

## Overview

Single-target SwiftUI iOS 26.2 app. MVVM with `@Observable` ViewModels, SwiftData as a local cache, Supabase (PostgREST) as source of truth. Mapbox v11 renders the map. One ViewModel per screen; shared state holders flow through the environment. Networking is the Supabase Swift SDK plus a couple of `URLSession` outliers. Strict Swift 6 concurrency (`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`).

## Module structure

Single Xcode target `Marti` inside `marti/Marti.xcodeproj`. Two test targets (`MartiTests`, `MartiUITests`). No Swift packages. Uses `PBXFileSystemSynchronizedRootGroup` — files in the on-disk folder structure compile without explicit project entries.

```
marti/Marti/
├── MartiApp.swift              — @main; builds SupabaseClient + services; installs modelContainer
├── Info.plist                  — SUPABASE_URL / SUPABASE_ANON_KEY / MBXAccessToken
├── Assets.xcassets             — AccentColor, AppIcon
├── Models/                     — Pure value types + paired @Model/DTO
├── Services/                   — Protocol + impl, one file per concern
├── ViewModels/                 — One @Observable class per screen
├── Views/
│   ├── MainTabView.swift       — Tab host
│   ├── Auth/                   — Auth sheets
│   ├── Discovery/              — Listing discovery (list + map)
│   │   └── Components/         — Discovery-specific subviews
│   ├── ListingDetail/          — Listing detail (in progress)
│   └── Shared/                 — Reusable: FloatingTabView, ListingCardView, buttons, banners…
└── Extensions/                 — DesignTokens, MapConfiguration, environment keys
```

## Patterns

### Model ↔ DTO pairing

Every persisted entity has two types:

- **`@Model` reference type** (e.g. `Listing`) — SwiftData cache row, `@MainActor` by default.
- **`nonisolated struct …DTO` value type** (e.g. `ListingDTO`) — Codable, snake_case mapped, the wire format.

Map at the service boundary: `Listing(dto:)` to hydrate, `ListingDTO(model:)` to send back.

The cache **read path returns DTOs**, never attached `@Model` instances. Prevents a concurrent stale-purge from detaching a model still held by a View.

### Service shape

- Protocol + concrete impl, both in the same file.
- Dependencies injected via init — never read globally.
- Errors mapped to `AppError` at the service boundary. URL errors → `.network`; preserve `AppError`s; everything else → `.unknown`.

### Cache + truth flow

1. ViewModel reads cache (DTOs) → seeds UI immediately.
2. ViewModel awaits service call.
3. On success: replace in-memory state, upsert cache, purge stale.
4. On failure with non-empty cache: flip `isOffline = true` instead of surfacing an error.

### Pagination

Keyset pagination over `(created_at DESC, id DESC)` via PostgREST `or(...)` cursor. Implemented in `SupabaseListingService.fetchListings`.

### Migration safety

- New `@Model` properties get a default value so pre-migration cached rows decode.
- DTO `init(from:)` uses `decodeIfPresent` for fields that aren't on every PostgREST view.

## Persistence

| Data                            | Storage                                                                |
| ------------------------------- | ---------------------------------------------------------------------- |
| Listings, Categories            | SwiftData `@Model` (`Models/`)                                         |
| Currency rate + timestamp       | `UserDefaults` (`currency.usdToSosRate`, `currency.usdToSosFetchedAt`) |
| Onboarding flags (e.g. fee tag) | `UserDefaults`, injected into VMs (default `.standard`)                |
| Image bytes                     | `URLCache` (200 MB disk) inside `CachedImageService`                   |
| Decoded `UIImage`               | `NSCache<NSURL, UIImage>` (count limit 50) inside `CachedImageService` |
| Auth tokens                     | **Plan: Keychain.** No real auth flow shipped yet.                     |
| Saved listings                  | Supabase `saved_listings` only (no local mirror)                       |

`@Model` container declared at `MartiApp` root via `.modelContainer(for: [Listing.self, DiscoveryCategory.self])`.

## Networking

- **Supabase Swift SDK** — used exclusively inside services for PostgREST.
- **`URLSession`** — only inside `CachedImageService` (own session, custom `URLCache`) and `LiveCurrencyService` (`URLSession.shared`).
- **No Combine. No completion handlers. No long-lived subscriptions.** Everything is `async`/`await`. Long tasks are held as `Task` handles on the VM so they can be cancelled.
- **Offline:** services throw; VMs catch and gate behind `isOffline = true` if cache is non-empty.

## State management

- **One `@Observable` class per screen.** Held as `@State` on the screen's root view.
- **Environment-scoped shared state:** `AuthManager`, `FloatingTabViewHelper`, currency service.
- **No `@AppStorage`, no `EnvironmentObject`, no `@Query`, no singletons** beyond Apple's (`FileManager`, `URLSession.shared`).
- **`@Bindable`** (not `@ObservedObject`) for VMs in subviews.
- VMs that touch `UserDefaults` take it as an injectable dependency (default `.standard`).

## Background & system integration

- **No push notifications, no background tasks, no widgets, no deep linking, no analytics** in v1.
- **Haptics:** `.sensoryFeedback(.impact, …)` on save, tab change, search-this-area.
- **Core Location:** imported for `CLLocationCoordinate2D` value types only — no `CLLocationManager` yet. `MapConfiguration.defaultUserLocation` is the seam for a future `UserLocationService`.
- **Notifications strategy** (planned): APNs for messages/booking status; SMS (Twilio) for confirmed booking + check-in reminder + host cancellation; email for receipts.

## Security & privacy

- **Supabase publishable anon key** committed in `Info.plist` (matches `sb_publishable_` convention). Data is gated by RLS — see `docs/db/*.sql`.
- **Mapbox public token** in `Info.plist`. **Secret token** in `~/.netrc` only — never committed.
- **HTTPS only.** No `NSAppTransportSecurity` overrides.
- **RLS:** `listings` public-read; `saved_listings` keyed on `auth.uid() = user_id`.
- **Privacy usage descriptions** must be added to `Info.plist` before any feature touches Core Location / Camera / Photos / Microphone.
- **Auth tokens → Keychain** when real auth ships (current `AuthManager.isAuthenticated` is a placeholder).

## Don't

- Don't put business logic, networking, or persistence in `View` bodies.
- Don't introduce a singleton beyond `FileManager` / `URLSession.shared`.
- Don't use `@ObservedObject` — `@Bindable` for `@Observable` classes.
- Don't let a `@Model` class escape the service boundary into UI as anything other than a fresh attached instance.
- Don't add Combine or completion handlers to new code.
- Don't hold a long-running task in `@State` without a way to cancel on view disappear.

## See also

- Architectural rules → @.claude/rules/architecture.md
- SwiftUI rules → @.claude/rules/swiftui.md
- Code style → @.claude/rules/style.md
- Testing rules → @.claude/rules/testing.md
- Build / test / run → @.claude/rules/build.md
- Project gotchas (money, currency, iOS 26) → @.claude/rules/gotchas.md
- Design system → @docs/DESIGN.md
- Product requirements → @docs/PRD.md
- Audit history → `docs/audits/`
