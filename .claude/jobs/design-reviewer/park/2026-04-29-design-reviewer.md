# Park Document — design-reviewer — 2026-04-29

## Session summary

Audited the Listing Detail v2 visual pass per `docs/specs/Listing Detail v2 visual pass.md`. Returned a structured verdict: **loop back**. One blocker, one major, three minors, two nits. Five locked-decision items (surface color, host-tenure drop, footer subtitle, decorative share, statusDanger Reserve) were verified verbatim and left unscored per the inbox brief.

The blocker is a **duplicate back affordance** — the v1 audit's M3 fix (`.navigationTitle + .inline`) was correct for v1 but is now in conflict with v2's floating back-chevron disc. Two back chevrons render simultaneously over the hero. Fix: hide the nav bar (`.toolbar(.hidden, for: .navigationBar)`) and let the floating disc be the single back affordance, matching the Airbnb reference.

The major is **floating-cluster ignoring top safe-area** on Dynamic Island devices — `padding(.top, Spacing.base)` is a fixed 16pt with no inset awareness, so the discs slide under the island/nav bar on iPhone 14/15/16/17 Pro models. Fix: `.safeAreaPadding(.top)`.

Audit landed at `docs/audits/2026-04-29-design-audit-Listing Detail v2.md`. No code changed by me — review-only output.

## Files touched

| File | Change | Why |
| --- | --- | --- |
| `docs/audits/2026-04-29-design-audit-Listing Detail v2.md` | Created | The audit itself — primary deliverable |
| `.claude/jobs/design-reviewer/park/2026-04-29-design-reviewer.md` | Created | This park doc |
| `.claude/jobs/design-reviewer/inbox/20260429_0345-from-coo-Listing Detail v2 visual pass.md` | Moved → history/ | Processed |

Did not write a separate inbox message to ios-engineer this loop — COO routes the loop-back per the inbox brief ("Do NOT modify any Swift files — audit only. If you find blockers, write them up; COO will route the fixes back to ios-engineer.").

## Findings (full detail in the audit doc)

### Blocker

- **B1** — Duplicate back affordance: floating chevron disc + system inline nav-bar back chevron render simultaneously after the v2 visual pass. v1's M3 fix (`.navigationTitle + .inline`) is now in conflict with v2's `§B` floating cluster. Fix: hide the nav bar with `.toolbar(.hidden, for: .navigationBar)`. One-line change at `ListingDetailView.swift:52–53`.

### Major

- **M1** — Hero floating-buttons cluster slides under the navigation bar / Dynamic Island on Pro-class devices. `.padding(.top, Spacing.base)` is fixed 16pt with no top-safe-area awareness. Fix: `.safeAreaPadding(.top)` at `ListingDetailView.swift:107`. One-line change.

### Minors

- **m1** — Amenity icon glyph size `16` is a magic number (`ListingAmenitiesSection.swift:33`). Spec-faithful; recommend accept as a leaf primitive with a doc-comment.
- **m2** — Amenity icon container `36×36` is a magic number (`ListingAmenitiesSection.swift:35`). Same class as m1; recommend accept.
- **m3** — Counter pill `Color.black.opacity(0.5)` (`ListingPhotoGalleryView.swift:63`) does not honor Reduce Transparency. Spec-locked but worth a hairline-stroke harden in a future polish pass.

### Nits

- **n1** — Fee-tag dismissal transition is dual-tracked (explicit `.opacity.combined(with: .move)` + implicit layout collapse). Reads fine at 0.18s real-time. Tuning available if a polish pass touches the footer.
- **n2** — Counter pill vertical padding routed through `Spacing.sm` is a token-compromise (value `4`, semantics "tight pill padding"). Pre-approved by the inbox brief; flag for the next tokens-pass.

## Decisions made

### Decision: B1 fix is to hide the nav bar (option 2 from v1's M3), not remove the floating chevron. (Severity: Blocker.)

- **What**: replace `.navigationTitle(viewModel.listing.title) + .navigationBarTitleDisplayMode(.inline)` with `.toolbar(.hidden, for: .navigationBar)`. The floating chevron disc becomes the single back affordance on this surface.
- **Why**: the v2 spec adopted the Airbnb reference's hero-photo-immersive treatment verbatim — three floating discs over a full-bleed photo with no nav bar. The v1 audit's M3 fix (option 1: add inline title) was correct *for v1* (no floating chevron existed). v2 supersedes it: now both back affordances ship, and the user sees two stacked chevrons. Hiding the nav bar matches the reference and resolves the duplication.
- **Why not "remove the floating chevron and keep the nav bar"**: the v2 spec explicitly demands the floating cluster (locked decision §B). Removing the floating chevron would void the spec.
- **Reversibility**: trivial. If the team decides hero-photo-immersion is too aggressive, swap back to inline title and remove the floating chevron — but that's a v3 spec call, not a fix loop.

