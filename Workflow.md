# Workflow: Marti

The day-to-day loop for building Marti. `CLAUDE.md` owns the *rules* (stack, conventions, file layout); this file owns the *sequencing* — which slash command to run when, and in what order.

---

## Current phase (2026-04-19)

- **Shipped:** Listing Discovery — list view with category rails, map view (Mapbox), filter sheet, skeleton / empty / error / offline states, USD + SOS pricing, saved-heart, SwiftData cache.
- **Audited today:** `docs/ARCHITECTURE.md` and `docs/DESIGN.md` were regenerated from shipped code. Original intent docs are preserved at `ARCHITECTURE.previous.md` / `DESIGN.previous.md`.
- **In progress (uncommitted on `dev`):** `discovery-map-redesign` — adds `Views/Discovery/Components/`, `CategoryRailView`, `FavoriteHeartButton`, `Buttons`, `VerifiedBadgeView`, and DB migrations `003_categories.sql` / `004_sample_categories.sql`. Task tracker: `docs/tasks/discovery-map-redesign.md`.
- **Next feature:** Listing Detail (P0 per `docs/PRD.md`).
- **Placeholders:** Auth (`AuthSheetPlaceholderView` flips a Bool), Saved / Bookings / Messages / Profile (all render `ComingSoonView` stubs in `MainTabView.swift`).

---

## Feature-dev loop

For each new feature (e.g. Listing Detail):

1. **`/generate-spec <feature>`** — writes `docs/specs/<feature>.md` derived from `PRD.md`.
2. **`/generate-tasks <feature>`** — breaks the spec into ordered tasks in `docs/tasks/<feature>.md`.
3. **`/new-feature <feature>`** — implements, adds Swift Testing coverage for ViewModels / Services, HIG-reviews.
4. **`/build` · `/test` · `/run-app`** — verify in the iPhone 17 Pro simulator after each meaningful chunk.
5. **Commit when green.** No AI-attribution in messages (see `CLAUDE.md`).

Skip `/generate-spec` only for trivial work (typo, single-field addition, copy tweak). For everything non-trivial, going straight to `/new-feature` means Claude makes design decisions you never approved.

---

## Audit cadence

Re-run both audits after every 3–5 features, and always before App Store submission:

- **`/audit-architecture`** — reads the real code and regenerates `docs/ARCHITECTURE.md`. Backs the previous audit up into `docs/ARCHITECTURE.previous.md` only if no intent doc lives there already; the original intent is preserved by convention.
- **`/audit-design`** — reads SwiftUI views and regenerates `docs/DESIGN.md`. Same backup convention.

These catch drift that's invisible from inside the work: dead tokens, duplicated chrome, stale file paths, animations that forgot about Reduce Motion. The current DESIGN.md summary lists three live items worth knowing about: no motion tokens yet, no shadow tokens yet, and a duplicated 48pt icon button pattern.

---

## Ship prep

- **`/ship-prep`** — full App Store readiness checklist.
- **`/review-ui <view>`** — HIG audit of a single screen.

Active blockers from the current audits (to fix before a submission):

- Pin `mapbox-maps-ios` to a v11 release tag — currently tracks `main`.
- Replace `fatalError` in `SupabaseConfig` / `MapboxConfig` with a startup error screen.
- Decide on the three dead-code sites flagged in `ARCHITECTURE.md`: `ContentView.swift`, `SupabaseConfig.client`, and `CachedImageService` (wire it in or delete it).
- Add shadow + motion tokens in `DesignTokens.swift` before the next feature lands more inline curves and tuples.

---

## Command reference

| Command                 | Purpose                                                            |
| ----------------------- | ------------------------------------------------------------------ |
| `/create-prd`           | One-off: (re)generate `docs/PRD.md` from a description.            |
| `/generate-spec`        | Spec for one feature from the PRD.                                 |
| `/generate-tasks`       | Ordered task list from a spec.                                     |
| `/new-feature`          | Implement + test + HIG-review a feature end to end.                |
| `/build`                | `xcodebuild` for the iPhone 17 Pro simulator.                      |
| `/test`                 | Run the Swift Testing suite.                                       |
| `/run-app`              | Build + install + launch on the booted simulator.                  |
| `/add-tests`            | Generate Swift Testing tests for a ViewModel or service.           |
| `/review-ui`            | HIG audit of a specific SwiftUI screen or component.               |
| `/audit-architecture`   | Regenerate `docs/ARCHITECTURE.md` from code.                       |
| `/audit-design`         | Regenerate `docs/DESIGN.md` from views.                            |
| `/ship-prep`            | App Store submission readiness checklist.                          |

---

## Conventions

- **Stack, file layout, style rules, testing policy → `CLAUDE.md`.**
- **Observed architecture → `docs/ARCHITECTURE.md`** (regenerate on cadence).
- **Observed design system → `docs/DESIGN.md`** (regenerate on cadence).
- **Per-feature specs → `docs/specs/<feature>.md`.** Task breakdowns → `docs/tasks/<feature>.md`.
- **SQL migrations run in order** — any new file under `docs/db/` must be numerically later than the previous one and idempotent for sample data.

---

*Last refreshed 2026-04-19 alongside the ARCHITECTURE + DESIGN audits. Update this file when the workflow itself changes — not when a feature ships.*
