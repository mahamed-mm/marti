# Current state — design-reviewer

> Last updated: 2026-05-01 (Loop 2 re-audit)
> Update this file at the end of every session.

## What's in flight

**Listing Detail v3 visual-pass audit — Loop 2 re-audit closed at SHIP.**

- Loop 1 audit + Loop 2 re-audit both at `.claude/jobs/design-reviewer/park/2026-05-01-listing-detail-v3-audit.md`.
- Loop 1 verdict: 2 blockers + 4 majors + 5 minors → fix-and-ship.
- Loop 2 verdict: **all 6 cleared, no regressions, ship.** Five minors (m1–m5) remain as documented carry-overs.
- Net AC table: #1–#11, #13, #14 all Pass. #12 overridden by COO.
- Engineering judgment calls validated in Loop 1, untouched in Loop 2: em-dash in §C col-2, Apple Maps hand-off in §I, `surfaceDefault` for §K avatar.
- M2 stroke-drop on §G "Show all" button approved ship-as-is — engineer's spec-literalism + project-precedent + dark-mode-contrast rationale all hold.

## What's clean / stable

- Listing Detail v2 surfaces — last audited at the v2 loop close (2026-04-29).
- Listing Detail v3 — full surface (sections §B–§M) cleared this cycle. Ready for STATUS.md / commit.
- AC #12 explicitly overridden by COO (sheet state on View `@State`, no VM property, no new test). Not flagged.

## What's blocked

Nothing on my side.

## v3-specific watch items (track for next ship)

- **B2 was a project-shape concern.** `.sensoryFeedback(_, trigger:)` applied per row when N rows watch the same trigger fires N times. Same shape will reappear in Bookings detail and Message thread. Recommended a one-line `decisions.md` entry to COO.
- **§I disc + Show-more pair both call `MKMapItem.openInMaps()`.** Not a defect (two entry points for two cohorts); revisit if usage analytics later show one is dead.
- **AX5 manual pass** still untested on the v3 surface — same carry-over from v2. Worth folding into the next audit cycle that touches Listing Detail.

## Open questions

- **Project-wide invariant: should pushed detail screens auto-hide the floating tab bar?** (carry-over from v1/v2.)
- **Project-wide UX policy on `.notFound` resource-gone transitions.** (carry-over from v1/v2.)

## Carry-over minors from v3 audit (m1–m5)

Open as documented; no action required pre-ship. Pick up in the next polish pass through this surface.

- **m1** — §C em-dash foreground `textTertiary` → consider `textSecondary` (`ListingDetailHighlightsRow.swift:60`).
- **m2** — §I disc redundant hint (`ListingDetailView.swift:407–408`).
- **m3** — `amenity != amenities.last` divider in `ListingAmenitiesSheet.swift:30` is fragile on duplicates.
- **m4** — `ComingSoonSheetView` two-dismiss (`ComingSoonSheetView.swift:51` + `:60`).
- **m5** — §L `Spacer(minLength: Spacing.md)` AX5 risk (`ListingDetailThingsToKnowSection.swift:105`).

## Next actions

1. Drop a confirmation message in COO's inbox: v3 cleared, ready for STATUS.md / commit.
2. When the next surface (likely v4 polish or Feature 3 Request-to-Book) lands, fold the deferred AX5 manual sweep on Listing Detail into that cycle.
3. Watch for the `.sensoryFeedback` per-row anti-pattern in Bookings detail / Message thread surfaces — same shape, same bug if not lifted.

## Standing watch items (not actionable until next surface lands)

- **Reduce Transparency check on photo-gallery counter pill** (carry-over from v2 m3).
- **Reduce Motion check on fee-tag dismissal** — 180ms is borderline.
- **`.accessibilityElement(children: .combine)` on container views with a header trait inside** — flag whenever this pattern recurs.

## Files reviewed this cycle (v3 audit, both loops)

Loop 2 re-audit re-read these four (the Loop 1 fix surface):
- `marti/Marti/Views/ListingDetail/ListingDetailView.swift` — B1 + M3
- `marti/Marti/Views/ListingDetail/Components/ListingDetailThingsToKnowSection.swift` — B2
- `marti/Marti/Views/ListingDetail/Components/ListingReviewsAggregateView.swift` — M1
- `marti/Marti/Views/ListingDetail/Components/ListingAmenitiesSection.swift` — M2 + M4

Loop 1 also covered (untouched in Loop 2 — confirmed):
- `marti/Marti/Views/Shared/ComingSoonSheetView.swift`
- `marti/Marti/Views/ListingDetail/Components/ListingDetailHighlightsRow.swift`
- `marti/Marti/Views/ListingDetail/Components/ListingDetailWhyStaySection.swift`
- `marti/Marti/Views/ListingDetail/Components/ListingDetailExpandedHostCard.swift`
- `marti/Marti/Views/ListingDetail/Components/ListingAmenitiesSheet.swift`
- `marti/Marti/Views/ListingDetail/Components/ListingDetailStickyFooterView.swift`
- `marti/Marti/Views/ListingDetail/Components/ListingHostCardView.swift`

Reference primitives consulted (read-only; not in audit scope):
- `marti/Marti/Extensions/DesignTokens.swift`
- `marti/Marti/Views/Shared/VerifiedBadgeView.swift`
- `marti/Marti/Views/Shared/NeighborhoodMapView.swift`
- `marti/Marti/Views/Shared/Buttons.swift`