### Decision: m3 (Reduce Transparency on counter pill) ships as-is; flagged as watch.

- **What**: keep the spec-locked `Color.black.opacity(0.5)` capsule fill on the counter pill. Don't promote to a Major even though Reduce Transparency is a real HIG concern.
- **Why**: the inbox brief explicitly flags counter-pill contrast as a known hot-spot the user pre-approved the trade-off on. Per the brief — "If you find a *new* HIG concern with any of these, flag it as a minor with a 'user pre-approved this trade-off' note." Applied.
- **Reversibility**: cheap. Three options listed in the audit (hairline stroke / `.thinMaterial` / bump opacity to 0.6); any can land in a polish pass.

## Hot-spots cross-check (per inbox brief)

The inbox brief named four engineer-flagged hot-spots. My audit position on each:

1. **Title-block centering at AX5** — flagged as a watch item under "AX5 dynamic-type sweep" in the audit. Not a finding this loop because the spec explicitly demanded centered alignment for the rating row. Manual AX5 pass before /ship-prep — if optical balance reads off, switch to leading.
2. **Hero floating-button top inset on Dynamic Island** — promoted to **Major (M1)**. Engineer's instinct was right; the fix is `.safeAreaPadding(.top)`.
3. **Counter pill contrast on dark photos under Reduce Transparency** — flagged as **Minor (m3)** with three optional fixes. Spec-locked; ship as-is with a hairline-stroke harden recommended for the next polish pass.
4. **Fee-tag dismissal transition tuning** — flagged as **Nit (n1)**. The current 180ms motion reads fine in real time; the dual-track is only visible on slow-motion playback. Recommend ship as-is.

## Open questions / blockers

- None on my side. Holding for ios-engineer's re-submission on B1 + M1.
- The two policy questions to COO from v1 (project-wide auto-hide-tab-bar invariant; project-wide `.notFound` UX policy) are still open. Neither blocks this v2 loop.

## Inbox state at session end

- **Processed (moved to history/)**:
  `20260429_0345-from-coo-Listing Detail v2 visual pass.md` — audit complete, verdict delivered.
- **Remaining**: none.

## Outbox summary

- No new inbox messages sent — COO routes the loop-back per the inbox brief constraint ("audit only — COO will route the fixes back to ios-engineer").
- The audit doc itself (`docs/audits/2026-04-29-design-audit-Listing Detail v2.md`) and this park doc are the deliverables.

## What the next session should do first

1. Read this park doc + `context/current.md`.
2. Check the design-reviewer inbox for ios-engineer's re-submission message confirming B1 + M1 are resolved (COO will route once engineer lands the fixes).
3. Re-audit just those two spots:
   - B1: confirm `.toolbar(.hidden, for: .navigationBar)` replaces the inline-title pair, and confirm the floating chevron is the only back affordance on push.
   - M1: confirm the floating cluster honors top safe-area on iPhone 17 Pro (default sim) — discs sit clear of the Dynamic Island.
4. Update the existing audit file in place with a "2026-04-XX re-audit" section. Don't fork a new audit; the doc tracks the surface, not the pass.
5. **Run an AX5 manual pass on Listing Detail v2** before /ship-prep — title-block centering risk + sticky-footer height risk. Carry-over from v1 audit's "untested" flag plus v2's new risks (centered rating row, bumped `martiHeading3` price). Fold into the re-audit section.
6. If verdict flips to ✅, drop a confirmation message in COO's inbox to unblock /ship-feature close-out.

## Gotchas for next session

- **The v1→v2 chrome conflict is the recurring failure mode.** Each visual revision can silently invalidate the prior audit's fix. Watch this on every multi-loop surface: re-read the prior audit's findings list before the current audit starts, check whether each fix is still consistent with the new spec. v1's M3 fix (`.navigationTitle + .inline`) was correct at the time and still in the file unchanged — but v2's `§B` floating cluster turns it into a defect. The audit framework needs to flag "prior fixes that no longer cohere with the current spec" as a class.

- **`Color.black.opacity(0.5)` is in the diff but it's spec-locked.** Don't reflexively flag literal colors as token drift — check the spec first. If the spec calls for a SwiftUI primitive (`Color.black`, `Color.white`), it's not drift; it's a spec choice. The token adherence score in the audit reflects this nuance.

