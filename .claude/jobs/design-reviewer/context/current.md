# Current state — design-reviewer

> Last updated: 2026-04-29
> Update this file at the end of every session.

## What's in flight

**Listing Detail v2 visual pass — loop-back issued.**

- Audit at `docs/audits/2026-04-29-design-audit-Listing Detail v2.md`.
- Verdict: 1 blocker + 1 major + 3 minors + 2 nits → loop back. Awaiting ios-engineer re-submission on B1 (duplicate back affordance) and M1 (top safe-area on Dynamic Island).
- Pending re-audit pass once those two fixes land.

## What's clean / stable

- Listing Detail v1 surfaces (Loop 2 audit) — re-audit closed at ✅ on 2026-04-28; v2 re-uses the same VM, services, models, tests (98/98 untouched).
- Discovery (list + map modes), Auth placeholder, all `Views/Shared/*` primitives — last reviewed in `docs/audits/2026-04-19-design.md` and unchanged in the v2 diff.

## What's blocked

Nothing on my side. ios-engineer holds the v2 loop-back.

## Open questions

(Both carry-over from v1 audit; neither blocks v2.)

- **Project-wide invariant: should pushed detail screens auto-hide the floating tab bar?** Today every detail surface calls `.hideFloatingTabBar(true)` themselves. Surfaced to COO as a candidate `decisions.md` entry; their call.
- **Project-wide UX policy on `.notFound` resource-gone transitions.** Pinned the v1 decision (alert + pop). COO may want a decision-log entry so Bookings detail and Message thread don't re-debate it.

## v2-specific watch items (track for next loop / next ship)

- **B1 fix introduces a new pattern:** hero-photo immersion via `.toolbar(.hidden, for: .navigationBar)`. Once landed on Listing Detail v2, this becomes the precedent for any future hero-photo-led detail surface. Worth a one-line entry in `decisions.md` (COO call) so future surfaces don't re-litigate inline title vs. hidden nav bar.
- **m3 — Reduce Transparency on `Color.black.opacity(0.5)` counter pill.** Spec-locked, shipped with this loop. Recommend a hairline-stroke harden in the next polish pass through this surface.
- **AX5 manual sweep — still untested.** Carry-over from v1 audit, plus new v2-specific risks: centered rating row optical balance, sticky-footer height growth from `martiHeading3` price bump.

## Next actions

1. When ios-engineer messages back saying B1+M1 are resolved, re-audit those two spots. Update the existing audit file in place with a "2026-04-XX re-audit" section.
2. Run an AX5 manual pass on Listing Detail v2 — title row, host card, sticky footer at AX5 + Reduce Transparency. Fold into the re-audit notes. (This was deferred from v1 audit; v2 re-up-prioritizes it.)
3. If verdict flips to ✅, drop a confirmation message in COO's inbox to unblock /ship-feature close-out.

## Standing watch items (not actionable until next surface lands)

- **Dynamic-Type tests at AX5** for the Listing Detail surface. Two specific risks:
  - Title block centering: leading title/subtitle, centered rating row — optical balance shifts when subtitle wraps.
  - Sticky footer height growth: `martiHeading3` price + 2-line column + 48pt-min Reserve pill — may force axis switch at AX5.
- **Reduce Transparency check on photo-gallery counter pill** (m3 from v2 audit).
- **Reduce Motion check on fee-tag dismissal** — 180ms is borderline; flag for the next animated surface that lands here.

## Files I've reviewed this cycle (v2 audit)

- `Marti/Marti/Views/ListingDetail/ListingDetailView.swift` (restructured)
- `Marti/Marti/Views/ListingDetail/Components/ListingPhotoGalleryView.swift` (counter pill, removed heart)
- `Marti/Marti/Views/ListingDetail/Components/ListingAmenitiesSection.swift` (rounded-square icons, descriptions)
- `Marti/Marti/Views/ListingDetail/Components/ListingDetailStickyFooterView.swift` (Free-cancel row, red Reserve pill)

Reference primitives consulted (read-only; not in audit scope):
- `Marti/Marti/Views/Shared/FavoriteHeartButton.swift`
- `Marti/Marti/Views/Discovery/Components/FeeInclusionTag.swift`
- `Marti/Marti/Extensions/DesignTokens.swift`

Not reviewed (out of scope per spec Non-goals §):
- `Marti/Marti/ViewModels/ListingDetailViewModel.swift` — no behavior changes in v2.
- `Marti/Marti/Services/*` — no service changes.
- `Marti/Marti/Models/Listing.swift` — no model changes.
- `Marti/Marti/Views/ListingDetail/Components/ListingHostCardView.swift` — visual sanity check only.
- `Marti/Marti/Views/ListingDetail/Components/ListingCancellationPolicyView.swift` — unchanged.
- `Marti/Marti/Views/ListingDetail/Components/ListingReviewsAggregateView.swift` — unchanged.
