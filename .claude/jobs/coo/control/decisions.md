# Decisions — Marti

> COO-maintained. Append-only log of architectural and project-level decisions.
> Never delete or rewrite entries. If a decision is reversed, add a new entry referencing the old one.

Format per entry:

```
## YYYY-MM-DD — <Short decision title>

**Context**: What was the situation.
**Decision**: What we decided to do.
**Rationale**: Why.
**Alternatives considered**: What we rejected and why.
**Reversibility**: cheap / moderate / one-way door
**Proposed by**: <role>
```

---

## 2026-04-22 — Adopt role-based subagent pipeline for Claude Code

**Context**: Single-dev iOS project. Claude Code sessions forget state between invocations, causing repeated context re-explanation and occasional architectural drift when one session doesn't know what a prior session decided. Also, pushing all work through a single generic session causes context-window bloat on multi-concern features.

**Decision**: Adopt the `.claude/agents/` + `.claude/jobs/` pattern. The **main Claude Code session acts as COO** (instructions in `CLAUDE.md`). Five specialist subagents live in `.claude/agents/`: `ios-engineer`, `backend-engineer`, `maps-engineer`, `qa-engineer`, `design-reviewer`. A `/ship-feature <name>` slash command orchestrates the full feature pipeline with human checkpoints. Each role gets a persistent working directory under `.claude/jobs/<role>/` with `context/`, `history/`, `inbox/`, `outbox/`, `park/`. COO additionally writes to `.claude/jobs/coo/control/`.

**Rationale**:

- Park documents + persistent per-role context solve session state loss.
- Role separation isolates context windows — ios-engineer doesn't carry backend schema deliberation in its context, and vice versa.
- Main-session-as-COO (rather than COO as its own subagent) works around the constraint that subagents cannot chain-delegate to other subagents.
- COO centralization prevents two engineers making contradictory architectural calls without a tiebreaker.
- `/ship-feature` with checkpoints gives one-prompt pipeline UX without sacrificing human oversight at key moments (scope approval, manual Supabase migration, build-green gate, STATUS.md update).

**Alternatives considered**:

- Keep the existing linear command workflow only (`/generate-spec` → `/generate-tasks` → `/new-feature`). Rejected because it doesn't address session-state loss or context bloat.
- Make COO a subagent too. Rejected because Claude Code subagents cannot reliably chain-delegate to other subagents; the orchestrator needs to be the main session.
- Use a single generic "assistant" agent instead of five roles. Rejected because a one-prompt agent blurs UI/backend separation and the role prompts also function as guardrails.
- Full 20-job model from the Reddit reference that inspired this approach. Rejected as overkill for a one-person project.
- Fully autonomous `/ship-feature` with no checkpoints. Rejected because a pipeline that goes wrong 20 minutes in is worse than a checkpointed one that takes 30.

**Reversibility**: Cheap. `.claude/agents/`, `.claude/commands/ship-feature.md`, and `.claude/jobs/` can all be deleted without touching production code. CLAUDE.md revisions are in git history.

**Proposed by**: user / initial setup

---

## 2026-04-23 — Discovery initial `isLoading` defaults to `true`

**Context**: `/fix-bug` report — on cold launch (no cache, no listings yet), `DiscoveryView` briefly rendered `EmptyStateView` ("No listings found") before `SkeletonListingCard`s appeared. Root cause: `ListingDiscoveryViewModel.isLoading` defaulted to `false`, so the first frame hit `ListingListView.states`' `rails.isEmpty` branch before `.task` could fire `loadListings()` and flip `isLoading = true`.

**Decision**: A freshly-constructed `ListingDiscoveryViewModel` starts in the loading state. One-line change — `ListingDiscoveryViewModel.swift:19` now initializes `isLoading: Bool = true`. `loadListings()` already sets it back to `false` on completion, so no downstream flow changes. Regression pinned by `freshViewModel_startsInLoadingState_soFirstFrameShowsSkeletonsNotEmptyState` in `ListingDiscoveryViewModelTests.swift`.