- **`.glassDisc(diameter:)` is a Chrome recipe, not a token.** It composes `.ultraThinMaterial` + a hairline stroke + the `.glassDisc` shadow token. Reduce Transparency *will* flip the material to opaque automatically — so the back/share/heart discs honor Reduce Transparency for free, but the counter pill (which uses `Color.black.opacity(0.5)`, not material) does not. This is the asymmetry behind m3.

- **Leaf-primitive integer literals (`16`, `36`) for SF Symbol glyph sizing and small UI containers are still acceptable** under DESIGN.md — same call as v1's `m3` (marker diameter) and `m2` (avatar diameter). The rule is "if a value isn't in the scale, add it to the scale, **OR** call it out as an explicit leaf primitive." Both choices are legitimate; flag minors when the call hasn't been made either way.

- **`.safeAreaPadding(.top)` vs `.safeAreaInset(.top)`** — both work for M1's fix. `safeAreaPadding` is the lighter touch (just adds inset to the existing layout); `safeAreaInset` is for inserting new chrome that should *be* the safe area boundary. For a floating overlay that wants to sit clear of system chrome, `.safeAreaPadding(.top)` is correct.

## Session metadata

- **Duration**: approx. 25 minutes
- **Output state at end**: audit complete, verdict delivered to COO via the audit doc, inbox processed.
- **Build state**: not run (audit-only role; engineer reports green and the inbox brief explicitly says SourceKit phantom diagnostics on the four files are benign — `xcodebuild build` is genuinely green).
- **Test state**: not run (audit-only role; engineer reports 98/98 untouched — no test-level changes in this v2 visual pass per the spec's Non-goals §).

---

## Loop 2 follow-up — 2026-04-29

Re-audit pass on Listing Detail v2 after ios-engineer landed the B1 + M1 fixes. Scope was the two flagged spots only; m1/m2/m3/n1/n2 were out of scope per COO direction.

### Verdict

**Ship.** Both blockers from Loop 1 closed. HIG compliance score moves from 6/10 → 9/10. Token adherence unchanged at 8.5/10 (view-only chrome edits, no token changes).

### Verification summary

- **B1 cleared.** `.navigationTitle + .navigationBarTitleDisplayMode(.inline)` replaced by `.toolbar(.hidden, for: .navigationBar)` at `ListingDetailView.swift:52`. System nav bar is suppressed; floating chevron disc at `:109–118` is the sole back affordance, still wrapping `dismiss()` and rendering `chevron.left` on `.glassDisc(diameter: 44)`. VoiceOver focus-order side effect also closed.
- **M1 cleared.** `.padding(.top, Spacing.base)` replaced by `.safeAreaPadding(.top)` at `ListingDetailView.swift:106`, with horizontal padding still on `:105`. Cluster honors top safe area on Dynamic Island devices. Fix landed verbatim from option 1 in the original finding.

### Files touched this loop

| File | Change | Why |
| --- | --- | --- |
| `docs/audits/2026-04-29-design-audit-Listing Detail v2.md` | Appended "Re-audit pass — 2026-04-29" section | Loop 2 verification; same surface, new pass |
| `.claude/jobs/design-reviewer/park/2026-04-29-design-reviewer.md` | Appended this Loop 2 follow-up section | Per the brief: don't write a fresh park doc |

### Carry-forward (unchanged from original audit)

- m1, m2, m3, n1, n2 — explicitly out of scope per COO direction. Not re-scored.
- AX5 manual sweep — still untested; watch item before `/ship-prep`. Not gating.
- Test count drift (98 → 97) — reconciled by ios-engineer. View-only edits cannot change test count; not scored.
- SourceKit phantom diagnostics — benign per the brief; build green per ios-engineer; not scored.

### What the next session should do first

The re-audit is closed. If COO opens a new loop on this surface (e.g., AX5 manual sweep finds a layout regression), re-read the audit doc and append a new dated section. Otherwise this surface is parked.

### Loop 2 gotchas

- **Re-audit framing worked well.** Reading the prior audit's findings list before the re-audit confirmed both fixes landed on the exact lines flagged (`:52` for B1, `:106` for M1). The `current.md` + park doc + inbox brief loop is doing its job — no surprise scope creep, no re-litigation of out-of-scope items.
- **`.safeAreaPadding(.top)` on a single child of a `ZStack(alignment: .top)` is the correct lightweight fix** for floating chrome that should sit below the device's top safe area. Worth recording as a recipe — likely to recur on future hero-photo surfaces.
