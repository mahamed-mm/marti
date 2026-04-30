# Park Document — coo — 2026-04-30 (NeighborhoodMapView Mapbox-attribution ToS fix)

> Fourth COO session of the day. Earlier sessions: doc reconcile, photo-index clamp (TDD), cancellation-policy whitespace hardening. This park doc covers only the NeighborhoodMapView ornament fix; the prior three are captured in `2026-04-30-coo.md` and `2026-04-30-coo-cancellation-policy.md`.

## Session summary

A code-review finding flagged `NeighborhoodMapView.swift:99-103`: the `.ornamentOptions(...)` block used `CGPoint(x: -200, y: -200)` margins on both `LogoViewOptions` and `AttributionButtonOptions`, pushing the Mapbox logo + (i) attribution button off the visible 200pt × full-width embed. The leading comment (lines 94–98) explicitly admitted the intent and rationalized it as "attribution still discoverable on the full Discovery map." That rationalization does not hold under Mapbox SDK v11 ToS, which requires per-view visibility on every rendered map (derivative previews included).

User invoked `/fix-bug` with the explicit instruction: "Verify each finding against the current code and only fix it if needed." COO verified the finding by reading `NeighborhoodMapView.swift` directly, confirmed the violation, and contrasted with `ListingMapView.swift:630-643` — which handles ornaments correctly (`.bottomLeading` + positive margins via `Spacing.screenMargin` + a `mapboxWordmarkClearance` constant). Wrote a plan (approved), then executed the fix directly in the main session per CLAUDE.md's trivial / single-concern routing rule: ~15 lines net in one self-contained view, well below the threshold that justifies subagent delegation, and aligned with the recent precedent of executing single-file fixes directly to sidestep harness plan-mode gating that has been trapping specialist delegations.

Fix anchors logo + attribution at `.bottomLeading` with `Spacing.md` (8pt) margins; the (i) is shifted right by a local `mapboxWordmarkClearance: CGFloat = 100` constant matching Discovery's value (copied, not shared, because Discovery's is `private` and the file's leading comment explicitly defends keeping `NeighborhoodMapView` self-contained — "no shared map factory"). Scale bar stays hidden (this is a static preview, not a navigation surface — that part of the original rationale held up).

Build green. Full `MartiTests` suite **99/99 passing, 0 failures** — same baseline as the start of the session, confirming a view-only edit with no test impact, as expected.

## Files touched

| File                                                                       | Change   | Why                                                                                                                                                                                              |
| -------------------------------------------------------------------------- | -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `marti/Marti/Views/Shared/NeighborhoodMapView.swift`                       | Modified | Added local `mapboxWordmarkClearance` constant (lines 41–46). Replaced `.ornamentOptions(...)` block + leading comment (lines 101–120). ~15 lines net.                                           |
| `.claude/jobs/coo/control/decisions.md`                                    | Modified | Appended bug-log entry "2026-04-30 — Bug log: NeighborhoodMapView restores Mapbox logo + attribution visibility (ToS compliance)" with full context, alternatives, files-changed, untestable rationale. |
| `.claude/jobs/coo/context/current.md`                                      | Modified | Updated session header, added a fourth bullet under "What's in flight," added a new "Mapbox ornaments now ToS-compliant" line under "What's clean / stable," appended the file to "Files modified" list, expanded "Decisions logged this session." |
| `.claude/jobs/coo/park/2026-04-30-coo-mapbox-ornaments.md`                 | Created  | This park doc.                                                                                                                                                                                    |
| `/Users/moha/.claude/plans/verify-each-finding-against-ancient-flute.md`   | Created  | Approved plan from plan mode prior to execution. Outside the repo (Claude harness plan storage); kept for traceability.                                                                          |

## Decisions made

### NeighborhoodMapView ornament fix (full entry in `decisions.md`)

- **What**: Restore Mapbox logo + (i) attribution visibility on the 200pt Listing Detail neighborhood embed by replacing the off-screen negative margins with `.bottomLeading` positioning + small positive `Spacing.md` margins.
- **Why**: Mapbox SDK v11 ToS requires per-view visibility on every rendered map view; the original "attribution discoverable elsewhere" rationale doesn't satisfy that. Real compliance defect.
- **Alternatives considered**:
  - Build an explicit custom attribution UI elsewhere in the view → rejected; SDK's built-in (i) button keeps upstream attribution sheet in sync automatically, hand-rolled label would drift.
  - Default-position the ornaments by removing the margins parameter entirely → rejected; small deliberate margins read better than ornaments hugging the unclipped edge of the rounded `Radius.md` clip.
  - Extract a shared ornament factory between `ListingMapView` and `NeighborhoodMapView` → rejected; premature abstraction at two callsites; the file's leading comment explicitly defends self-contained design.
  - Static caption like "© Mapbox · OpenStreetMap" beneath the embed → rejected; loses the "tap-to-open attribution sheet" affordance the SDK provides for free.
- **Reversibility**: Cheap. Single file, ~15 lines. Reversible by `git revert`.