**Rationale**: A VM that has never been asked to load also has no data to show — from the view's perspective the two are indistinguishable, so defaulting to "loading" matches user-perceived state and closes the race without adding a separate `hasLoadedOnce` flag or a full `LoadState` enum. No existing test asserted pre-load `isLoading == false`.

**Alternatives considered**:

- Introduce a `hasLoadedOnce` flag and OR it into each predicate. Rejected — adds state for no benefit over the one-line default.
- Full `LoadState` enum (`.initial/.loading/.loaded/.error`). Rejected — bigger refactor than the bug warranted; can revisit if more screens need the same pattern.
- Set `isLoading = true` synchronously as the first line of `loadListings()` outside the inner `Task`. Rejected — still leaves a gap between view construction and `.task` firing.

**Reversibility**: Cheap.

**Proposed by**: coo

**Follow-up logged (not fixed here)**: `DiscoveryView.anchoredItem` (map-mode bottom chrome, `DiscoveryView.swift:234-266`) has no loading-state branch — during first-load in map mode, pin skeletons appear over the map but the bottom chrome is blank. Separate bug, narrower than this report; not bundled to keep the fix minimal.

---

## 2026-04-28 — `.notFound` UX policy: alert before pop, not silent dismiss

**Context**: Listing Detail's `refresh()` call may return `AppError.notFound` (the listing was deleted server-side between the user tapping the card and the network call landing). The first cut shipped a silent `dismiss()` on detection. Design-reviewer flagged it Major during the Loop 1 audit.

**Decision**: Detail surfaces that hit `.notFound` after a navigated push present a confirming alert (single-line title, single OK button, OK action pops the stack) rather than dismissing silently. For Listing Detail specifically: title `"This listing is no longer available"`, no body, single OK. The view binds a `shouldShowNotFoundAlert: Bool` flag on the ViewModel.

**Rationale**: A silent pop reads as a phantom navigation event or app glitch — the user has no signal that the listing was deleted. Apple's Mail / Photos / Maps all acknowledge a vanished resource before unwinding. The alert isn't there to inform — it's there to convert a confusing nav event into a deliberate one. Cost: ~10 lines per surface; no infra cost.

**Alternatives considered**:

- Silent dismiss (the original implementation). Rejected per design-reviewer reasoning above.
- Inline error state on the detail screen (no pop). Rejected because the listing genuinely no longer exists; staying on a dead screen is worse than unwinding with acknowledgment.
- Toast at the parent screen after pop. Rejected because the user's mental model on push is "I'm looking at this listing"; the acknowledgment must land where the listing was visible, not the screen they came from.

**Reversibility**: Cheap. One screen so far; future detail-ish surfaces (Booking Detail, Message Thread) will follow the same pattern when they ship.

**Proposed by**: design-reviewer (audit `docs/audits/2026-04-28-design-audit-Listing Detail.md`)

---

## 2026-04-28 — Pushed detail surfaces hide the floating tab bar via `.hideFloatingTabBar(true)`

**Context**: `FloatingTabView` hosts a custom canvas-masked tab bar that overlays the entire NavigationStack subtree (the home-indicator-area mask is global). Discovery toggles `.hideFloatingTabBar(viewModel.viewMode == .map)` to clear the bar in map mode, but the bar is otherwise visible across pushed children. When Listing Detail first shipped, the tab bar overlaid its sticky CTA — direct PRD AC1 violation flagged as Blocker B1 in the audit.

**Decision**: Any view pushed via `.navigationDestination` onto a NavigationStack hosted inside `FloatingTabView` calls `.hideFloatingTabBar(true)` on its root container. Convention applies to every detail / drill-in surface. We do NOT auto-hide in `FloatingTabViewHelper` itself: too many false positives (some pushed views may legitimately want the bar).

**Rationale**: Sticky CTAs, full-bleed photo galleries, immersive detail content all need the screen real estate that the tab bar otherwise consumes. Per-screen opt-in keeps `FloatingTabViewHelper` simple and predictable; auto-hide would bake a global navigation policy into a layout primitive.

**Alternatives considered**:

