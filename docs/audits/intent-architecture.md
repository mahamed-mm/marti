# Architecture: Marti (iOS Traveler App)

## Overview

Marti is a SwiftUI iOS app using MVVM with `@Observable`. Supabase is the backend (PostgreSQL, Auth, Storage, Realtime). SwiftData provides local caching for offline browsing. Mapbox renders map views. The app is a single Xcode target — no Swift packages or multi-module setup until a second target (widget, extension) justifies the complexity.

## Key Decisions

1. **Single target, feature folders.** No Swift packages in v1. A single app target with feature-based folders keeps the build simple and avoids premature abstraction. When a widget or App Clip arrives, extract `MartiCore` then — not before.

2. **Supabase as source of truth, SwiftData as local cache.** All data lives in Supabase (PostgreSQL + RLS). SwiftData mirrors listings and bookings locally for offline browsing and fast launch. Writes always go to Supabase first; SwiftData updates on success. No offline write queue in v1 — booking/messaging/saving require network.

3. **`AuthManager` in SwiftUI Environment.** A single `@Observable` class injected via `.environment()` at the app root. Every screen can check auth state without passing it through ViewModels. Auth gates (booking, messaging, saving) read from this shared instance.

4. **Protocol-based services with async/await.** Each service (listings, bookings, messaging, reviews, auth) is a protocol + concrete Supabase implementation. ViewModels depend on protocols, test doubles conform to the same protocols. No Combine, no completion handlers.

5. **Mapbox over Apple/Google Maps.** Apple Maps and Google Maps have poor Somalia coverage. Mapbox provides decent base tiles, a solid iOS SDK, and the option to add custom neighborhood/landmark data later.

6. **Image caching with dedicated cache layer.** Listing photos load from Supabase Storage URLs. A thin cache layer wraps `URLSession` with `URLCache` (disk-backed, 200MB cap) and an in-memory `NSCache` for decoded images. `AsyncImage` alone doesn't give enough control over cache eviction or prefetching. The cache layer is one file, not a framework.

7. **APNs push only in v1.** Register for remote notifications via Supabase (store device token). No background fetch, no silent push, no background app refresh. SMS and email are triggered server-side (Supabase Edge Functions + Twilio) — the iOS app just receives pushes. Background modes can be added in v2 when messaging volume justifies it.

8. **Browse-first auth.** The app launches into listing discovery with no auth wall. Auth is triggered lazily — only when the user taps "Request to Book", "Message Host", or the save/heart icon. This means every ViewModel must handle both authenticated and unauthenticated states gracefully.

## Module Structure

```
marti/
├── App.swift                     # @main, environment setup, tab bar
├── Models/
│   ├── Listing.swift             # SwiftData @Model + Codable
│   ├── Booking.swift
│   ├── Message.swift
│   ├── Review.swift
│   ├── UserProfile.swift
│   └── Host.swift
├── Services/
│   ├── AuthManager.swift         # @Observable, injected via .environment()
│   ├── ListingService.swift      # protocol + SupabaseListingService
│   ├── BookingService.swift
│   ├── MessagingService.swift
│   ├── ReviewService.swift
│   ├── ImageCacheService.swift   # NSCache + URLCache wrapper
│   └── CurrencyService.swift    # USD/SOS rate cache (fixer.io)
├── ViewModels/
│   ├── ListingDiscoveryViewModel.swift
│   ├── ListingDetailViewModel.swift
│   ├── BookingRequestViewModel.swift
│   ├── MessagingViewModel.swift
│   ├── ReviewViewModel.swift
│   ├── ProfileViewModel.swift
│   ├── SavedListingsViewModel.swift
│   └── MyBookingsViewModel.swift
├── Views/
│   ├── Discovery/                # List view, map view, filters
│   ├── ListingDetail/            # Photo gallery, amenities, reviews, CTA
│   ├── Booking/                  # Request form, status, cancellation
│   ├── Messaging/                # Chat thread, message bubbles
│   ├── Reviews/                  # Write review, review list
│   ├── Profile/                  # Auth screens, profile edit, settings
│   ├── Saved/                    # Saved listings tab
│   ├── Bookings/                 # My bookings tab (upcoming/active/past)
│   └── Shared/                   # Reusable components (ListingCard, etc.)
├── Extensions/
│   └── (Date+, View+, etc.)
└── Resources/
    ├── Assets.xcassets
    └── Localizable.xcstrings
```

