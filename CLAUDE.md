# Project: Marti

Marti — a short-term rental marketplace connecting travelers with verified hosts across Somalia and the Horn of Africa, built for the Somali diaspora visiting home and business travelers seeking trusted local stays.

## WHAT

Short-term rental marketplace for Somalia & the Horn of Africa — connects Somali diaspora and business travelers with verified local hosts.

## WHY

- **Browse-first.** Auth gates only `save` / `book` / `message`. Discovery is public.
- **SwiftData = cache, Supabase = truth.** Writes hit Supabase first, then upsert cache.
- **Strict concurrency.** Swift 6, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. No Combine.
- **HIG-first.** SF Symbols, AX5-tested, VoiceOver labels on every interactive element without visible text.

## HOW

- **Feature flow:** `/create-prd` → `/generate-spec <feature>` → `/generate-tasks <feature>` → `/new-feature <feature>`.
- **Quick commands:** `/build`, `/test`, `/run-app`, `/ship-prep`.
- **Reference docs (imported on demand):**
  - Build / test / run commands → @.claude/rules/build.md
  - Architecture rules (MVVM, services, state) → @.claude/rules/architecture.md
  - Code style (Swift API guidelines, formatting) → @.claude/rules/style.md
  - SwiftUI rules (`@Observable`, `@Bindable`, view limits) → @.claude/rules/swiftui.md
  - Testing rules (Swift Testing, mocks, serialization) → @.claude/rules/testing.md
  - Project-specific gotchas (money, currency, iOS 26 quirks) → @.claude/rules/gotchas.md
  - File layout → @docs/ARCHITECTURE.md
  - Design system → @docs/DESIGN.md
  - Product requirements → @docs/PRD.md

## Stack

- **Lang/UI:** Swift 6 · SwiftUI · MVVM · `@Observable`
- **Test:** Swift Testing (`@Test`, `#expect`) — **not** XCTest
- **Data:** SwiftData (`@Model`) + Supabase Swift SDK 2.43.1
- **Map:** Mapbox Maps iOS v11 (⚠ pinned to `main`, tag before submit)
- **Target:** iOS 26.2 · Xcode 26.x · Simulator: iPhone 17 Pro

## Feature status

- ✅ Listing Discovery (`docs/tasks/listing-discovery.md`)
- 🚧 Listing Detail — next
- 🚧 Auth · Booking · Messaging · Reviews · Profile

## Don't

- Don't use UIKit. Exception: `UITabBar.appearance()`.
- Don't use deprecated APIs (`NavigationView`, single-param `.onChange`, etc).
- Don't add SPM dependencies without approval.
- Don't add lorem ipsum — ask for real copy.
- Don't auto-format the project.
- Don't add AI attribution to commits, PRs, or code comments.
- Don't generate App Icons or Launch Screens.
- Don't force-unwrap (`!`) outside `@IBOutlet` and tests.
- Don't use singletons except Apple-provided (`FileManager`, `URLSession.shared`).
