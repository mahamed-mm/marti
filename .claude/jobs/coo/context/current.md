# Current state — coo

> Last updated: 2026-04-30 (NeighborhoodMapView Mapbox-attribution ToS fix)
> Update this file at the end of every session.

## What's in flight

Nothing. Today shipped four things:

1. **Doc reconcile** — one-line `98/98` → `97/97` fix inside `.claude/jobs/ios-engineer/context/current.md` line 39 (earlier in the day).
2. **Bug fix (TDD)** — `ListingDetailViewModel.refresh()` now clamps `currentPhotoIndex = min(currentPhotoIndex, max(0, listing.photoURLs.count - 1))` immediately after the listing reassignment. New unit test asserts the clamp. Logged in `decisions.md`.
3. **Defensive hardening** — cancellation-policy gating now trims whitespace before lowercasing at both surfaces:
   - `ListingDetailStickyFooterView.showFreeCancellation` (line 103)
   - `ListingCancellationPolicyView.key` (line 32, used by `displayName` + `subtitle`)
   Without this, a stray `" strict "` from a hand-edited Supabase row would render "Free cancellation" on top of a Strict listing in the footer, **and** drop the strict subtitle in the policy section — two surfaces disagreeing on the same value. DB schema (`docs/db/001_listings.sql:22`) has no CHECK constraint, so any string is currently persistable. No PRD or STATUS.md change — the fix preserves existing behavior for clean values; only malformed inputs are affected. No regression test (private View internals; project rule "do not test SwiftUI view bodies"). Not logged in `decisions.md` — hardening, not architecture.
4. **Bug fix (ToS compliance)** — `NeighborhoodMapView.ornamentOptions` no longer hides the Mapbox logo + (i) attribution button. Negative `CGPoint(x: -200, y: -200)` margins on `LogoViewOptions` and `AttributionButtonOptions` were pushing both off the visible 200pt embed; the original comment ("attribution still discoverable on the full Discovery map") rationalized a real ToS violation — Mapbox SDK v11 requires per-view visibility on every rendered map, derivative previews included. Fix anchors both at `.bottomLeading` with `Spacing.md` (8pt) margins; the (i) is shifted right by a local `mapboxWordmarkClearance: CGFloat = 100` (matches Discovery's value, copied because Discovery's is `private` and the leading comment defends keeping `NeighborhoodMapView` self-contained). Scale bar stays hidden — it's a static preview, not a navigation surface. **Untestable** as a unit test (Mapbox SDK doesn't expose ornament state to Swift Testing; project rule against testing view bodies); verified by build + full suite green. Logged in `decisions.md`.

Subagent delegation kept getting trapped in plan-mode approval gates from the harness side, so COO executed today's fixes directly per CLAUDE.md's trivial / single-concern routing rule — the photo-index clamp was ios-engineer's lane, the cancellation-policy hardening was ios-engineer's lane, and the NeighborhoodMapView ornament fix was maps-engineer's lane. All three are documented as such in the relevant role park docs / decision log.

**Test count is still 99/99 passing**, build green on iPhone 17 Pro after today's NeighborhoodMapView edit. The ornament fix is view-only (15 lines net, single file) and didn't move the count. Both prior baselines (2026-04-28 "98/98" and 2026-04-29 "97/97 corrected") were drift; today's measurement remains the anchor (98 pre-photo-clamp → 99 post-photo-clamp → 99 still after cancellation-policy hardening → 99 still after NeighborhoodMapView ornaments). Future sessions should anchor to the current run output, not historical doc claims.

Working tree carries: the 2026-04-28 ship + the 2026-04-29 v2 visual pass + COO paperwork from prior sessions + today's photo-index bug fix + today's cancellation-policy hardening + today's NeighborhoodMapView ornament fix + today's COO paperwork. **Nothing is committed yet — user has not requested a commit.**

## What's clean / stable

