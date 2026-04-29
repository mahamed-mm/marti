# Status: Marti

The one file that updates per feature ship. Everything transient — current phase, shipped features, active blockers, what's next — lives here. Evergreen workflow and rules live in [`Workflow.md`](../Workflow.md) and [`CLAUDE.md`](../CLAUDE.md).

---

## Current phase

**v1 — building out P0 features.** Discovery and Listing Detail are shipped. Request to Book is next.

---

## Shipped

- **Listing Discovery** — list view with a `martiDisplay` editorial hero header over horizontal category rails, map view (Mapbox) with pin-to-card selection, filter sheet, skeleton / empty / error / offline states, USD + SOS pricing, saved-heart, SwiftData cache.
- **Listing Detail** — paged photo gallery (swipe + page-dots) with overlay save-heart, host card, amenities list (SF Symbol mapped), description, neighborhood-level Mapbox embed (`NeighborhoodMapView`), cancellation policy, reviews aggregate (text reviews deferred to Feature 5), sticky USD/SOS price + Request-to-Book CTA (opens `RequestToBookComingSoonSheet`). Heart-tap when unauthed presents `AuthSheetPlaceholderView`. `.notFound` shows alert + pop.
- **Floating tab bar** — canvas-masked custom tab bar with hide-on-detail behavior.
- **Supabase client** — wired with Row-Level Security.
- **Currency service** — USD → SOS conversion (open.er-api.com, 24h cache).
- **Design-system components** — `PrimaryButtonStyle`, `GhostButtonStyle`, `FavoriteHeartButton`, `VerifiedBadgeView`, `DiscoveryHeroHeaderView`, plus the full token scale in `DesignTokens.swift`.
- **Swift Testing suite** — ViewModels, Services, Models, component-constant checks (heart + verified badge).

Closed task trackers: [`docs/tasks/listing-discovery.md`](tasks/listing-discovery.md), [`docs/tasks/discovery-map-redesign.md`](tasks/discovery-map-redesign.md), [`docs/tasks/Listing Detail.md`](<tasks/Listing Detail.md>).

---

## In progress

Nothing active. Working tree is clean.

---

## Next up

**Request to Book** (P0 per `docs/PRD.md`, Feature 3). Detail's sticky CTA already renders and presents a coming-soon sheet — Feature 3 wires that CTA through to a real flow. Date-availability filter on Discovery is also gated on this feature. Start with `/generate-spec request-to-book`.

---

## Deferred (explicit)

- **Auth** — `AuthSheetPlaceholderView` toggles `isAuthenticated` for now; real sign-in flow lands with Bookings.
- **Bookings** — date-availability filter is stubbed; wires into the `bookings` table when the feature ships.
- **Messaging · Reviews · Profile** — all render `ComingSoonView` stubs in `MainTabView.swift`.
- **Image cache** — `CachedImageService` is built but not wired; listing photos currently use `AsyncImage`.
- **Host response rate** — not in `listings` schema, not in `Listing` model; intentionally deferred (not meaningful until Messaging exists).
- **Individual review text** — Listing Detail renders an aggregate-only reviews row; text reviews ship with Feature 5 (Reviews) once review submission and double-blind reveal are designed.
- **Full-screen photo viewer** — Listing Detail's photo gallery is paged-swipe-only; tap-to-zoom modal can land later if user research shows demand.

---

## Active submission blockers

Fix before any App Store submission:

- [ ] Pin `mapbox-maps-ios` to a v11 release tag (currently tracks `main`).
- [ ] Replace `fatalError` in `SupabaseConfig` / `MapboxConfig` with a startup error screen.
- [ ] Decide on dead-code sites flagged in the most recent architecture audit (`ContentView.swift`, `SupabaseConfig.client`, `CachedImageService`): wire in or delete.
- [ ] Add shadow + motion tokens to `DesignTokens.swift` before more inline curves and tuples accumulate.

---

## Most recent audits

- Architecture: see newest file in `docs/audits/*-architecture.md`.
- Design: see newest file in `docs/audits/*-design.md`.

---

_Update this file whenever a feature ships, a blocker clears, or the next-up target changes._
