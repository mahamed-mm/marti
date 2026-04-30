# Park Document — design-reviewer — 2026-04-28

## Session summary

Audited the Listing Detail surfaces shipped by ios-engineer and
maps-engineer per `docs/specs/Listing Detail.md`. Returned a structured
verdict: loop back. One blocker, three majors, five minors, three nits.
Made the call on the open `.notFound` silent-pop vs alert question:
alert is required.

Audit landed at `docs/audits/2026-04-28-design-audit-Listing Detail.md`.
Routed loop-back instructions to ios-engineer and an audit summary to
COO. No code changed by me — review-only output.

## Files touched

| File | Change | Why |
| --- | --- | --- |
| `docs/audits/2026-04-28-design-audit-Listing Detail.md` | Created | The audit itself — primary deliverable |
| `.claude/jobs/ios-engineer/inbox/20260428_1830-from-design-reviewer-Listing Detail audit findings.md` | Created | Loop-back instructions for the four required fixes |
| `.claude/jobs/coo/inbox/20260428_1835-from-design-reviewer-Listing Detail audit verdict.md` | Created | Verdict + counts + decision-log suggestions |
| `.claude/jobs/design-reviewer/context/current.md` | Replaced | First non-stub state |
| `.claude/jobs/design-reviewer/park/2026-04-28-design-reviewer.md` | Created | This park doc |
| `.claude/jobs/design-reviewer/inbox/20260428_1730-from-coo-Listing Detail.md` | Moved → history/ | Processed |

## Findings (full detail in the audit doc)

### Blocker

- **B1** — `FloatingTabBar` overlays the sticky CTA on Listing Detail
  because the screen never calls `.hideFloatingTabBar(true)`. AC1 violation.
  One-line fix in `ListingDetailView.swift`.

### Majors

- **M1** — `.notFound` triggers a silent dismiss instead of the spec-canonical
  alert + pop. Decision below.
- **M2** — Request-to-Book haptic wired with `.sensoryFeedback(..., trigger: false)`
  — constant trigger, never fires. ~5 lines in `ListingDetailStickyFooterView.swift`.
- **M3** — Detail screen pushes with an empty inline nav bar (no
  `.navigationTitle`). Reviewers will flag.

### Minors / nits

- m1 — `lineSpacing(4)` magic number → `Spacing.sm`.
- m2 — `avatarDiameter: CGFloat = 50` magic number; pick token or document.
- m3 — `markerDiameter: CGFloat = 18` in `NeighborhoodMapView` (same class).
- m4 — Rating-star size differs between title row (12pt) and reviews
  aggregate (14pt) on the same screen.
- m5 — Seven `Divider().background(Color.dividerLine)` callsites in one
  file — extract a `MartiDivider`.
- n1 — `aspectRatio(4.0 / 3.0)` applied twice in photo gallery branches.
- n2 — Page-dot indicator visibility on dark photos at Reduce Transparency
  is unverified.
- n3 — `RequestToBookComingSoonSheet` and `AuthSheetPlaceholderView` are
  structurally identical — extract before a third "coming soon" surface
  lands.

## Decisions made

### Decision: `.notFound` is alert + pop, not silent pop. (Severity: Major.)

- **What**: When `fetchListing` returns `AppError.notFound`, the View must
  show an alert ("This listing is no longer available") and pop on OK.
  The current silent `dismiss()` on `.onChange(of: error)` is rejected.
- **Why**: The user has no signal a listing was deleted between push and
  refresh. A silent dismiss reads as a phantom nav transition or an app
  glitch. Apple's pattern across Mail / Photos / Maps for a navigated-to
  resource that's gone is consistent: acknowledge the change before
  unwinding. The alert's job isn't to inform; it's to turn a confusing
  nav event into a deliberate one.
- **Why Major and not Blocker**: the screen does dismiss; data is not at
  risk and App Review won't reject. Promote to Blocker if unresolved at
  /ship-prep. ios-engineer estimated the swap at 5–10 minutes.
- **Alternatives considered**: keep silent dismiss (rejected — confusion
  over brevity); add a transient toast in Discovery on return (rejected —
  more code than the alert and doesn't solve the "what just happened" beat
  on Detail).
