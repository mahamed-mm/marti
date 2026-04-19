# Product Requirements Document: Marti (iOS Traveler App)

> The iOS app for diaspora Somalis to discover, book, and review verified short-term rentals in Mogadishu and Hargeisa. The host-side web dashboard is a separate project.

## Executive Summary

Marti is an Airbnb-style marketplace purpose-built for Somalia. Diaspora Somalis traveling home for summer, Ramadan/Eid, or family events currently rely on word-of-mouth, WhatsApp group recommendations, or showing up and hoping for the best. Hosts — small guesthouses, families with spare rooms, boutique hotels — have no digital presence beyond social media. Marti bridges the gap with a trust-first approach: manually verified listings, a request-to-book flow, and in-app messaging, launching in Mogadishu and Hargeisa.

## Problem Statement

Diaspora Somalis (estimated 2M+ globally) travel to Somalia regularly but have no reliable way to find and book accommodation. Current options:

- **WhatsApp/word-of-mouth:** works if you have the right contacts, fails if you don't. No photos, no reviews, no accountability.
- **Booking.com/Airbnb:** virtually no Somalia coverage. A handful of Hargeisa hotels, nothing beyond that.
- **Walking in:** risky, time-consuming, and stressful — especially for families or women traveling alone.

Meanwhile, accommodation exists but is invisible to the diaspora audience that has the spending power.

## Target Users

- **Primary:** Somali diaspora (ages 22-45) in North America, Europe (especially Nordics/UK), and the Gulf, traveling to Mogadishu or Hargeisa for family visits, weddings, Eid, or personal trips. They have USD/EUR/NOK income, are bilingual (Somali + English), and are reachable via Somali TikTok/Instagram/Facebook.

## Success Metrics (first 6 months)

| Metric | Target | How measured |
|---|---|---|
| Diaspora signups (iOS) | 100-200 | Supabase auth |
| Completed bookings | 10-20 | Booking status tracking |
| Review rate | > 60% of completed stays | Reviews / completed bookings |
| Repeat bookings | At least 3 | User booking history |
| Crash-free rate | 99.5% | Xcode Organizer |
| App Store rating | 4.5+ | App Store Connect |

## Core Features

### Feature 1: Listing Discovery

- **Priority:** P0
- **Description:** Travelers browse verified listings in Mogadishu or Hargeisa. Search by city, dates, guests, price range. Map view (Mapbox) and list view. Each listing shows photos, price/night, host info, verification badge, and location on map.
- **User stories:**
  - As a traveler, I want to browse listings in Mogadishu so that I can find a place to stay for my trip.
  - As a traveler, I want to filter by dates and number of guests so that I only see available places.
  - As a traveler, I want to see listings on a map so that I can pick a location near family or landmarks.
- **Acceptance criteria:**
  - [ ] List view shows photo, price, rating, city, verification badge
  - [ ] Map view shows pins with price labels (Mapbox SDK)
  - [ ] Filter by city (Mogadishu / Hargeisa), dates, guests, price range
  - [ ] Pull-to-refresh and pagination
  - [ ] Empty state when no listings match filters

### Feature 2: Listing Detail

- **Priority:** P0
- **Description:** Full listing page with photo gallery, description, amenities, house rules, host profile (with verification badge), location on map, reviews, and pricing breakdown.
- **User stories:**
  - As a traveler, I want to see detailed photos and description so that I know what to expect.
  - As a traveler, I want to read reviews from other diaspora travelers so that I can trust the listing.
- **Acceptance criteria:**
  - [ ] Scrollable photo gallery (min 3 photos required per listing)
  - [ ] Host profile section with name, photo, verification status, response rate
  - [ ] Amenities list (AC, WiFi, parking, airport pickup, etc.)
  - [ ] Reviews section with ratings and text
  - [ ] Map showing approximate location (neighborhood level, not exact address)
  - [ ] "Request to Book" CTA with date and guest count

### Feature 3: Request to Book