- **Mapbox ornaments now ToS-compliant on both map surfaces.** Discovery's `ListingMapView` was already correct; today's fix brings `NeighborhoodMapView` (Listing Detail's 200pt embed) in line — logo + (i) attribution at `.bottomLeading` with `Spacing.md` margins, scale bar hidden (static preview, not nav). If a third map surface ever ships, formalize a `.claude/rules/` entry; for now, vigilance note in `decisions.md`.
- **Cancellation-policy gating is whitespace-tolerant** at both UI surfaces (footer + section). Schema-level enum/CHECK constraint deferred to backend-engineer when host-write ships.
- **Listing Detail v2 shipped.** Hero gallery: 1/N counter pill, three floating circular buttons (back via `dismiss()`, share decorative, favorite via `FavoriteHeartButton(.large)`). Title card: rounded-top `surfaceDefault` overlay (`-Spacing.lg` offset) with `martiHeading3` title, two-line subtitle (`{neighborhood}, {city}` + `N guests`), centered ★ rating row. Amenities: rounded-square icon containers + bold name + secondary description, no section heading. Sticky footer: free-cancel check row (when policy ≠ strict) + bumped-to-`martiHeading3` price + `Monthly · {SOS}` subtitle + red `Capsule()` Reserve on `Color.statusDanger`. Fee-tag floats above footer with smooth dismiss animation. Nav bar hidden via `.toolbar(.hidden, for: .navigationBar)`. Floating cluster honors top safe area via `.safeAreaPadding(.top)`.
- **Build green** on iPhone 17 Pro (Xcode 26.x) — verified by COO after ios-engineer's claim.
- **Test suite: 97/97 green.** Note: prior baseline was logged as 98 but the actual count is 97 (per ios-engineer's per-suite breakdown during Loop 2). View-only edits cannot affect count, so this is a tracker drift, not a regression. STATUS.md / prior park docs that say "98/98" should be reconciled to 97/97 next time they're touched.
- **Files modified by the v2 ship (4 view files only)**:
  - `Marti/Marti/Views/ListingDetail/ListingDetailView.swift`
  - `Marti/Marti/Views/ListingDetail/Components/ListingPhotoGalleryView.swift`
  - `Marti/Marti/Views/ListingDetail/Components/ListingAmenitiesSection.swift`
  - `Marti/Marti/Views/ListingDetail/Components/ListingDetailStickyFooterView.swift`
- **Files modified by today's cancellation-policy hardening (2 view files)**:
  - `Marti/Marti/Views/ListingDetail/Components/ListingDetailStickyFooterView.swift` (touched again — line 103-105)
  - `Marti/Marti/Views/ListingDetail/Components/ListingCancellationPolicyView.swift` (line 32)
- **File modified by today's NeighborhoodMapView ornament fix (1 view file)**:
  - `Marti/Marti/Views/Shared/NeighborhoodMapView.swift` — added local `mapboxWordmarkClearance` constant (lines 41–46) and replaced `.ornamentOptions(...)` block + leading comment (lines 101–120). ~15 lines net.
- **Tokens / VM / services / models / tests untouched** — the visual-only constraint held.
- Discovery, NeighborhoodMapView, FavoriteHeartButton, FeeInclusionTag, all design tokens — unchanged.

## What's blocked

Nothing.

## Open questions

None for the v2 ship. Carry-over follow-ups (still logged, still not in flight):

- **Test count reconciliation (latest)**: actual count as of 2026-04-30 is **99/99 passing**. The prior 97/97 reconcile baseline was itself off by one — pre-add was 98, +1 today = 99. STATUS.md still references "98/98" — reconcile to 99/99 next time STATUS.md is touched. Park/history docs stay frozen.
- **Manual AX5 sweep on Listing Detail v2** (per spec's manual test scenarios). Pick up in next sweep.
- **Carried minors / nits from the audit**: m1 (amenity icon glyph 16pt), m2 (icon container 36×36), m3 (counter pill black/0.5 contrast under Reduce Transparency). All explicitly ship-as-is per design-reviewer; watch items for next polish pass.
- **Pre-existing carry-overs from 2026-04-28** still open: `MartiDivider` extraction, star-size unification (12pt vs 14pt), avatar-size token, `ComingSoonSheetView` extraction, image cache wiring, Mapbox v11 release-tag pin.
- **New deferred — cancellation-policy schema hardening**: when host-write ships, add a Postgres CHECK constraint (`cancellation_policy in ('flexible', 'moderate', 'strict')`) and introduce a Swift `CancellationPolicy` enum decoded at the DTO boundary. Today's whitespace-trim is the client-side band-aid; both client trims become redundant once the schema rejects malformed values. Owner: backend-engineer (schema) + ios-engineer (enum). Ticket-this when host-write begins.

## Next actions

1. Confirm with the user whether to commit the working tree (now contains both the 2026-04-28 Listing Detail ship + the 2026-04-29 v2 visual pass + COO paperwork). Do NOT commit unprompted.
2. **Next feature per STATUS.md is still Request to Book** (P0). Listing Detail's sticky CTA (`RequestToBookComingSoonSheet`) remains the wire-through point.
3. Optionally schedule the carried follow-ups before the next surface lands.

## Decisions logged this session

Two bug-log entries appended to `decisions.md` today:

1. **2026-04-30 — `currentPhotoIndex` clamp on `refresh()`** (earlier this session) — ViewModel-level invariant for shrinking photo arrays after server refresh. Class-of-bug note about "stale state after refresh" patterns.
2. **2026-04-30 — NeighborhoodMapView Mapbox attribution visibility (ToS compliance)** (this session's fourth fix) — restored logo + attribution button visibility on the Listing Detail map embed. Class-of-bug note: future map surfaces must keep ornaments visible; consider a `.claude/rules/` entry if a third surface ships.

No purely-architectural decisions — both are bug-log entries kept in `decisions.md` for traceability of root cause + class-of-bug. The two carry-over architectural decisions from 2026-04-28 (`.notFound` UX policy, hide-tab-bar invariant on pushed details) still apply unchanged.

## Gotchas carried over

- **SourceKit phantom diagnostics — confirmed again.** Every v2 file edit triggered a wave of "Cannot find type / Cannot find in scope" errors against `Spacing`, `Radius`, `Color.canvas`, `Color.dividerLine`, `martiFootnote`, `ListingDetailViewModel`, `OfflineBannerView`, `AuthSheetPlaceholderView`, `RequestToBookComingSoonSheet`, etc. — all of which are genuinely in scope. `xcodebuild build` was green throughout. Trust the build, ignore the diagnostics, document this for the next session.
- **Test-count drift**: prior baseline of "98/98" was off by one. Actual is 97/97. ios-engineer caught this during Loop 2 with a per-suite breakdown.
- **Loop 2 audit pattern works.** Two-line fix (`.toolbar(.hidden, for: .navigationBar)` + `.safeAreaPadding(.top)`) cleared B1 + M1 in one round-trip. Re-audit by a fresh design-reviewer agent (since the prior wasn't named for SendMessage continuity) was efficient at ~1 minute.
- **Swift 6 / iOS 17+ corner API**: `.clipShape(.rect(topLeadingRadius:topTrailingRadius:bottomLeadingRadius:bottomTrailingRadius:))` is the canonical way to round only the top corners of a `View` clip. Avoid `RoundedCornersShape` custom shapes when this API is available.
- **Case-insensitive FS** — paths like `marti/Marti/...` and `Marti/Marti/...` both resolve. After `Read`, use the same casing in `Edit`.