- **Reversibility**: cheap. Single alert binding on the view. If user
  testing later shows the alert is overkill, swap to a Discovery-side
  toast and revisit.

### Decision: hold off on a project-wide auto-hide-tab-bar invariant pending COO call.

- **What**: B1 (the tab bar overlay) is fixed by adding one line to the
  Listing Detail view, not by changing the platform. Leaving the platform
  as-is for now.
- **Why**: changing `FloatingTabViewHelper` to auto-hide on push depth
  changes behavior for every future pushed surface — Saved detail,
  Bookings detail, Message thread. That's a one-way decision worth a
  COO decision-log entry rather than a quiet platform tweak from a
  design audit.
- **Routed**: noted in the COO inbox message as a candidate `decisions.md`
  entry. Their call.
- **Reversibility**: trivial both ways — either fix all pushed views (one
  line each) or change the helper (a few lines plus a behavior decision).

## Open questions / blockers

- None on my side. Holding for ios-engineer's re-submission.
- Two open policy questions surfaced for COO:
  1. Project-wide invariant on detail-screen tab-bar hiding (per-view vs.
     auto-hide-on-push).
  2. Project-wide UX policy on `.notFound` resource-gone transitions
     (alert vs. toast vs. silent — current call: alert).

## Inbox state at session end

- **Processed (moved to history/)**:
  `20260428_1730-from-coo-Listing Detail.md` — audit complete, verdict
  delivered, loop-back issued.
- **Remaining**: none.

## Outbox summary

- `ios-engineer` ← loop-back with the four required changes (B1+M1+M2+M3).
- `coo` ← verdict, counts, decision suggestions for `decisions.md`.

## What the next session should do first

1. Read this park doc + `context/current.md`.
2. Check the design-reviewer inbox for ios-engineer's re-submission
   message confirming B1+M1+M2+M3 are resolved.
3. Re-audit just those four spots. Update the existing audit file in
   place with a "2026-04-XX re-audit" section — same file, dated subsection.
   Don't fork a new audit; the doc tracks the surface, not the pass.
4. Run an AX5 manual pass on Listing Detail (title row, host card,
   sticky footer) since the original audit flagged it as untested. Fold
   into the re-audit notes.
5. If verdict flips to ✅, drop a confirmation message in COO's inbox
   to unblock /ship-feature close-out.

## Gotchas for next session

- **The `.hideFloatingTabBar` invariant is ambient, not enforced.** The
  helper sits on `FloatingTabViewHelper` in the environment. Any pushed
  surface that forgets to call `.hideFloatingTabBar(true)` inherits
  whatever state Discovery left behind. Worth flagging on every
  detail-ish surface review until COO either codifies a project-wide
  invariant or auto-hides at the helper level.
- **The `marti*` typography tokens cover everything text.** `.font(.system(size:…))`
  is permitted **only** for SF Symbol icon glyph sizing — DESIGN.md is
  unambiguous. Two callsites in this surface use it correctly (icon
  glyphs); none misuse it. Watch for drift on future surfaces.
- **Shadow tokens are five (`Shadow.glassDisc/pin/island/tabBar/floatingCard`).**
  Any new shadow recipe should pick one of those, not a free-floating
  `(color:radius:y:)` triplet. The maps-engineer's marker shadow on
  `NeighborhoodMapView.swift:128` uses a free-floating triplet — flag
  on future map-engineer reviews; not in scope this audit.
- **`docs/audits/2026-04-19-design.md` is the most recent prior audit.**
  Useful for cross-checking continuity (same tokens, same patterns) when
  a new surface lands. Reference list of which tokens appear in which
  callsites is in §"Color system" of that doc.

## Session metadata

- **Duration**: approx. 35 minutes
- **Output state at end**: audit complete, loop-back routed, COO and
  ios-engineer notified, inbox processed.
- **Build state**: not run (audit-only role; engineer reports green).
- **Test state**: not run (audit-only role; engineer reports 98/98).

## Loop 2 re-audit — 2026-04-28 (later same day)

ios-engineer landed B1+M1+M2+M3 plus the small a11y fold-in and pinged
back via inbox at 19:00. Ran a narrow re-audit on just those five items —
no scope expansion, no re-litigating minors/nits.

### Verification at file:line