- **Priority:** P0
- **Description:** Traveler requests a booking for specific dates. No instant booking — host approval is required. No in-app payment; reservation locks the dates, payment settles off-platform. Prices displayed in USD (primary) with SOS equivalent (secondary).
- **User stories:**
  - As a traveler, I want to request a booking so that the host can confirm my stay.
  - As a traveler, I want to cancel a booking if my plans change, with a clear policy.
- **Acceptance criteria:**
  - [ ] Traveler selects dates and guest count, submits request
  - [ ] Traveler sees booking status: pending → confirmed / declined
  - [ ] Push notification when host confirms or declines
  - [ ] Confirmed booking shows as locked dates on listing
  - [ ] Auto-decline after 48 hours if host doesn't respond
  - [ ] Booking summary shows total price in USD with SOS equivalent
  - [ ] Cancellation policy displayed before booking (Flexible / Moderate / Strict)
  - [ ] Traveler can cancel with policy terms applied

### Feature 4: In-App Messaging

- **Priority:** P0
- **Description:** Once a booking request is submitted, traveler can message the host. Handles logistics: arrival time, airport pickup, directions, payment arrangement. Uses Supabase Realtime.
- **User stories:**
  - As a traveler, I want to message my host so that I can coordinate arrival details.
  - As a traveler, I want to answer host questions before they confirm my booking.
- **Acceptance criteria:**
  - [ ] Chat thread per booking request
  - [ ] Text messages with timestamps
  - [ ] Push notifications for new messages
  - [ ] Chat persists after booking completes (for post-stay coordination)
  - [ ] No messaging before a booking request exists (prevents spam)

### Feature 5: Reviews

- **Priority:** P0
- **Description:** After a completed stay, traveler leaves a review (1-5 stars + text). Reviews are public on the listing. Double-blind: neither party sees the other's review until both submit or 14 days pass.
- **User stories:**
  - As a traveler, I want to review my stay so that future travelers benefit from my experience.
  - As a traveler, I want to read honest reviews so that I can trust listings.
- **Acceptance criteria:**
  - [ ] Review prompt after checkout date
  - [ ] 1-5 star rating + optional text
  - [ ] Double-blind reveal (both submit, or 14-day timeout)
  - [ ] Reviews appear on listing detail page
  - [ ] Average rating displayed on listing cards

### Feature 6: User Profile & Auth

- **Priority:** P0
- **Description:** Browse-first experience — no auth required to explore listings. Auth triggered at intent: "Request to Book", "Message Host", or "Save". Sign in with Apple + phone OTP (Twilio via Supabase). Profile includes name, photo, and home city.
- **User stories:**
  - As a traveler, I want to browse listings without signing up so that I can explore before committing.
  - As a traveler, I want to sign up quickly when I'm ready to book.
  - As a traveler, I want hosts to see my profile so that they trust me.
- **Acceptance criteria:**
  - [ ] Unauthenticated browsing of all listings, details, reviews, and map
  - [ ] Auth required only at booking request, messaging, or saving a listing
  - [ ] Sign in with Apple (primary for diaspora)
  - [ ] Phone OTP signup/login (Twilio via Supabase)
  - [ ] Profile: name, photo, bio, home city
  - [ ] View past bookings and reviews
  - [ ] Edit profile

### Feature 7: Saved Listings

- **Priority:** P0
- **Description:** Travelers save/favorite listings for later. Heart icon on listing cards and detail page. Saved tab in the main tab bar. Triggers auth if unauthenticated — natural conversion point. Diaspora travelers research trips 2-3 months ahead; without favorites, they lose listings and churn.
- **User stories:**
  - As a traveler, I want to save listings I like so that I can compare them later.
  - As a traveler, I want a dedicated tab for my saved listings so that I can find them quickly.
- **Acceptance criteria:**
  - [ ] Heart icon on listing cards and detail page
  - [ ] Tapping save triggers auth if not signed in
  - [ ] Saved tab in main tab bar
  - [ ] Saved listings persist across sessions (Supabase)
  - [ ] Remove from saved with toggle

### Feature 8: My Bookings