- Auto-hide on push by inspecting NavigationStack depth in `FloatingTabViewHelper`. Rejected — couples the layout primitive to navigation state and breaks any pushed view that wants the bar.
- Move the policy into `MainTabView` via a `.tabViewStyle` config. Rejected — `MainTabView` doesn't see pushed children directly.
- Hide globally and require pushed views to opt-in. Rejected — inverts the cost; most pushed views in scope today need the bar hidden, but the architecture should enforce intent at the screen level.

**Reversibility**: Cheap. One callsite so far (Listing Detail). If we accumulate >5 detail surfaces all repeating the same modifier, revisit auto-hide.

**Proposed by**: design-reviewer (audit `docs/audits/2026-04-28-design-audit-Listing Detail.md`, B1)

---

## 2026-04-30 — Bug log: Listing Detail's `currentPhotoIndex` clamped on `refresh()` to handle shrinking photo arrays

**Context**: `ListingDetailViewModel` is seeded from a SwiftData snapshot (cached by Discovery) and then background-refreshed against Supabase via `refresh()`. The reassignment `listing = Listing(dto: dto)` at line 103 swaps in the server snapshot, which can carry fewer `photoURLs` than the cached seed (host-side photo deletion between cache write and refresh). `currentPhotoIndex` was not adjusted when `listing` changed, so an out-of-bounds index could orphan the gallery `TabView`'s selection and cause the bottom-trailing counter pill to render `"6 / 3"`. No crash — visual drift only — but a real user-visible defect.

**Decision**: Clamp `currentPhotoIndex` inside the ViewModel's `refresh()`, immediately after the listing reassignment: `currentPhotoIndex = min(currentPhotoIndex, max(0, listing.photoURLs.count - 1))`. Add a Swift Testing unit test in `ListingDetailViewModelTests` that seeds a 6-photo listing, sets the index to 5, stubs the service to return a 3-photo DTO, and asserts the index lands at 2 after `refresh()`.

**Rationale**: The state owner enforces the invariant. `architecture.md` says "Views are dumb, no business logic in View bodies"; `testing.md` says "do not test SwiftUI view bodies." Putting the clamp in the ViewModel keeps the View dumb and makes the invariant unit-testable.

**Alternatives considered**:

- The bug report's suggested shape: `.onChange(of: photoURLs.count)` modifier on `ListingPhotoGalleryView`. Rejected — pushes invariant ownership outside the state owner, makes the invariant untestable, spreads the data-flow concern across two files.
- Reset to 0 on every refresh. Rejected — discards the user's current paging position even when the new array is at least as large; degrades the common case (refresh returns same or more photos) to fix the rare case (refresh returns fewer).
- Reset only when `photoURLs.count == 0`. Rejected — leaves the orphan-tag bug intact for the actual symptom (shrunk-not-emptied arrays).

**Files changed**:

- `marti/Marti/ViewModels/ListingDetailViewModel.swift` (one-line clamp + 3-line comment in `refresh()`)
- `marti/MartiTests/ViewModels/ListingDetailViewModelTests.swift` (one new `@Test` + defaulted `photoURLs:` parameters on `makeListing` / `makeListingDTO` helpers — additive, no existing call-site changes)

**Regression test**: `ListingDetailViewModelTests/refresh_whenServerSnapshotHasFewerPhotos_clampsCurrentPhotoIndex` — verified red against pre-fix code, green against fixed code. Full suite: **99/99 passing**.

**Class-of-bug note**: Any state owned by a ViewModel that depends on the *shape* of a refreshable model (array sizes, ID presence, conditional flags derived from model fields) is at risk of the same "stale state after refresh" pattern. Applying the principle: when `listing` is reassigned by `refresh()`, audit every property of the ViewModel that derives from `listing`'s shape and assert its post-condition. No architectural rule change — just a vigilance note.

**Reversibility**: Cheap. One line, one file. Reversible by deletion.

**Proposed by**: COO (verified bug report, executed TDD fix directly in the main session after subagent delegation rounds were trapped by harness plan-mode gating).

---

## 2026-04-30 — Bug log: NeighborhoodMapView restores Mapbox logo + attribution visibility (ToS compliance)