- **B1** ✅ — `Views/ListingDetail/ListingDetailView.swift:76` —
  `.hideFloatingTabBar(true)` lives next to `.navigationBarTitleDisplayMode(.inline)`,
  the placement I recommended.
- **M1** ✅ — VM gains `shouldShowNotFoundAlert` flag at
  `ViewModels/ListingDetailViewModel.swift:50`; `refresh()` flips it
  in the `.notFound` branch (`:108–112`); View binds it to
  `.alert("This listing is no longer available", isPresented: …)`
  at `Views/ListingDetail/ListingDetailView.swift:93–102` with single
  OK button → `dismiss()`. Title matches spec exactly. `didHandleNotFound`
  guard preserved.
- **M2** ✅ — `ListingDetailStickyFooterView.swift:20,37,41` — real
  `@State` `hapticTrigger`, button toggles it before `onRequestToBook()`,
  `.sensoryFeedback` binds to the changing `Bool`. Light-impact weight
  matches spec.
- **M3** ✅ — `Views/ListingDetail/ListingDetailView.swift:74` —
  `.navigationTitle(viewModel.listing.title)`. Option 1 from the audit,
  default Apple-style inline title.
- **a11y fold-in** ✅ — `Views/ListingDetail/ListingDetailView.swift:117` —
  `.accessibilityHidden(true)` on the `mappin.and.ellipse` glyph. The
  adjacent neighborhood text carries the meaning.

### Build + test re-run

I broke role precedent and re-ran `MartiTests` on this loop — the audit's
verdict claims "ship" so I wanted independent verification rather than
trusting the engineer's report alone.

- **Result:** `** TEST SUCCEEDED **`, 98 passed / 0 failed. Matches the
  engineer's report exactly. No regressions in adjacent suites.
- **Command:** `xcodebuild -project marti/Marti.xcodeproj -scheme Marti -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:MartiTests test`.
- This is the right pattern at the ship gate even from an audit-only
  role: the verdict to ship should not be conditional on someone else's
  green light. Cheap to run, keeps the gate honest.

### Test coverage updates I checked

- `ListingDetailViewModelTests.swift:31` — `vm.shouldShowNotFoundAlert == false`
  on init.
- `ListingDetailViewModelTests.swift:81` — `vm.shouldShowNotFoundAlert == true`
  after `.notFound` is surfaced.
- No new test methods (assertions extended in place), no deletions.
  Total `MartiTests` count unchanged at 98.

### Final verdict — Loop 2

✅ **Ship.** All four named findings + a11y fold-in pass. Build green,
tests green, no regressions. Audit `docs/audits/2026-04-28-design-audit-Listing Detail.md`
gets a "Re-audit (Loop 2)" appended section confirming each fix.

### Loop 2 outbox

- ios-engineer ← no new inbox message; the re-audit lives in the audit
  doc and they already have their next-session pointer in
  `context/current.md`. If they want a confirmation ping, COO routes it.
- COO ← no new inbox message **from this loop** (the original verdict
  message from Loop 1 already flagged the two policy questions). The
  COO can now read the appended Loop 2 section directly to unblock
  `/ship-feature Listing Detail` close-out.

### Loop 2 inbox state

- **Processed (moved to history/)**:
  `20260428_1900-from-ios-engineer-Listing Detail re-audit.md` — Loop 2
  re-audit complete, ship verdict appended.
- **Remaining**: none.

### Carryover for next session

- Minors and nits from Loop 1 (m1–m5, n1–n3) are still open by intent.
  Engineer carries them in their `context/current.md` under "deferred
  from audit". `m3` (`markerDiameter` in `NeighborhoodMapView`) belongs
  to maps-engineer — flag if you re-audit that surface.
- Two policy questions to COO remain open from Loop 1 — neither blocks
  this ship; both are decision-log candidates:
  1. Project-wide auto-hide-tab-bar invariant (per-view vs. helper-level).
  2. Project-wide `.notFound` UX policy (current call: alert; revisit
     once a second `.notFound` surface lands).
- AX5 manual pass on Listing Detail was **not** run this loop — the
  re-audit was scoped to the four named fixes, and AX5 verification
  wasn't a Loop 1 finding (it was a watch-item under "a11y gaps"). Pick
  it up on the next AX5 sweep, or fold into the next surface review
  that touches sticky-footer layouts.
