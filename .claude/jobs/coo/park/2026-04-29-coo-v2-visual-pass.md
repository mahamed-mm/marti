# Park Document — coo — 2026-04-29 (v2 visual pass session)

> This is the end-of-session handoff. The next session of this role reads it first.

## Session summary

Listing Detail visual + layout pass to match an Airbnb reference. User invoked COO mode in plan mode, attached `screenshots/airbnb_141871.webp`, listed seven specific zones to restyle, and constrained scope to "visual / layout only — no new features, no schema changes, no new components unless strictly needed, reuse `DesignTokens.swift`, keep ViewModel + tests untouched, no QA delegation unless tests break." Plan-mode workflow: read mandatory COO files → 1 Explore agent for primitive verification → 4-question AskUserQuestion clarification round (card surface, host tenure, footer subtitle, share button) → wrote plan file → ExitPlanMode → user approved with auto-mode active. Execution: wrote `docs/specs/Listing Detail v2 visual pass.md`, dispatched ios-engineer (Loop 1, ~10 min, 4 files modified, build + 97 tests green), dispatched design-reviewer (verdict Loop 2: 1 blocker B1 + 1 major M1, three minors and two nits all ship-as-is), dispatched ios-engineer Loop 2 with the focused 2-line fix, dispatched fresh design-reviewer for re-audit (verdict **Ship**), updated objectives and current.md, wrote this park doc. End state: ✅ build green, ✅ 97/97 tests green (ios-engineer reconciled the prior "98" baseline drift), ✅ design verdict Ship, no architectural decisions added, all five locked decisions held through both loops with zero scope expansion.

## Files touched

| File                                                                | Change   | Why                                                                 |
| ------------------------------------------------------------------- | -------- | ------------------------------------------------------------------- |
| `~/.claude/plans/coo-i-want-quirky-lampson.md`                      | Created  | Plan-mode plan file with locked decisions and zone-by-zone recipe.  |
| `docs/specs/Listing Detail v2 visual pass.md`                       | Created  | Canonical spec for the v2 visual pass; ios-engineer's source of truth. |
| `.claude/jobs/coo/control/objectives.md`                            | Modified | Listing Detail v2 added to Completed (2026-04-29).                  |
| `.claude/jobs/coo/context/current.md`                               | Modified | Reflects post-v2-ship state, test-count reconciliation note.        |
| `.claude/jobs/coo/park/2026-04-29-coo-v2-visual-pass.md`            | Created  | This park doc.                                                      |
| `.claude/jobs/ios-engineer/inbox/...-Listing Detail v2 visual pass` | Created  | Loop 1 delegation; ios-engineer moved to its history.               |
| `.claude/jobs/ios-engineer/inbox/...-Listing Detail v2 audit fixes` | Created  | Loop 2 delegation; ios-engineer moved to its history.               |
| `.claude/jobs/design-reviewer/inbox/...-Listing Detail v2 visual pass` | Created | Audit delegation; design-reviewer moved to its history.            |

(Specialist roles owned all production Swift code changes — see their park docs for paths.)

## Decisions made

No architectural decisions this session. All five locked decisions during the clarification round were scope-bounded visual choices captured in the spec, not in `control/decisions.md`:

1. **Card surface** = `Color.surfaceDefault` rounded-top overlay (not literal white).
2. **Host tenure copy** dropped entirely (no "N years hosting").
3. **Footer subtitle** keeps `fullSOSPriceLine` (no date range copy).
4. **Share button** is decorative (no `ShareLink` plumbing).
5. **Reserve button** uses `Color.statusDanger` (closest brand-red token Marti owns).

The two prior architectural decisions (2026-04-28: `.notFound` UX policy + hide-tab-bar invariant) still apply unchanged.

## Open questions / blockers

None. Both loops landed clean with zero scope expansion. Carry-over follow-ups (logged, NOT bundled into this ship):

- **Test count reconciliation**: STATUS.md and prior park docs reference "98/98" — actual is 97/97 (verified per-suite by ios-engineer Loop 2). Reconcile next time those files are touched.
- **Audit minors / nits ship-as-is per design-reviewer**: m1 (amenity glyph 16pt magic), m2 (icon container 36×36 magic), m3 (counter pill `Color.black.opacity(0.5)` does not honor Reduce Transparency — watch item for next polish pass), n1 (fee-tag dual-tracked transition), n2 (`Spacing.sm` for counter-pill v-padding).
- **Pre-existing carry-overs from 2026-04-28** still open: `MartiDivider` extraction, star-size unification (12pt vs 14pt), avatar-size token, `ComingSoonSheetView` extraction, image-cache wiring (`CachedImageService`), Mapbox v11 release-tag pin.
- Manual AX5 sweep on Listing Detail v2 — out of QA scope this loop.