## Data Flow

```
User action
    → View calls ViewModel method
        → ViewModel calls Service (async/await)
            → Service calls Supabase REST/Realtime
            → On success: update SwiftData cache
        ← ViewModel updates @Observable properties
    ← SwiftUI re-renders
```

For real-time messaging:

```
Supabase Realtime (WebSocket)
    → MessagingService receives new message
        → Inserts into SwiftData
        → MessagingViewModel picks up change
    ← Chat view updates
```

Auth-gated actions:

```
User taps "Request to Book"
    → ViewModel checks AuthManager.isAuthenticated
        → If false: present auth sheet (Sign in with Apple / Phone OTP)
        → On auth success: proceed with original action
        → If true: proceed immediately
```

## State Management

| State                                | Where it lives                       | How it's accessed                             |
| ------------------------------------ | ------------------------------------ | --------------------------------------------- |
| Auth state (current user, token)     | `AuthManager` (`@Observable`)        | `.environment(AuthManager.self)` on app root  |
| Screen-specific state                | Per-screen ViewModel (`@Observable`) | `@State` in the view that owns it             |
| View-local state (toggles, sheets)   | `@State` in the view                 | Direct                                        |
| Cached data (listings, bookings)     | SwiftData `ModelContext`             | `@Query` in views, `ModelContext` in services |
| Ephemeral UI state (filters, search) | ViewModel properties                 | Bound to view via `@Bindable`                 |

No global state beyond `AuthManager`. No singletons. No `EnvironmentObject` — use the typed `.environment()` API from iOS 17.

## Persistence

| Data                          | Storage                            | Reason                                                   |
| ----------------------------- | ---------------------------------- | -------------------------------------------------------- |
| Auth tokens                   | Keychain (via Supabase SDK)        | Security — never in UserDefaults or SwiftData            |
| Listings cache                | SwiftData                          | Offline browsing, fast launch                            |
| Bookings cache                | SwiftData                          | View past/upcoming bookings offline                      |
| Messages cache                | SwiftData                          | Read conversation history offline                        |
| Saved listings                | SwiftData (synced to Supabase)     | Available offline, persisted across devices via Supabase |
| User profile                  | SwiftData (synced to Supabase)     | Quick access without network round-trip                  |
| USD/SOS exchange rate         | UserDefaults (daily cache)         | Simple key-value, no model needed                        |
| Image cache                   | URLCache (disk) + NSCache (memory) | System-managed eviction, no SwiftData bloat              |
| Onboarding/first-launch flags | UserDefaults                       | Simple booleans                                          |

SwiftData models mirror Supabase tables but are not the API layer. Codable structs decode from Supabase JSON, then map to SwiftData `@Model` objects for local storage. Full listing data is cached — with 30-50 listings at ~2KB each, total cache is under 100KB. Caching partial data would require a second fetch on detail tap, which is slow on Somali networks. Cache everything, display instantly, refresh in background when online.

## Networking

- **Client:** Supabase Swift SDK (`supabase-swift`). Wraps REST (PostgREST) for CRUD, Realtime for messaging/booking updates, Auth for identity, Storage for photos. Two Supabase projects: **dev** (Debug scheme) and **production** (Release scheme). No staging — unnecessary at this scale. Environment config via Xcode build schemes.
- **No raw URLSession** except inside `ImageCacheService` for photo loading.
- **Error handling:** Services throw typed errors. ViewModels catch and surface user-facing messages. No silent failures.
- **Pagination:** Cursor-based pagination for listings (Supabase `range()` queries). Load 20 listings per page.
- **Offline:** Read from SwiftData cache. All write operations show "No connection" and block until network is available. No offline write queue.
- **Currency:** One daily GET to fixer.io or exchangerate-api.com for USD/SOS rate. Cached in UserDefaults with a 24h TTL.
- **Analytics:** TelemetryDeck. Privacy-first (no consent banner needed), Swift-native, free tier covers v1 scale. Tracks funnel metrics from the PRD: signups, bookings, reviews, repeat usage. App Store Connect alone can't measure feature adoption or conversion. PostHog/Mixpanel are overkill and raise GDPR concerns for Nordic diaspora users.