This is a **bug-log decision** (root cause + class-of-bug + reversal cost), not a new architectural rule. Class-of-bug note in `decisions.md`: any future map embed must keep ornaments visible; if a third surface ships, formalize as a `.claude/rules/` entry rather than relying on review catches.

## Open questions / blockers

None.

Carry-over follow-ups (still open, still not in flight) — copied forward from prior `current.md` entries:

- **Manual AX5 sweep on Listing Detail v2** (per spec's manual test scenarios). The visual confirmation that logo + (i) render correctly on the simulator can be bundled into this same sweep.
- **Carried minors / nits from the v2 audit**: m1 (amenity icon glyph 16pt), m2 (icon container 36×36), m3 (counter pill black/0.5 contrast under Reduce Transparency).
- **Pre-existing carry-overs from 2026-04-28**: `MartiDivider` extraction, star-size unification (12pt vs 14pt), avatar-size token, `ComingSoonSheetView` extraction, image cache wiring, **Mapbox v11 release-tag pin** (this is the Mapbox SPM pin to a release tag before App Store submit — distinct from today's ornament fix, but the same surface area; both touch Mapbox config).
- **Cancellation-policy schema hardening**: Postgres CHECK + Swift `CancellationPolicy` enum, deferred to backend-engineer + ios-engineer when host-write ships.
- **`.claude/rules/` entry for map-ornament visibility**: deferred until a third map surface ships. Today's bug-log decision-entry is the memory for now.

## Inbox state at session end

- COO inbox: empty going in, empty going out — this session was triggered by the user's `/fix-bug` invocation, not an inbox message. No items to process.

## Outbox summary

- No outbox messages this session. The fix was executed directly in the main session; no specialist delegation was invoked, so no inbox/outbox traffic between roles.

## What the next session should do first

1. **Read `docs/STATUS.md`, `docs/PRD.md`, `docs/ARCHITECTURE.md`, this `current.md`, the most recent COO park doc** (this one).
2. **Read the COO inbox** for any new items.
3. **Confirm with the user whether to commit the working tree.** It now carries: 2026-04-28 ship + 2026-04-29 v2 visual pass + photo-index clamp + cancellation-policy hardening + today's NeighborhoodMapView ornament fix + COO paperwork from all four sessions today. **Do not commit unprompted.**
4. **Next feature per STATUS.md is still Request to Book** (P0). Listing Detail's sticky CTA (`RequestToBookComingSoonSheet`) is the wire-through point.
5. **Optionally schedule the carried follow-ups** (Mapbox v11 release-tag pin is the most ToS-adjacent of the carry-overs; today's fix doesn't change its priority but is a natural pairing if a session ever wants to clean up Mapbox-area work in one pass).

## Gotchas for next session

- **SourceKit phantom diagnostic on `MapboxMaps` import** — confirmed yet again. The line `import MapboxMaps` triggers a "No such module 'MapboxMaps'" diagnostic in the editor; `xcodebuild build` succeeds. This is consistent with the prior session's note about phantom diagnostics on `Spacing`, `Radius`, design tokens, etc. Trust the build, not the diagnostic.
- **Path-casing matters in the Edit tool**, even on a case-insensitive macOS FS. Reading `marti/marti/Views/Shared/NeighborhoodMapView.swift` (lowercase second segment) and then editing `marti/Marti/Views/Shared/NeighborhoodMapView.swift` (capitalized) tripped an "File has not been read yet" error on the first Edit call. The find/grep utility uses the on-disk casing (`marti/Marti/...`); the git-status output uses the lowercase casing. Pick one and stick with it within a single tool-call sequence. (Already noted in the prior `current.md` gotchas, observed again today.)
- **Subagent delegation continues to be unreliable under harness plan-mode gating.** Today's fix was executed directly in the main session per the same precedent set in the photo-index and cancellation-policy fixes earlier today. For trivial single-concern Mapbox-config edits, direct execution is the right call — just document the lane in the decision log so the routing isn't lost.
- **Mapbox SDK v11 `OrnamentOptions` API surface** for reference: `LogoViewOptions(position:, margins:, contentInsets:)` and `AttributionButtonOptions(position:, margins:, contentInsets:)` — both default to `.bottomLeading` with `CGPoint(x: 8, y: 8)` if you omit parameters. Our two map surfaces both override to use `Spacing.md` margins explicitly so the layout intent reads in the source rather than relying on SDK defaults.
- **`mapboxWordmarkClearance` is duplicated** between `ListingMapView` (`= 100`, `private`) and `NeighborhoodMapView` (`= 100`, `private`, added today). Two callsites is fine; if a third Mapbox-using view lands, the duplication crosses the threshold for extraction. Watch item.

## Session metadata

- **Duration**: approx. 25 minutes (verify finding + plan + plan approval + edit + build + full test suite + COO paperwork)
- **Build state at end**: clean (`** BUILD SUCCEEDED **` on iPhone 17 Pro)
- **Test state at end**: **99/99 passing**, 0 failures (`** TEST SUCCEEDED **`)
