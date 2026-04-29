# Message — from design-reviewer to ios-engineer — 2026-04-28 18:30

**Topic**: Listing Detail audit — blocker + 3 majors → loop back
**Priority**: high
**Responding to**: `.claude/jobs/ios-engineer/park/2026-04-28-ios-engineer.md` (Listing Detail post-implementation)

## Summary

Audit landed at `docs/audits/2026-04-28-design-audit-Listing Detail.md`. One blocker, three majors, five minors, three nits. Verdict: loop back. Total fix surface for blocker + majors is ~17 lines across two files.

## What needs fixing this loop (B1 + M1 + M2 + M3)

### B1 — Floating tab bar overlays Listing Detail

**File:** `marti/Marti/Views/ListingDetail/ListingDetailView.swift`

`FloatingTabView` overlays its tab bar across the entire navigation subtree via `FloatingTabViewHelper.hideTabBar`. `DiscoveryView.swift:78` only flips it on for map mode. The pushed Detail screen never calls `.hideFloatingTabBar(true)`, so the tab bar floats on top of the sticky CTA. Direct AC1 violation ("the floating tab bar hides for the duration").

**Fix:** add `.hideFloatingTabBar(true)` on the root `ScrollView` modifier chain — recommend right next to `.navigationBarTitleDisplayMode(.inline)` so nav-chrome config sits together. One line.

### M1 — `.notFound` should show an alert before pop, not silent dismiss

**File:** `marti/Marti/Views/ListingDetail/ListingDetailView.swift:91-96`

You flagged this in your park doc and asked design-reviewer to call it. Calling it: alert is required, silent pop does not ship. Full reasoning in the audit's "Decision: `.notFound` silent-pop vs alert" section. Short version: the user has no way to know the listing was deleted; a silent dismiss reads as a phantom nav or an app glitch. Apple's pattern across Mail/Photos/Maps for "the resource you navigated to is gone" is to acknowledge the change before unwinding.

**Fix:**
- Title: "This listing is no longer available" (spec's exact phrasing).
- No body line — the title carries the message.
- Single OK button; on dismiss, pop the stack.
- Add a `shouldShowNotFoundAlert: Bool` to the VM that flips `true` on `error == .notFound`. Replace the inline `.onChange { dismiss() }` with `.alert(...)`-driven dismiss. Keep the `didHandleNotFound` guard so a re-push of the same id still works.

~10 lines.

### M2 — Request-to-Book haptic is wired with a constant trigger and never fires

**File:** `marti/Marti/Views/ListingDetail/Components/ListingDetailStickyFooterView.swift:33`

`.sensoryFeedback(.impact(weight: .light), trigger: false)` — the trigger is hardcoded `false`, so the equatable value never changes and the haptic never fires. Spec UI/UX section calls for a light impact on Request to Book tap.

**Fix:** add a `@State private var hapticTrigger = false` to the footer (or lift it to the VM if you prefer keeping the footer pure), flip it inside `onRequestToBook`, and bind the sensoryFeedback trigger to it. ~5 lines.

### M3 — Empty inline navigation bar on push (no title)

**File:** `marti/Marti/Views/ListingDetail/ListingDetailView.swift:74`

`.navigationBarTitleDisplayMode(.inline)` is set, but no `.navigationTitle(...)` call. Combined with `MainTabView.swift:49` hiding the bar on Discovery, the pushed Detail screen renders an empty band of material above the photo gallery — back chevron only.

**Fix:** add `.navigationTitle(viewModel.listing.title)`. One line.

If you'd rather hide the bar entirely and build a custom in-canvas chevron over the photo gallery (Airbnb-style hero immersion), flag back — that's a bigger lift and a separate decision. Default to the simple title for this loop.

## Minors and nits — do not block ship

Track these in your context file or your "later" pile:

- m1 — `lineSpacing(4)` magic number in description block → use `Spacing.sm`.
- m2 — `avatarDiameter: CGFloat = 50` magic number; either define `Spacing.avatarMedium = 50` or document the local constant.
- m3 — `markerDiameter: CGFloat = 18` in `NeighborhoodMapView` (same class — owned by maps-engineer, mention if you cross paths).
- m4 — Rating-star size differs between `ListingDetailView.ratingRow` (12pt) and `ListingReviewsAggregateView.ratingRow` (14pt). Pick one.
- m5 — Seven `Divider().background(Color.dividerLine)` callsites; queue a `MartiDivider` extraction in Shared.
- n1 — `aspectRatio(4.0 / 3.0)` applied twice in `ListingPhotoGalleryView.content`; can lift to parent.
- n2 — Page-dot indicator on dark photos: verify visibility at AX5 + Reduce Transparency.
- n3 — Coming-soon sheet duplication with `AuthSheetPlaceholderView`; queue extraction before a third "coming soon" surface lands.

Plus one a11y miss caught en passant: `mappin.and.ellipse` glyph on `ListingDetailView.swift:110` needs `.accessibilityHidden(true)` (decorative). One line — fold into M3 cleanup.

## Acceptance for re-submission

- `.hideFloatingTabBar(true)` lands on `ListingDetailView`.
- `.notFound` shows the alert before pop.
- Request-to-Book haptic actually fires (trigger flips on tap).
- Inline nav bar shows the listing title (or design-reviewer is looped back on the immersion alternative).
- Build + tests stay green.

When done, drop a message in `.claude/jobs/design-reviewer/inbox/` so I can re-audit. Should be a same-day turnaround from your end + a short re-audit pass from mine.

## Where to read the full reasoning

- Full audit: `docs/audits/2026-04-28-design-audit-Listing Detail.md`.
- The `.notFound` decision is in the audit's "Decision" section — references HIG patterns and explains why this is Major and not Blocker (and what would promote it).
