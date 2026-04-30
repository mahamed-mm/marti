# Park Document — coo — 2026-05-01 (Listing Detail v3 ship)

> First COO session of 2026-05-01. Single substantive job: orchestrate Listing Detail v3 (visual + scroll-rhythm pass) end-to-end through the specialist pipeline. Today's prior work all happened on 2026-04-30 (4 sessions: doc reconcile, photo-index clamp, cancellation-policy hardening, NeighborhoodMapView ornaments).

## Session summary

User invoked COO to kick off **Listing Detail v3**, the third visual iteration on the Listing Detail surface (v1 ship → v2 visual pass → v3 scroll-rhythm restructure). Spec at `docs/specs/Listing Detail v3 visual pass.md` restructures the content stack into 10 hairline-separated sections (§B–§M) mirroring an Airbnb-style reference.

The session ran the full role pipeline as instructed by the user:

1. **Pre-flight reads** — STATUS, PRD, ARCHITECTURE, current.md, latest park doc (2026-04-30 NeighborhoodMapView), inbox (empty). Flagged five findings to user before any delegation: spec-path mismatch (user's reference path didn't exist; actual spec is in `docs/specs/`), dirty working tree, test baseline drift in STATUS.md, prior subagent gating issues, and a **VM-scope conflict** between user's "no VM changes" instruction and spec §G + AC #12 (which add `isAmenitiesSheetPresented` + a unit test).
2. **AskUserQuestion x2** — resolved the VM-scope conflict (chose **View `@State`**, sheet state on the View rather than the VM, test count holds at 99/99) and the commit posture (**stack v3 on dirty tree**, no commits in-session).
3. **Plan written + approved** — stored at `/Users/moha/.claude/plans/coo-kicking-off-polished-goblet.md`. ExitPlanMode → user approved.
4. **Loop 1 ios-engineer delegation** (~26 minutes) — created 6 new component files + modified 4 existing, plus 1 verify-only no-op. Build green; 99/99 tests; structured return summary with engineering judgment calls flagged (§C col-3 fallback chose **em-dash placeholder** over spec's `reviewCount` recommendation; §I expand-disc chose Apple Maps hand-off via `MKMapItem(location:address:).openInMaps()`).
5. **Checkpoint (c)** — surfaced to user. User green-lit design-reviewer.
6. **Loop 1 design-reviewer audit** (~5 minutes) — returned **fix-and-ship** with 2 blockers (B1: §D not tappable; B2: §L triple-buzz haptic) + 4 majors (M1: §J header AT erased; M2: §G Show-all missing fill; M3: §I disc glyph 16pt vs spec's 20pt; M4: §G Show-all missing haptic) + 5 minors (m1–m5, carry-over). Validated all three engineering judgment calls (em-dash, Apple Maps hand-off, `surfaceDefault` avatar background).
7. **Checkpoint (d)** — surfaced findings to user. **AskUserQuestion x2** — user approved fixing all 6 + a re-audit (Loop 2).
8. **Loop 2 ios-engineer fast-follow** (~9 minutes, via SendMessage to existing agent — UUID-addressed, worked first try) — all 6 fixes applied across 4 files. Build green; 99/99 tests; M2 stroke dropped entirely (defensible per `PrimaryButtonStyle` precedent + dark-mode contrast).
9. **Loop 2 design-reviewer re-audit** (~4 minutes, also via SendMessage) — **SHIP**. All 6 cleared, zero regressions, AC #6/#7/#13 flipped Partial → Pass. Net: #1–#11, #13, #14 all Pass; #12 overridden.
10. **Close-out** — this park doc + current.md update.

**Outcome**: v3 is ship-ready. Working tree carries all of v1 + v2 + 4 prior fixes + COO paperwork + v3 Loop 1 + v3 Loop 2 + today's COO paperwork. Nothing committed (per locked posture). User decides commit grouping next.

## Files touched

### Listing Detail v3 implementation (ios-engineer)

**Created (6 new component files):**

| File                                                                                          | Why                                                                            |
| --------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| `marti/Marti/Views/Shared/ComingSoonSheetView.swift`                                          | Generic sheet for §L houseRules + safety. Closes 2026-04-28 carry-over.        |
| `marti/Marti/Views/ListingDetail/Components/ListingDetailHighlightsRow.swift`                 | §C 3-column stat row with vertical hairlines + Guest-favorite gate.            |
| `marti/Marti/Views/ListingDetail/Components/ListingDetailWhyStaySection.swift`                | §E 3 bare-glyph rows (no container box) computed from `Listing` only.          |
| `marti/Marti/Views/ListingDetail/Components/ListingDetailExpandedHostCard.swift`              | §K `surfaceElevated` + `Radius.lg` two-column expanded host card.              |
| `marti/Marti/Views/ListingDetail/Components/ListingDetailThingsToKnowSection.swift`           | §L 3 tappable rows; owns `enum DetailSheet` + `.sheet(item:)` routing.         |
| `marti/Marti/Views/ListingDetail/Components/ListingAmenitiesSheet.swift`                      | §G destination sheet using v2's stroked-container row recipe.                  |

**Modified (5 — 4 with real diffs across both loops, 1 verify-only no-op):**

| File                                                                                          | Loops | Why                                                                                                                                |
| --------------------------------------------------------------------------------------------- | ----- | ---------------------------------------------------------------------------------------------------------------------------------- |
| `marti/Marti/Views/ListingDetail/ListingDetailView.swift`                                     | L1+L2 | Re-ordered content stack §B→§L; §I map-callsite affordances + Apple Maps hand-off; sheet `@State`; **L2**: B1 ScrollViewReader + §K anchor + §D tap; M3 disc glyph 16pt → 20pt. |
| `marti/Marti/Views/ListingDetail/Components/ListingAmenitiesSection.swift`                    | L1+L2 | Bare glyphs in this surface, 6-row preview cap, "Show all" stroked button, `onShowAll:` callback. **L2**: M2 fill + stroke drop; M4 haptic added. |
| `marti/Marti/Views/ListingDetail/Components/ListingReviewsAggregateView.swift`                | L1+L2 | Centered hero rating block + Guest-favorite gate + footnote. **L2**: M1 `.accessibilityElement(.combine)` scoped to inner block, header AT trait restored. |
| `marti/Marti/Views/ListingDetail/Components/ListingDetailStickyFooterView.swift`              | L1    | §M restructure; `secondaryLine: String?` cleanly omits "Monthly · SOS" sub-line when SOS is nil.                                   |
| `marti/Marti/Views/ListingDetail/Components/ListingDetailThingsToKnowSection.swift`           | L2    | B2: lifted `.sensoryFeedback` from per-row to outer VStack; eliminated triple-buzz.                                                |
| `marti/Marti/Views/ListingDetail/Components/ListingHostCardView.swift`                        | —     | Verify-only; no edit.                                                                                                              |

### Paperwork

| File                                                                                          | Change   | Why                                                                                |
| --------------------------------------------------------------------------------------------- | -------- | ---------------------------------------------------------------------------------- |
| `.claude/jobs/ios-engineer/park/2026-05-01-listing-detail-v3.md`                              | Created  | ios-engineer's park doc, includes "Loop 2 — fix round" section.                    |
| `.claude/jobs/ios-engineer/context/current.md`                                                | Modified | ios-engineer state at session end.                                                 |
| `.claude/jobs/design-reviewer/park/2026-05-01-listing-detail-v3-audit.md`                     | Created  | design-reviewer park doc; Loop 1 + Loop 2 sections.                                |
| `.claude/jobs/design-reviewer/context/current.md`                                              | Modified | design-reviewer state flipped to ship.                                             |
| `.claude/jobs/coo/park/2026-05-01-coo-listing-detail-v3.md`                                   | Created  | This file.                                                                         |
| `.claude/jobs/coo/context/current.md`                                                          | Modified | COO state at session end.                                                          |
| `/Users/moha/.claude/plans/coo-kicking-off-polished-goblet.md`                                | Created  | Approved plan from plan mode prior to delegation. Outside the repo (harness storage). |

**Untouched (per locked scope):**

- `marti/Marti/ViewModels/ListingDetailViewModel.swift` — VM scope override held.
- `marti/MartiTests/**` — no test changes; baseline 99/99 held.
- `marti/Marti/Extensions/DesignTokens.swift` — no new tokens.
- `marti/Marti/Services/**`, `Models/**` — no service or schema changes.
- `marti/Marti/Views/Shared/NeighborhoodMapView.swift` — callsite-only changes; map view itself unchanged.
- `docs/STATUS.md` — left for user's commit decision (still says 98/98; reconcile to 99/99 + add Listing Detail v3 paragraph at commit time).

## Decisions made

### 1. VM-scope override — sheet state on View, not VM

- **What**: §G "Show all amenities" sheet presentation state lives on `ListingDetailView` as `@State private var isAmenitiesSheetPresented: Bool = false`, not on `ListingDetailViewModel`. Spec §G + AC #12 explicitly overridden by user instruction. Test count holds at 99/99 — no new test added.
- **Why**: User's "visual/layout only" instruction was unambiguous. Project precedent supports it: `isFeeTagDismissed` is on the View, the §L `enum DetailSheet` (per the same spec) is on the View. Sheet presentation is pure UI navigation state with no business meaning — it never belonged on the VM.
- **Alternatives considered**:
  - **Allow VM addition + test (spec literal)**: rejected per user instruction.
  - **Drop §G "Show all" entirely**: rejected — would explicitly fudge AC #6, leave amenity overflow undiscoverable.
- **Reversibility**: Cheap. Promoting to VM later is one-line. The design-reviewer Loop 2 confirmed the View-State approach reads correctly.

### 2. Commit posture — stack v3 on existing dirty tree

- **What**: ios-engineer made no commits across either loop; v3 lands on top of the existing 4-day-deep dirty tree (v1 ship + v2 + 4 fixes + COO paperwork + v3 L1 + v3 L2 + today's COO paperwork). User decides commit grouping later.
- **Why**: User chose this option at AskUserQuestion. Matches the persistent `current.md` guidance "do not commit unprompted." Avoids fragmenting commit history during a high-iteration session.
- **Alternatives considered**: Commit pre-v3 work first as a checkpoint; commit per-step inside session.
- **Reversibility**: Cheap. User can group / split as they prefer at commit time.

### 3. Engineering judgment calls (validated by design-reviewer Loop 1)

These three weren't COO-originated but were surfaced for COO review and stuck after design-reviewer signed off. Logging here so future sessions don't re-litigate.

- **§C col-3 em-dash fallback** (kept, not `reviewCount` as spec recommended). design-reviewer optionally suggested promoting `textTertiary` → `textSecondary` (m1, deferred).
- **§I expand-disc + "Show more" pairing** (both kept; both call `MKMapItem(location:address:).openInMaps()`). The disc and the caption serve different cohorts (thumb-affordance vs text/AT-affordance). Apple Maps hand-off used the iOS 26-current `MKMapItem(location:address:)` initializer, not the deprecated `placemark:`.
- **§K avatar background `Color.surfaceDefault`** (kept, not `canvas`). One step down from the card's `surfaceElevated` reads as recessed; two steps down would punch through.

### 4. M2 §G "Show all" stroke drop (Loop 2)

- **What**: Loop 2 fix added `surfaceElevated` fill **and dropped the hairline stroke entirely**. Result: fill-only button.
- **Why**: Spec §G "View all-style buttons" invariant lists fill + radius + minHeight + font + foreground only — no stroke. Project precedent `PrimaryButtonStyle` is fill-only. In dark mode the `surfaceElevated` (#1F2D42) on `surfaceDefault` (#131D2B) gives ~12 luminance units of separation — enough to read as a discrete affordance without chrome. design-reviewer Loop 2 explicitly endorsed this call.
- **Alternatives considered**: Keep the stroke as a hairline boundary (rejected: divergent from `PrimaryButtonStyle`, adds chrome without information).
- **Reversibility**: Cheap. `.overlay(RoundedRectangle.stroke(...))` is one line if a future audit wants the hairline back.

**No purely-architectural decisions this session.** All four entries are visual/UI design decisions with traceability via this park doc + the spec. Nothing appended to `decisions.md` — this is a polish ship, not an architecture change.

## Open questions / blockers

None. v3 is ship-ready per design-reviewer Loop 2.

### Carry-over follow-ups (still open, still not in flight)

**New from v3 (filed by ios-engineer + design-reviewer):**

- **f1** — Per-room photos schema column + `ListingBedroomsRail` component (§H deferred slot).
- **f2** — `host_languages: [String]` schema column (§K hard-coded "Speaks English & Somali").
- **f3** — `host_city: String` schema column (§K hard-coded `listing.city`).
- **f4** — Years-hosting / response-rate / response-time stats (§K stat rows we couldn't populate).
- **f5** — Per-review carousel below §J hero block (Feature 5 territory).
- **f6** — Real "Send message to host" button (Feature 4 territory).
- **f7** — Collapsing nav-bar morph (v4 polish, IMG_0606 → IMG_0607 in the inspiration screenshots).
- **f8** — Translate notice + Trust banner (later features).
- **m1** — §C col-3 em-dash foreground `textTertiary` → `textSecondary` (one-line tweak).
- **m2** — §I disc accessibility hint redundancy (label already telegraphs the action).
- **m3** — `ListingAmenitiesSheet` divider uses `amenity != amenities.last` — fragile under duplicate strings; switch to enumerated index.
- **m4** — `ComingSoonSheetView` has both a "Got it" button and a "Cancel" toolbar; pick one (HIG: prefer toolbar dismiss).
- **m5** — §L row `Spacer(minLength: Spacing.md)` may push chevron off-screen at AX5 with very long subtitles. Watch.
- **f9** — Rating-star size unification (v3 introduced a third 10pt size — now three star sizes across the surface: 10pt, 12pt, 14pt).
- **f10** — `MartiDivider` extraction (carry-over `m5` from prior sessions; v3 added five more inline `Divider().background(Color.dividerLine)` instances; pressure increasing).

**Pre-existing carry-overs (still open):**

- **2026-04-29 v2 audit minors**: amenity icon glyph 16pt (m1), icon container 36×36 (m2), counter pill black/0.5 contrast under Reduce Transparency (m3) — all explicit ship-as-is per design-reviewer.
- **2026-04-28 carry-overs**: star-size unification (now 12pt vs 14pt vs 10pt — see f9), avatar-size token, image cache wiring, **Mapbox v11 release-tag pin** (the SPM pin to a release tag before App Store submit; current `main` tracking remains a submission blocker per STATUS.md).
- **`ComingSoonSheetView` extraction** — **CLOSED** by v3 Loop 1 (the file was created).
- **Cancellation-policy schema hardening** (Postgres CHECK + Swift `CancellationPolicy` enum, deferred to backend-engineer + ios-engineer when host-write ships).
- **`.claude/rules/` entry for map-ornament visibility** — deferred until a third map surface ships.

**Manual verification still owed (lightweight):**

- **AX5 sweep on simulator** — design-reviewer Loop 2 marked AC #13 Pass on programmatic AT traits (header trait, button trait, hint, label, focus order), but the manual VoiceOver + Dynamic Type AX5 sweep on simulator wasn't run this session. Recommend bundling with the next manual sweep alongside Listing Detail v2's still-owed AX5 sweep.

### Two candidate `.claude/rules/swiftui.md` additions surfaced by ios-engineer

Worth user discussion before adding, since these would become project-wide policy:

1. **Combine-at-root pitfall**: When a section has a `Text` header you want VoiceOver to announce as a heading, never `.accessibilityElement(children: .combine)` at the section root — combine on the contentful child instead. The combine modifier silently flattens nested AT traits including `.isHeader`. This was the root cause of M1 (§J in Loop 1) and is easy to repeat.
2. **`.sensoryFeedback` ownership**: `.sensoryFeedback(_, trigger:)` belongs on the surface that **owns the state change**, not on each surface that emits the gesture. When N rows watch the same trigger expression, all N fire on each state change. This was the root cause of B2 (§L triple-buzz in Loop 1).

If user wants these codified: append to `.claude/rules/swiftui.md`. Both are well-supported by today's session-evidence.

## Inbox state at session end

- **COO inbox**: empty going in, empty going out. No specialist sent COO any messages this session — both delegations returned via the structured-summary protocol.

## Outbox summary

- **To `ios-engineer` (a751a9e22ed65a6b1)**: Loop 1 delegation (Listing Detail v3 implementation) + Loop 2 fast-follow (B1+B2+M1+M2+M3+M4 fixes). Both via fresh Agent spawn (Loop 1) and SendMessage continuation (Loop 2). UUID-addressed continuation worked first try — useful precedent given the SendMessage tool's "name not UUID" guidance is loose.
- **To `design-reviewer` (a04da9a857f892343)**: Loop 1 audit + Loop 2 re-audit. Same spawn-then-resume pattern.

No outbox messages to other roles.

## What the next session should do first

1. **Read `docs/STATUS.md`, `docs/PRD.md`, `docs/ARCHITECTURE.md`, COO `current.md`, this park doc, COO inbox.** Standard preflight.
2. **Confirm with user the commit decision.** v3 is ship-ready. Working tree now carries: 2026-04-28 v1 ship + 2026-04-29 v2 visual pass + 4× 2026-04-30 fixes + 2026-05-01 v3 (Loops 1 + 2) + COO paperwork from all of it. **Do not commit unprompted** — but prompt the user that v3 is ready for a STATUS.md reconcile + commit if they want it.
3. **STATUS.md reconcile** (when user OKs commit): test count `98/98` → `99/99`; add a Listing Detail v3 paragraph under "Shipped" — section restructure + 6 new components + bare-glyph why-stay rows + 3-column highlights stat row + centered reviews hero + expanded host card + things-to-know sheet rows + sticky-footer cleanup; bump "Most recent audits" if a new audit file lands.
4. **Decide on the two `.claude/rules/swiftui.md` candidate additions** (combine-at-root pitfall, sensoryFeedback ownership). Both are well-evidenced; both prevent recurring footguns. Surface to user for the call.
5. **Manual AX5 sweep** on Listing Detail v3 in simulator — bundle with Listing Detail v2's still-owed sweep. Then confirm AC #13 fully clean (programmatic side already verified by design-reviewer Loop 2).
6. **Next feature per STATUS.md is still Request to Book** (P0). Listing Detail's sticky CTA (`RequestToBookComingSoonSheet`) remains the wire-through point. Start with `/generate-spec request-to-book` when user is ready.
7. **Optionally schedule the carried follow-ups.** Mapbox v11 release-tag pin remains the most submission-adjacent of the carry-overs. f1–f10 + m1–m5 + prior carries are accumulating; a sweep PR before Request to Book lands could compress the surface.

## Gotchas for next session

- **SourceKit phantom diagnostics — confirmed yet again.** Today's fresh wave: `Spacing`, `Radius`, `Color.coreAccent`, `Color.surfaceDefault`, `Color.surfaceElevated`, `Color.textPrimary`, `Color.textSecondary`, `Color.textTertiary`, `Color.statusWarning`, `Font.martiHeading4`, `Font.martiDisplay`, `Font.martiLabel1`, plus a `Cannot find type 'ListingDetailViewModel' in scope` ghost on `ListingDetailView.swift:27` and `Cannot find 'ComingSoonSheetView' in scope` on `ListingDetailThingsToKnowSection.swift:127`. **All fakes** — `xcodebuild build` was clean throughout both loops, and `xcodebuild test` ran 99/99 passing. Same gotcha as 2026-04-29 + 2026-04-30. Trust the build, ignore the editor.
- **SendMessage UUID-addressing works** despite the tool description saying "name not UUID." When a spawned Agent returns its `agentId`, SendMessage with `to: "<uuid>"` resumes that agent's transcript. Used twice this session, both first-try success. If the user prefers names, pass `name:` at Agent spawn — but UUIDs are robust.
- **`MKMapItem(placemark:)` is deprecated in iOS 26.** Use `MKMapItem(location:address:)` (the §I expand-disc + Show-more both call this). ios-engineer caught this in Loop 1 without prompting.
- **`ScrollViewReader` placement subtlety** — for `proxy.scrollTo(...)` to scroll the page (not the inner card), the reader must wrap the **child of the outer ScrollView**, not the ScrollView itself. ios-engineer confirmed this in Loop 2 B1. Worth noting if a future feature wants similar scroll-to behavior.
- **Test-count drift in STATUS.md persists.** STATUS.md still says 98/98; actual is 99/99 (and has been since 2026-04-30). Reconcile next time STATUS.md is touched.
- **Working tree pressure increasing.** Six days of uncommitted work + ~14 files modified in v3 alone. The longer this stretches, the harder it gets to write a clean commit message that doesn't read as a kitchen-sink. Worth a soft nudge to user at next session opener.

## Session metadata

- **Duration**: approx. 70 minutes (preflight reads + plan + 2x AskUserQuestion + 4 specialist round-trips via Agent + SendMessage + close-out paperwork).
- **Build state at end**: clean (`** BUILD SUCCEEDED **` on iPhone 17 Pro after Loop 2).
- **Test state at end**: **99/99 passing**, 0 failures. No regressions across either loop.
- **Working tree at end**: dirty by design. ~14 files modified across the v3 ship (6 new components + 4 modified component files + 1 view file + paperwork). No commits.
- **Specialist roundtrip count**: 4 (ios-engineer L1, design-reviewer L1, ios-engineer L2, design-reviewer L2).
- **Ship verdict**: SHIP. v3 is ready for STATUS.md / commit.