## Inbox state at session end

Empty. No outstanding messages. The 2026-04-29 03:15 inbox file (Loop 1) and 04:10 inbox file (Loop 2) both flowed to ios-engineer's history.

## Outbox summary

Three delegation messages dispatched (all routed to specialists' inboxes; specialists moved them to their own history folders):

- → ios-engineer Loop 1: full visual pass across 4 files (gallery, view, amenities, footer).
- → design-reviewer: HIG + token audit on the new layout. Returned Loop 2 verdict.
- → ios-engineer Loop 2: B1 + M1 two-line fix.
- → design-reviewer (fresh dispatch, since prior agent wasn't named for SendMessage): re-audit pass cleared both. Verdict: Ship.

## What the next session should do first

1. Read this park doc + `docs/STATUS.md` (Next-up still = Request to Book).
2. Read `decisions.md` 2026-04-28 entries (`.notFound` UX, hide-tab-bar invariant) — both still apply to any future detail-ish surface.
3. Confirm with the user whether to commit the working tree. The unstaged changes now span (a) the original 2026-04-28 Listing Detail ship + COO paperwork, and (b) the 2026-04-29 v2 visual pass + COO paperwork. Do NOT commit unprompted. If the user says "commit", group them logically (e.g., one commit per ship + one for paperwork) or as the user prefers.
4. If the user wants to keep moving, kick off **Request to Book** with `/ship-feature request-to-book` (or `/generate-spec` first if they prefer per-step).
5. Optionally schedule small follow-ups: the m1/m2/m3 token cleanup before next polish pass, the AX5 manual sweep, and the test-count baseline reconciliation in `STATUS.md`.

## Gotchas for next session

- **SourceKit phantom diagnostics confirmed again.** Every v2 file edit triggered a wave of "Cannot find type / Cannot find in scope" errors against `Spacing`, `Radius`, `Color.canvas`, `Color.dividerLine`, `martiFootnote`, `ListingDetailViewModel`, `OfflineBannerView`, `AuthSheetPlaceholderView`, `RequestToBookComingSoonSheet`, etc. — all genuinely in scope. `xcodebuild build` was green throughout both loops. **Trust the build.** Re-running `xcodebuild build` once after the agent finishes is cheap insurance to ground-truth the agent's claim.
- **Test-count baseline drift**: prior session logged "98/98", actual count is **97**. Caught by ios-engineer's per-suite breakdown during Loop 2. View-only edits cannot affect count — this is pre-existing tracker drift.
- **Subagent naming for re-audit continuity**: I dispatched the original design-reviewer with `Agent({...})` but didn't pass a `name`, so I couldn't `SendMessage` to continue them for the re-audit. A fresh dispatch worked fine (~1 min for 2-line re-check), but for future loops where context cost matters, **pass `name:` to the first dispatch** so the same agent can be continued via SendMessage.
- **Loop 2 fix surface was tiny** (~2 lines, single file): `.toolbar(.hidden, for: .navigationBar)` replaces `.navigationTitle + .navigationBarTitleDisplayMode(.inline)`; `.safeAreaPadding(.top)` replaces `.padding(.top, Spacing.base)`. Pattern: when design-reviewer's findings are surgical, the COO routing overhead (write inbox file, dispatch agent, wait, dispatch re-audit) dominates the actual implementation time. Acceptable for the audit traceability; consider in-line edits in main session for genuinely 1-line fixes that don't need a written audit trail.
- **`/ship-feature` checkpoints scale to revisions too.** The checkpoint protocol (AskUserQuestion at scope-decision points, batch decisions, route silently between specialists) worked just as well for a visual revision as for a fresh feature ship. Keep using it.

## Session metadata

- **Duration**: approx. 60 minutes wall-clock.
- **Build state at end**: clean. `** BUILD SUCCEEDED **` (verified by COO post-ios-engineer claim).
- **Test state at end**: passing. `** TEST SUCCEEDED **`. **97/97** in `MartiTests`.
- **Working tree**: unstaged changes spanning both the 2026-04-28 Listing Detail ship and the 2026-04-29 v2 visual pass plus all COO paperwork. User did not request a commit; do NOT commit unprompted.
- **Verdict**: Ship.