**Context**: Code-review finding flagged `marti/Marti/Views/Shared/NeighborhoodMapView.swift:99-103`. The `.ornamentOptions(...)` block used `CGPoint(x: -200, y: -200)` margins on both `LogoViewOptions` and `AttributionButtonOptions` to push the Mapbox logo + (i) attribution button off the visible 200pt × full-width embed. The leading comment (lines 94–98) acknowledged this was intentional and rationalized it as "attribution still discoverable on the full Discovery map." Mapbox SDK v11 terms of use require the logo and attribution button to remain visible on **every** rendered map view; "discoverable elsewhere" does not exempt derivative previews. Real ToS-compliance defect, not a styling preference.

**Decision**: Restore visibility by anchoring both ornaments at `.bottomLeading` with `Spacing.md` (8pt) positive margins. Shift the (i) attribution button right by a local `mapboxWordmarkClearance: CGFloat = 100` so it doesn't stack on the wordmark — same value `ListingMapView` uses for the same purpose, copied (not shared) because Discovery's constant is `private` and the file's leading comment defends keeping `NeighborhoodMapView` self-contained ("no shared map factory"). Scale bar stays hidden — that part of the original rationale (this is a static preview, not a navigation surface) still holds. Discovery (`ListingMapView.swift:630-643`) already complies; this fix brings the second map surface in line.

**Rationale**: The SDK's built-in attribution button is the contractually-correct surface — tapping it opens the up-to-date OpenStreetMap / Mapbox / Maxar attribution sheet, which a hand-rolled label cannot keep in sync. Restoring the built-in is cheaper and more correct than building a custom attribution UI elsewhere in the view. Matching Discovery's `.bottomLeading` positioning also gives visual continuity — Listing Detail's neighborhood map reads as the same product as the Discovery map the user just left.

**Alternatives considered**:

- Build an explicit custom attribution UI elsewhere in the view (the bug report's second option). Rejected — the SDK's built-in button stays in sync with upstream attribution requirements automatically; a hand-rolled label would drift.
- Default-position the ornaments by removing the margins parameter entirely. Rejected — the SDK's defaults work but small deliberate margins inside the rounded `Radius.md` clip read better than letting the ornaments hug the unclipped edge.
- Extract a shared ornament factory between `ListingMapView` and `NeighborhoodMapView`. Rejected — premature abstraction at two callsites; the file's leading comment explicitly defends the self-contained design.
- Keep ornaments hidden and just add a static caption like "© Mapbox · OpenStreetMap" beneath the embed. Rejected — fails the "tap-to-open attribution sheet" affordance the SDK provides for free.

**Files changed**:

- `marti/Marti/Views/Shared/NeighborhoodMapView.swift` — added local `mapboxWordmarkClearance` constant (lines 41–46) and replaced the `.ornamentOptions(...)` block + its leading comment (lines 101–120). Single file, ~15 lines net touched.

**Regression test**: **Untestable as a unit test, logged here per protocol.** `OrnamentOptions` is applied via the SwiftUI `.ornamentOptions(...)` view modifier; the Mapbox iOS SDK does not expose ornament visibility / position state to Swift Testing assertions, and project rule (`/.claude/rules/testing.md`) forbids testing SwiftUI view bodies. Verified by:

1. `xcodebuild build` on iPhone 17 Pro simulator — green.
2. Full `MartiTests` suite — **99/99 passing, 0 failures, no regressions**.
3. Manual visual check on simulator (Listing Detail neighborhood map) deferred to next manual sweep — bundling with the carry-over AX5 sweep on Listing Detail v2.

**Class-of-bug note**: Any future map embed must keep the Mapbox logo + attribution button visible. Two surfaces today (Discovery + Listing Detail neighborhood embed); if a third lands, formalize this as a project rule under `.claude/rules/` rather than relying on review catches. Vigilance note for now — no rule entry yet.

**Reversibility**: Cheap. Single file, ~15 lines, reversible by `git revert` on the diff.

**Proposed by**: code-reviewer finding; COO verified against current source; COO executed the fix directly in the main session (single-file Mapbox config change, qualifies for the trivial / single-concern routing rule, and avoids the harness plan-mode gating that has trapped recent specialist delegations).