## Background & System Integration

- **Push notifications (APNs):** Register device token with Supabase on auth. Receive notifications for booking updates, new messages, review prompts. Server-side delivery via Supabase Edge Functions.
- **SMS (Twilio):** Triggered server-side only — the iOS app doesn't interact with Twilio directly. Three events: booking confirmed, check-in reminder (24h), host cancellation.
- **No background fetch** in v1. No silent push. No background app refresh. No widgets. These are v2 candidates when messaging volume and engagement data justify the complexity.
- **Push tap-through routing:** Push notification payloads carry a `type` + `id` (e.g., `{"type": "booking_confirmed", "bookingId": "abc123"}`). A `DeepLinkRouter` enum matches on type and navigates to the correct screen. No Universal Links or custom URL schemes in v1 — add Universal Links (`marti.so/booking/{id}`) when the web presence exists.

## Security & Privacy

- **Auth tokens:** Keychain only. Supabase SDK handles this by default.
- **Row-Level Security:** All Supabase tables use RLS policies. The iOS app never bypasses RLS — it authenticates as the user and gets only their data.
- **No sensitive data in SwiftData.** Cached listings, bookings, and messages are not secrets. Auth tokens and passwords never touch SwiftData or UserDefaults.
- **HTTPS only.** App Transport Security enforced (default). No exceptions.
- **Photo uploads:** Validated server-side (type, size). Supabase Storage policies restrict who can upload where.
- **Profile photos:** Stored in Supabase Storage, served via signed URLs with expiry. No public buckets for user content.
- **Location:** Listings show approximate neighborhood, not exact address. Exact address revealed only after booking confirmation.

## Testing Strategy

| Layer       | Tested?               | How                                                                                                                             |
| ----------- | --------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| ViewModels  | Yes                   | Swift Testing (`@Test`, `#expect`). Mock services via protocol conformance. Test state transitions, error handling, auth gates. |
| Services    | Yes                   | Swift Testing against mock Supabase responses. Test request construction, response parsing, error mapping.                      |
| Models      | Yes (if logic exists) | Swift Testing for computed properties, validation, Codable conformance.                                                         |
| Views       | No                    | Not tested directly. Views are thin — logic lives in ViewModels.                                                                |
| Integration | Manual                | Test against Supabase dev project. No automated integration tests in v1.                                                        |
| Snapshots   | No                    | Not in v1. Reserved for design-system primitives if needed later.                                                               |

One test file per ViewModel, mirroring source structure. Mock services conform to the same protocols as production services. No mocking frameworks.

## Known Constraints

1. **Supabase Swift SDK maturity.** The SDK is newer than Firebase's. Realtime and Auth work well; edge cases around reconnection and token refresh need defensive handling.
2. **Mapbox SDK size.** Adds ~30MB to the binary. Acceptable for v1 but worth monitoring. No way around this if we need Somalia map coverage.
3. **No offline writes.** Users in Somalia (visiting diaspora) may have spotty connectivity. Booking and messaging require network. This is a v2 problem — building an offline write queue with conflict resolution is significant scope.
4. **SwiftData + Supabase sync is manual.** There's no built-in sync engine. Each service is responsible for fetching from Supabase and updating SwiftData. Sync conflicts default to server-wins.
5. **Single Xcode target.** If we add a widget or notification service extension, we'll need to extract shared models and services into a package. Plan for this but don't do it now.

## Open Questions

None. All architectural decisions are resolved for v1.

---

_Last updated: 2026-04-17_
