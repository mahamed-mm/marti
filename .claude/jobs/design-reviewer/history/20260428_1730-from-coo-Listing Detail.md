# Message — from coo to design-reviewer — 2026-04-28 17:30

**Topic**: HIG audit — Listing Detail surfaces
**Priority**: high
**Responding to**: (initial)

## Objective

Audit the new Listing Detail surfaces. Write findings to `docs/audits/2026-04-28-design-audit-Listing Detail.md`. Return a severity summary.

## Acceptance criteria

- New audit file at `docs/audits/2026-04-28-design-audit-Listing Detail.md` covering:
  - `marti/Marti/Views/ListingDetail/ListingDetailView.swift`
  - `marti/Marti/Views/ListingDetail/Components/*.swift` (gallery, host card, amenities, cancellation policy, reviews aggregate, sticky footer, coming-soon sheet)
  - `marti/Marti/Views/Shared/NeighborhoodMapView.swift`
- Findings categorized: **blocker** / **major** / **minor** / **nit**.
- Specific check on the open-question follow-up from ios-engineer:
  > Spec edge case 5 says "show alert + pop" when `fetchListing` returns `.notFound`. ios-engineer shipped a silent `dismiss()` instead. Decide whether the silent pop is acceptable or whether an alert is required (HIG-wise).
- Park doc written at `.claude/jobs/design-reviewer/park/2026-04-28-design-reviewer.md`.

## Context

`/ship-feature Listing Detail` is post-implementation. Build and tests are green. Last gate before COO close-out. Look at typography, spacing, dark-mode contrast, AX5 layout, sticky-footer safe-area handling, page-dot indicator visibility on photos, VoiceOver labels.

## Relevant files / specs

- Spec: `docs/specs/Listing Detail.md` (see Acceptance Criteria, Edge Cases, UI/UX sections)
- Tasks: `docs/tasks/Listing Detail.md`
- ios-engineer park doc: `.claude/jobs/ios-engineer/park/2026-04-28-ios-engineer.md`
- Maps-engineer park doc: `.claude/jobs/maps-engineer/park/2026-04-28-maps-engineer.md`
- Design system: `docs/DESIGN.md`, `marti/Marti/Extensions/DesignTokens.swift`
- Architecture rules: `.claude/rules/swiftui.md`, `.claude/rules/architecture.md`

## Constraints

- Audit only. Don't implement fixes. If you find a blocker, write it up; coo will decide whether to loop back to ios-engineer.
- Don't critique decisions that were locked at CHECKPOINT 1 (reviews aggregate-only, host response rate omitted, photo gallery format, etc.) — those are intentional scope boundaries.
- Don't expand scope to Discovery's existing surfaces; this audit is about the new files only.

## Expected response

Return a structured summary:
1. Path to the new audit doc.
2. Findings count by severity.
3. **Verdict**: ✅ no blockers/majors → ship / ⚠️ majors → loop back / ❌ blockers → loop back.
4. Decision on the `.notFound` silent-pop question.
5. Top 3 minors / nits worth queueing for follow-up (no action this ship).