- **Priority:** P0
- **Description:** Central place for travelers to track all bookings — upcoming, active, past, and declined. Shows status, dates, host info, and links to messaging and review flows.
- **User stories:**
  - As a traveler, I want to see all my bookings in one place so that I can manage my trips.
  - As a traveler, I want to quickly check the status of a pending request.
- **Acceptance criteria:**
  - [ ] Segmented view: Upcoming / Active / Past
  - [ ] Each booking shows listing photo, dates, status, host name
  - [ ] Tap to open booking detail (messaging, listing, review)
  - [ ] Pending requests show time remaining before auto-decline (48h)
  - [ ] Past bookings prompt for review if not yet submitted

## Notifications Strategy

- **Push (APNs):** Day-to-day — new messages, booking status updates, review prompts.
- **SMS (Twilio):** Three critical moments only — booking confirmed, check-in reminder (24h before), cancellation by host. Push alone will fail (diaspora roaming + carrier reliability).
- **Email:** Receipts, booking summaries, and anything the traveler might need to forward (e.g., accommodation proof for visa applications). Not for real-time alerts.

## Cancellation Policy

Three tiers (set by host via web dashboard, displayed to traveler in-app):

| Tier | Refund window | After window |
|---|---|---|
| **Flexible** | Full refund up to 24h before check-in | No refund |
| **Moderate** (default) | Full refund up to 5 days before, 50% after | No refund |
| **Strict** | 50% refund up to 7 days before | No refund |

In v1 with no in-app payments, "refund" means the reservation is released and no settlement obligation exists. The policy governs whether the guest owes a cancellation fee. Logic is built now so v2 with payments is a backend flip, not a rewrite.

## Currency

- **Primary:** USD. Somalia is heavily dollarized — listings are quoted in USD.
- **Secondary:** SOS equivalent shown as a secondary line, using a daily cached rate (XE API or fixer.io free tier).
- No EUR/GBP/NOK conversion in v1. Auto-localize by device region in v2.

## Non-Functional Requirements

- **Performance:** Cold launch < 2s on iPhone 12+. Listing feed scrolls at 60fps. Images lazy-loaded and cached.
- **Accessibility:** VoiceOver fully supported. Dynamic Type support.
- **Localization:** English UI for v1. Somali greetings, confirmations, and cultural flavor throughout. Full Somali localization in v1.1. Arabic in v2.
- **Security:** Supabase Row-Level Security for all data. Keychain for auth tokens on iOS. HTTPS only. Photo uploads validated (type, size).
- **Offline:** Listings cached for offline browsing. Booking actions require network. Messaging queues and syncs.

## Technical Constraints

- iOS 26.2+ minimum
- Swift 6 with strict concurrency
- SwiftUI + MVVM with `@Observable`
- Supabase (PostgreSQL, Auth, Storage, Realtime)
- Mapbox iOS SDK for maps
- No third-party SDKs without explicit approval
- No in-app payments in v1

## Out of Scope (v1.0)

- Instant booking (host approval required for all requests)
- In-app payments (settlement is off-platform: EVC Plus, ZAAD, Sahal, hawala)
- Calendar sync (iCal, Google Calendar)
- Multi-city beyond Mogadishu and Hargeisa
- Business traveler or tourist-specific features
- Arabic localization
- Social features (sharing, travel guides)
- Pricing tools (dynamic pricing, special offers, weekly/monthly discounts)
- Dispute resolution system (handled manually via support)

## Business Model

- **V1 (first 3-6 months):** Free for both sides. Zero friction to attract supply.
- **V2:** 10-12% guest-side service fee per booking (guests are used to this from Booking/Airbnb). Alternative: flat $5-10/night booking fee.

## Open Questions

1. **App name trademark:** "Marti" is not yet cleared. Check WIPO, EUIPO, UKIPO, and Somalia MoCI for Class 39/43 conflicts. Consider "Marti Stays" or "Marti — Somali Stays" as App Store display name. Secure marti.so domain and martistays.com as defensive hedge.

---

*Last updated: 2026-04-17*
